import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../libraries/design_system/theme/app_colors.dart';
import '../cubit/staff_qr_scan_cubit.dart';

final class StaffQrScanPage extends StatefulWidget {
  const StaffQrScanPage({required this.purposeLabel, super.key});

  final String purposeLabel;

  @override
  State<StaffQrScanPage> createState() => _StaffQrScanPageState();
}

final class _StaffQrScanPageState extends State<StaffQrScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handlingCode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StaffQrScanCubit, StaffQrScanState>(
      listener: (context, state) async {
        if (state.status == StaffQrScanStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'QR berhasil diverifikasi.'),
            ),
          );
          Navigator.of(context).pop(true);
          return;
        }
        if (state.status == StaffQrScanStatus.failure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.message ?? 'QR tidak valid.')),
            );
          _handlingCode = false;
          context.read<StaffQrScanCubit>().retry();
          await _controller.start();
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('Scan QR ${widget.purposeLabel}'),
          foregroundColor: Colors.white,
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              tooltip: 'Nyalakan lampu',
              onPressed: _controller.toggleTorch,
              icon: const Icon(Icons.flash_on_rounded),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: _controller, onDetect: _onDetect),
            const _ScannerOverlay(),
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.isProcessing) ...[
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        state.message ??
                            'Arahkan kamera ke QR milik customer. Lokasi perangkat akan dicatat saat QR diverifikasi.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingCode) return;
    String? token;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        token = value;
        break;
      }
    }
    if (token == null) return;

    _handlingCode = true;
    await _controller.stop();
    if (mounted) await context.read<StaffQrScanCubit>().verify(token);
  }
}

final class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.secondary, width: 4),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    ),
  );
}
