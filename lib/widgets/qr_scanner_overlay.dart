// qr_scanner_overlay.dart
//
// Voice-triggered QR Scanner  
// Shows a centered GlassCard containing a live MobileScanner view.
// On detection, sends a "ready-made" prompt to Convai instead of raw data.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

typedef QrDetectedCallback = void Function(String qrValue);

class QrScannerOverlay extends StatefulWidget {
  final bool isVisible;
  final QrDetectedCallback onDetected;
  final VoidCallback onClose;

  const QrScannerOverlay({
    super.key,
    required this.isVisible,
    required this.onDetected,
    required this.onClose,
  });

  @override
  State<QrScannerOverlay> createState() => _QrScannerOverlayState();
}

class _QrScannerOverlayState extends State<QrScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  );

  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  late final Animation<double> _scale =
      Tween<double>(begin: 0.85, end: 1.0)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) _ctrl.forward();
  }

  @override
  void didUpdateWidget(QrScannerOverlay old) {
    super.didUpdateWidget(old);
    if (widget.isVisible && !old.isVisible) {
      _scanned = false;
      _ctrl.forward();
    } else if (!widget.isVisible && old.isVisible) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scanner.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue ?? '';
    if (raw.isEmpty) return;
    _scanned = true;
    widget.onDetected(raw);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _ctrl.isDismissed) return const SizedBox();

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Center(
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.85,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4FC3F7).withValues(alpha: 0.20),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header ─────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Color(0xFF4FC3F7),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Scan Boarding Pass',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.white54, size: 22),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                      ),

                      // ── Scanner View ───────────────────────────────────────
                      SizedBox(
                        height: 260,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(24),
                              ),
                              child: MobileScanner(
                                controller: _scanner,
                                onDetect: _onBarcodeDetect,
                              ),
                            ),
                            // Scanning frame overlay
                            Center(
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF4FC3F7),
                                    width: 2.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Stack(
                                  children: [
                                    // Corner accents
                                    ..._buildCornerAccents(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Hint text ──────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Text(
                          'Point the camera at a QR code or barcode',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCornerAccents() {
    const size = 20.0;
    const thick = 3.0;
    const color = Color(0xFF4FC3F7);
    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: _Corner(top: true, left: true, size: size, thickness: thick, color: color),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: _Corner(top: true, left: false, size: size, thickness: thick, color: color),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: _Corner(top: false, left: true, size: size, thickness: thick, color: color),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: _Corner(top: false, left: false, size: size, thickness: thick, color: color),
      ),
    ];
  }
}

class _Corner extends StatelessWidget {
  final bool top, left;
  final double size, thickness;
  final Color color;
  const _Corner({
    required this.top,
    required this.left,
    required this.size,
    required this.thickness,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(top: top, left: left, color: color, thickness: thickness),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top, left;
  final Color color;
  final double thickness;
  const _CornerPainter({
    required this.top,
    required this.left,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
