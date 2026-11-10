import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../../bookings/domain/entities/booking_record.dart';
import '../../domain/entities/booking_qr_code.dart';
import '../cubit/customer_qr_cubit.dart';

final class CustomerBookingQrCard extends StatelessWidget {
  const CustomerBookingQrCard({required this.booking, super.key});

  final BookingRecord booking;

  BookingQrPurpose? get _purpose => switch (booking.status) {
    'on_the_way' => BookingQrPurpose.arrival,
    'in_progress' => BookingQrPurpose.completion,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final purpose = _purpose;
    if (purpose == null) return const SizedBox.shrink();
    final purposeLabel = context.tr(
      purpose == BookingQrPurpose.arrival
          ? LanguageKeys.qrPurposeArrival
          : LanguageKeys.qrPurposeCompletion,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: BlocBuilder<CustomerQrCubit, CustomerQrState>(
        builder: (context, state) {
          final qr = state.qrCode;
          final hasCurrentQr =
              state.status == CustomerQrStatus.success &&
              qr?.purpose == purpose;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(LanguageKeys.qrVerificationTitle, {
                        'purpose': purposeLabel,
                      }),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                purpose == BookingQrPurpose.arrival
                    ? context.tr(LanguageKeys.qrArrivalInstruction)
                    : context.tr(LanguageKeys.qrCompletionInstruction),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (state.status == CustomerQrStatus.failure) ...[
                Text(
                  state.message ?? context.tr(LanguageKeys.qrLoadFailed),
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 12),
              ],
              if (hasCurrentQr) ...[
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: QrImageView(
                        data: qr!.token,
                        size: 210,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.textPrimary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    context.tr(LanguageKeys.qrExpiresAt, {
                      'date': AppFormatters.dateTime(qr.expiresAt),
                    }),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ] else
                AppButton(
                  label: context.tr(LanguageKeys.showQr, {
                    'purpose': purposeLabel,
                  }),
                  icon: Icons.qr_code_rounded,
                  isLoading: state.status == CustomerQrStatus.loading,
                  onPressed: () => context.read<CustomerQrCubit>().load(
                    bookingId: booking.id,
                    purpose: purpose,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                context.tr(LanguageKeys.qrSafetyNotice),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
