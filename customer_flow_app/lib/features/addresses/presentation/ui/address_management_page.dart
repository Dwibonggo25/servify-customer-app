import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../../../libraries/design_system/widgets/app_text_field.dart';
import '../../../../libraries/design_system/widgets/detail_app_bar.dart';
import '../../domain/entities/address_draft.dart';
import '../../domain/entities/customer_address.dart';
import '../cubit/address_cubit.dart';
import '../cubit/address_state.dart';

final class AddressManagementPage extends StatelessWidget {
  const AddressManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddressCubit, AddressState>(
      listenWhen: (previous, current) =>
          current.message != null && previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: state.status == AddressStatus.failure
                  ? AppColors.error
                  : null,
            ),
          );
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F8FC),
          appBar: DetailAppBar(
            title: context.tr(LanguageKeys.addressManagement),
            subtitle: context.tr(LanguageKeys.addressManagementSubtitle),
          ),
          body: Stack(
            children: [
              _AddressBody(state: state),
              if (state.isSaving)
                const Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: AppButton(
                label: context.tr(LanguageKeys.addAddress),
                icon: Icons.add_location_alt_outlined,
                isLoading: state.isSaving,
                onPressed: () => _openAddressEditor(context),
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _AddressBody extends StatelessWidget {
  const _AddressBody({required this.state});

  final AddressState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const _AddressLoading();
    if (state.status == AddressStatus.failure && state.addresses.isEmpty) {
      return _AddressError(onRetry: () => context.read<AddressCubit>().load());
    }
    if (state.addresses.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<AddressCubit>().load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 72, 28, 32),
          children: const [_EmptyAddressState()],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<AddressCubit>().load(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        itemCount: state.addresses.length + 1,
        separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 18 : 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _AddressSummary(count: state.addresses.length);
          }
          final address = state.addresses[index - 1];
          return _AddressCard(
            address: address,
            enabled: !state.isSaving,
            onEdit: () => _openAddressEditor(context, address: address),
            onSetDefault: () =>
                context.read<AddressCubit>().setDefault(address.id),
            onDelete: () => _confirmDelete(context, address),
          );
        },
      ),
    );
  }
}

