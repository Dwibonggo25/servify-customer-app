import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

final class NotificationPage extends StatefulWidget {
  const NotificationPage({
    required this.repository,
    required this.staffMode,
    super.key,
  });

  final NotificationRepository repository;
  final bool staffMode;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

final class _NotificationPageState extends State<NotificationPage> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = widget.repository.getNotifications();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: const _NotificationAppBar(),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _NotificationLoading();
          }
          if (snapshot.hasError) {
            return _NotificationMessageState(
              icon: Icons.cloud_off_rounded,
              title: context.tr(LanguageKeys.notificationLoadFailedTitle),
              description: context.tr(
                LanguageKeys.notificationLoadFailedDescription,
              ),
              actionLabel: context.tr(LanguageKeys.retry),
              onAction: () => setState(_reload),
            );
          }
          final items = snapshot.data ?? const <AppNotification>[];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 72, 20, 32),
                children: [
                  _NotificationMessageState(
                    icon: Icons.notifications_none_rounded,
                    title: context.tr(LanguageKeys.notificationEmptyTitle),
                    description: context.tr(
                      LanguageKeys.notificationEmptyDescription,
                    ),
                  ),
                ],
              ),
            );
          }

          final unreadCount = items.where((item) => !item.isRead).length;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              children: [
                _NotificationSummary(unreadCount: unreadCount),
                const SizedBox(height: 26),
                Text(
                  context.tr(LanguageKeys.notificationLatest),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationTile(
                      item: item,
                      onTap: () => _open(item),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _open(AppNotification item) async {
    if (!item.isRead) await widget.repository.markAsRead(item.id);
    if (!mounted) return;
    final bookingId = item.bookingId;
    if (bookingId != null) {
      await context.push(
        widget.staffMode ? '/staff/bookings/$bookingId' : '/orders/$bookingId',
      );
    }
    if (mounted) setState(_reload);
  }
}

final class _NotificationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _NotificationAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(96);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: preferredSize.height,
    backgroundColor: const Color(0xFFFBFBFE),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleSpacing: 8,
    shape: const Border(
      bottom: BorderSide(color: AppColors.border, width: 0.8),
    ),
    leadingWidth: 68,
    leading: Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Center(
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.maybePop(context),
            child: const SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    ),
    title: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEBFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(LanguageKeys.notifications),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.tr(LanguageKeys.notificationsPageSubtitle),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFF0EEFF),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFDDD8FF)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.mark_email_unread_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(LanguageKeys.notificationSummaryTitle),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unreadCount > 0
                    ? context.tr(LanguageKeys.notificationUnreadSummary, {
                        'count': unreadCount.toString(),
                      })
                    : context.tr(LanguageKeys.notificationAllReadSummary),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appearance = _NotificationAppearance.from(item.type);

    return Material(
      color: item.isRead ? AppColors.surface : const Color(0xFFF8F6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: item.isRead
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.24),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: appearance.background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  appearance.icon,
                  color: appearance.foreground,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              context.tr(LanguageKeys.notificationNew),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.textSecondary,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            AppFormatters.dateTime(item.createdAt),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (item.bookingId != null)
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.textSecondary,
                            size: 14,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _NotificationAppearance {
  const _NotificationAppearance({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;

  factory _NotificationAppearance.from(String type) => switch (type) {
    'booking_created' => const _NotificationAppearance(
      icon: Icons.receipt_long_rounded,
      foreground: AppColors.primary,
      background: Color(0xFFEDEBFF),
    ),
    'new_booking' => const _NotificationAppearance(
      icon: Icons.add_task_rounded,
      foreground: Color(0xFF0F766E),
      background: Color(0xFFCCFBF1),
    ),
    'booking_status' => const _NotificationAppearance(
      icon: Icons.sync_rounded,
      foreground: Color(0xFFB45309),
      background: Color(0xFFFEF3C7),
    ),
    _ => const _NotificationAppearance(
      icon: Icons.notifications_rounded,
      foreground: AppColors.primary,
      background: Color(0xFFEDEBFF),
    ),
  };
}

final class _NotificationLoading extends StatefulWidget {
  const _NotificationLoading();

  @override
  State<_NotificationLoading> createState() => _NotificationLoadingState();
}

final class _NotificationLoadingState extends State<_NotificationLoading>
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
            Color(0xFFF7F7FC),
            Color(0xFFE5E5EE),
          ],
          stops: const [0.25, 0.5, 0.75],
        ).createShader(bounds),
        child: child,
      );
    },
    child: const _NotificationSkeleton(),
  );
}

final class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();

  static const _baseColor = Color(0xFFE8E8F0);
  static const _surfaceColor = Color(0xFFF1F1F6);

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
    children: [
      Container(
        height: 86,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          children: [
            _SkeletonBlock(width: 48, height: 48, radius: 16),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBlock(width: 148, height: 14, radius: 7),
                  SizedBox(height: 9),
                  _SkeletonBlock(width: 208, height: 11, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      const _SkeletonBlock(width: 142, height: 18, radius: 8),
      const SizedBox(height: 14),
      ...List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _NotificationCardSkeleton(),
        ),
      ),
    ],
  );
}

final class _NotificationCardSkeleton extends StatelessWidget {
  const _NotificationCardSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    height: 126,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _NotificationSkeleton._surfaceColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBlock(width: 46, height: 46, radius: 15),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBlock(width: 172, height: 14, radius: 7),
              SizedBox(height: 10),
              _SkeletonBlock(height: 10, radius: 5),
              SizedBox(height: 7),
              _SkeletonBlock(width: 214, height: 10, radius: 5),
              Spacer(),
              _SkeletonBlock(width: 126, height: 9, radius: 5),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    this.width,
    required this.height,
    required this.radius,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width ?? double.infinity,
    height: height,
    decoration: BoxDecoration(
      color: _NotificationSkeleton._baseColor,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

final class _NotificationMessageState extends StatelessWidget {
  const _NotificationMessageState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFEDEBFF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}
