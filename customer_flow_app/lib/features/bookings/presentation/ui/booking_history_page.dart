import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_bottom_navigation.dart';
import '../../domain/entities/booking_record.dart';
import '../../domain/repositories/booking_repository.dart';
import '../widgets/booking_status_badge.dart';

final class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({required this.repository, super.key});

  final BookingRepository repository;

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

final class _BookingHistoryPageState extends State<BookingHistoryPage> {
  String _filter = 'all';
  late Future<List<BookingRecord>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = widget.repository.getCustomerBookings();

  @override
  Widget build(BuildContext context) {
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
              children: ['all', 'ongoing', 'completed'].map((filter) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          context.tr(switch (filter) {
                            'ongoing' => LanguageKeys.ongoing,
                            'completed' => LanguageKeys.completed,
                            _ => LanguageKeys.all,
                          }),
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
          Expanded(child: _buildBookings()),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 1,
        onScanPressed: () => _message(context.tr(LanguageKeys.scanComingSoon)),
        onDestinationSelected: (index) {
          if (index == 0) context.go('/home');
          if (index == 2) context.go('/favorites');
          if (index == 3) context.go('/profile');
        },
      ),
    );
  }

  Widget _buildBookings() {
    return FutureBuilder<List<BookingRecord>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton.icon(
              onPressed: () => setState(_reload),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr(LanguageKeys.retry)),
            ),
          );
        }
        final items = (snapshot.data ?? const <BookingRecord>[])
            .where(
              (booking) => switch (_filter) {
                'ongoing' => !booking.isFinished,
                'completed' => booking.status == 'completed',
                _ => true,
              },
            )
            .toList(growable: false);
        if (items.isEmpty) {
          return Center(child: Text(context.tr(LanguageKeys.noOrders)));
        }
        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _future;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _BookingCard(
              item: items[index],
              onTap: () => context.push('/orders/${items[index].id}'),
            ),
          ),
        );
      },
    );
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.item, required this.onTap});

  final BookingRecord item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(item.icon, color: item.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.serviceName,
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
                  BookingStatusBadge(status: item.status),
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
                      AppFormatters.date(item.scheduledAt),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    AppFormatters.rupiah(item.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
