import 'package:customer_flow_app/features/staff/presentation/widgets/staff_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fits inside an iPhone-style bottom safe area', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
          child: Scaffold(bottomNavigationBar: StaffBottomNavigation(index: 0)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Pesanan'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });
}
