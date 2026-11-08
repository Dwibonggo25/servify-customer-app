import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../domain/entities/booking_record.dart';

final class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({required this.booking, super.key});

  final BookingRecord booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(LanguageKeys.bookingConfirmation))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _SuccessHeader(number: booking.number),
          const SizedBox(height: 24),
          _SummaryCard(booking: booking),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(LanguageKeys.providerWillContact),
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          AppButton(
            label: context.tr(LanguageKeys.viewOrderHistory),
            icon: Icons.receipt_long_rounded,
            onPressed: () => context.go('/orders'),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: context.tr(LanguageKeys.backToHome),
            isOutlined: true,
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}

final class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 52,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr(LanguageKeys.orderCreated),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(LanguageKeys.orderNumber, {'number': number}),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

final class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.booking});

  final BookingRecord booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(LanguageKeys.orderSummary),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            icon: booking.icon,
            label: context.tr(LanguageKeys.service),
            value: booking.serviceName,
          ),
          _SummaryRow(
            icon: Icons.calendar_month_outlined,
            label: context.tr(LanguageKeys.schedule),
            value: AppFormatters.date(booking.scheduledAt),
          ),
          _SummaryRow(
            icon: Icons.location_on_outlined,
            label: context.tr(LanguageKeys.address),
            value: booking.address,
          ),
          _SummaryRow(
            icon: Icons.payments_outlined,
            label: context.tr(LanguageKeys.payment),
            value: _paymentLabel(context, booking.paymentMethod),
          ),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr(LanguageKeys.total),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                AppFormatters.rupiah(booking.totalAmount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _paymentLabel(BuildContext context, String method) {
    return context.tr(switch (method) {
      'bank_transfer' => LanguageKeys.bankTransfer,
      'e_wallet' => LanguageKeys.eWallet,
      _ => LanguageKeys.cash,
    });
  }
}

final class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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
