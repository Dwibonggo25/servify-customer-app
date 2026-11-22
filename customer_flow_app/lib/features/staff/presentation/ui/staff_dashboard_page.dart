import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../bloc/staff_bookings_bloc.dart';
import '../bloc/staff_bookings_event.dart';
import '../bloc/staff_bookings_state.dart';
import '../widgets/staff_booking_card.dart';
import '../widgets/staff_bottom_navigation.dart';
import '../widgets/staff_gradient_app_bar.dart';

final class StaffDashboardPage extends StatelessWidget {
  const StaffDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F8FC),
    appBar: StaffGradientAppBar(
      title: context.tr(LanguageKeys.staffDashboard),
      subtitle: context.tr(LanguageKeys.staffDashboardSubtitle),
      icon: Icons.dashboard_customize_rounded,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton.filledTonal(
            tooltip: context.tr(LanguageKeys.notifications),
            onPressed: () => context.push('/staff/notifications'),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
    ),
    body: BlocBuilder<StaffBookingsBloc, StaffBookingsState>(
      builder: (context, state) {
        if (state.status == StaffBookingsStatus.loading &&
            state.bookings.isEmpty) {
          return const _LoadingView(dashboardMode: true);
        }
        if (state.status == StaffBookingsStatus.failure &&
            state.bookings.isEmpty) {
          return _ErrorView(message: state.message);
        }
        return RefreshIndicator(
          onRefresh: () => _refreshBookings(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
            children: [
              if (state.status == StaffBookingsStatus.failure) ...[
                _SyncErrorBanner(message: state.message),
                const SizedBox(height: 16),
              ],
              if (state.realtimeFailed &&
                  state.status != StaffBookingsStatus.failure) ...[
                _SyncErrorBanner(
                  message: context.tr(LanguageKeys.staffRealtimeDisconnected),
                ),
                const SizedBox(height: 16),
              ],
              _OpportunityBanner(
                count: state.available.length,
                onTap: () => context.go('/staff/incoming'),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: context.tr(LanguageKeys.workSummary),
                subtitle: context.tr(LanguageKeys.currentAccountActivity),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: context.tr(LanguageKeys.newLabel),
                      value: state.available.length,
                      icon: Icons.mark_email_unread_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: context.tr(LanguageKeys.active),
                      value: state.active.length,
                      icon: Icons.handyman_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: context.tr(LanguageKeys.completed),
                      value: state.completedCount,
                      icon: Icons.task_alt_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _SectionTitle(
                title: context.tr(LanguageKeys.activeWork),
                subtitle: context.tr(LanguageKeys.activeWorkDescription),
                actionLabel: context.tr(LanguageKeys.seeAll),
                onAction: () => context.go('/staff/incoming'),
              ),
              const SizedBox(height: 14),
              if (state.active.isEmpty)
                _EmptyCard(
                  icon: Icons.work_history_outlined,
                  title: context.tr(LanguageKeys.noActiveWork),
                  subtitle: context.tr(LanguageKeys.noActiveWorkDescription),
                )
              else
                ...state.active
                    .take(2)
                    .map(
                      (booking) => StaffBookingCard(
                        booking: booking,
                        onTap: () async {
                          await context.push('/staff/bookings/${booking.id}');
                          if (context.mounted) {
                            context.read<StaffBookingsBloc>().add(
                              const StaffBookingsRequested(refresh: true),
                            );
                          }
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    ),
    bottomNavigationBar: const StaffBottomNavigation(index: 0),
  );
}

final class StaffBookingListPage extends StatelessWidget {
  const StaffBookingListPage({required this.historyMode, super.key});

  final bool historyMode;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F8FC),
    appBar: StaffGradientAppBar(
      title: context.tr(
        historyMode ? LanguageKeys.workHistory : LanguageKeys.incomingOrders,
      ),
      subtitle: historyMode
          ? context.tr(LanguageKeys.workHistoryDescription)
          : context.tr(LanguageKeys.incomingOrdersDescription),
      icon: historyMode ? Icons.history_rounded : Icons.inbox_rounded,
    ),
    body: BlocBuilder<StaffBookingsBloc, StaffBookingsState>(
      builder: (context, state) {
        if (state.status == StaffBookingsStatus.loading &&
            state.bookings.isEmpty) {
          return const _LoadingView(dashboardMode: false);
        }
        if (state.status == StaffBookingsStatus.failure &&
            state.bookings.isEmpty) {
          return _ErrorView(message: state.message);
        }
        final items = historyMode ? state.history : state.incoming;
        return RefreshIndicator(
          onRefresh: () => _refreshBookings(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
            children: [
              if (state.status == StaffBookingsStatus.failure) ...[
                _SyncErrorBanner(message: state.message),
                const SizedBox(height: 16),
              ],
              if (state.realtimeFailed &&
                  state.status != StaffBookingsStatus.failure) ...[
                _SyncErrorBanner(
                  message: context.tr(LanguageKeys.staffRealtimeDisconnected),
                ),
                const SizedBox(height: 16),
              ],
              _ListSummaryCard(
                historyMode: historyMode,
                count: items.length,
                newCount: state.available.length,
              ),
              const SizedBox(height: 22),
              _SectionTitle(
                title: context.tr(
                  historyMode
                      ? LanguageKeys.allHistory
                      : LanguageKeys.orderList,
                ),
                subtitle: historyMode
                    ? context.tr(LanguageKeys.workFound, {
                        'count': items.length,
                      })
                    : context.tr(LanguageKeys.newOrdersWaiting, {
                        'count': state.available.length,
                      }),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                _EmptyCard(
                  icon: historyMode
                      ? Icons.history_toggle_off_rounded
                      : Icons.inbox_outlined,
                  title: historyMode
                      ? context.tr(LanguageKeys.noWorkHistory)
                      : context.tr(LanguageKeys.noIncomingOrders),
                  subtitle: historyMode
                      ? context.tr(LanguageKeys.completedWorkAppear)
                      : context.tr(LanguageKeys.pullLatestOrders),
                )
              else
                ...items.map(
                  (booking) => StaffBookingCard(
                    booking: booking,
                    onTap: () async {
                      await context.push('/staff/bookings/${booking.id}');
                      if (context.mounted) {
                        context.read<StaffBookingsBloc>().add(
                          const StaffBookingsRequested(refresh: true),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ),
    bottomNavigationBar: StaffBottomNavigation(index: historyMode ? 2 : 1),
  );
}

Future<void> _refreshBookings(BuildContext context) async {
  final bloc = context.read<StaffBookingsBloc>();
  bloc.add(const StaffBookingsRequested(refresh: true));
  await bloc.stream.firstWhere(
    (state) => !state.refreshing && state.status != StaffBookingsStatus.loading,
  );
}

final class _OpportunityBanner extends StatelessWidget {
  const _OpportunityBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF7E6), Color(0xFFFFE8B8)],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFFCD38D)),
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count == 0
                    ? context.tr(LanguageKeys.noNewOrders)
                    : context.tr(LanguageKeys.newOrdersAvailable, {
                        'count': count,
                      }),
                style: const TextStyle(
                  color: Color(0xFF78350F),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count == 0
                    ? context.tr(LanguageKeys.newWorkNotify)
                    : context.tr(LanguageKeys.checkAndTakeWork),
                style: const TextStyle(color: Color(0xFF92400E), fontSize: 12),
              ),
            ],
          ),
        ),
        if (count > 0)
          IconButton.filled(
            onPressed: onTap,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
      ],
    ),
  );
}

final class _ListSummaryCard extends StatelessWidget {
  const _ListSummaryCard({
    required this.historyMode,
    required this.count,
    required this.newCount,
  });

  final bool historyMode;
  final int count;
  final int newCount;

  @override
  Widget build(BuildContext context) {
    final color = historyMode ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              historyMode ? Icons.task_alt_rounded : Icons.assignment_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    historyMode
                        ? LanguageKeys.completedWorkCount
                        : LanguageKeys.activeOrderCount,
                    {'count': count},
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  historyMode
                      ? context.tr(LanguageKeys.workDocumentation)
                      : context.tr(LanguageKeys.newOrdersAmong, {
                          'count': newCount,
                        }),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.07),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 9),
        Text(
          '$value',
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      if (actionLabel != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

final class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Icon(icon, size: 44, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}

final class _LoadingView extends StatefulWidget {
  const _LoadingView({required this.dashboardMode});

  final bool dashboardMode;

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

final class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    key: const Key('staff_loading_shimmer'),
    animation: _controller,
    builder: (context, child) {
      final position = (_controller.value * 3) - 1.5;
      return ShaderMask(
        blendMode: BlendMode.modulate,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(position - 1, 0),
          end: Alignment(position + 1, 0),
          colors: const [
            Color(0xFFE5E5EE),
            Color(0xFFF8F8FC),
            Color(0xFFE5E5EE),
          ],
          stops: const [0.25, 0.5, 0.75],
        ).createShader(bounds),
        child: child,
      );
    },
    child: _StaffLoadingSkeleton(dashboardMode: widget.dashboardMode),
  );
}

final class _StaffLoadingSkeleton extends StatelessWidget {
  const _StaffLoadingSkeleton({required this.dashboardMode});

  final bool dashboardMode;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
    children: dashboardMode
        ? const [
            _LoadingSummaryCard(),
            SizedBox(height: 24),
            _LoadingSectionTitle(),
            SizedBox(height: 14),
            _LoadingMetrics(),
            SizedBox(height: 28),
            _LoadingSectionTitle(hasAction: true),
            SizedBox(height: 14),
            _LoadingBookingCard(),
            SizedBox(height: 12),
            _LoadingBookingCard(),
          ]
        : const [
            _LoadingSummaryCard(),
            SizedBox(height: 22),
            _LoadingSectionTitle(),
            SizedBox(height: 14),
            _LoadingBookingCard(),
            SizedBox(height: 12),
            _LoadingBookingCard(),
            SizedBox(height: 12),
            _LoadingBookingCard(),
          ],
  );
}

final class _LoadingSummaryCard extends StatelessWidget {
  const _LoadingSummaryCard();

  @override
  Widget build(BuildContext context) => Container(
    height: 94,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: const Row(
      children: [
        _StaffLoadingBlock(width: 52, height: 52, radius: 17),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StaffLoadingBlock(width: 186, height: 16),
              SizedBox(height: 9),
              _StaffLoadingBlock(width: 224, height: 11),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _LoadingSectionTitle extends StatelessWidget {
  const _LoadingSectionTitle({this.hasAction = false});

  final bool hasAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StaffLoadingBlock(width: 146, height: 19),
            SizedBox(height: 8),
            _StaffLoadingBlock(width: 218, height: 11),
          ],
        ),
      ),
      if (hasAction)
        const _StaffLoadingBlock(width: 56, height: 28, radius: 10),
    ],
  );
}

final class _LoadingMetrics extends StatelessWidget {
  const _LoadingMetrics();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: _LoadingMetricCard()),
      SizedBox(width: 10),
      Expanded(child: _LoadingMetricCard()),
      SizedBox(width: 10),
      Expanded(child: _LoadingMetricCard()),
    ],
  );
}

final class _LoadingMetricCard extends StatelessWidget {
  const _LoadingMetricCard();

  @override
  Widget build(BuildContext context) => Container(
    height: 126,
    padding: const EdgeInsets.symmetric(vertical: 15),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: const Column(
      children: [
        _StaffLoadingBlock(width: 38, height: 38, radius: 13),
        SizedBox(height: 10),
        _StaffLoadingBlock(width: 32, height: 20),
        SizedBox(height: 7),
        _StaffLoadingBlock(width: 54, height: 10),
      ],
    ),
  );
}

final class _LoadingBookingCard extends StatelessWidget {
  const _LoadingBookingCard();

  @override
  Widget build(BuildContext context) => Container(
    height: 156,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StaffLoadingBlock(width: 54, height: 54, radius: 17),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StaffLoadingBlock(width: 92, height: 11),
              SizedBox(height: 9),
              _StaffLoadingBlock(width: 174, height: 17),
              SizedBox(height: 10),
              _StaffLoadingBlock(width: double.infinity, height: 11),
              SizedBox(height: 7),
              _StaffLoadingBlock(width: 156, height: 11),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StaffLoadingBlock(width: 88, height: 13),
                  _StaffLoadingBlock(width: 72, height: 28, radius: 10),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _StaffLoadingBlock extends StatelessWidget {
  const _StaffLoadingBlock({
    required this.width,
    required this.height,
    this.radius = 7,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE8E8F0),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

final class _ErrorView extends StatelessWidget {
  const _ErrorView({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
          Text(
            message ?? context.tr(LanguageKeys.ordersLoadFailed),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.read<StaffBookingsBloc>().add(
              const StaffBookingsRequested(),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr(LanguageKeys.retry)),
          ),
        ],
      ),
    ),
  );
}

final class _SyncErrorBanner extends StatelessWidget {
  const _SyncErrorBanner({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.sync_problem_rounded, color: AppColors.error),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message ?? context.tr(LanguageKeys.latestDataSyncFailed),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
