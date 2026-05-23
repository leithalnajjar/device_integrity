import 'dart:io' show Platform;

import 'package:device_integrity/device_integrity.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Device Integrity',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const _HomePage(),
      );
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  static const _gcpProjectNumber = 'YOUR_GCP_PROJECT_NUMBER';
  static const _hmsAppId = 'YOUR_HMS_APP_ID';

  final _api = const DeviceIntegrity();
  String _log = 'Tap a button to run a check.';
  bool _busy = false;

  Future<void> _run(String label, Future<Object?> Function() task) async {
    setState(() {
      _busy = true;
      _log = '$label…';
    });
    try {
      final out = await task();
      if (!mounted) return;
      setState(() => _log = '$label →\n$out');
    } catch (e) {
      if (!mounted) return;
      setState(() => _log = '$label failed:\n$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final isIos = !kIsWeb && Platform.isIOS;
    return Scaffold(
      appBar: AppBar(title: const Text('Device Integrity')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _log,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isAndroid)
                  _btn(
                      'Play Integrity (classic)',
                      () => _api.playIntegrityToken(
                          cloudProjectNumber: _gcpProjectNumber)),
                if (isAndroid)
                  _btn('Prepare Standard', () async {
                    await _api.prepareStandardIntegrityToken(
                        cloudProjectNumber: _gcpProjectNumber);
                    return 'prepared';
                  }),
                if (isAndroid)
                  _btn(
                      'Play Integrity (standard)',
                      () =>
                          _api.playIntegrityStandardToken(requestHash: 'demo')),
                if (isAndroid)
                  _btn('Huawei SysIntegrity',
                      () => _api.huaweiSysIntegrity(appId: _hmsAppId)),
                if (isAndroid)
                  _btn(
                      'Huawei URL Check',
                      () => _api.huaweiUrlCheck(
                          url: 'https://example.com', appId: _hmsAppId)),
                if (isAndroid)
                  _btn('Huawei User Detect',
                      () => _api.huaweiUserDetect(appId: _hmsAppId)),
                if (isAndroid)
                  _btn('Huawei Wi-Fi Detect', _api.huaweiWifiDetect),
                if (isAndroid)
                  _btn('Huawei Enable AppsCheck', _api.huaweiEnableAppsCheck),
                if (isAndroid)
                  _btn(
                      'Huawei Malicious Apps', _api.huaweiGetMaliciousAppsList),
                if (isIos) _btn('DeviceCheck token', _api.deviceCheckToken),
                if (isIos)
                  _btn('App Attest: supported?', _api.isAppAttestSupported),
                if (isIos)
                  _btn('App Attest: generate key', () async {
                    final r = await _api.appAttestGenerateKey();
                    return r;
                  }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, Future<Object?> Function() task) {
    return FilledButton.tonal(
      onPressed: _busy ? null : () => _run(label, task),
      child: Text(label),
    );
  }
}

// End of demo app.
