import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/top_bar.dart';
import '../../../widgets/icon_btn.dart';
import '../data/staff_repository.dart';

/// Escáner de QR con cámara (mobile_scanner). Al detectar un código lo valida
/// contra el backend y muestra el resultado.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _busy = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final codigo = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (codigo == null || codigo.isEmpty) return;

    setState(() => _busy = true);
    try {
      final resultado = await context.read<StaffRepository>().validar(codigo);
      if (!mounted) return;
      // Espera a que el resultado se cierre para reanudar el escaneo.
      await context.push('/worker/result', extra: resultado);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
    unawaited(_controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              left: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconBtn(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Escanear QR',
                      style: AppTextStyles.display.copyWith(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              right: IconBtn(
                onTap: () => _controller.toggleTorch(),
                child: const Icon(Icons.flash_on, size: 18),
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No se pudo abrir la cámara:\n${error.errorCode}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  // Marco de escaneo
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.red, width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  if (_busy)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.red),
                      ),
                    ),
                  Positioned(
                    bottom: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Apunta al QR del ticket',
                        style: AppTextStyles.mono.copyWith(
                            fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
