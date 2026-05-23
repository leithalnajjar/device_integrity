import 'package:flutter_test/flutter_test.dart';
import 'package:device_integrity/device_integrity.dart';
import 'package:device_integrity/device_integrity_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _MockPlatform
    with MockPlatformInterfaceMixin
    implements DeviceIntegrityPlatform {
  bool prepared = false;

  @override
  Future<IntegrityResult> playIntegrityToken({
    String? nonce,
    String? cloudProjectNumber,
  }) async =>
      const IntegrityResult(success: true, token: 'play-classic');

  @override
  Future<void> prepareStandardIntegrityToken({
    required String cloudProjectNumber,
  }) async {
    prepared = true;
  }

  @override
  Future<IntegrityResult> playIntegrityStandardToken(
          {String? requestHash}) async =>
      IntegrityResult(
          success: prepared, token: prepared ? 'play-standard' : null);

  @override
  Future<IntegrityResult> huaweiSysIntegrity({
    String? nonce,
    required String appId,
  }) async =>
      const IntegrityResult(success: true, token: 'huawei-sys');

  @override
  Future<UrlCheckResult> huaweiUrlCheck({
    required String url,
    required String appId,
    List<int>? threatTypes,
  }) async =>
      const UrlCheckResult(success: true, threats: [UrlThreatType.malware]);

  @override
  Future<UserDetectResult> huaweiUserDetect({required String appId}) async =>
      const UserDetectResult(success: true, responseToken: 'ud');

  @override
  Future<WifiDetectResult> huaweiWifiDetect() async =>
      const WifiDetectResult(success: true, wifiDetectStatus: 0);

  @override
  Future<bool> huaweiEnableAppsCheck() async => true;

  @override
  Future<bool> huaweiIsVerifyAppsCheck() async => true;

  @override
  Future<List<MaliciousApp>> huaweiGetMaliciousAppsList() async =>
      const [MaliciousApp(packageName: 'com.bad.app')];

  @override
  Future<bool> isDeviceCheckSupported() async => true;

  @override
  Future<IntegrityResult> deviceCheckToken() async =>
      const IntegrityResult(success: true, token: 'dc-token');

  @override
  Future<bool> isAppAttestSupported() async => true;

  @override
  Future<IntegrityResult> appAttestGenerateKey() async =>
      const IntegrityResult(success: true, token: 'keyId');

  @override
  Future<IntegrityResult> appAttestAttestKey({
    required String keyId,
    required String clientDataHash,
  }) async =>
      const IntegrityResult(success: true, token: 'attest');

  @override
  Future<IntegrityResult> appAttestGenerateAssertion({
    required String keyId,
    required String clientDataHash,
  }) async =>
      const IntegrityResult(success: true, token: 'assertion');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default platform is MethodChannelDeviceIntegrity', () {
    expect(
        DeviceIntegrityPlatform.instance, isA<MethodChannelDeviceIntegrity>());
  });

  group('DeviceIntegrity facade', () {
    late DeviceIntegrity api;
    late _MockPlatform mock;

    setUp(() {
      mock = _MockPlatform();
      DeviceIntegrityPlatform.instance = mock;
      api = const DeviceIntegrity();
    });

    test('playIntegrityToken', () async {
      final r = await api.playIntegrityToken(cloudProjectNumber: '1');
      expect(r.success, isTrue);
      expect(r.token, 'play-classic');
    });

    test('standard requires prepare', () async {
      final before = await api.playIntegrityStandardToken();
      expect(before.success, isFalse);
      await api.prepareStandardIntegrityToken(cloudProjectNumber: '1');
      final after = await api.playIntegrityStandardToken(requestHash: 'h');
      expect(after.success, isTrue);
      expect(after.token, 'play-standard');
    });

    test('huawei sys integrity', () async {
      final r = await api.huaweiSysIntegrity(appId: '1');
      expect(r.token, 'huawei-sys');
    });

    test('huawei url check', () async {
      final r = await api.huaweiUrlCheck(url: 'https://e', appId: '1');
      expect(r.threats, contains(UrlThreatType.malware));
    });

    test('huawei user detect', () async {
      final r = await api.huaweiUserDetect(appId: '1');
      expect(r.responseToken, 'ud');
    });

    test('huawei wifi detect', () async {
      final r = await api.huaweiWifiDetect();
      expect(r.wifiDetectStatus, 0);
    });

    test('huawei apps check + list', () async {
      expect(await api.huaweiEnableAppsCheck(), isTrue);
      expect(await api.huaweiIsVerifyAppsCheck(), isTrue);
      final list = await api.huaweiGetMaliciousAppsList();
      expect(list.first.packageName, 'com.bad.app');
    });

    test('device check', () async {
      expect(await api.isDeviceCheckSupported(), isTrue);
      expect((await api.deviceCheckToken()).token, 'dc-token');
    });

    test('app attest', () async {
      expect(await api.isAppAttestSupported(), isTrue);
      expect((await api.appAttestGenerateKey()).token, 'keyId');
      expect(
          (await api.appAttestAttestKey(keyId: 'k', clientDataHash: 'h')).token,
          'attest');
      expect(
          (await api.appAttestGenerateAssertion(
                  keyId: 'k', clientDataHash: 'h'))
              .token,
          'assertion');
    });
  });

  group('IntegrityResult', () {
    test('fromMap success', () {
      final r = IntegrityResult.fromMap({'success': true, 'token': 't'});
      expect(r.success, isTrue);
      expect(r.token, 't');
    });

    test('fromMap failure', () {
      final r = IntegrityResult.fromMap({
        'success': false,
        'error': 'E',
        'errorCode': 'C',
      });
      expect(r.success, isFalse);
      expect(r.error, 'E');
      expect(r.errorCode, 'C');
    });
  });
}
