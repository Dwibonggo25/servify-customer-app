import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_bar.dart';
import '../../../../libraries/design_system/widgets/app_bottom_navigation.dart';
import '../../../services/presentation/widgets/service_image.dart';
import '../../domain/entities/booking_record.dart';
import '../cubit/booking_history_cubit.dart';
import '../cubit/booking_history_state.dart';
import '../widgets/booking_status_badge.dart';

final class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBarWidget(
        title: LanguageKeys.myOrders,
        icons: Icons.receipt_long_rounded,
        subtitle: LanguageKeys.myOrdersSubtitle,
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          const _OrderFilterBar(),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<BookingHistoryCubit, BookingHistoryState>(
              builder: (context, state) => _OrderBody(state: state),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 1,
        onScanPressed: () =>
            _message(context, context.tr(LanguageKeys.scanComingSoon)),
        onDestinationSelected: (index) {
          if (index == 0) context.go('/home');
          if (index == 2) context.go('/favorites');
          if (index == 3) context.go('/profile');
        },
      ),
    );
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _OrderFilterBar extends StatelessWidget {
  const _OrderFilterBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingHistoryCubit, BookingHistoryState>(
      buildWhen: (previous, current) => previous.filter != current.filter,
      builder: (context, state) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFEDEDF5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: BookingHistoryFilter.values.map((filter) {
              final selected = state.filter == filter;
              return Expanded(
                child: Material(
                  color: selected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context
                        .read<BookingHistoryCubit>()
                        .selectFilter(filter),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        context.tr(switch (filter) {
                          BookingHistoryFilter.ongoing => LanguageKeys.ongoing,
                          BookingHistoryFilter.completed =>
                            LanguageKeys.completed,
                          BookingHistoryFilter.all => LanguageKeys.all,
                        }),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

final class _OrderBody extends StatelessWidget {
  const _OrderBody({required this.state});

  final BookingHistoryState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const _OrderListLoading();

    if (state.status == BookingHistoryStatus.failure &&
        state.bookings.isEmpty) {
      return _OrderError(onRetry: context.read<BookingHistoryCubit>().load);
    }

    final items = state.visibleBookings;
    if (items.isEmpty) return const _EmptyOrders();

    return RefreshIndicator(
      onRefresh: () => context.read<BookingHistoryCubit>().load(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) => _BookingCard(
          item: items[index],
          onTap: () => context.push('/orders/${items[index].id}'),
        ),
      ),
    );
  }
}

final class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.item, required this.onTap});

  final BookingRecord item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF20213A).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 84,
                      child: ServiceImage(
                        imageUrl: item.imageUrl,
                        fallbackIcon: item.icon,
                        color: item.color,
                        iconSize: 32,
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.serviceName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.number,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          BookingStatusBadge(status: item.status),
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.status != 'cancelled') ...[
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _statusProgress(item.status),
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE9E9F1),
                      color: item.status == 'completed'
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEBFF),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
                        size: 19,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(LanguageKeys.serviceDate),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppFormatters.date(item.scheduledAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.tr(LanguageKeys.total),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.rupiah(item.totalAmount),
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      context.tr(LanguageKeys.viewDetails),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _statusProgress(String status) {
    return switch (status) {
      'pending' => 0.12,
      'confirmed' => 0.28,
      'assigned' => 0.45,
      'on_the_way' => 0.62,
      'in_progress' => 0.82,
      'completed' => 1,
      _ => 0.08,
    };
  }
}

final class _OrderListLoading extends StatelessWidget {
  const _OrderListLoading();

  @override
  Widget build(BuildContext context) => ListView.separated(
    key: const Key('booking_history_loading'),
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
    itemCount: 3,
    separatorBuilder: (_, _) => const SizedBox(height: 14),
    itemBuilder: (_, _) => Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9F1),
        borderRadius: BorderRadius.circular(22),
      ),
    ),
  );
}

final class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFEDEBFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr(LanguageKeys.noOrders),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

final class _OrderError extends StatelessWidget {
  const _OrderError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: Text(context.tr(LanguageKeys.retry)),
    ),
  );
}
