import 'package:flutter_test/flutter_test.dart';

import 'package:device_integrity_example/main.dart';

void main() {
  testWidgets('Demo app builds', (tester) async {
    await tester.pumpWidget(const DemoApp());
    expect(find.text('Device Integrity'), findsOneWidget);
  });
}
