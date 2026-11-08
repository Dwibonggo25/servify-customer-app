import 'package:flutter/material.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../domain/entities/booking_record.dart';
import '../../domain/repositories/booking_repository.dart';
import '../widgets/booking_status_badge.dart';

final class BookingDetailPage extends StatefulWidget {
  const BookingDetailPage({
    required this.bookingId,
    required this.repository,
    this.staffMode = false,
    super.key,
  });

  final String bookingId;
  final BookingRepository repository;
  final bool staffMode;

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

final class _BookingDetailPageState extends State<BookingDetailPage> {
  late Future<BookingRecord?> _future;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.staffMode
        ? widget.repository.getStaffBooking(widget.bookingId)
        : widget.repository.getCustomerBooking(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail pesanan')),
      body: FutureBuilder<BookingRecord?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _errorState();
          final booking = snapshot.data;
          if (booking == null) {
            return const Center(child: Text('Pesanan tidak ditemukan.'));
          }
          return _content(booking);
        },
      ),
    );
  }

  Widget _content(BookingRecord booking) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.serviceName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.number,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            BookingStatusBadge(status: booking.status),
          ],
        ),
        const SizedBox(height: 24),
        _InfoCard(
          children: [
            _InfoRow(
              icon: Icons.calendar_month_outlined,
              label: 'Jadwal',
              value: AppFormatters.date(booking.scheduledAt),
            ),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Customer',
              value: booking.customerName,
            ),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Telepon',
              value: booking.customerPhone,
            ),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Alamat',
              value: booking.address,
            ),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Total',
              value: AppFormatters.rupiah(booking.totalAmount),
            ),
            if (booking.note?.trim().isNotEmpty == true)
              _InfoRow(
                icon: Icons.notes_rounded,
                label: 'Catatan',
                value: booking.note!,
              ),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          'Tracking pesanan',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        if (booking.history.isEmpty)
          const Text('Belum ada riwayat status.')
        else
          ...booking.history.indexed.map(
            (entry) => _TimelineEntry(
              entry: entry.$2,
              isLast: entry.$1 == booking.history.length - 1,
            ),
          ),
        if (widget.staffMode) ...[
          const SizedBox(height: 26),
          ..._staffActions(booking),
        ],
      ],
    );
  }

  List<Widget> _staffActions(BookingRecord booking) {
    if (booking.isAvailable) {
      return [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Tolak',
                isOutlined: true,
                isLoading: _submitting,
                onPressed: () => _respond(accept: false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Terima',
                isLoading: _submitting,
                onPressed: () => _respond(accept: true),
              ),
            ),
          ],
        ),
      ];
    }
    final next = switch (booking.status) {
      'assigned' => ('on_the_way', 'Berangkat ke lokasi'),
      'on_the_way' => ('in_progress', 'Mulai pekerjaan'),
      'in_progress' => ('completed', 'Selesaikan pekerjaan'),
      _ => null,
    };
    if (next == null) return const [];
    return [
      AppButton(
        label: next.$2,
        isLoading: _submitting,
        onPressed: () => _updateStatus(next.$1),
      ),
    ];
  }

  Future<void> _respond({required bool accept}) async {
    setState(() => _submitting = true);
    try {
      await widget.repository.respondToBooking(
        widget.bookingId,
        accept: accept,
      );
      if (!mounted) return;
      if (!accept) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(_reload);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _submitting = true);
    try {
      await widget.repository.updateProgress(widget.bookingId, status);
      if (mounted) setState(_reload);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Aksi gagal: $error')));
  }

  Widget _errorState() => Center(
    child: FilledButton.icon(
      onPressed: () => setState(_reload),
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Coba lagi'),
    ),
  );
}

final class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: children),
  );
}

final class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.entry, required this.isLast});
  final BookingStatusEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          const CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.check_rounded, color: Colors.white, size: 13),
          ),
          if (!isLast) Container(width: 2, height: 42, color: AppColors.border),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BookingStatusBadge.label(entry.status),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                AppFormatters.date(entry.createdAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
