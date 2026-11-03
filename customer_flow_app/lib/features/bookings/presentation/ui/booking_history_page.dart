import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_bottom_navigation.dart';
import '../../../services/data/mock_service_catalog.dart';
import '../../../services/domain/entities/service_item.dart';
import '../../domain/entities/booking_draft.dart';

final class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({this.latestBooking, super.key});

  final BookingDraft? latestBooking;

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

final class _BookingHistoryPageState extends State<BookingHistoryPage> {
  String _filter = 'Semua';

  List<_BookingHistoryItem> get _items {
    final homeCleaning = MockServiceCatalog.findById('home-cleaning')!;
    final acService = MockServiceCatalog.findById('ac-service')!;
    final repair = MockServiceCatalog.findById('home-repair')!;
    final items = <_BookingHistoryItem>[
      if (widget.latestBooking case final booking?)
        _BookingHistoryItem(
          number: 'SRV-2026-001',
          service: booking.service,
          schedule: booking.schedule,
          timeLabel: booking.timeLabel,
          status: 'Menunggu konfirmasi',
        ),
      _BookingHistoryItem(
        number: 'SRV-2026-104',
        service: homeCleaning,
        schedule: DateTime(2026, 11, 5),
        timeLabel: '09.00',
        status: 'Terjadwal',
      ),
      _BookingHistoryItem(
        number: 'SRV-2026-087',
        service: acService,
        schedule: DateTime(2026, 10, 21),
        timeLabel: '13.00',
        status: 'Selesai',
      ),
      _BookingHistoryItem(
        number: 'SRV-2026-063',
        service: repair,
        schedule: DateTime(2026, 9, 12),
        timeLabel: '11.00',
        status: 'Dibatalkan',
      ),
    ];

    return items.where((item) {
      if (_filter == 'Semua') return true;
      if (_filter == 'Berjalan') {
        return item.status != 'Selesai' && item.status != 'Dibatalkan';
      }
      return item.status == 'Selesai';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.tr(LanguageKeys.myOrders)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Row(
              children: ['Semua', 'Berjalan', 'Selesai'].map((filter) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          _filterLabel(context, filter),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const _EmptyHistory()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _BookingCard(item: items[index]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 1,
        onScanPressed: () =>
            _showMessage(context, context.tr(LanguageKeys.scanComingSoon)),
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/home');
          } else if (index != 1) {
            if (index == 3) {
              context.go('/profile');
              return;
            }
            final labels = [
              context.tr(LanguageKeys.home),
              context.tr(LanguageKeys.orders),
              context.tr(LanguageKeys.favorites),
              context.tr(LanguageKeys.profile),
            ];
            _showMessage(
              context,
              context.tr(LanguageKeys.pageComingSoon, {'page': labels[index]}),
            );
          }
        },
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _filterLabel(BuildContext context, String filter) {
    return context.tr(switch (filter) {
      'Berjalan' => LanguageKeys.ongoing,
      'Selesai' => LanguageKeys.completed,
      _ => LanguageKeys.all,
    });
  }
}

final class _BookingHistoryItem {
  const _BookingHistoryItem({
    required this.number,
    required this.service,
    required this.schedule,
    required this.timeLabel,
    required this.status,
  });

  final String number;
  final ServiceItem service;
  final DateTime schedule;
  final String timeLabel;
  final String status;
}

final class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.item});

  final _BookingHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusBackground) = switch (item.status) {
      'Selesai' => (AppColors.success, const Color(0xFFDCFCE7)),
      'Dibatalkan' => (AppColors.error, const Color(0xFFFEE2E2)),
      'Terjadwal' => (const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
      _ => (const Color(0xFFB45309), const Color(0xFFFEF3C7)),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.service.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(item.service.icon, color: item.service.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.service.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.number,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(context, item.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 19,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${AppFormatters.date(item.schedule)}, ${item.timeLabel}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Text(
                AppFormatters.rupiah(item.service.price),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(BuildContext context, String status) {
    return context.tr(switch (status) {
      'Selesai' => LanguageKeys.completed,
      'Dibatalkan' => LanguageKeys.cancelled,
      'Terjadwal' => LanguageKeys.scheduled,
      _ => LanguageKeys.awaitingConfirmation,
    });
  }
}

final class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(context.tr(LanguageKeys.noOrders)),
          ],
        ),
      ),
    );
  }
}
