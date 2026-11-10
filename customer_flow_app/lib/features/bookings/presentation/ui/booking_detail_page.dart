import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../../../libraries/design_system/widgets/detail_app_bar.dart';
import '../../../services/presentation/widgets/service_image.dart';
import '../../../qr_verification/presentation/widgets/customer_booking_qr_card.dart';
import '../../domain/entities/booking_record.dart';
import '../bloc/booking_detail_bloc.dart';
import '../bloc/booking_detail_event.dart';
import '../bloc/booking_detail_state.dart';
import '../widgets/booking_status_badge.dart';

final class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({this.staffMode = false, super.key});

  final bool staffMode;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingDetailBloc, BookingDetailState>(
      listener: (context, state) {
        if (state.status == BookingDetailStatus.actionSuccess) {
          _showMessage(
            context,
            state.message ?? context.tr(LanguageKeys.actionSucceeded),
          );
          if (state.shouldPop) Navigator.of(context).pop(true);
        } else if (state.status == BookingDetailStatus.failure &&
            state.booking != null) {
          _showMessage(
            context,
            state.message ?? context.tr(LanguageKeys.actionFailed),
          );
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: const Color(0xFFF8F8FC),
        appBar: DetailAppBar(
          title: context.tr(LanguageKeys.bookingDetail),
          subtitle: context.tr(
            staffMode
                ? LanguageKeys.staffBookingDetailSubtitle
                : LanguageKeys.bookingDetailSubtitle,
          ),
        ),
        body: _body(context, state),
      ),
    );
  }

  Widget _body(BuildContext context, BookingDetailState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == BookingDetailStatus.failure && state.booking == null) {
      return _ErrorState(
        message: state.message,
        onRetry: () => context.read<BookingDetailBloc>().add(
          const BookingDetailRequested(),
        ),
      );
    }
    final booking = state.booking;
    if (booking == null) {
      return Center(child: Text(context.tr(LanguageKeys.orderNotFound)));
    }

    return _BookingDetailContent(
      booking: booking,
      staffMode: staffMode,
      submitting: state.isSubmitting,
      realtimeConnected: state.realtimeConnected,
      realtimeFailed: state.realtimeFailed,
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _BookingDetailContent extends StatelessWidget {
  const _BookingDetailContent({
    required this.booking,
    required this.staffMode,
    required this.submitting,
    required this.realtimeConnected,
    required this.realtimeFailed,
  });

  final BookingRecord booking;
  final bool staffMode;
  final bool submitting;
  final bool realtimeConnected;
  final bool realtimeFailed;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
    children: [
      _StatusSection(
        booking: booking,
        showRealtime: !staffMode,
        realtimeConnected: realtimeConnected,
        realtimeFailed: realtimeFailed,
      ),
      if (!staffMode &&
          (booking.status == 'on_the_way' ||
              booking.status == 'in_progress')) ...[
        const SizedBox(height: 16),
        CustomerBookingQrCard(booking: booking),
      ],
      const SizedBox(height: 16),
      _ProductSection(booking: booking, staffMode: staffMode),
      const SizedBox(height: 16),
      staffMode
          ? _StaffActionSection(booking: booking, submitting: submitting)
          : _HelpSection(booking: booking, submitting: submitting),
      const SizedBox(height: 16),
      _PaymentSection(booking: booking),
    ],
  );
}

final class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.booking,
    required this.showRealtime,
    required this.realtimeConnected,
    required this.realtimeFailed,
  });

  final BookingRecord booking;
  final bool showRealtime;
  final bool realtimeConnected;
  final bool realtimeFailed;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: context.tr(LanguageKeys.orderStatus),
    icon: Icons.local_shipping_outlined,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              BookingStatusBadge.label(context, booking.status),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          BookingStatusBadge(status: booking.status),
        ],
      ),
      if (showRealtime) ...[
        const SizedBox(height: 10),
        _RealtimeIndicator(
          connected: realtimeConnected,
          failed: realtimeFailed,
        ),
      ],
      const Divider(height: 28),
      _LabelValue(
        label: context.tr(LanguageKeys.invoice),
        value: booking.number,
      ),
      const SizedBox(height: 12),
      _LabelValue(
        label: context.tr(LanguageKeys.orderDate),
        value: AppFormatters.dateTime(booking.createdAt),
      ),
      const SizedBox(height: 12),
      _LabelValue(
        label: context.tr(LanguageKeys.serviceDate),
        value: AppFormatters.dateTime(booking.scheduledAt),
      ),
      if (booking.history.isNotEmpty) ...[
        const Divider(height: 28),
        Text(
          context.tr(LanguageKeys.statusJourney),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        ...booking.history.indexed.map(
          (entry) => _TimelineEntry(
            entry: entry.$2,
            isLast: entry.$1 == booking.history.length - 1,
          ),
        ),
      ],
    ],
  );
}

