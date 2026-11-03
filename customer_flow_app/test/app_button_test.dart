import 'package:customer_flow_app/libraries/design_system/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppButton displays its label and handles taps', (tester) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Lanjutkan', onPressed: () => pressed = true),
        ),
      ),
    );

    expect(find.text('Lanjutkan'), findsOneWidget);
    await tester.tap(find.text('Lanjutkan'));
    expect(pressed, isTrue);
  });
}
