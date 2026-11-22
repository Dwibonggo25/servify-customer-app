import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../libraries/core/formatters/app_formatters.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/design_system/theme/app_colors.dart';
import '../../../../libraries/design_system/widgets/detail_app_bar.dart';
import '../../domain/entities/work_proof.dart';
import '../cubit/work_proof_cubit.dart';
import '../cubit/work_proof_state.dart';

final class WorkProofPage extends StatelessWidget {
  const WorkProofPage({
    required this.bookingNumber,
    required this.serviceName,
    required this.bookingStatus,
    super.key,
  });

  final String bookingNumber;
  final String serviceName;
  final String bookingStatus;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<WorkProofCubit, WorkProofState>(
        listener: (context, state) {
          final message = state.message;
          if (message == null) return;
          final text = switch (message) {
            'uploaded' => context.tr(LanguageKeys.workProofUploaded),
            'deleted' => context.tr(LanguageKeys.workProofDeleted),
            _ => context.tr(LanguageKeys.workProofActionFailed),
          };
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(text),
                backgroundColor: state.status == WorkProofStatus.failure
                    ? AppColors.error
                    : null,
              ),
            );
          context.read<WorkProofCubit>().clearMessage();
        },
        builder: (context, state) => Scaffold(
          backgroundColor: const Color(0xFFF8F8FC),
          appBar: DetailAppBar(
            title: context.tr(LanguageKeys.workProof),
            subtitle: context.tr(LanguageKeys.workProofSubtitle),
          ),
          body: _body(context, state),
        ),
      );

  Widget _body(BuildContext context, WorkProofState state) {
    if (state.isInitialLoading) return const _WorkProofLoading();
    if (state.status == WorkProofStatus.failure && state.proofs.isEmpty) {
      return _WorkProofError(onRetry: context.read<WorkProofCubit>().load);
    }

    final canAddBefore = const {
      'assigned',
      'on_the_way',
      'in_progress',
    }.contains(bookingStatus);
    final canAddAfter = const {
      'in_progress',
      'completed',
    }.contains(bookingStatus);

    return RefreshIndicator(
      onRefresh: context.read<WorkProofCubit>().load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
        children: [
          _WorkProofHero(
            bookingNumber: bookingNumber,
            serviceName: serviceName,
            total: state.proofs.length,
          ),
          const SizedBox(height: 22),
          _ProofSection(
            type: WorkProofType.before,
            proofs: state.before,
            canAdd: canAddBefore,
            busy: state.isBusy,
          ),
          const SizedBox(height: 18),
          _ProofSection(
            type: WorkProofType.after,
            proofs: state.after,
            canAdd: canAddAfter,
            busy: state.isBusy,
          ),
          if (!canAddBefore && !canAddAfter) ...[
            const SizedBox(height: 18),
            const _LockedNotice(),
          ],
        ],
      ),
    );
  }
}

final class _WorkProofHero extends StatelessWidget {
  const _WorkProofHero({
    required this.bookingNumber,
    required this.serviceName,
    required this.total,
  });

