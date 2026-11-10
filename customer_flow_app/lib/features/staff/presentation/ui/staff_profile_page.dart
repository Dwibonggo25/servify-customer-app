import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../../../libraries/design_system/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/domain/entities/customer_profile.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
import '../widgets/staff_bottom_navigation.dart';
import '../widgets/staff_gradient_app_bar.dart';

final class StaffProfilePage extends StatelessWidget {
  const StaffProfilePage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          final message = state.message;
          if (message == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: state.status == ProfileStatus.failure
                    ? AppColors.error
                    : null,
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
              SnackBar(content: Text(state.message ?? 'Gagal keluar akun.')),
            );
          }
        },
      ),
    ],
    child: Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      appBar: const StaffGradientAppBar(
        title: 'Profil Staff',
        subtitle: 'Kelola identitas dan pengaturan akun Anda',
        icon: Icons.badge_outlined,
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state.isLoading && state.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = state.profile;
          if (profile == null) return const _ProfileErrorView();
          return RefreshIndicator(
            onRefresh: () => context.read<ProfileCubit>().load(),
            child: _ProfileContent(profile: profile),
          );
        },
      ),
      bottomNavigationBar: const StaffBottomNavigation(index: 3),
    ),
  );
}

final class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
    children: [
      _ProfileHero(profile: profile),
      const SizedBox(height: 22),
      const _SectionTitle(
        title: 'Informasi akun',
        subtitle: 'Data yang digunakan pada pekerjaan Anda',
      ),
      const SizedBox(height: 12),
      _InformationCard(profile: profile),
      const SizedBox(height: 24),
      const _SectionTitle(
        title: 'Pengaturan',
        subtitle: 'Kelola preferensi dan keamanan akun',
      ),
      const SizedBox(height: 12),
      _MenuCard(
        children: [
          _MenuTile(
            icon: Icons.edit_outlined,
            title: 'Edit profil',
            subtitle: 'Ubah nama lengkap dan nomor telepon',
            onTap: () => _openEditProfile(context, profile),
          ),
          const Divider(height: 1, indent: 68),
          _MenuTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifikasi pekerjaan',
            subtitle: 'Lihat pembaruan pesanan dan pekerjaan',
            onTap: () => context.push('/staff/notifications'),
          ),
          const Divider(height: 1, indent: 68),
          _MenuTile(
            icon: Icons.shield_outlined,
            title: 'Keamanan akun',
            subtitle: 'Password dan keamanan akses akun',
            onTap: () => _showMessage(
              context,
              'Pengaturan keamanan akan tersedia pada tahap berikutnya.',
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) => AppButton(
          label: 'Keluar dari akun',
          icon: Icons.logout_rounded,
          isOutlined: true,
          isLoading: state.isLoading,
          onPressed: () => _confirmLogout(context),
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Servify Staff • Akun terhubung dan terlindungi',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
    ],
  );

  Future<void> _openEditProfile(BuildContext context, CustomerProfile profile) {
    final cubit = context.read<ProfileCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _EditStaffProfileSheet(profile: profile),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda harus masuk kembali untuk menerima dan mengelola pekerjaan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const SignOutRequested());
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl?.trim();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 43,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarUrl == null || avatarUrl.isEmpty
                      ? null
                      : NetworkImage(avatarUrl),
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          profile.initial,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: -2,
                bottom: 4,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profile.fullName.isEmpty ? 'Staff Servify' : profile.fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: const [
              _ProfileBadge(
                icon: Icons.badge_outlined,
                label: 'Staff',
                color: AppColors.primary,
              ),
              _ProfileBadge(
                icon: Icons.verified_rounded,
                label: 'Terverifikasi',
                color: AppColors.success,
              ),
              _ProfileBadge(
                icon: Icons.circle,
                label: 'Aktif',
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

final class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.profile});

  final CustomerProfile profile;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        _InfoTile(
          icon: Icons.person_outline_rounded,
          label: 'Nama lengkap',
          value: profile.fullName.isEmpty
              ? 'Belum ditambahkan'
              : profile.fullName,
        ),
        const Divider(height: 1, indent: 66),
        _InfoTile(
          icon: Icons.email_outlined,
          label: 'Email',
          value: profile.email,
        ),
        const Divider(height: 1, indent: 66),
        _InfoTile(
          icon: Icons.phone_outlined,
          label: 'Nomor telepon',
          value: profile.phone?.trim().isNotEmpty == true
              ? profile.phone!
              : 'Belum ditambahkan',
        ),
        const Divider(height: 1, indent: 66),
        const _InfoTile(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Peran akun',
          value: 'Staff layanan',
        ),
      ],
    ),
  );
}

final class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

final class _MenuTile extends StatelessWidget {
  const _MenuTile({
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
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: AppColors.primary),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    ],
  );
}

final class _EditStaffProfileSheet extends StatefulWidget {
  const _EditStaffProfileSheet({required this.profile});

  final CustomerProfile profile;

  @override
  State<_EditStaffProfileSheet> createState() => _EditStaffProfileSheetState();
}

final class _EditStaffProfileSheetState extends State<_EditStaffProfileSheet> {
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
  Widget build(BuildContext context) => Container(
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
              'Edit profil staff',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            const Text(
              'Pastikan customer dapat mengenali identitas Anda.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            AppTextField(
              controller: _nameController,
              label: 'Nama lengkap',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) return 'Nama lengkap wajib diisi.';
                if (name.length > 120) return 'Nama terlalu panjang.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _phoneController,
              label: 'Nomor telepon',
              hint: 'Contoh: 08123456789',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: (value) {
                final phone = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                if (phone.isNotEmpty && phone.length < 9) {
                  return 'Nomor telepon tidak valid.';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) => AppButton(
                label: 'Simpan perubahan',
                icon: Icons.save_outlined,
                isLoading: state.isSaving,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<ProfileCubit>().update(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;
    if (context.read<ProfileCubit>().state.status == ProfileStatus.saved) {
      Navigator.of(context).pop();
    }
  }
}

final class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_off_outlined,
            size: 52,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
          const Text(
            'Profil staff gagal dimuat.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.read<ProfileCubit>().load(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    ),
  );
}
