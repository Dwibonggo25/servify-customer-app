import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
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
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _AdminServiceFilter _selectedFilter = _AdminServiceFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      appBar: _AdminAppBar(
        onLogout: () => context.read<AuthBloc>().add(const SignOutRequested()),
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, profileState) {
          if (profileState.isLoading) {
            return const _AdminDashboardLoading();
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
                return const _AdminDashboardLoading();
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
              final normalizedQuery = _searchQuery.trim().toLowerCase();
              final visibleServices = services.where((service) {
                final matchesQuery =
                    normalizedQuery.isEmpty ||
                    service.name.toLowerCase().contains(normalizedQuery) ||
                    service.category.toLowerCase().contains(normalizedQuery);
                final matchesFilter = switch (_selectedFilter) {
                  _AdminServiceFilter.all => true,
                  _AdminServiceFilter.active => service.isActive,
                  _AdminServiceFilter.inactive => !service.isActive,
                };
                return matchesQuery && matchesFilter;
              }).toList();

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                  children: [
                    _AdminHeader(
                      profile: profile,
                      total: services.length,
                      active: activeCount,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Daftar layanan',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          '${visibleServices.length} dari ${services.length}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau kategori layanan',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _AdminServiceFilter.values
                            .map(
                              (filter) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  selected: _selectedFilter == filter,
                                  showCheckmark: false,
                                  avatar: Icon(filter.icon, size: 17),
                                  label: Text(filter.label),
                                  onSelected: (_) =>
                                      setState(() => _selectedFilter = filter),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (services.isEmpty)
                      const _EmptyServices()
                    else if (visibleServices.isEmpty)
                      const _EmptyFilteredServices()
                    else
                      ...visibleServices.map(
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
      floatingActionButton: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state.profile?.role != 'admin') return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _openEditor(null),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah layanan'),
          );
        },
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

enum _AdminServiceFilter {
  all('Semua', Icons.grid_view_rounded),
  active('Aktif', Icons.check_circle_outline_rounded),
  inactive('Nonaktif', Icons.pause_circle_outline_rounded);

  const _AdminServiceFilter(this.label, this.icon);

  final String label;
  final IconData icon;
}

final class _AdminAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _AdminAppBar({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: preferredSize.height,
    titleSpacing: 20,
    backgroundColor: const Color(0xFFFBFBFE),
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    shape: const Border(
      bottom: BorderSide(color: AppColors.border, width: 0.8),
    ),
    title: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Admin',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Kelola katalog Servify',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
    actions: [
      BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) => Tooltip(
          message: 'Keluar',
          child: Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: state.isLoading ? null : onLogout,
              child: SizedBox.square(
                dimension: 42,
                child: state.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.logout_rounded,
                        color: AppColors.textPrimary,
                        size: 21,
                      ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
    ],
  );
}

final class _AdminDashboardLoading extends StatelessWidget {
  const _AdminDashboardLoading();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
    children: const [
      _SkeletonBlock(height: 156, radius: 24),
      SizedBox(height: 14),
      Row(
        children: [
          Expanded(child: _SkeletonBlock(height: 96, radius: 18)),
          SizedBox(width: 10),
          Expanded(child: _SkeletonBlock(height: 96, radius: 18)),
          SizedBox(width: 10),
          Expanded(child: _SkeletonBlock(height: 96, radius: 18)),
        ],
      ),
      SizedBox(height: 28),
      _SkeletonBlock(height: 56, radius: 16),
      SizedBox(height: 16),
      _SkeletonBlock(height: 140, radius: 20),
      SizedBox(height: 12),
      _SkeletonBlock(height: 140, radius: 20),
    ],
  );
}

final class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: AppColors.border.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
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
    appBar: _AdminFormAppBar(editing: _editing),
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
        if (state.isLoading) return const _AdminServiceFormLoading();
        if (state.categories.isEmpty) {
          return _AdminError(
            message: state.message ?? 'Kategori layanan belum tersedia.',
            onRetry: () => context.read<AdminServiceFormBloc>().add(
              const AdminServiceFormStarted(),
            ),
          );
        }

        final categories = state.categories;
        if (!categories.any((category) => category.id == _categoryId)) {
          _categoryId = categories.first.id;
        }
        return Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _FormSectionCard(
                icon: Icons.image_outlined,
                title: 'Foto layanan',
                subtitle: 'Gunakan foto yang jelas agar layanan lebih menarik.',
                child: _ServiceImageEditor(
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
              ),
              const SizedBox(height: 16),
              _FormSectionCard(
                icon: Icons.edit_note_rounded,
                title: 'Informasi dasar',
                subtitle: 'Tentukan kategori dan informasi utama layanan.',
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Kategori layanan',
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
                      onChanged: state.isSaving
                          ? null
                          : (value) => setState(() => _categoryId = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Nama layanan',
                        hintText: 'Contoh: Servis AC Rumah',
                        prefixIcon: Icon(Icons.home_repair_service_outlined),
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _shortDescriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 140,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi singkat',
                        hintText: 'Ringkasan yang tampil pada card layanan',
                        alignLabelWithHint: true,
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi lengkap',
                        hintText:
                            'Jelaskan proses, manfaat, dan ketentuan layanan',
                        alignLabelWithHint: true,
                      ),
                      validator: _required,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSectionCard(
                icon: Icons.payments_outlined,
                title: 'Harga dan durasi',
                subtitle: 'Masukkan harga dasar serta estimasi pengerjaan.',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Harga',
                          prefixText: 'Rp ',
                          hintText: '150000',
                        ),
                        validator: _positiveNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Durasi',
                          suffixText: 'menit',
                          hintText: '60',
                        ),
                        validator: _positiveNumber,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FormSectionCard(
                icon: Icons.checklist_rounded,
                title: 'Cakupan layanan',
                subtitle: 'Jelaskan hal yang sudah termasuk dalam harga.',
                child: TextFormField(
                  controller: _inclusionsController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Yang termasuk dalam layanan',
                    hintText:
                        'Tulis satu item per baris\nContoh: Pemeriksaan awal',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ServiceStatusCard(
                isActive: _isActive,
                enabled: !state.isSaving,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        );
      },
    ),
    bottomNavigationBar:
        BlocBuilder<AdminServiceFormBloc, AdminServiceFormState>(
          builder: (context, state) {
            if (state.isLoading || state.categories.isEmpty) {
              return const SizedBox.shrink();
            }
            return _AdminFormBottomBar(
              label: _editing ? 'Simpan perubahan' : 'Tambah layanan',
              isLoading: state.isSaving,
              onSave: () => _save(state.categories),
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

final class _AdminFormAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _AdminFormAppBar({required this.editing});

  final bool editing;

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: preferredSize.height,
    titleSpacing: 4,
    backgroundColor: const Color(0xFFFBFBFE),
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    shape: const Border(
      bottom: BorderSide(color: AppColors.border, width: 0.8),
    ),
    leadingWidth: 64,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16),
      child: IconButton.filledTonal(
        tooltip: 'Kembali',
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    title: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          editing ? 'Edit layanan' : 'Tambah layanan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          editing ? 'Perbarui informasi katalog' : 'Buat layanan baru',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

final class _AdminServiceFormLoading extends StatelessWidget {
  const _AdminServiceFormLoading();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      _SkeletonBlock(height: 250, radius: 22),
      SizedBox(height: 16),
      _SkeletonBlock(height: 420, radius: 22),
      SizedBox(height: 16),
      _SkeletonBlock(height: 150, radius: 22),
    ],
  );
}

final class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07191A2C),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(13),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

final class _ServiceStatusCard extends StatelessWidget {
  const _ServiceStatusCard({
    required this.isActive,
    required this.enabled,
    required this.onChanged,
  });

  final bool isActive;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
    decoration: BoxDecoration(
      color: isActive
          ? AppColors.success.withValues(alpha: 0.07)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.24)
            : AppColors.border,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: (isActive ? AppColors.success : AppColors.textSecondary)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            isActive
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: isActive ? AppColors.success : AppColors.textSecondary,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActive ? 'Layanan aktif' : 'Layanan nonaktif',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                isActive
                    ? 'Dapat dilihat dan dipesan oleh customer.'
                    : 'Disembunyikan dari katalog customer.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(value: isActive, onChanged: enabled ? onChanged : null),
      ],
    ),
  );
}

final class _AdminFormBottomBar extends StatelessWidget {
  const _AdminFormBottomBar({
    required this.label,
    required this.isLoading,
    required this.onSave,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      12 + MediaQuery.paddingOf(context).bottom,
    ),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
      boxShadow: [
        BoxShadow(
          color: Color(0x0D191A2C),
          blurRadius: 18,
          offset: Offset(0, -5),
        ),
      ],
    ),
    child: AppButton(
      label: label,
      icon: Icons.save_rounded,
      isLoading: isLoading,
      onPressed: onSave,
    ),
  );
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
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5046E5), Color(0xFF312E81)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -32,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'ADMINISTRATOR',
                          style: TextStyle(
                            color: Color(0xFFEDE9FE),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Halo, ${profile.fullName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pantau dan kelola katalog layanan dalam satu tempat.',
                        style: TextStyle(color: Color(0xFFE7E5FF), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _SummaryCard(
              value: '$total',
              label: 'Total',
              icon: Icons.inventory_2_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              value: '$active',
              label: 'Aktif',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              value: '${total - active}',
              label: 'Nonaktif',
              icon: Icons.pause_circle_outline_rounded,
              color: const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    ],
  );
}

final class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    child: Container(
      height: 104,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08191A2C),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08191A2C),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: ServiceImage(
                  imageUrl: service.imageUrl,
                  fallbackIcon: service.icon,
                  color: service.color,
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(active: service.isActive),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 15,
                          color: service.color,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            service.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatters.rupiah(service.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${service.durationMinutes} menit',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: 'Pilihan lainnya',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Hapus layanan',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
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
      AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                : ServiceImage(
                    imageUrl: imageUrl,
                    fallbackIcon: fallbackIcon,
                    color: fallbackColor,
                    iconSize: 56,
                    borderRadius: BorderRadius.circular(17),
                  ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'JPG, PNG, HEIC, WebP · maks. 5 MB',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null) ...[
            IconButton(
              tooltip: 'Hapus gambar',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.error,
            ),
            const SizedBox(width: 4),
          ],
          FilledButton.tonalIcon(
            onPressed: onSelect,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(
              imageBytes != null || imageUrl != null ? 'Ganti' : 'Pilih foto',
            ),
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

final class _EmptyFilteredServices extends StatelessWidget {
  const _EmptyFilteredServices();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: const Column(
      children: [
        Icon(
          Icons.search_off_rounded,
          size: 44,
          color: AppColors.textSecondary,
        ),
        SizedBox(height: 12),
        Text(
          'Layanan tidak ditemukan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 5),
        Text(
          'Coba kata kunci atau filter status yang berbeda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
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