  final String bookingNumber;
  final String serviceName;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.photo_camera_back_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                serviceName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$bookingNumber • ${context.tr(LanguageKeys.workProofPhotoCount, {'count': total})}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _ProofSection extends StatelessWidget {
  const _ProofSection({
    required this.type,
    required this.proofs,
    required this.canAdd,
    required this.busy,
  });

  final WorkProofType type;
  final List<WorkProof> proofs;
  final bool canAdd;
  final bool busy;

  bool get _isBefore => type == WorkProofType.before;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
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
                color: (_isBefore ? const Color(0xFFF59E0B) : AppColors.success)
                    .withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _isBefore
                    ? Icons.photo_camera_outlined
                    : Icons.verified_rounded,
                color: _isBefore ? const Color(0xFFD97706) : AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      _isBefore
                          ? LanguageKeys.beforeWork
                          : LanguageKeys.afterWork,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.tr(
                      _isBefore
                          ? LanguageKeys.beforeWorkDescription
                          : LanguageKeys.afterWorkDescription,
                    ),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (proofs.isEmpty)
          const _EmptyProof()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: proofs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) =>
                _ProofTile(proof: proofs[index], busy: busy),
          ),
        if (canAdd) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : () => _pickPhoto(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo_outlined),
              label: Text(
                context.tr(
                  _isBefore
                      ? LanguageKeys.addBeforePhoto
                      : LanguageKeys.addAfterPhoto,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Future<void> _pickPhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(LanguageKeys.addWorkProof),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(context.tr(LanguageKeys.takePhoto)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.tr(LanguageKeys.chooseFromGallery)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
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
        imageQuality: 82,
        maxWidth: 1800,
      );
      if (image == null || !context.mounted) return;
      final bytes = await image.readAsBytes();
      if (!context.mounted) return;
      await context.read<WorkProofCubit>().upload(
        type: type,
        bytes: bytes,
        fileExtension: image.name.split('.').last,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.tr(LanguageKeys.workProofSelectionFailed)),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }
}

final class _ProofTile extends StatelessWidget {
  const _ProofTile({required this.proof, required this.busy});

  final WorkProof proof;
  final bool busy;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: const Color(0xFFF0F0F6),
          child: Image.network(
            proof.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 22, 8, 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xB8000000)],
              ),
            ),
            child: Text(
              AppFormatters.dateTime(proof.createdAt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
        Positioned(
          top: 7,
          right: 7,
          child: IconButton.filled(
            tooltip: context.tr(LanguageKeys.deletePhoto),
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.55),
              foregroundColor: Colors.white,
            ),
            onPressed: busy ? null : () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
          ),
        ),
      ],
    ),
  );

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr(LanguageKeys.deleteWorkProof)),
        content: Text(context.tr(LanguageKeys.deleteWorkProofConfirmation)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr(LanguageKeys.cancel)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.tr(LanguageKeys.delete)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<WorkProofCubit>().delete(proof);
    }
  }
}

final class _EmptyProof extends StatelessWidget {
  const _EmptyProof();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F8FC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.add_photo_alternate_outlined,
          color: AppColors.textSecondary,
          size: 34,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(LanguageKeys.noWorkProofPhoto),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}

final class _LockedNotice extends StatelessWidget {
  const _LockedNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFCD38D)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.tr(LanguageKeys.workProofLocked),
            style: const TextStyle(fontSize: 12, color: Color(0xFF78350F)),
          ),
        ),
      ],
    ),
  );
}

final class _WorkProofLoading extends StatefulWidget {
  const _WorkProofLoading();

  @override
  State<_WorkProofLoading> createState() => _WorkProofLoadingState();
}

final class _WorkProofLoadingState extends State<_WorkProofLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final position = (_controller.value * 3) - 1.5;
      return ShaderMask(
        blendMode: BlendMode.modulate,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(position - 1, 0),
          end: Alignment(position + 1, 0),
          colors: const [
            Color(0xFFE5E5EE),
            Color(0xFFF8F8FC),
            Color(0xFFE5E5EE),
          ],
          stops: const [0.25, 0.5, 0.75],
        ).createShader(bounds),
        child: child,
      );
    },
    child: const _WorkProofSkeleton(),
  );
}

final class _WorkProofSkeleton extends StatelessWidget {
  const _WorkProofSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
    children: const [
      _LoadingBlock(height: 98, radius: 24),
      SizedBox(height: 22),
      _LoadingBlock(height: 220, radius: 22),
      SizedBox(height: 18),
      _LoadingBlock(height: 220, radius: 22),
    ],
  );
}

final class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE8E8F0),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

final class _WorkProofError extends StatelessWidget {
  const _WorkProofError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 14),
          Text(
            context.tr(LanguageKeys.workProofLoadFailed),
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
