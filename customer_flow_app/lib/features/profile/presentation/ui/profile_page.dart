import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_bar.dart';
import '../../../../libraries/design_system/widgets/app_bottom_navigation.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../../../libraries/design_system/widgets/app_text_field.dart';
import '../../../../libraries/design_system/widgets/language_selection_sheet.dart';
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
        appBar: AppBarWidget(
          title: LanguageKeys.profile,
          subtitle: LanguageKeys.profilePageSubtitle,
          icons: Icons.person_rounded,
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
              return const _ProfileLoading();
            }
            final profile = state.profile;
            if (profile == null) {
              return _ProfileErrorState(
                onRetry: () => context.read<ProfileCubit>().load(),
              );
            }
            return _ProfileContent(
              profile: profile,
              isUploadingAvatar: state.isUploadingAvatar,
              onAvatarTap: state.isSaving
                  ? null
                  : () => _selectProfilePhoto(context),
            );
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

  Future<void> _selectProfilePhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
                child: Text(
                  context.tr(LanguageKeys.changeProfilePhoto),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.tr(LanguageKeys.chooseFromGallery)),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(context.tr(LanguageKeys.takePhoto)),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (image == null || !context.mounted) return;

      final bytes = await image.readAsBytes();
      if (!context.mounted) return;
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        _showMessage(context, context.tr(LanguageKeys.profilePhotoTooLarge));
        return;
      }

      final nameParts = image.name.split('.');
      await context.read<ProfileCubit>().uploadAvatar(
        bytes: bytes,
        fileExtension: nameParts.length > 1 ? nameParts.last : 'jpg',
      );
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(
        context,
        context.tr(LanguageKeys.profilePhotoSelectionFailed),
      );
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.isUploadingAvatar,
    required this.onAvatarTap,
  });

  final CustomerProfile profile;
  final bool isUploadingAvatar;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        _ProfileHeader(
          profile: profile,
          isUploading: isUploadingAvatar,
          onAvatarTap: onAvatarTap,
        ),
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
          onTap: () => context.push('/profile/addresses'),
        ),
        const SizedBox(height: 10),
        _ProfileMenuTile(
          icon: Icons.lock_outline_rounded,
          title: context.tr(LanguageKeys.accountSecurity),
          subtitle: context.tr(LanguageKeys.accountSecurityDescription),
          onTap: () => context.push('/profile/security'),
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

  Future<void> _openLanguageSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const LanguageSelectionSheet(),
    );
  }
}

final class _ProfileLoading extends StatefulWidget {
  const _ProfileLoading();

  @override
  State<_ProfileLoading> createState() => _ProfileLoadingState();
}

final class _ProfileLoadingState extends State<_ProfileLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = Color.lerp(
          const Color(0xFFE6E6EE),
          const Color(0xFFF5F5F9),
          _controller.value,
        )!;
        return ListView(
          key: const Key('profile_loading_shimmer'),
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            _ProfileHeaderSkeleton(color: color),
            const SizedBox(height: 24),
            _ProfileSkeletonBlock(color: color, width: 164, height: 22),
            const SizedBox(height: 12),
            _ProfileInformationSkeleton(color: color),
            const SizedBox(height: 24),
            _ProfileSkeletonBlock(color: color, width: 104, height: 22),
            const SizedBox(height: 12),
            for (var index = 0; index < 3; index++) ...[
              _ProfileMenuSkeleton(color: color),
              if (index < 2) const SizedBox(height: 10),
            ],
            const SizedBox(height: 22),
            _ProfileSkeletonBlock(
              color: color,
              width: double.infinity,
              height: 54,
              radius: 16,
            ),
          ],
        );
      },
    );
  }
}

final class _ProfileHeaderSkeleton extends StatelessWidget {
  const _ProfileHeaderSkeleton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          _ProfileSkeletonBlock(
            color: color,
            width: 76,
            height: 76,
            radius: 38,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileSkeletonBlock(color: color, width: 148, height: 20),
                const SizedBox(height: 9),
                _ProfileSkeletonBlock(color: color, width: 188, height: 13),
                const SizedBox(height: 11),
                _ProfileSkeletonBlock(
                  color: color,
                  width: 72,
                  height: 24,
                  radius: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _ProfileInformationSkeleton extends StatelessWidget {
  const _ProfileInformationSkeleton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < 3; index++) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _ProfileSkeletonBlock(
                    color: color,
                    width: 26,
                    height: 26,
                    radius: 8,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ProfileSkeletonBlock(
                          color: color,
                          width: 74,
                          height: 10,
                        ),
                        const SizedBox(height: 7),
                        _ProfileSkeletonBlock(
                          color: color,
                          width: index == 1 ? 190 : 132,
                          height: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (index < 2) const Divider(height: 1, indent: 58),
          ],
        ],
      ),
    );
  }
}

final class _ProfileMenuSkeleton extends StatelessWidget {
  const _ProfileMenuSkeleton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _ProfileSkeletonBlock(
            color: color,
            width: 42,
            height: 42,
            radius: 13,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileSkeletonBlock(color: color, width: 126, height: 14),
                const SizedBox(height: 7),
                _ProfileSkeletonBlock(color: color, width: 186, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ProfileSkeletonBlock(color: color, width: 18, height: 18, radius: 6),
        ],
      ),
    );
  }
}

final class _ProfileSkeletonBlock extends StatelessWidget {
  const _ProfileSkeletonBlock({
    required this.color,
    required this.width,
    required this.height,
    this.radius = 7,
  });

  final Color color;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

final class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.isUploading,
    required this.onAvatarTap,
  });

  final CustomerProfile profile;
  final bool isUploading;
  final VoidCallback? onAvatarTap;

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
          Tooltip(
            message: context.tr(LanguageKeys.changeProfilePhoto),
            child: InkWell(
              onTap: onAvatarTap,
              borderRadius: BorderRadius.circular(44),
              child: SizedBox.square(
                dimension: 84,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CircleAvatar(
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
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: isUploading
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
      'admin' => context.tr(LanguageKeys.administrator),
      'staff' => context.tr(LanguageKeys.staff),
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
