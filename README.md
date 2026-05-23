# device_integrity

[![pub package](https://img.shields.io/pub/v/device_integrity.svg)](https://pub.dev/packages/device_integrity)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A single Flutter plugin that wraps every first-party device-attestation
API on Android and iOS:

| Platform              | API                                                      |
| --------------------- | -------------------------------------------------------- |
| Android (GMS)         | **Google Play Integrity** — classic & standard requests  |
| Android (HMS)         | **Huawei SafetyDetect** — SysIntegrity, URL check, User Detect, Wi-Fi Detect, AppsCheck |
| iOS 11+               | **Apple DeviceCheck** (`DCDevice`)                       |
| iOS 14+               | **Apple App Attest** (`DCAppAttestService`)              |

> ⚠️  **All tokens returned by this plugin are opaque blobs that must be
> verified on your backend server.** Never trust an integrity verdict
> computed on the device itself — the value of these APIs comes from the
> server-side signature and replay check.

---

## Table of contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Google Play Integrity (Android, GMS)](#google-play-integrity-android-gms)
  - [Verdicts you can request](#verdicts-you-can-request)
  - [Classic request](#classic-request)
  - [Standard request](#standard-request)
- [Huawei SafetyDetect (Android, HMS)](#huawei-safetydetect-android-hms)
- [Apple DeviceCheck (iOS)](#apple-devicecheck-ios)
- [Apple App Attest (iOS 14+)](#apple-app-attest-ios-14)
- [Server-side verification](#server-side-verification)
- [Error handling](#error-handling)
- [API reference](#api-reference)

---

## Installation

```yaml
dependencies:
  device_integrity: ^0.1.0
```

### Android

In `android/build.gradle` (project level) add the Huawei Maven repo so
that the HMS SafetyDetect SDK can be resolved:

```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://developer.huawei.com/repo/' }
    }
}
```

The plugin's `minSdkVersion` is **21**. Play Integrity needs nothing in
your manifest. Huawei SafetyDetect needs the `agconnect-services.json`
file from AppGallery Connect dropped into `android/app/`.

### iOS

- Deployment target: **iOS 14.0** (App Attest requires it).
- Add the `DeviceCheck` capability to your app on Apple Developer
  Portal (no extra entitlement file is required — the framework is
  linked by the podspec).
- For App Attest, your provisioning profile must include the
  **App Attest** entitlement (`com.apple.developer.devicecheck.appattest-environment`)
  set to `production` (or `development` for testing).

---

## Quick start

```dart
import 'package:device_integrity/device_integrity.dart';

final integrity = const DeviceIntegrity();

// Android (Google Play)
final play = await integrity.playIntegrityToken(
  cloudProjectNumber: '123456789012',
);
if (play.success) send(play.token!); else handle(play.error);

// iOS (DeviceCheck)
if (await integrity.isDeviceCheckSupported()) {
  final dc = await integrity.deviceCheckToken();
  if (dc.success) send(dc.token!);
}
```

---

## Google Play Integrity (Android, GMS)

### Verdicts you can request

This plugin supports every verdict currently exposed by the Play
Integrity API. Enable the ones you need in
**Play Console → Release → Setup → App integrity → Play Integrity API**
and link a Google Cloud project so the SDK can request them:

| Category               | Field in the decoded token              | Possible values                                                                                                |
| ---------------------- | --------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| Account details        | `appLicensingVerdict`                   | `LICENSED`, `UNLICENSED`, `UNEVALUATED`                                                                        |
| Application integrity  | `appRecognitionVerdict`                 | `PLAY_RECOGNIZED`, `UNRECOGNIZED_VERSION`, `UNEVALUATED`                                                       |
| Device integrity       | `deviceRecognitionVerdict`              | `MEETS_BASIC_INTEGRITY`, `MEETS_DEVICE_INTEGRITY`, `MEETS_STRONG_INTEGRITY`                                    |
| Recent device activity | `recentDeviceActivityLevel`             | `UNEVALUATED`, `LEVEL_1`, `LEVEL_2`, `LEVEL_3`, `LEVEL_4`                                                      |
| Device attributes      | `sdkVersion`                            | `19`–`37`                                                                                                      |
| Play Protect status    | `playProtectVerdict`                    | `UNEVALUATED`, `NO_ISSUES`, `NO_DATA`, `MEDIUM_RISK`, `HIGH_RISK`, `POSSIBLE_RISK`                             |
| App access risk        | `appAccessRiskVerdict`                  | `KNOWN_INSTALLED`, `KNOWN_CAPTURING`, `KNOWN_OVERLAYS`, `KNOWN_CONTROLLING`, `UNKNOWN_INSTALLED`, `UNKNOWN_CAPTURING`, `UNKNOWN_OVERLAYS`, `UNKNOWN_CONTROLLING` |

All of these are produced by Google and embedded in the JWE/JWS token
you receive — your backend decodes the token via the Play Integrity
decryption API and reads the values above.

### Classic request

Use for one-off, high-value actions (login, payment) where a few
seconds of latency are acceptable.

```dart
final result = await integrity.playIntegrityToken(
  cloudProjectNumber: '123456789012',
  // nonce is auto-generated when omitted, but you should bind it to the
  // request your backend is about to verify (e.g. a random challenge).
  nonce: serverChallenge,
);

if (result.success) {
  await sendToBackend(token: result.token!);
}
```

### Standard request

Lower latency, suited for frequent calls. Requires a warm-up call once
per cold start (do it at app start, not at the moment of use):

```dart
// At app start:
await integrity.prepareStandardIntegrityToken(
  cloudProjectNumber: '123456789012',
);

// Later, when you need a fresh token:
final token = await integrity.playIntegrityStandardToken(
  requestHash: sha256OfRequestBody,
);
```

---

## Huawei SafetyDetect (Android, HMS)

```dart
// 1. System integrity (root / bootloader / SELinux / etc.)
final sys = await integrity.huaweiSysIntegrity(appId: 'YOUR_HMS_APP_ID');

// 2. URL check
final url = await integrity.huaweiUrlCheck(
  url: 'https://example.com',
  appId: 'YOUR_HMS_APP_ID',
);
print(url.threats); // [UrlThreatType.malware, ...]

// 3. User detect (reCAPTCHA-style human check)
final user = await integrity.huaweiUserDetect(appId: 'YOUR_HMS_APP_ID');
await verifyResponseToken(user.responseToken);

// 4. Wi-Fi detect
final wifi = await integrity.huaweiWifiDetect();

// 5. AppsCheck
await integrity.huaweiEnableAppsCheck();
final enabled = await integrity.huaweiIsVerifyAppsCheck();
final malicious = await integrity.huaweiGetMaliciousAppsList();
```

---

## Apple DeviceCheck (iOS)

DeviceCheck lets your server set two opaque bits per device that
survive uninstall:

```dart
if (await integrity.isDeviceCheckSupported()) {
  final r = await integrity.deviceCheckToken();
  if (r.success) {
    // Send r.token (base64) to your backend.
    // Backend then calls Apple's https://api.devicecheck.apple.com endpoints.
  }
}
```

---

## Apple App Attest (iOS 14+)

App Attest gives you a hardware-bound key whose public counterpart is
attested by Apple. The flow is:

1. `appAttestGenerateKey()` — generates a key in the Secure Enclave.
   The returned token is the `keyId`. Persist it locally.
2. Ask your backend for a one-time challenge, hash it (SHA-256) and
   pass the base64 hash to `appAttestAttestKey()`.
3. Send the attestation object to your server, which validates it with
   Apple's public root and stores the public key.
4. For subsequent calls, sign payloads with
   `appAttestGenerateAssertion()`.

```dart
if (!await integrity.isAppAttestSupported()) return;

final keyIdResult = await integrity.appAttestGenerateKey();
final keyId = keyIdResult.token!;

final challenge = await api.fetchChallenge();
final clientDataHash = base64Encode(sha256.convert(challenge).bytes);

final attestation = await integrity.appAttestAttestKey(
  keyId: keyId,
  clientDataHash: clientDataHash,
);
await api.registerKey(keyId: keyId, attestation: attestation.token!);

// Later:
final assertion = await integrity.appAttestGenerateAssertion(
  keyId: keyId,
  clientDataHash: clientDataHashForThisRequest,
);
```

---

## Server-side verification

| Token                            | Where to verify                                                                                   |
| -------------------------------- | ------------------------------------------------------------------------------------------------- |
| Play Integrity (classic/standard) | [`playintegrity.googleapis.com/v1/.../decodeIntegrityToken`](https://developer.android.com/google/play/integrity/verdicts) |
| Huawei SysIntegrity              | [SafetyDetect SysIntegrity server APIs](https://developer.huawei.com/consumer/en/doc/development/HMSCore-Guides/sysintegritydevelopment-0000001050156331) |
| Huawei UserDetect                | [SafetyDetect UserDetect server APIs](https://developer.huawei.com/consumer/en/doc/development/HMSCore-Guides/userdetectdevelopment-0000001050156335) |
| Apple DeviceCheck                | [`api.devicecheck.apple.com`](https://developer.apple.com/documentation/devicecheck/accessing_and_modifying_per-device_data) |
| Apple App Attest                 | [Validating apps that connect to your server](https://developer.apple.com/documentation/devicecheck/validating_apps_that_connect_to_your_server) |

---

## Error handling

Every call returns either an [`IntegrityResult`](lib/src/models.dart) or
a typed result (`UrlCheckResult`, `UserDetectResult`,
`WifiDetectResult`). When something goes wrong:

```dart
final r = await integrity.playIntegrityToken();
if (!r.success) {
  print('failed: ${r.error}  (${r.errorCode})');
}
```

iOS-only methods called on Android (and vice versa) return a graceful
failure with `errorCode == 'UNSUPPORTED_PLATFORM'`.

---

## API reference

See the dartdoc on [pub.dev](https://pub.dev/documentation/device_integrity/latest/)
for the full reference. Key entry points:

- `DeviceIntegrity.playIntegrityToken`
- `DeviceIntegrity.prepareStandardIntegrityToken`
- `DeviceIntegrity.playIntegrityStandardToken`
- `DeviceIntegrity.huaweiSysIntegrity`
- `DeviceIntegrity.huaweiUrlCheck`
- `DeviceIntegrity.huaweiUserDetect`
- `DeviceIntegrity.huaweiWifiDetect`
- `DeviceIntegrity.huaweiEnableAppsCheck` /
  `huaweiIsVerifyAppsCheck` /
  `huaweiGetMaliciousAppsList`
- `DeviceIntegrity.isDeviceCheckSupported` /
  `deviceCheckToken`
- `DeviceIntegrity.isAppAttestSupported` /
  `appAttestGenerateKey` /
  `appAttestAttestKey` /
  `appAttestGenerateAssertion`

---

## License

[MIT](LICENSE)