final class _RealtimeIndicator extends StatelessWidget {
  const _RealtimeIndicator({required this.connected, required this.failed});

  final bool connected;
  final bool failed;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: connected
              ? AppColors.success
              : failed
              ? AppColors.error
              : AppColors.textSecondary,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 7),
      Text(
        connected
            ? context.tr(LanguageKeys.realtimeActive)
            : failed
            ? context.tr(LanguageKeys.realtimeDisconnected)
            : context.tr(LanguageKeys.realtimeConnecting),
        style: TextStyle(
          color: connected
              ? AppColors.success
              : failed
              ? AppColors.error
              : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

final class _ProductSection extends StatelessWidget {
  const _ProductSection({required this.booking, required this.staffMode});

  final BookingRecord booking;
  final bool staffMode;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: context.tr(LanguageKeys.productDetails),
    icon: Icons.home_repair_service_outlined,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            height: 86,
            child: ServiceImage(
              imageUrl: booking.imageUrl,
              fallbackIcon: booking.icon,
              color: booking.color,
              iconSize: 38,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr(LanguageKeys.serviceOrderType),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Text(
                  AppFormatters.rupiah(booking.servicePrice),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const Divider(height: 28),
      _IconDetail(
        icon: Icons.location_on_outlined,
        label: context.tr(LanguageKeys.serviceLocation),
        value: booking.address,
      ),
      if (staffMode) ...[
        const SizedBox(height: 14),
        _IconDetail(
          icon: Icons.person_outline_rounded,
          label: context.tr(LanguageKeys.customer),
          value: booking.customerName,
        ),
        const SizedBox(height: 14),
        _IconDetail(
          icon: Icons.phone_outlined,
          label: context.tr(LanguageKeys.phoneNumber),
          value: booking.customerPhone,
        ),
      ],
      if (booking.note?.trim().isNotEmpty == true) ...[
        const SizedBox(height: 14),
        _IconDetail(
          icon: Icons.notes_rounded,
          label: context.tr(LanguageKeys.notes),
          value: booking.note!,
        ),
      ],
    ],
  );
}

final class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.booking, required this.submitting});

  final BookingRecord booking;
  final bool submitting;

  bool get _canCancel =>
      booking.staffId == null &&
      (booking.status == 'pending' || booking.status == 'confirmed');

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: context.tr(LanguageKeys.help),
    icon: Icons.support_agent_rounded,
    padding: EdgeInsets.zero,
    children: [
      _ActionTile(
        icon: Icons.chat_bubble_outline_rounded,
        title: context.tr(LanguageKeys.chatProvider),
        subtitle: context.tr(LanguageKeys.chatProviderDescription),
        onTap: () =>
            _comingSoon(context, context.tr(LanguageKeys.chatComingSoon)),
      ),
      if (_canCancel)
        _ActionTile(
          icon: Icons.cancel_outlined,
          title: context.tr(LanguageKeys.cancelOrder),
          subtitle: context.tr(LanguageKeys.cancelOrderDescription),
          destructive: true,
          onTap: submitting ? null : () => _confirmCancellation(context),
        ),
      _ActionTile(
        icon: Icons.help_outline_rounded,
        title: context.tr(LanguageKeys.helpCenter),
        subtitle: context.tr(LanguageKeys.helpCenterDescription),
        showDivider: false,
        onTap: () =>
            _comingSoon(context, context.tr(LanguageKeys.helpCenterComingSoon)),
      ),
    ],
  );

  Future<void> _confirmCancellation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr(LanguageKeys.cancelOrderQuestion)),
        content: Text(context.tr(LanguageKeys.cancelOrderWarning)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr(LanguageKeys.back)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.tr(LanguageKeys.cancelOrder)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<BookingDetailBloc>().add(
        const BookingCancellationSubmitted(),
      );
    }
  }

  void _comingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _StaffActionSection extends StatelessWidget {
  const _StaffActionSection({required this.booking, required this.submitting});

  final BookingRecord booking;
  final bool submitting;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: context.tr(LanguageKeys.workActions),
    icon: Icons.engineering_outlined,
    children: _actions(context),
  );

  List<Widget> _actions(BuildContext context) {
    if (booking.isAvailable) {
      return [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: context.tr(LanguageKeys.reject),
                isOutlined: true,
                isLoading: submitting,
                onPressed: () => context.read<BookingDetailBloc>().add(
                  const BookingResponseSubmitted(accept: false),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: context.tr(LanguageKeys.accept),
                isLoading: submitting,
                onPressed: () => context.read<BookingDetailBloc>().add(
                  const BookingResponseSubmitted(accept: true),
                ),
              ),
            ),
          ],
        ),
      ];
    }

    if (booking.status == 'assigned') {
      return [
        AppButton(
          label: context.tr(LanguageKeys.leaveForLocation),
          icon: Icons.directions_rounded,
          isLoading: submitting,
          onPressed: () => context.read<BookingDetailBloc>().add(
            const BookingProgressSubmitted('on_the_way'),
          ),
        ),
      ];
    }

    final scanPurpose = switch (booking.status) {
      'on_the_way' => (
        context.tr(LanguageKeys.qrPurposeArrival),
        context.tr(LanguageKeys.scanArrivalQr),
      ),
      'in_progress' => (
        context.tr(LanguageKeys.qrPurposeCompletion),
        context.tr(LanguageKeys.scanCompletionQr),
      ),
      _ => null,
    };
    if (scanPurpose == null) {
      return [Text(context.tr(LanguageKeys.noFurtherAction))];
    }
    return [
      AppButton(
        label: scanPurpose.$2,
        icon: Icons.qr_code_scanner_rounded,
        isLoading: submitting,
        onPressed: () async {
          final verified = await context.push<bool>(
            '/staff/bookings/${booking.id}/scan'
            '?purpose=${scanPurpose.$1}',
          );
          if (verified == true && context.mounted) {
            context.read<BookingDetailBloc>().add(
              const BookingDetailRequested(),
            );
          }
        },
      ),
      const SizedBox(height: 10),
      Text(
        context.tr(LanguageKeys.qrLocationDisclosure),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    ];
  }
}

