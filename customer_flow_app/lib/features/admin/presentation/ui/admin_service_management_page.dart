import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/app_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../profile/domain/entities/customer_profile.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
import '../../../services/domain/entities/service_category.dart';
import '../../../services/domain/entities/service_draft.dart';
import '../../../services/domain/entities/service_item.dart';
import '../../../services/presentation/widgets/service_image.dart';
import '../bloc/admin_service_bloc.dart';
import '../bloc/admin_service_event.dart';
import '../bloc/admin_service_form_bloc.dart';
import '../bloc/admin_service_form_event.dart';
import '../bloc/admin_service_form_state.dart';
import '../bloc/admin_service_state.dart';

final class AdminServiceManagementPage extends StatefulWidget {
  const AdminServiceManagementPage({super.key});

  @override
  State<AdminServiceManagementPage> createState() =>
      _AdminServiceManagementPageState();
}

final class _AdminServiceManagementPageState
    extends State<AdminServiceManagementPage> {
  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthSubmissionStatus.success) {
            context.go('/login');
          } else if (state.status == AuthSubmissionStatus.failure) {
            _showMessage(context, state.message ?? 'Gagal keluar dari akun.');
          }
        },
      ),
      BlocListener<AdminServiceBloc, AdminServiceState>(
        listener: (context, state) {
          if (state.status == AdminServiceStatus.deleteSuccess ||
              (state.status == AdminServiceStatus.failure &&
                  state.services.isNotEmpty)) {
            _showMessage(context, state.message ?? 'Terjadi kesalahan.');
          }
        },
      ),
    ],
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Kelola layanan'),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) => IconButton(
              onPressed: state.isLoading
                  ? null
                  : () =>
                        context.read<AuthBloc>().add(const SignOutRequested()),
              tooltip: 'Keluar',
              icon: state.isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          if (profileState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (profileState.status == ProfileStatus.failure ||
              profileState.profile == null) {
            return _AdminError(
              message: profileState.message,
              onRetry: () => context.read<ProfileCubit>().load(),
            );
          }
          final profile = profileState.profile!;
          if (profile.role != 'admin') return const _AdminAccessDenied();

          return BlocBuilder<AdminServiceBloc, AdminServiceState>(
            builder: (context, serviceState) {
              if (serviceState.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (serviceState.status == AdminServiceStatus.failure &&
                  serviceState.services.isEmpty) {
                return _AdminError(
                  message: serviceState.message,
                  onRetry: () => context.read<AdminServiceBloc>().add(
                    const AdminServicesRequested(),
                  ),
                );
              }

              final services = serviceState.services;
              final activeCount = services
                  .where((item) => item.isActive)
                  .length;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  children: [
                    _AdminHeader(
                      profile: profile,
                      total: services.length,
                      active: activeCount,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Daftar layanan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (services.isEmpty)
                      const _EmptyServices()
                    else
                      ...services.map(
                        (service) => _AdminServiceCard(
                          service: service,
                          onEdit: () => _openEditor(service),
                          onDelete: () => _delete(service),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah layanan'),
      ),
    ),
  );

  Future<void> _refresh() async {
    final completer = Completer<void>();
    context.read<AdminServiceBloc>().add(
      AdminServicesRequested(completer: completer),
    );
    try {
      await completer.future;
    } catch (_) {
      // Error state and message are handled by the BLoC listener/builder.
    }
  }

  Future<void> _openEditor(ServiceItem? service) async {
    final changed = await context.push<bool>(
      service == null
          ? '/admin/services/new'
          : '/admin/services/${service.id}/edit',
      extra: service,
    );
    if (changed == true && mounted) {
      context.read<AdminServiceBloc>().add(const AdminServicesRequested());
    }
  }

  Future<void> _delete(ServiceItem service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus layanan?'),
        content: Text(
          'Layanan “${service.name}” akan dihapus. Jika sudah memiliki '
          'riwayat pesanan, layanan akan dinonaktifkan agar data tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (mounted) {
      context.read<AdminServiceBloc>().add(
        AdminServiceDeleteRequested(service.id),
      );
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final class AdminServiceFormPage extends StatefulWidget {
  const AdminServiceFormPage({this.service, super.key});

  final ServiceItem? service;

  @override
  State<AdminServiceFormPage> createState() => _AdminServiceFormPageState();
}

final class _AdminServiceFormPageState extends State<AdminServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late final TextEditingController _inclusionsController;
  String? _categoryId;
  bool _isActive = true;
  Uint8List? _selectedImageBytes;
  String? _selectedImageExtension;
  String? _imageUrl;

  bool get _editing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _nameController = TextEditingController(text: service?.name);
    _shortDescriptionController = TextEditingController(
      text: service?.shortDescription,
    );
    _descriptionController = TextEditingController(text: service?.description);
    _priceController = TextEditingController(text: service?.price.toString());
    _durationController = TextEditingController(
      text: service?.durationMinutes.toString(),
    );
    _inclusionsController = TextEditingController(
      text: service?.includes.join('\n'),
    );
    _categoryId = service?.categoryId;
    _isActive = service?.isActive ?? true;
    _imageUrl = service?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _inclusionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_editing ? 'Edit layanan' : 'Tambah layanan')),
    body: BlocConsumer<AdminServiceFormBloc, AdminServiceFormState>(
      listener: (context, state) {
        if (state.status == AdminServiceFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message ?? 'Tersimpan.')),
          );
          context.pop(true);
        } else if (state.status == AdminServiceFormStatus.failure &&
            state.categories.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Gagal menyimpan layanan.'),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.categories.isEmpty) {
          return _AdminError(
            message: state.message ?? 'Kategori layanan belum tersedia.',
            onRetry: () => context.read<AdminServiceFormBloc>().add(
              const AdminServiceFormStarted(),
            ),
          );
        }

        final categories = state.categories;
        _categoryId ??= categories.first.id;
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _ServiceImageEditor(
                imageBytes: _selectedImageBytes,
                imageUrl: _imageUrl,
                fallbackIcon:
                    widget.service?.icon ?? Icons.home_repair_service_rounded,
                fallbackColor: widget.service?.color ?? AppColors.primary,
                onSelect: _pickImage,
                onRemove: _selectedImageBytes != null || _imageUrl != null
                    ? () => setState(() {
                        _selectedImageBytes = null;
                        _selectedImageExtension = null;
                        _imageUrl = null;
                      })
                    : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama layanan',
                  prefixIcon: Icon(Icons.home_repair_service_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shortDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi singkat',
                  prefixIcon: Icon(Icons.short_text_rounded),
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi lengkap',
                  alignLabelWithHint: true,
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga',
                        prefixText: 'Rp ',
                      ),
                      validator: _positiveNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Durasi',
                        suffixText: 'menit',
                      ),
                      validator: _positiveNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _inclusionsController,
                minLines: 3,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Yang termasuk dalam layanan',
                  hintText: 'Tulis satu item per baris',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Layanan aktif'),
                subtitle: const Text(
                  'Layanan aktif dapat dilihat dan dipesan customer.',
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: _editing ? 'Simpan perubahan' : 'Tambah layanan',
                icon: Icons.save_rounded,
                isLoading: state.isSaving,
                onPressed: () => _save(categories),
              ),
            ],
          ),
        );
      },
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bagian ini wajib diisi.' : null;

  String? _positiveNumber(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed <= 0 ? 'Masukkan angka yang valid.' : null;
  }

  void _save(List<ServiceCategory> categories) {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    final category = categories.firstWhere((item) => item.id == _categoryId);
    final inclusions = _inclusionsController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final name = _nameController.text.trim();
    context.read<AdminServiceFormBloc>().add(
      AdminServiceSubmitted(
        serviceId: widget.service?.id,
        draft: ServiceDraft(
          categoryId: category.id,
          name: name,
          slug: _slugify(name),
          shortDescription: _shortDescriptionController.text.trim(),
          description: _descriptionController.text.trim(),
          price: int.parse(_priceController.text.trim()),
          durationMinutes: int.parse(_durationController.text.trim()),
          iconKey: category.iconKey,
          imageUrl: _imageUrl,
          colorValue: category.colorValue,
          includes: inclusions,
          isActive: _isActive,
        ),
        imageBytes: _selectedImageBytes,
        imageExtension: _selectedImageExtension,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 84,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran gambar maksimal 5 MB.')),
        );
        return;
      }

      final nameParts = image.name.split('.');
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageExtension = nameParts.length > 1
            ? nameParts.last.toLowerCase()
            : 'jpg';
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $error')));
    }
  }

  String _slugify(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

final class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.profile,
    required this.total,
    required this.active,
  });

  final CustomerProfile profile;
  final int total;
  final int active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, ${profile.fullName}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Kelola katalog layanan Servify.',
          style: TextStyle(color: Color(0xFFE7E5FF)),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SummaryChip(label: '$total layanan'),
            _SummaryChip(label: '$active aktif'),
            _SummaryChip(label: '${total - active} nonaktif'),
          ],
        ),
      ],
    ),
  );
}

