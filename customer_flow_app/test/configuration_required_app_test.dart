import 'package:customer_flow_app/app/bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows setup guidance when Supabase config is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ConfigurationRequiredApp(message: 'Supabase belum dikonfigurasi.'),
    );

    expect(find.text('Konfigurasi Supabase diperlukan'), findsOneWidget);
    expect(find.textContaining('--dart-define-from-file'), findsOneWidget);
  });
}
