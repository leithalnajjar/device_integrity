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
