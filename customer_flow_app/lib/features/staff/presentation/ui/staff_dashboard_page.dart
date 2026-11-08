import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../bookings/domain/entities/booking_record.dart';
import '../../../bookings/domain/repositories/booking_repository.dart';
import '../../../bookings/presentation/widgets/booking_status_badge.dart';
import '../widgets/staff_bottom_navigation.dart';

final class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({required this.repository, super.key});
  final BookingRepository repository;

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

final class _StaffDashboardPageState extends State<StaffDashboardPage> {
  late Future<List<BookingRecord>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = widget.repository.getStaffBookings();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Dashboard staff'),
      actions: [
        IconButton(
          onPressed: () => context.push('/staff/notifications'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    ),
    body: FutureBuilder<List<BookingRecord>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return _error();
        final bookings = snapshot.data ?? const <BookingRecord>[];
        final available = bookings.where((item) => item.isAvailable).toList();
        final active = bookings
            .where((item) => !item.isAvailable && !item.isFinished)
            .toList();
        final completed = bookings
            .where((item) => item.status == 'completed')
            .length;
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Ringkasan pekerjaan',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Pesanan baru',
                      value: available.length,
                      icon: Icons.inbox_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Aktif',
                      value: active.length,
                      icon: Icons.handyman_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Selesai',
                      value: completed,
                      icon: Icons.task_alt_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pekerjaan aktif',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/staff/incoming'),
                    child: const Text('Lihat semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (active.isEmpty)
                const _EmptyCard(text: 'Belum ada pekerjaan aktif.')
              else
                ...active
                    .take(3)
                    .map(
                      (item) => _StaffBookingTile(
                        booking: item,
                        onTap: () => context.push('/staff/bookings/${item.id}'),
                      ),
                    ),
            ],
          ),
        );
      },
    ),
    bottomNavigationBar: const StaffBottomNavigation(index: 0),
  );

  Widget _error() => Center(
    child: FilledButton.icon(
      onPressed: () => setState(_reload),
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Coba lagi'),
    ),
  );
}

final class StaffBookingListPage extends StatefulWidget {
  const StaffBookingListPage({
    required this.repository,
    required this.historyMode,
    super.key,
  });
  final BookingRepository repository;
  final bool historyMode;

  @override
  State<StaffBookingListPage> createState() => _StaffBookingListPageState();
}

final class _StaffBookingListPageState extends State<StaffBookingListPage> {
  late Future<List<BookingRecord>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = widget.repository.getStaffBookings();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.historyMode ? 'Riwayat pekerjaan' : 'Pesanan masuk'),
    ),
    body: FutureBuilder<List<BookingRecord>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton(
              onPressed: () => setState(_reload),
              child: const Text('Coba lagi'),
            ),
          );
        }
        final items = (snapshot.data ?? const <BookingRecord>[])
            .where(
              (item) => widget.historyMode ? item.isFinished : !item.isFinished,
            )
            .toList();
        if (items.isEmpty) {
          return Center(
            child: Text(
              widget.historyMode
                  ? 'Belum ada riwayat pekerjaan.'
                  : 'Belum ada pesanan masuk.',
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: items
                .map(
                  (item) => _StaffBookingTile(
                    booking: item,
                    onTap: () async {
                      await context.push('/staff/bookings/${item.id}');
                      if (mounted) setState(_reload);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    ),
    bottomNavigationBar: StaffBottomNavigation(
      index: widget.historyMode ? 2 : 1,
    ),
  );
}

final class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    ),
  );
}

final class _StaffBookingTile extends StatelessWidget {
  const _StaffBookingTile({required this.booking, required this.onTap});
  final BookingRecord booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: booking.color.withValues(alpha: 0.12),
        child: Icon(booking.icon, color: booking.color),
      ),
      title: Text(
        booking.serviceName,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('${booking.customerName}\n${booking.address}'),
      isThreeLine: true,
      trailing: BookingStatusBadge(status: booking.status),
    ),
  );
}

final class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(text, textAlign: TextAlign.center),
  );
}
