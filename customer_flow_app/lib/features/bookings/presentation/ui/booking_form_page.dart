import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../../../libraries/design_system/widgets/app_text_field.dart';
import '../../../../libraries/design_system/widgets/detail_app_bar.dart';
import '../../../addresses/domain/entities/customer_address.dart';
import '../../../addresses/presentation/cubit/address_cubit.dart';
import '../../../addresses/presentation/cubit/address_state.dart';
import '../../../services/domain/entities/service_item.dart';
import '../../domain/entities/booking_draft.dart';
import '../bloc/booking_form_bloc.dart';
import '../bloc/booking_form_event.dart';
import '../bloc/booking_form_state.dart';

final class BookingFormPage extends StatefulWidget {
  const BookingFormPage({
    required this.service,
    this.initialCustomerName = '',
    super.key,
  });

  final ServiceItem service;
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
  String? _selectedTime = '09.00';
  String? _selectedAddressId;
  String _paymentMethod = 'cash';

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
    final availableTimes = _availableTimesFor(_selectedDate);
    return BlocListener<AddressCubit, AddressState>(
      listenWhen: (previous, current) =>
          previous.addresses != current.addresses &&
          current.addresses.isNotEmpty,
      listener: (context, state) {
        if (_selectedAddressId != null &&
            state.addresses.any(
              (address) => address.id == _selectedAddressId,
            )) {
          return;
        }
        final address = state.addresses.firstWhere(
          (item) => item.isDefault,
          orElse: () => state.addresses.first,
        );
        _applySavedAddress(address);
      },
      child: BlocConsumer<BookingFormBloc, BookingFormState>(
        listener: (context, state) {
          if (state.status == BookingFormStatus.success &&
              state.booking != null) {
            context.pushReplacement(
              '/booking/confirmation',
              extra: state.booking,
            );
          } else if (state.status == BookingFormStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message ?? context.tr(LanguageKeys.bookingCreateFailed),
                ),
              ),
            );
          }
        },
        builder: (context, state) => Scaffold(
          backgroundColor: const Color(0xFFF8F8FC),
          appBar: DetailAppBar(
            title: context.tr(LanguageKeys.bookingForm),
            subtitle: context.tr(LanguageKeys.bookingFormSubtitle),
          ),
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
                _BookingAddressField(
                  selectedAddressId: _selectedAddressId,
                  manualController: _addressController,
                  onAddressSelected: _applySavedAddress,
                  onManageAddresses: _openAddressManagement,
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
                if (_selectedDate != null && availableTimes.isEmpty)
                  const Text(
                    'Tidak ada jadwal yang tersedia hari ini. Pilih tanggal lain.',
                    style: TextStyle(color: AppColors.error),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTimes.map((time) {
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
                isLoading: state.isSubmitting,
                onPressed: _submit,
              ),
            ),
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
    if (date != null && mounted) {
      final availableTimes = _availableTimesFor(date);
      setState(() {
        _selectedDate = date;
        if (!availableTimes.contains(_selectedTime)) {
          _selectedTime = availableTimes.isEmpty ? null : availableTimes.first;
        }
      });
    }
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(LanguageKeys.selectDateFirst))),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal lain yang masih memiliki jadwal.'),
        ),
      );
      return;
    }

    final addresses = context.read<AddressCubit>().state.addresses;
    CustomerAddress? selectedAddress;
    for (final address in addresses) {
      if (address.id == _selectedAddressId) selectedAddress = address;
    }
    selectedAddress ??= addresses.isEmpty
        ? null
        : addresses.firstWhere(
            (address) => address.isDefault,
            orElse: () => addresses.first,
          );

    final booking = BookingDraft(
      service: widget.service,
      customerName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: selectedAddress?.addressLine ?? _addressController.text.trim(),
      addressId: selectedAddress?.id,
      schedule: _selectedDate!,
      timeLabel: _selectedTime!,
      paymentMethod: _paymentMethod,
      note: _noteController.text.trim(),
    );
    context.read<BookingFormBloc>().add(BookingSubmitted(booking));
  }

  void _applySavedAddress(CustomerAddress address) {
    if (!mounted) return;
    setState(() {
      _selectedAddressId = address.id;
      _addressController.text = address.addressLine;
      if (_phoneController.text.trim().isEmpty) {
        _phoneController.text = address.phone;
      }
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = address.recipientName;
      }
    });
  }

  Future<void> _openAddressManagement() async {
    await context.push('/profile/addresses');
    if (mounted) await context.read<AddressCubit>().load();
  }

  List<String> _availableTimesFor(DateTime? date) {
    if (date == null) return _timeOptions;
    final now = DateTime.now();
    return _timeOptions
        .where((time) {
          final parts = time.split('.');
          final scheduledAt = DateTime(
            date.year,
            date.month,
            date.day,
            int.parse(parts.first),
            int.parse(parts.last),
          );
          return scheduledAt.isAfter(now);
        })
        .toList(growable: false);
  }
}

final class _BookingAddressField extends StatelessWidget {
  const _BookingAddressField({
    required this.selectedAddressId,
    required this.manualController,
    required this.onAddressSelected,
    required this.onManageAddresses,
  });

  final String? selectedAddressId;
  final TextEditingController manualController;
  final ValueChanged<CustomerAddress> onAddressSelected;
  final VoidCallback onManageAddresses;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddressCubit, AddressState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Container(
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEDF4),
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }

        if (state.addresses.isNotEmpty) {
          final selected =
              state.addresses.any((address) => address.id == selectedAddressId)
              ? selectedAddressId
              : state.addresses
                    .firstWhere(
                      (address) => address.isDefault,
                      orElse: () => state.addresses.first,
                    )
                    .id;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(selected),
                initialValue: selected,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr(LanguageKeys.serviceAddress),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                items: state.addresses
                    .map(
                      (address) => DropdownMenuItem(
                        value: address.id,
                        child: Text(
                          '${address.label} — ${address.addressLine}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (id) {
                  if (id == null) return;
                  onAddressSelected(
                    state.addresses.firstWhere((address) => address.id == id),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onManageAddresses,
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(context.tr(LanguageKeys.manageAddresses)),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: manualController,
              minLines: 3,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr(LanguageKeys.fieldRequired, {
                    'field': '',
                  }).trim();
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: context.tr(LanguageKeys.serviceAddress),
                hintText: context.tr(LanguageKeys.serviceAddressHint),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.location_on_outlined),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onManageAddresses,
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(context.tr(LanguageKeys.addSavedAddress)),
              ),
            ),
          ],
        );
      },
    );
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
