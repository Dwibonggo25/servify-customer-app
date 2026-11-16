import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../../../libraries/design_system/widgets/app_text_field.dart';
import '../../../../libraries/design_system/widgets/detail_app_bar.dart';
import '../../domain/entities/account_security_info.dart';
import '../cubit/account_security_cubit.dart';
import '../cubit/account_security_state.dart';

final class AccountSecurityPage extends StatelessWidget {
  const AccountSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountSecurityCubit, AccountSecurityState>(
      listenWhen: (previous, current) =>
          previous.status != current.status && current.message != null,
      listener: (context, state) {
        final isFailure = state.status == AccountSecurityStatus.failure;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: isFailure ? AppColors.error : null,
            ),
          );

        if (state.action == AccountSecurityAction.changePassword) {
          context.read<AccountSecurityCubit>().clearFeedback();
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: DetailAppBar(
          title: context.tr(LanguageKeys.accountSecurity),
          subtitle: context.tr(LanguageKeys.accountSecurityPageSubtitle),
        ),
        body: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AccountSecurityState state) {
    if (state.isLoading || state.status == AccountSecurityStatus.initial) {
      return const _SecurityLoading();
    }

    final info = state.info;
    if (info == null) {
      return _SecurityError(onRetry: context.read<AccountSecurityCubit>().load);
    }

    return _SecurityContent(info: info, state: state);
  }
}

final class _SecurityContent extends StatelessWidget {
  const _SecurityContent({required this.info, required this.state});

  final AccountSecurityInfo info;
  final AccountSecurityState state;

  @override
  Widget build(BuildContext context) {
    final isSubmitting = state.isSubmitting;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        _SecurityHero(info: info),
        const SizedBox(height: 24),
        _SectionLabel(text: context.tr(LanguageKeys.signInAndVerification)),
        const SizedBox(height: 12),
        _SecurityCard(
          children: [
            _SecurityRow(
              icon: Icons.alternate_email_rounded,
              title: context.tr(LanguageKeys.accountEmail),
              subtitle: info.email,
            ),
            const Divider(height: 1, indent: 68),
            _SecurityRow(
              icon: info.isEmailVerified
                  ? Icons.verified_user_outlined
                  : Icons.mark_email_unread_outlined,
              title: context.tr(LanguageKeys.emailVerification),
              subtitle: info.isEmailVerified
                  ? context.tr(LanguageKeys.emailVerified)
                  : context.tr(LanguageKeys.emailNotVerified),
              valueColor: info.isEmailVerified
                  ? AppColors.success
                  : const Color(0xFFD97706),
            ),
            const Divider(height: 1, indent: 68),
            _SecurityRow(
              icon: Icons.key_rounded,
              title: context.tr(LanguageKeys.signInMethod),
              subtitle: _providerLabel(context, info.providers),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionLabel(text: context.tr(LanguageKeys.passwordAndSessions)),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.password_rounded,
          title: context.tr(LanguageKeys.changePassword),
          description: context.tr(LanguageKeys.changePasswordDescription),
          buttonLabel: context.tr(LanguageKeys.changePassword),
          isLoading:
              isSubmitting &&
              state.action == AccountSecurityAction.changePassword,
          onPressed: isSubmitting ? null : () => _changePassword(context),
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.devices_rounded,
          title: context.tr(LanguageKeys.accountSessions),
          description: context.tr(LanguageKeys.accountSessionsDescription),
          buttonLabel: context.tr(LanguageKeys.signOutAllDevices),
          isOutlined: true,
          isLoading:
              isSubmitting &&
              state.action == AccountSecurityAction.signOutAllDevices,
          onPressed: isSubmitting ? null : () => _signOutAll(context),
        ),
        const SizedBox(height: 28),
        _SectionLabel(
          text: context.tr(LanguageKeys.dangerZone),
          color: AppColors.error,
        ),
        const SizedBox(height: 12),
        _DangerCard(
          isLoading:
              isSubmitting &&
              state.action == AccountSecurityAction.deleteAccount,
          onPressed: isSubmitting ? null : () => _deleteAccount(context),
        ),
      ],
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final request = await showModalBottomSheet<_PasswordChangeRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ChangePasswordSheet(requiresCurrentPassword: info.usesPassword),
    );
    if (request == null || !context.mounted) return;

    await context.read<AccountSecurityCubit>().changePassword(
      newPassword: request.newPassword,
      currentPassword: request.currentPassword,
    );
  }

  Future<void> _signOutAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.devices_rounded, color: AppColors.primary),
        title: Text(context.tr(LanguageKeys.signOutAllDevicesQuestion)),
        content: Text(context.tr(LanguageKeys.signOutAllDevicesWarning)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr(LanguageKeys.cancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr(LanguageKeys.signOut)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AccountSecurityCubit>().signOutAllDevices();
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _DeleteAccountDialog(requiresCurrentPassword: info.usesPassword),
    );
    if (password == null || !context.mounted) return;
    await context.read<AccountSecurityCubit>().deleteAccount(
      currentPassword: password,
    );
  }

  String _providerLabel(BuildContext context, List<String> providers) {
    return providers
        .map((provider) {
          return switch (provider) {
            'google' => 'Google',
            'email' => context.tr(LanguageKeys.emailAndPassword),
            _ => provider,
          };
        })
        .join(' • ');
  }
}

