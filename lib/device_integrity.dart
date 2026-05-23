/// Device Integrity Flutter plugin.
///
/// A Flutter plugin that wraps the device-attestation APIs from each
/// platform behind a single Dart facade:
///
/// | Platform              | API                                       |
/// | --------------------- | ----------------------------------------- |
/// | Android (Google Play) | Google Play Integrity (classic + standard)|
/// | Android (Huawei)      | SafetyDetect (SysIntegrity, URL check,    |
/// |                       | User Detect, Wi-Fi Detect, AppsCheck)     |
/// | iOS                   | DeviceCheck (`DCDevice`)                  |
/// | iOS 14+               | App Attest (`DCAppAttestService`)         |
///
/// All tokens returned by this plugin are **opaque** and **must be
/// validated on your backend server**. Never trust an integrity verdict
/// computed on the device itself.
library;

import 'device_integrity_platform_interface.dart';

export 'device_integrity_platform_interface.dart';

/// The main entry point of the plugin.
class DeviceIntegrity {
  /// Creates a [DeviceIntegrity].
  const DeviceIntegrity();

  DeviceIntegrityPlatform get _platform => DeviceIntegrityPlatform.instance;

  // ---------------------------------------------------------------------------
  // Google Play Integrity
  // ---------------------------------------------------------------------------

  /// Requests a Google Play **classic** Integrity token.
  ///
  /// The returned token decodes (server-side) to verdicts covering:
  ///
  /// - **Account details** — `appLicensingVerdict`:
  ///   `LICENSED`, `UNLICENSED`, `UNEVALUATED`.
  /// - **Application integrity** — `appRecognitionVerdict`:
  ///   `PLAY_RECOGNIZED`, `UNRECOGNIZED_VERSION`, `UNEVALUATED`.
  /// - **Device integrity** — `deviceRecognitionVerdict` labels:
  ///   `MEETS_BASIC_INTEGRITY`, `MEETS_DEVICE_INTEGRITY`,
  ///   `MEETS_STRONG_INTEGRITY`.
  /// - **Recent device activity** — `recentDeviceActivityLevel`:
  ///   `UNEVALUATED`, `LEVEL_1`, `LEVEL_2`, `LEVEL_3`, `LEVEL_4`.
  /// - **Device attributes** — `sdkVersion`.
  /// - **Environment / Play Protect** — `playProtectVerdict`:
  ///   `UNEVALUATED`, `NO_ISSUES`, `NO_DATA`, `MEDIUM_RISK`, `HIGH_RISK`,
  ///   `POSSIBLE_RISK`.
  /// - **Environment / App access risk** — `appAccessRiskVerdict`:
  ///   `KNOWN_INSTALLED`, `KNOWN_CAPTURING`, `KNOWN_OVERLAYS`,
  ///   `KNOWN_CONTROLLING`, `UNKNOWN_INSTALLED`, `UNKNOWN_CAPTURING`,
  ///   `UNKNOWN_OVERLAYS`, `UNKNOWN_CONTROLLING`.
  ///
  /// To receive all of these verdicts you must:
  ///
  /// 1. Link your app to a Google Cloud project and provide
  ///    [cloudProjectNumber].
  /// 2. Enable each verdict (Account details, App integrity, Device
  ///    integrity, Recent device activity, Device attributes, Play Protect
  ///    status, App access risk) in Play Console → Release → Setup →
  ///    App integrity → Play Integrity API.
  ///
  /// [nonce] is optional; if omitted the native side generates a random
  /// 24-byte base64 nonce.
  Future<IntegrityResult> playIntegrityToken({
    String? nonce,
    String? cloudProjectNumber,
  }) =>
      _platform.playIntegrityToken(
        nonce: nonce,
        cloudProjectNumber: cloudProjectNumber,
      );

  /// Warms up the **standard** Play Integrity provider. Must be called
  /// before [playIntegrityStandardToken], ideally well in advance (for
  /// example at app start) because preparation takes a few hundred
  /// milliseconds.
  Future<void> prepareStandardIntegrityToken({
    required String cloudProjectNumber,
  }) =>
      _platform.prepareStandardIntegrityToken(
        cloudProjectNumber: cloudProjectNumber,
      );

