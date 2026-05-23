/// Default [DeviceIntegrityPlatform] implementation that talks to the
/// native side over a Flutter [MethodChannel].
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'device_integrity_platform_interface.dart';

/// An implementation of [DeviceIntegrityPlatform] that uses method channels.
class MethodChannelDeviceIntegrity extends DeviceIntegrityPlatform {
  /// The method channel used to talk to the native side.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('device_integrity');

  Future<Map<String, dynamic>> _invokeMap(
    String method, [
    Map<String, dynamic>? args,
  ]) async {
    final result =
        await methodChannel.invokeMethod<Map<Object?, Object?>>(method, args);
    if (result == null) {
      return {'success': false, 'error': 'No result from platform'};
    }
    return result.map((k, v) => MapEntry(k.toString(), v));
  }

  // -------- Play Integrity --------

  @override
  Future<IntegrityResult> playIntegrityToken({
    String? nonce,
    String? cloudProjectNumber,
  }) async {
    final map = await _invokeMap('playIntegrityToken', {
      'nonce': nonce,
      'cloudProjectNumber': cloudProjectNumber,
    });
    return IntegrityResult.fromMap(map);
  }

  @override
  Future<void> prepareStandardIntegrityToken({
    required String cloudProjectNumber,
  }) async {
    await methodChannel.invokeMethod<void>(
      'prepareStandardIntegrityToken',
      {'cloudProjectNumber': cloudProjectNumber},
    );
  }

  @override
  Future<IntegrityResult> playIntegrityStandardToken({
    String? requestHash,
  }) async {
    final map = await _invokeMap('playIntegrityStandardToken', {
      'requestHash': requestHash,
    });
    return IntegrityResult.fromMap(map);
  }

  // -------- Huawei SafetyDetect --------

  @override
  Future<IntegrityResult> huaweiSysIntegrity({
    String? nonce,
    required String appId,
  }) async {
    final map = await _invokeMap('huaweiSysIntegrity', {
      'nonce': nonce,
      'appId': appId,
    });
    return IntegrityResult.fromMap(map);
  }

  @override
  Future<UrlCheckResult> huaweiUrlCheck({
    required String url,
    required String appId,
    List<int>? threatTypes,
  }) async {
    final map = await _invokeMap('huaweiUrlCheck', {
      'url': url,
      'appId': appId,
      'threatTypes': threatTypes,
    });
    return UrlCheckResult.fromMap(map);
  }

  @override
  Future<UserDetectResult> huaweiUserDetect({required String appId}) async {
    final map = await _invokeMap('huaweiUserDetect', {'appId': appId});
    return UserDetectResult.fromMap(map);
  }

  @override
  Future<WifiDetectResult> huaweiWifiDetect() async {
    final map = await _invokeMap('huaweiWifiDetect');
    return WifiDetectResult.fromMap(map);
  }

  @override
  Future<bool> huaweiEnableAppsCheck() async {
    final result =
        await methodChannel.invokeMethod<bool>('huaweiEnableAppsCheck');
    return result ?? false;
  }

  @override
  Future<bool> huaweiIsVerifyAppsCheck() async {
    final result =
        await methodChannel.invokeMethod<bool>('huaweiIsVerifyAppsCheck');
    return result ?? false;
  }

  @override
  Future<List<MaliciousApp>> huaweiGetMaliciousAppsList() async {
    final result = await methodChannel
        .invokeMethod<List<Object?>>('huaweiGetMaliciousAppsList');
    if (result == null) return const [];
    return result
        .whereType<Map>()
        .map((m) =>
            MaliciousApp.fromMap(m.map((k, v) => MapEntry(k.toString(), v))))
        .toList(growable: false);
  }

  // -------- Apple DeviceCheck --------

  @override
  Future<bool> isDeviceCheckSupported() async {
    final result =
        await methodChannel.invokeMethod<bool>('isDeviceCheckSupported');
    return result ?? false;
  }

  @override
  Future<IntegrityResult> deviceCheckToken() async {
    final map = await _invokeMap('deviceCheckToken');
    return IntegrityResult.fromMap(map);
  }

  // -------- Apple App Attest --------

  @override
  Future<bool> isAppAttestSupported() async {
    final result =
        await methodChannel.invokeMethod<bool>('isAppAttestSupported');
    return result ?? false;
  }

  @override
  Future<IntegrityResult> appAttestGenerateKey() async {
    final map = await _invokeMap('appAttestGenerateKey');
    return IntegrityResult.fromMap(map);
  }

  @override
  Future<IntegrityResult> appAttestAttestKey({
    required String keyId,
    required String clientDataHash,
  }) async {
    final map = await _invokeMap('appAttestAttestKey', {
      'keyId': keyId,
      'clientDataHash': clientDataHash,
    });
    return IntegrityResult.fromMap(map);
  }

  @override
  Future<IntegrityResult> appAttestGenerateAssertion({
    required String keyId,
    required String clientDataHash,
  }) async {
    final map = await _invokeMap('appAttestGenerateAssertion', {
      'keyId': keyId,
      'clientDataHash': clientDataHash,
    });
    return IntegrityResult.fromMap(map);
  }
}