final class _SecurityHero extends StatelessWidget {
  const _SecurityHero({required this.info});

  final AccountSecurityInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3730A3), Color(0xFF5B52EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(LanguageKeys.accountProtected),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.tr(LanguageKeys.accountProtectedDescription),
                  style: const TextStyle(
                    color: Color(0xFFE0E7FF),
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
}

final class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      color: color,
      fontWeight: FontWeight.w800,
    ),
  );
}

final class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: children),
  );
}

final class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEBFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
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

final class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    required this.isLoading,
    this.isOutlined = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEBFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(
            label: buttonLabel,
            onPressed: onPressed,
            isLoading: isLoading,
            isOutlined: isOutlined,
          ),
        ],
      ),
    );
  }
}

final class _DangerCard extends StatelessWidget {
  const _DangerCard({required this.onPressed, required this.isLoading});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7F7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(LanguageKeys.deleteAccount),
          style: const TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(LanguageKeys.deleteAccountDescription),
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: Text(context.tr(LanguageKeys.deleteAccount)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

final class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.requiresCurrentPassword});

  final bool requiresCurrentPassword;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

final class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr(LanguageKeys.changePassword),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(LanguageKeys.changePasswordFormDescription),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              if (widget.requiresCurrentPassword) ...[
                AppTextField(
                  controller: _currentController,
                  label: context.tr(LanguageKeys.currentPassword),
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscure,
                  validator: _requiredPassword,
                ),
                const SizedBox(height: 14),
              ],
              AppTextField(
                controller: _newController,
                label: context.tr(LanguageKeys.newPassword),
                prefixIcon: Icons.password_rounded,
                obscureText: _obscure,
                validator: (value) {
                  if ((value ?? '').length < 8) {
                    return context.tr(LanguageKeys.minimumPassword);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirmationController,
                label: context.tr(LanguageKeys.confirmNewPassword),
                prefixIcon: Icons.password_rounded,
                obscureText: _obscure,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                validator: (value) {
                  if (value != _newController.text) {
                    return context.tr(LanguageKeys.passwordsDoNotMatch);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              AppButton(
                label: context.tr(LanguageKeys.saveNewPassword),
                icon: Icons.check_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return context.tr(LanguageKeys.currentPasswordRequired);
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _PasswordChangeRequest(
        currentPassword: widget.requiresCurrentPassword
            ? _currentController.text
            : null,
        newPassword: _newController.text,
      ),
    );
  }
}

final class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.requiresCurrentPassword});

  final bool requiresCurrentPassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

final class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final confirmationWord = context.tr(
      LanguageKeys.deleteAccountConfirmationWord,
    );
    return AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: AppColors.error,
        size: 36,
      ),
      title: Text(context.tr(LanguageKeys.deleteAccountQuestion)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr(LanguageKeys.deleteAccountWarning)),
              if (widget.requiresCurrentPassword) ...[
                const SizedBox(height: 18),
                AppTextField(
                  controller: _passwordController,
                  label: context.tr(LanguageKeys.currentPassword),
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (value) => (value ?? '').isEmpty
                      ? context.tr(LanguageKeys.currentPasswordRequired)
                      : null,
                ),
              ],
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirmationController,
                label: context.tr(LanguageKeys.typeToConfirm, {
                  'word': confirmationWord,
                }),
                validator: (value) => value?.trim() == confirmationWord
                    ? null
                    : context.tr(LanguageKeys.deleteConfirmationInvalid),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr(LanguageKeys.cancel)),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(context.tr(LanguageKeys.deletePermanently)),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      widget.requiresCurrentPassword ? _passwordController.text : '',
    );
  }
}

final class _PasswordChangeRequest {
  const _PasswordChangeRequest({
    required this.newPassword,
    this.currentPassword,
  });

  final String newPassword;
  final String? currentPassword;
}

final class _SecurityLoading extends StatelessWidget {
  const _SecurityLoading();

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('account_security_loading'),
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
    children: const [
      _LoadingBlock(height: 122, radius: 26),
      SizedBox(height: 24),
      _LoadingBlock(height: 20, width: 180),
      SizedBox(height: 12),
      _LoadingBlock(height: 216, radius: 20),
      SizedBox(height: 24),
      _LoadingBlock(height: 20, width: 154),
      SizedBox(height: 12),
      _LoadingBlock(height: 170, radius: 20),
    ],
  );
}

final class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.height, this.width, this.radius = 8});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE9E9F1),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

final class _SecurityError extends StatelessWidget {
  const _SecurityError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 54,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
          Text(context.tr(LanguageKeys.accountSecurityLoadFailed)),
          const SizedBox(height: 18),
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
