import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_bottom_navigation.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../../../libraries/design_system/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/customer_profile.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

final class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileCubit, ProfileState>(
          listener: (context, state) {
            final message = state.message;
            if (message == null) return;
            final isError = state.status == ProfileStatus.failure;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: isError ? AppColors.error : null,
                ),
              );
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthSubmissionStatus.success) {
              context.go('/login');
            } else if (state.status == AuthSubmissionStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message ?? context.tr(LanguageKeys.logoutFailed),
                  ),
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(context.tr(LanguageKeys.profile)),
          actions: [
            BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) => IconButton(
                tooltip: context.tr(LanguageKeys.editProfile),
                onPressed: state.profile == null
                    ? null
                    : () => _openEditProfile(context, state.profile!),
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final profile = state.profile;
            if (profile == null) {
              return _ProfileErrorState(
                onRetry: () => context.read<ProfileCubit>().load(),
              );
            }
            return _ProfileContent(profile: profile);
          },
        ),
        bottomNavigationBar: AppBottomNavigation(
          selectedIndex: 3,
          onScanPressed: () =>
              _showComingSoon(context, context.tr(LanguageKeys.scanComingSoon)),
          onDestinationSelected: (index) {
            if (index == 0) {
              context.go('/home');
            } else if (index == 1) {
              context.go('/orders');
            } else if (index == 2) {
              context.go('/favorites');
            }
          },
        ),
      ),
    );
  }

  Future<void> _openEditProfile(BuildContext context, CustomerProfile profile) {
    final cubit = context.read<ProfileCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _EditProfileSheet(profile: profile),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        _ProfileHeader(profile: profile),
        const SizedBox(height: 24),
        Text(
          context.tr(LanguageKeys.accountInformation),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _ProfileInfoTile(
                icon: Icons.person_outline_rounded,
                label: context.tr(LanguageKeys.fullName),
                value: profile.fullName.isEmpty ? '-' : profile.fullName,
              ),
              const Divider(height: 1, indent: 58),
              _ProfileInfoTile(
                icon: Icons.email_outlined,
                label: context.tr(LanguageKeys.email),
                value: profile.email,
              ),
              const Divider(height: 1, indent: 58),
              _ProfileInfoTile(
                icon: Icons.phone_outlined,
                label: context.tr(LanguageKeys.phoneNumber),
                value: profile.phone?.trim().isNotEmpty == true
                    ? profile.phone!
                    : context.tr(LanguageKeys.notAdded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.tr(LanguageKeys.settings),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _ProfileMenuTile(
          icon: Icons.location_on_outlined,
          title: context.tr(LanguageKeys.savedAddresses),
          subtitle: context.tr(LanguageKeys.savedAddressesDescription),
          onTap: () =>
              _showMessage(context, context.tr(LanguageKeys.addressComingSoon)),
        ),
        const SizedBox(height: 10),
        _ProfileMenuTile(
          icon: Icons.lock_outline_rounded,
          title: context.tr(LanguageKeys.accountSecurity),
          subtitle: context.tr(LanguageKeys.accountSecurityDescription),
          onTap: () => _showMessage(
            context,
            context.tr(LanguageKeys.securityComingSoon),
          ),
        ),
        const SizedBox(height: 10),
        _ProfileMenuTile(
          icon: Icons.language_rounded,
          title: context.tr(LanguageKeys.language),
          subtitle: LanguageController.instance.value.languageCode == 'en'
              ? context.tr(LanguageKeys.english)
              : context.tr(LanguageKeys.indonesian),
          onTap: () => _openLanguageSheet(context),
        ),
        const SizedBox(height: 22),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => AppButton(
            label: context.tr(LanguageKeys.logoutAccount),
            icon: Icons.logout_rounded,
            isOutlined: true,
            isLoading: state.isLoading,
            onPressed: () =>
                context.read<AuthBloc>().add(const SignOutRequested()),
          ),
        ),
      ],
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLanguageSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _LanguageSheet(),
    );
  }
}

final class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl?.trim();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white,
            backgroundImage: avatarUrl == null || avatarUrl.isEmpty
                ? null
                : NetworkImage(avatarUrl),
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    profile.initial,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName.isEmpty
                      ? context.tr(LanguageKeys.customer)
                      : profile.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFE4E2FF)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _roleLabel(context, profile.role),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(BuildContext context, String role) {
    return switch (role) {
      'admin' => 'Administrator',
      'staff' => 'Staff',
      _ => context.tr(LanguageKeys.customer),
    };
  }
}

final class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEBFF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

final class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
            Text(context.tr(LanguageKeys.profileLoadError)),
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
}

final class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile});

  final CustomerProfile profile;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

final class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
                context.tr(LanguageKeys.editProfile),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(LanguageKeys.editProfileDescription),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              AppTextField(
                controller: _nameController,
                label: context.tr(LanguageKeys.fullName),
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr(LanguageKeys.nameRequired);
                  }
                  if (value.trim().length > 120) {
                    return context.tr(LanguageKeys.nameTooLong);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _phoneController,
                label: context.tr(LanguageKeys.phoneNumber),
                hint: context.tr(LanguageKeys.phoneExample),
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                  if (phone.isNotEmpty && phone.length < 9) {
                    return context.tr(LanguageKeys.invalidPhone);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
              BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) => AppButton(
                  label: context.tr(LanguageKeys.saveChanges),
                  isLoading: state.isSaving,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<ProfileCubit>().update(
      fullName: _nameController.text,
      phone: _phoneController.text,
    );
    if (!mounted) return;
    if (context.read<ProfileCubit>().state.status == ProfileStatus.saved) {
      Navigator.of(context).pop();
    }
  }
}

final class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final currentLanguage = LanguageController.instance.value.languageCode;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(LanguageKeys.language),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr(LanguageKeys.languageDescription),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _LanguageOption(
              title: context.tr(LanguageKeys.indonesian),
              languageCode: 'id',
              isSelected: currentLanguage == 'id',
            ),
            _LanguageOption(
              title: context.tr(LanguageKeys.english),
              languageCode: 'en',
              isSelected: currentLanguage == 'en',
            ),
          ],
        ),
      ),
    );
  }
}

final class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    required this.languageCode,
    required this.isSelected,
  });

  final String title;
  final String languageCode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEDEBFF),
        child: Text(
          languageCode.toUpperCase(),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        Navigator.of(context).pop();
        LanguageController.instance.changeLanguage(languageCode);
      },
    );
  }
}