  /// Requests a Google Play **standard** Integrity token. Requires
  /// [prepareStandardIntegrityToken] to have been called previously.
  ///
  /// [requestHash] is an arbitrary string (typically the SHA-256 of the
  /// request body) that will be bound to the returned token.
  Future<IntegrityResult> playIntegrityStandardToken({String? requestHash}) =>
      _platform.playIntegrityStandardToken(requestHash: requestHash);

  // ---------------------------------------------------------------------------
  // Huawei SafetyDetect
  // ---------------------------------------------------------------------------

  /// Huawei SafetyDetect **SysIntegrity** check.
  Future<IntegrityResult> huaweiSysIntegrity({
    String? nonce,
    required String appId,
  }) =>
      _platform.huaweiSysIntegrity(nonce: nonce, appId: appId);

  /// Huawei SafetyDetect **URL check** for malicious URLs. [threatTypes]
  /// defaults to the SDK defaults (malware + phishing) when `null`.
  Future<UrlCheckResult> huaweiUrlCheck({
    required String url,
    required String appId,
    List<int>? threatTypes,
  }) =>
      _platform.huaweiUrlCheck(
        url: url,
        appId: appId,
        threatTypes: threatTypes,
      );

  /// Huawei SafetyDetect **User Detect** (reCAPTCHA-style human check).
  Future<UserDetectResult> huaweiUserDetect({required String appId}) =>
      _platform.huaweiUserDetect(appId: appId);

  /// Huawei SafetyDetect **Wi-Fi detect**.
  Future<WifiDetectResult> huaweiWifiDetect() => _platform.huaweiWifiDetect();

  /// Enables Huawei SafetyDetect **AppsCheck**. Must be called once
  /// before [huaweiGetMaliciousAppsList].
  Future<bool> huaweiEnableAppsCheck() => _platform.huaweiEnableAppsCheck();

  /// Returns whether Huawei SafetyDetect AppsCheck is currently enabled.
  Future<bool> huaweiIsVerifyAppsCheck() => _platform.huaweiIsVerifyAppsCheck();

  /// Returns the list of malicious apps detected by AppsCheck.
  Future<List<MaliciousApp>> huaweiGetMaliciousAppsList() =>
      _platform.huaweiGetMaliciousAppsList();

  // ---------------------------------------------------------------------------
  // Apple DeviceCheck
  // ---------------------------------------------------------------------------

  /// Whether Apple DeviceCheck (`DCDevice`) is supported on this device.
  Future<bool> isDeviceCheckSupported() => _platform.isDeviceCheckSupported();

  /// Generates an Apple DeviceCheck token. The token (Base64) must be
  /// sent to your server, which then talks to Apple's DeviceCheck API
  /// to set / query the two per-device bits.
  Future<IntegrityResult> deviceCheckToken() => _platform.deviceCheckToken();

  // ---------------------------------------------------------------------------
  // Apple App Attest
  // ---------------------------------------------------------------------------

  /// Whether Apple App Attest (`DCAppAttestService`) is supported on
  /// this device (iOS 14+ with Secure Enclave).
  Future<bool> isAppAttestSupported() => _platform.isAppAttestSupported();

  /// Generates a fresh App Attest key. [IntegrityResult.token] holds the
  /// generated `keyId`, which you must persist and send to your server
  /// to begin the attestation flow.
  Future<IntegrityResult> appAttestGenerateKey() =>
      _platform.appAttestGenerateKey();

  /// Produces an attestation object for [keyId] using [clientDataHash]
  /// (base64-encoded SHA-256 of a one-time challenge from your server).
  Future<IntegrityResult> appAttestAttestKey({
    required String keyId,
    required String clientDataHash,
  }) =>
      _platform.appAttestAttestKey(
        keyId: keyId,
        clientDataHash: clientDataHash,
      );

  /// Produces an assertion for an already-attested [keyId].
  Future<IntegrityResult> appAttestGenerateAssertion({
    required String keyId,
    required String clientDataHash,
  }) =>
      _platform.appAttestGenerateAssertion(
        keyId: keyId,
        clientDataHash: clientDataHash,
      );
}
