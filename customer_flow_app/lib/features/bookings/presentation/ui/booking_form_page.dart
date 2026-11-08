import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../../../libraries/design_system/widgets/app_text_field.dart';
import '../../../services/domain/entities/service_item.dart';
import '../../domain/entities/booking_draft.dart';
import '../../domain/repositories/booking_repository.dart';

final class BookingFormPage extends StatefulWidget {
  const BookingFormPage({
    required this.service,
    required this.bookingRepository,
    this.initialCustomerName = '',
    super.key,
  });

  final ServiceItem service;
  final BookingRepository bookingRepository;
  final String initialCustomerName;

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

final class _BookingFormPageState extends State<BookingFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedTime = '09.00';
  String _paymentMethod = 'cash';
  bool _submitting = false;

  static const _timeOptions = ['09.00', '11.00', '13.00', '15.00', '17.00'];
  static const _paymentOptions = ['cash', 'bank_transfer', 'e_wallet'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCustomerName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(LanguageKeys.bookingForm))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            _ServiceSummary(service: widget.service),
            const SizedBox(height: 28),
            _SectionTitle(
              number: '1',
              title: context.tr(LanguageKeys.customerInformation),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _nameController,
              label: context.tr(LanguageKeys.fullName),
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) => _requiredValidator(context, value),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _phoneController,
              label: context.tr(LanguageKeys.whatsappNumber),
              hint: context.tr(LanguageKeys.phoneExample),
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr(LanguageKeys.fieldRequired, {
                    'field': context.tr(LanguageKeys.whatsappNumber),
                  });
                }
                if (value.replaceAll(RegExp(r'\D'), '').length < 9) {
                  return context.tr(LanguageKeys.invalidWhatsapp);
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              minLines: 3,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              validator: (value) => _requiredValidator(context, value),
              decoration: InputDecoration(
                labelText: context.tr(LanguageKeys.serviceAddress),
                hintText: context.tr(LanguageKeys.serviceAddressHint),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.location_on_outlined),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _SectionTitle(
              number: '2',
              title: context.tr(LanguageKeys.serviceSchedule),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: context.tr(LanguageKeys.date),
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                  errorText: _selectedDate == null ? null : null,
                ),
                child: Text(
                  _selectedDate == null
                      ? context.tr(LanguageKeys.selectServiceDate)
                      : AppFormatters.date(_selectedDate!),
                  style: TextStyle(
                    color: _selectedDate == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeOptions.map((time) {
                return ChoiceChip(
                  label: Text(time),
                  selected: _selectedTime == time,
                  onSelected: (_) => setState(() => _selectedTime = time),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            _SectionTitle(
              number: '3',
              title: context.tr(LanguageKeys.paymentAndNotes),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: InputDecoration(
                labelText: context.tr(LanguageKeys.paymentMethod),
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              items: _paymentOptions
                  .map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Text(_paymentLabel(context, method)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _paymentMethod = value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: context.tr(LanguageKeys.optionalNotes),
                hintText: context.tr(LanguageKeys.optionalNotesHint),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          color: AppColors.surface,
          child: AppButton(
            label: context.tr(LanguageKeys.reviewOrder),
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr(LanguageKeys.fieldRequired, {'field': ''}).trim();
    }
    return null;
  }

  String _paymentLabel(BuildContext context, String method) {
    return context.tr(switch (method) {
      'bank_transfer' => LanguageKeys.bankTransfer,
      'e_wallet' => LanguageKeys.eWallet,
      _ => LanguageKeys.cash,
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(LanguageKeys.selectDateFirst))),
      );
      return;
    }

    final booking = BookingDraft(
      service: widget.service,
      customerName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      schedule: _selectedDate!,
      timeLabel: _selectedTime,
      paymentMethod: _paymentMethod,
      note: _noteController.text.trim(),
    );
    setState(() => _submitting = true);
    try {
      final record = await widget.bookingRepository.createBooking(booking);
      if (mounted) {
        context.pushReplacement('/booking/confirmation', extra: record);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Pesanan gagal dibuat: $error')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

final class _ServiceSummary extends StatelessWidget {
  const _ServiceSummary({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: service.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(service.icon, color: service.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  AppFormatters.rupiah(service.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
        ],
      ),
    );
  }
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
