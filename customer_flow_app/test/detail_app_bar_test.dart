import 'package:customer_flow_app/libraries/core/localization/app_localizations.dart';
import 'package:customer_flow_app/libraries/core/localization/language_keys.dart';
import 'package:customer_flow_app/libraries/design_system/widgets/detail_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('detail app bar fits an iPhone-sized screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: DetailAppBar(
            title: 'Order details',
            subtitle: 'Track your service, schedule, and payment details.',
          ),
        ),
      ),
    );

    expect(find.text('Order details'), findsOneWidget);
    expect(
      find.text('Track your service, schedule, and payment details.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('booking detail has English translations', () {
    const localizations = AppLocalizations(Locale('en'));

    expect(
      localizations.translate(LanguageKeys.bookingDetail),
      'Order details',
    );
    expect(
      localizations.translate(LanguageKeys.paymentDetails),
      'Payment details',
    );
    expect(
      localizations.translate(LanguageKeys.statusInProgress),
      'In progress',
    );
  });
}
