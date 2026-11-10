import 'package:flutter/material.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../bookings/domain/entities/booking_record.dart';
import '../../../bookings/presentation/widgets/booking_status_badge.dart';
import '../../../services/presentation/widgets/service_image.dart';

final class StaffBookingCard extends StatelessWidget {
  const StaffBookingCard({
    required this.booking,
    required this.onTap,
    super.key,
  });

  final BookingRecord booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isNew = booking.isAvailable;
    final accent = isNew ? const Color(0xFFF59E0B) : booking.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isNew
                    ? accent.withValues(alpha: 0.45)
                    : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNew)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    color: accent.withValues(alpha: 0.1),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.fiber_new_rounded,
                          size: 19,
                          color: Color(0xFFB45309),
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Pesanan baru — menunggu respons Anda',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 62,
                            height: 62,
                            child: ServiceImage(
                              imageUrl: booking.imageUrl,
                              fallbackIcon: booking.icon,
                              color: booking.color,
                              iconSize: 28,
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.serviceName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  booking.number,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          BookingStatusBadge(status: booking.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_available_rounded,
                              size: 19,
                              color: accent,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                AppFormatters.dateTime(booking.scheduledAt),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        text: booking.customerName,
                      ),
                      const SizedBox(height: 9),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: booking.address,
                        maxLines: 2,
                      ),
                      const Divider(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nilai pekerjaan',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppFormatters.rupiah(booking.totalAmount),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'Lihat detail',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

final class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.maxLines = 1});

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(width: 1),
      Icon(icon, size: 18, color: AppColors.textSecondary),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
