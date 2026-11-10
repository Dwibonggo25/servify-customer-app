import 'package:customer_flow_app/features/bookings/domain/entities/booking_draft.dart';
import 'package:customer_flow_app/features/bookings/domain/entities/booking_record.dart';
import 'package:customer_flow_app/features/bookings/domain/repositories/booking_repository.dart';
import 'package:customer_flow_app/features/staff/presentation/bloc/staff_bookings_bloc.dart';
import 'package:customer_flow_app/features/staff/presentation/bloc/staff_bookings_event.dart';
import 'package:customer_flow_app/features/staff/presentation/bloc/staff_bookings_state.dart';
import 'package:customer_flow_app/features/staff/presentation/ui/staff_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads staff bookings through the repository', () async {
    final repository = _FakeBookingRepository([_booking]);
    final bloc = StaffBookingsBloc(repository);
    final loaded = bloc.stream.firstWhere(
      (state) => state.status == StaffBookingsStatus.success,
    );

    bloc.add(const StaffBookingsRequested());
    final state = await loaded;

    expect(repository.loadCount, 1);
    expect(state.available, [_booking]);
    await bloc.close();
  });

  testWidgets('incoming page renders the revamped header and booking card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeBookingRepository([_booking]);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) =>
              StaffBookingsBloc(repository)
                ..add(const StaffBookingsRequested()),
          child: const StaffBookingListPage(historyMode: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pesanan Masuk'), findsOneWidget);
    expect(find.text('Pesanan baru — menunggu respons Anda'), findsOneWidget);
    expect(find.text('Kebersihan Rumah'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final _booking = BookingRecord(
  id: 'booking-1',
  number: 'SRV-20261110-001',
  serviceId: 'service-1',
  serviceName: 'Kebersihan Rumah',
  servicePrice: 150000,
  customerName: 'Customer Servify',
  customerPhone: '08123456789',
  address: 'Jalan Contoh Nomor 10, Jakarta Selatan',
  scheduledAt: DateTime(2026, 11, 10, 10),
  paymentMethod: 'cash',
  status: 'pending',
  totalAmount: 150000,
  createdAt: DateTime(2026, 11, 9),
  icon: Icons.cleaning_services_rounded,
  imageUrl: null,
  color: const Color(0xFF4F46E5),
);

final class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository(this.bookings);

  final List<BookingRecord> bookings;
  int loadCount = 0;

  @override
  Future<List<BookingRecord>> getStaffBookings() async {
    loadCount++;
    return bookings;
  }

  @override
  Future<BookingRecord?> getStaffBooking(String id) async => bookings.first;

  @override
  Future<BookingRecord> createBooking(BookingDraft draft) =>
      throw UnimplementedError();

  @override
  Future<List<BookingRecord>> getCustomerBookings() =>
      throw UnimplementedError();

  @override
  Future<BookingRecord?> getCustomerBooking(String id) =>
      throw UnimplementedError();

  @override
  Stream<BookingRecord> watchCustomerBooking(String id) =>
      throw UnimplementedError();

  @override
  Future<void> respondToBooking(String id, {required bool accept}) async {}

  @override
  Future<void> updateProgress(String id, String status) async {}

  @override
  Future<void> cancelBooking(String id) async {}
}
