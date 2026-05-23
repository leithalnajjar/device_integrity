/// Platform interface for the `device_integrity` plugin.
///
/// Plugin implementations (such as [MethodChannelDeviceIntegrity]) should
/// extend this class rather than implement it, so that newly added methods
/// are not breaking changes for existing implementations.
library;

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'device_integrity_method_channel.dart';
import 'src/models.dart';

export 'src/models.dart';

/// The interface that platform implementations of `device_integrity` must
/// implement.
abstract class DeviceIntegrityPlatform extends PlatformInterface {
  /// Constructs a [DeviceIntegrityPlatform].
  DeviceIntegrityPlatform() : super(token: _token);

  static final Object _token = Object();

  static DeviceIntegrityPlatform _instance = MethodChannelDeviceIntegrity();

  /// The default instance of [DeviceIntegrityPlatform].
  static DeviceIntegrityPlatform get instance => _instance;

  /// Sets the platform implementation. Used by platform-specific plugins
  /// during registration and by tests.
  static set instance(DeviceIntegrityPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // ---------------------------------------------------------------------------
  // Google Play Integrity (Android, GMS)
  // ---------------------------------------------------------------------------

  /// Requests a Google Play **classic** Integrity token.
  Future<IntegrityResult> playIntegrityToken({
    String? nonce,
    String? cloudProjectNumber,
  }) {
    throw UnimplementedError('playIntegrityToken() has not been implemented.');
  }

  /// Warms up Play Integrity's **standard** API token provider. Must be
  /// called at least once (ideally well in advance of the request) before
  /// calling [playIntegrityStandardToken].
  Future<void> prepareStandardIntegrityToken({
    required String cloudProjectNumber,
  }) {
    throw UnimplementedError(
        'prepareStandardIntegrityToken() has not been implemented.');
  }

  /// Requests a Google Play **standard** Integrity token. You must call
  /// [prepareStandardIntegrityToken] beforehand.
  Future<IntegrityResult> playIntegrityStandardToken({
    String? requestHash,
  }) {
    throw UnimplementedError(
        'playIntegrityStandardToken() has not been implemented.');
  }

  // ---------------------------------------------------------------------------
  // Huawei SafetyDetect (Android, HMS)
  // ---------------------------------------------------------------------------

  /// Huawei SafetyDetect SysIntegrity check.
  Future<IntegrityResult> huaweiSysIntegrity({
    String? nonce,
    required String appId,
  }) {
    throw UnimplementedError('huaweiSysIntegrity() has not been implemented.');
  }

  /// Huawei SafetyDetect URL check.
  Future<UrlCheckResult> huaweiUrlCheck({
    required String url,
    required String appId,
    List<int>? threatTypes,
  }) {
    throw UnimplementedError('huaweiUrlCheck() has not been implemented.');
  }

  /// Huawei SafetyDetect User Detect (reCAPTCHA-style).
  Future<UserDetectResult> huaweiUserDetect({required String appId}) {
    throw UnimplementedError('huaweiUserDetect() has not been implemented.');
  }

  /// Huawei SafetyDetect Wi-Fi Detect.
  Future<WifiDetectResult> huaweiWifiDetect() {
    throw UnimplementedError('huaweiWifiDetect() has not been implemented.');
  }

  /// Enables Huawei SafetyDetect AppsCheck (must be called before
  /// [huaweiGetMaliciousAppsList]).
  Future<bool> huaweiEnableAppsCheck() {
    throw UnimplementedError(
        'huaweiEnableAppsCheck() has not been implemented.');
  }

  /// Returns whether Huawei SafetyDetect AppsCheck is currently enabled.
  Future<bool> huaweiIsVerifyAppsCheck() {
    throw UnimplementedError(
        'huaweiIsVerifyAppsCheck() has not been implemented.');
  }

  /// Returns the list of malicious apps reported by SafetyDetect AppsCheck.
  Future<List<MaliciousApp>> huaweiGetMaliciousAppsList() {
    throw UnimplementedError(
        'huaweiGetMaliciousAppsList() has not been implemented.');
  }

  // ---------------------------------------------------------------------------
  // Apple DeviceCheck (iOS)
  // ---------------------------------------------------------------------------

  /// Returns `true` when Apple `DCDevice` is supported on this device.
  Future<bool> isDeviceCheckSupported() {
    throw UnimplementedError(
        'isDeviceCheckSupported() has not been implemented.');
  }

  /// Generates a DeviceCheck token (`DCDevice.generateToken`).
  Future<IntegrityResult> deviceCheckToken() {
    throw UnimplementedError('deviceCheckToken() has not been implemented.');
  }

  // ---------------------------------------------------------------------------
  // Apple App Attest (iOS 14+)
  // ---------------------------------------------------------------------------

  /// Returns `true` when Apple App Attest is supported on this device
  /// (iOS 14+ on devices with the Secure Enclave).
  Future<bool> isAppAttestSupported() {
    throw UnimplementedError(
        'isAppAttestSupported() has not been implemented.');
  }

  /// Generates a new App Attest hardware-backed key. Returns the `keyId`
  /// in [IntegrityResult.token].
  Future<IntegrityResult> appAttestGenerateKey() {
    throw UnimplementedError(
        'appAttestGenerateKey() has not been implemented.');
  }

  /// Produces an attestation object for the given key.
  Future<IntegrityResult> appAttestAttestKey({
    required String keyId,
    required String clientDataHash,
  }) {
    throw UnimplementedError('appAttestAttestKey() has not been implemented.');
  }

  /// Produces an assertion for the given (already attested) key.
  Future<IntegrityResult> appAttestGenerateAssertion({
    required String keyId,
    required String clientDataHash,
  }) {
    throw UnimplementedError(
        'appAttestGenerateAssertion() has not been implemented.');
  }
}