final class _PaymentSection extends StatelessWidget {
  const _PaymentSection({required this.booking});

  final BookingRecord booking;

  @override
  Widget build(BuildContext context) {
    final serviceFee = booking.totalAmount - booking.servicePrice;
    return _SectionCard(
      title: context.tr(LanguageKeys.paymentDetails),
      icon: Icons.receipt_long_outlined,
      children: [
        _PaymentRow(
          label: context.tr(LanguageKeys.servicePrice),
          value: AppFormatters.rupiah(booking.servicePrice),
        ),
        const SizedBox(height: 12),
        _PaymentRow(
          label: context.tr(LanguageKeys.serviceFee),
          value: AppFormatters.rupiah(serviceFee < 0 ? 0 : serviceFee),
        ),
        const SizedBox(height: 12),
        _PaymentRow(
          label: context.tr(LanguageKeys.paymentMethod),
          value: _paymentMethodLabel(context, booking.paymentMethod),
        ),
        const Divider(height: 28),
        _PaymentRow(
          label: context.tr(LanguageKeys.totalPayment),
          value: AppFormatters.rupiah(booking.totalAmount),
          emphasized: true,
        ),
      ],
    );
  }

  String _paymentMethodLabel(BuildContext context, String method) =>
      switch (method) {
        'bank_transfer' => context.tr(LanguageKeys.bankTransfer),
        'ewallet' || 'e_wallet' => context.tr(LanguageKeys.eWallet),
        _ => context.tr(LanguageKeys.cash),
      };
}

final class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.padding = const EdgeInsets.all(18),
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Row(
            children: [
              Icon(icon, size: 21, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    ),
  );
}

final class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 118,
        child: Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

final class _IconDetail extends StatelessWidget {
  const _IconDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 21, color: AppColors.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  );
}

final class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: emphasized ? AppColors.primary : AppColors.textPrimary,
          fontSize: emphasized ? 17 : 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

final class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: destructive
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            icon,
            color: destructive ? AppColors.error : AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: destructive ? AppColors.error : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
      if (showDivider) const Divider(height: 1, indent: 76, endIndent: 18),
    ],
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
          if (!isLast) Container(width: 2, height: 38, color: AppColors.border),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BookingStatusBadge.label(context, entry.status),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                AppFormatters.dateTime(entry.createdAt),
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

final class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? context.tr(LanguageKeys.bookingDetailLoadFailed)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr(LanguageKeys.retry)),
          ),
        ],
      ),
    ),
  );
}
