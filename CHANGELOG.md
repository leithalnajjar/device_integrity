## 1.0.3

* **Android**: fix Play Integrity nonce format. The generated nonce is now
  32 bytes (up from 24) and URL-safe base64 without padding, so it reliably
  meets the Play Integrity API's nonce format requirements.

## 1.0.2

* **iOS**: add Swift Package Manager support. The plugin now ships both a
  `Package.swift` (for projects with Flutter's SPM support enabled) and the
  existing CocoaPods podspec — no migration needed on the app side.
* iOS sources moved to the standard SPM layout
  (`ios/device_integrity/Sources/device_integrity/`); the privacy manifest is
  bundled as an SPM resource and still shipped via CocoaPods as before.

## 1.0.1

* Docs: add a donation (Ko-fi) link to the README. No code changes.

## 1.0.0

* Initial stable release.
* **Android (GMS)** — Google Play Integrity API:
  * Classic request (`playIntegrityToken`).
  * Standard request flow (`prepareStandardIntegrityToken`,
    `playIntegrityStandardToken`).
  * Full verdict surface documented: account details, application
    integrity, device integrity, recent device activity, device
    attributes, Play Protect status, app access risk.
* **Android (HMS)** — full Huawei SafetyDetect surface:
  * `huaweiSysIntegrity`, `huaweiUrlCheck`, `huaweiUserDetect`,
    `huaweiWifiDetect`, `huaweiEnableAppsCheck`,
    `huaweiIsVerifyAppsCheck`, `huaweiGetMaliciousAppsList`.
* **iOS** — Apple DeviceCheck (`DCDevice.generateToken`) and Apple
  App Attest (`DCAppAttestService.generateKey` / `attestKey` /
  `generateAssertion`) with support-detection helpers.
* iOS deployment target: 14.0 (required by App Attest); privacy
  manifest bundle included.