final class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    ),
  );
}

final class _AdminServiceCard extends StatelessWidget {
  const _AdminServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  final ServiceItem service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: ServiceImage(
              imageUrl: service.imageUrl,
              fallbackIcon: service.icon,
              color: service.color,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusBadge(active: service.isActive),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  service.category,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp${service.price} • ${service.durationMinutes} menit',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Hapus'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

final class _ServiceImageEditor extends StatelessWidget {
  const _ServiceImageEditor({
    required this.imageBytes,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.onSelect,
    required this.onRemove,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final VoidCallback onSelect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Gambar layanan',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      const Text(
        'Gunakan JPG, PNG, HEIC, atau WebP dengan ukuran maksimal 5 MB.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      const SizedBox(height: 12),
      AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                : ServiceImage(
                    imageUrl: imageUrl,
                    fallbackIcon: fallbackIcon,
                    color: fallbackColor,
                    iconSize: 56,
                    borderRadius: BorderRadius.circular(21),
                  ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: onSelect,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(
              imageBytes != null || imageUrl != null
                  ? 'Ganti gambar'
                  : 'Pilih gambar',
            ),
          ),
          if (onRemove != null)
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Hapus gambar'),
            ),
        ],
      ),
    ],
  );
}

final class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: active
          ? AppColors.success.withValues(alpha: 0.12)
          : AppColors.textSecondary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      active ? 'Aktif' : 'Nonaktif',
      style: TextStyle(
        color: active ? AppColors.success : AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

final class _EmptyServices extends StatelessWidget {
  const _EmptyServices();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        Icon(Icons.home_repair_service_outlined, size: 52),
        SizedBox(height: 12),
        Text('Belum ada layanan. Tambahkan layanan pertama.'),
      ],
    ),
  );
}

final class _AdminError extends StatelessWidget {
  const _AdminError({required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'Data admin gagal dimuat.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    ),
  );
}

final class _AdminAccessDenied extends StatelessWidget {
  const _AdminAccessDenied();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.admin_panel_settings_outlined, size: 56),
          SizedBox(height: 12),
          Text(
            'Halaman ini hanya dapat diakses oleh admin.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