final class _AddressSummary extends StatelessWidget {
  const _AddressSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.tr(LanguageKeys.savedAddresses),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEDEBFF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            context.tr(LanguageKeys.savedAddressCount, {
              'count': count.toString(),
            }),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

final class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.enabled,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  final CustomerAddress address;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: address.isDefault
              ? AppColors.primary.withValues(alpha: 0.38)
              : AppColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09191A2C),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: address.isDefault
                      ? const Color(0xFFEDEBFF)
                      : const Color(0xFFF4F4F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _addressIcon(address.label),
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        address.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      const _DefaultAddressBadge(),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _AddressActionMenu(
                enabled: enabled,
                onSelected: (action) {
                  if (action == _AddressAction.edit) onEdit();
                  if (action == _AddressAction.delete) onDelete();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _AddressDetailRow(
                  icon: Icons.person_outline_rounded,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: address.recipientName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '  •  ${address.phone}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AddressDetailRow(
                  icon: Icons.location_on_outlined,
                  child: Text(
                    address.addressLine,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                if (address.notes?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _AddressDetailRow(
                    icon: Icons.info_outline_rounded,
                    child: Text(
                      address.notes!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!address.isDefault) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                ),
                onPressed: enabled ? onSetDefault : null,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(context.tr(LanguageKeys.setAsDefaultAddress)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _addressIcon(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('office') || normalized.contains('kantor')) {
      return Icons.business_outlined;
    }
    return Icons.home_outlined;
  }
}

final class _DefaultAddressBadge extends StatelessWidget {
  const _DefaultAddressBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFEDEBFF),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      context.tr(LanguageKeys.defaultAddress),
      style: const TextStyle(
        color: AppColors.primaryDark,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

final class _AddressDetailRow extends StatelessWidget {
  const _AddressDetailRow({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: AppColors.textSecondary),
      const SizedBox(width: 9),
      Expanded(child: child),
    ],
  );
}

final class _AddressActionMenu extends StatelessWidget {
  const _AddressActionMenu({required this.enabled, required this.onSelected});

  final bool enabled;
  final ValueChanged<_AddressAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AddressAction>(
      enabled: enabled,
      tooltip: context.tr(LanguageKeys.moreOptions),
      offset: const Offset(0, 40),
      constraints: const BoxConstraints(minWidth: 176, maxWidth: 196),
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AddressAction.edit,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr(LanguageKeys.editAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: _AddressAction.delete,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr(LanguageKeys.deleteAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F9),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}

enum _AddressAction { edit, delete }

final class _EmptyAddressState extends StatelessWidget {
  const _EmptyAddressState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: Color(0xFFEDEBFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_location_alt_outlined,
            color: AppColors.primary,
            size: 34,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr(LanguageKeys.addressEmptyTitle),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(LanguageKeys.addressEmptyDescription),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
      ],
    );
  }
}

final class _AddressError extends StatelessWidget {
  const _AddressError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.textSecondary,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              context.tr(LanguageKeys.addressLoadFailed),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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
}

final class _AddressLoading extends StatelessWidget {
  const _AddressLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => Container(
        height: index == 0 ? 82 : 190,
        decoration: BoxDecoration(
          color: index == 0 ? const Color(0xFFEDEBFF) : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: index == 0 ? null : Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
    );
  }
}

Future<void> _openAddressEditor(
  BuildContext context, {
  CustomerAddress? address,
}) {
  final cubit = context.read<AddressCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _AddressEditorSheet(address: address),
    ),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  CustomerAddress address,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      title: Text(context.tr(LanguageKeys.deleteAddressTitle)),
      content: Text(
        context.tr(LanguageKeys.deleteAddressConfirmation, {
          'label': address.label,
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.tr(LanguageKeys.cancel)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(context.tr(LanguageKeys.deleteAddress)),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await context.read<AddressCubit>().delete(address.id);
  }
}

final class _AddressEditorSheet extends StatefulWidget {
  const _AddressEditorSheet({this.address});

  final CustomerAddress? address;

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

final class _AddressEditorSheetState extends State<_AddressEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _recipientController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late bool _isDefault;

  bool get _editing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _labelController = TextEditingController(text: address?.label ?? '');
    _recipientController = TextEditingController(
      text: address?.recipientName ?? '',
    );
    _phoneController = TextEditingController(text: address?.phone ?? '');
    _addressController = TextEditingController(
      text: address?.addressLine ?? '',
    );
    _notesController = TextEditingController(text: address?.notes ?? '');
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _recipientController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            _editing
                                ? LanguageKeys.editAddress
                                : LanguageKeys.addAddress,
                          ),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.tr(LanguageKeys.addressFormDescription),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr(LanguageKeys.cancel),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _labelController,
                        label: context.tr(LanguageKeys.addressLabel),
                        hint: context.tr(LanguageKeys.addressLabelHint),
                        prefixIcon: Icons.label_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (value) => _required(context, value),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _recipientController,
                        label: context.tr(LanguageKeys.recipientName),
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (value) => _required(context, value),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _phoneController,
                        label: context.tr(LanguageKeys.phoneNumber),
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (_required(context, value) case final error?) {
                            return error;
                          }
                          return value!.replaceAll(RegExp(r'\D'), '').length < 9
                              ? context.tr(LanguageKeys.invalidPhone)
                              : null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addressController,
                        minLines: 3,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        validator: (value) => _required(context, value),
                        decoration: InputDecoration(
                          labelText: context.tr(LanguageKeys.fullAddress),
                          hintText: context.tr(LanguageKeys.serviceAddressHint),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: context.tr(LanguageKeys.addressNotes),
                          hintText: context.tr(LanguageKeys.addressNotesHint),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: _isDefault,
                        contentPadding: EdgeInsets.zero,
                        secondary: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          context.tr(LanguageKeys.makeDefaultAddress),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          context.tr(
                            LanguageKeys.makeDefaultAddressDescription,
                          ),
                        ),
                        onChanged: widget.address?.isDefault == true
                            ? null
                            : (value) => setState(() => _isDefault = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            BlocBuilder<AddressCubit, AddressState>(
              builder: (context, state) => Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: AppButton(
                  label: context.tr(LanguageKeys.saveAddress),
                  isLoading: state.isSaving,
                  onPressed: _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr(LanguageKeys.fieldRequired, {'field': ''}).trim();
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await context.read<AddressCubit>().save(
      id: widget.address?.id,
      draft: AddressDraft(
        label: _labelController.text,
        recipientName: _recipientController.text,
        phone: _phoneController.text,
        addressLine: _addressController.text,
        notes: _notesController.text,
        isDefault: _isDefault,
        latitude: widget.address?.latitude,
        longitude: widget.address?.longitude,
      ),
    );
    if (success && mounted) Navigator.pop(context);
  }
}
