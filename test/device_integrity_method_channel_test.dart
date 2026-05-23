import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:device_integrity/device_integrity.dart';
import 'package:device_integrity/device_integrity_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelDeviceIntegrity();
  const channel = MethodChannel('device_integrity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'playIntegrityToken':
          return {'success': true, 'token': 'play-token'};
        case 'prepareStandardIntegrityToken':
          return null;
        case 'playIntegrityStandardToken':
          return {'success': true, 'token': 'standard-token'};
        case 'huaweiSysIntegrity':
          return {'success': true, 'token': 'hms-token'};
        case 'huaweiUrlCheck':
          return {'success': true, 'threats': [1, 3]};
        case 'huaweiUserDetect':
          return {'success': true, 'responseToken': 'ud'};
        case 'huaweiWifiDetect':
          return {'success': true, 'wifiDetectStatus': 0};
        case 'huaweiEnableAppsCheck':
        case 'huaweiIsVerifyAppsCheck':
          return true;
        case 'huaweiGetMaliciousAppsList':
          return [
            {'packageName': 'com.bad', 'apkSha256': 'sha', 'category': 1}
          ];
        case 'isDeviceCheckSupported':
        case 'isAppAttestSupported':
          return true;
        case 'deviceCheckToken':
          return {'success': true, 'token': 'dc'};
        case 'appAttestGenerateKey':
          return {'success': true, 'token': 'keyId'};
        case 'appAttestAttestKey':
          return {'success': true, 'token': 'att'};
        case 'appAttestGenerateAssertion':
          return {'success': true, 'token': 'asr'};
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('playIntegrityToken', () async {
    final r = await platform.playIntegrityToken(cloudProjectNumber: '1');
    expect(r.token, 'play-token');
  });

  test('prepare + standard', () async {
    await platform.prepareStandardIntegrityToken(cloudProjectNumber: '1');
    final r = await platform.playIntegrityStandardToken(requestHash: 'h');
    expect(r.token, 'standard-token');
  });

  test('huaweiSysIntegrity', () async {
    final r = await platform.huaweiSysIntegrity(appId: '1');
    expect(r.token, 'hms-token');
  });

  test('huaweiUrlCheck decodes threats', () async {
    final r = await platform.huaweiUrlCheck(url: 'https://e', appId: '1');
    expect(r.threats, [UrlThreatType.malware, UrlThreatType.phishing]);
  });

  test('huaweiUserDetect', () async {
    final r = await platform.huaweiUserDetect(appId: '1');
    expect(r.responseToken, 'ud');
  });

  test('huaweiWifiDetect', () async {
    final r = await platform.huaweiWifiDetect();
    expect(r.wifiDetectStatus, 0);
  });

  test('apps check + malicious list', () async {
    expect(await platform.huaweiEnableAppsCheck(), isTrue);
    expect(await platform.huaweiIsVerifyAppsCheck(), isTrue);
    final list = await platform.huaweiGetMaliciousAppsList();
    expect(list.first.packageName, 'com.bad');
  });

  test('apple flows', () async {
    expect(await platform.isDeviceCheckSupported(), isTrue);
    expect((await platform.deviceCheckToken()).token, 'dc');
    expect(await platform.isAppAttestSupported(), isTrue);
    expect((await platform.appAttestGenerateKey()).token, 'keyId');
    expect((await platform.appAttestAttestKey(keyId: 'k', clientDataHash: 'h'))
        .token, 'att');
    expect((await platform.appAttestGenerateAssertion(
            keyId: 'k', clientDataHash: 'h'))
        .token, 'asr');
  });

  test('null result becomes failure', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    final r = await platform.playIntegrityToken();
    expect(r.success, isFalse);
    expect(r.error, 'No result from platform');
  });
}

