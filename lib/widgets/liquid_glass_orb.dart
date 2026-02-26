// liquid_glass_orb.dart
//
// "Liquid Glass Orb" Voice Visualizer
//
// Replaces the standard MicButton with a custom-painted glowing glass sphere:
//   • BackdropFilter blur sphere for 3D glass effect
//   • Siri-style gradient glow (Blue → Purple → Pink)
//   • Breathing scale animation when idle
//   • Outer rings that expand + fade on active voice
//   • LinearGradient highlight (top-left "wet glass" sheen)
//   • Real-time glow intensity + size changes from mic volume

import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/assistant_state.dart';

class LiquidGlassOrb extends StatefulWidget {
  final AssistantState aiState;
  final bool isMicActive;
  final VoidCallback onTap;

  /// 0.0 = silent, 1.0 = loudest. Drives glow intensity + ring expansion.
  final double volumeLevel;

  const LiquidGlassOrb({
    super.key,
    required this.aiState,
    required this.onTap,
    this.isMicActive = true,
    this.volumeLevel = 0.0,
  });

  @override
  State<LiquidGlassOrb> createState() => _LiquidGlassOrbState();
}

class _LiquidGlassOrbState extends State<LiquidGlassOrb>
    with TickerProviderStateMixin {
  // Breathing controller — runs continuously
  late final AnimationController _breathCtrl = AnimationController(
    duration: const Duration(milliseconds: 2800),
    vsync: this,
  )..repeat(reverse: true);

  late final Animation<double> _breathAnim = CurvedAnimation(
    parent: _breathCtrl,
    curve: Curves.easeInOut,
  );

  // Press scale controller
  double _pressScale = 1.0;

  // Expanding outer ring controllers (3 rings)
  late final List<AnimationController> _ringCtrls = List.generate(
    3,
    (i) => AnimationController(
      duration: Duration(milliseconds: 900 + i * 180),
      vsync: this,
    ),
  );

  @override
  void dispose() {
    _breathCtrl.dispose();
    for (final c in _ringCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(LiquidGlassOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Launch outer ring burst when speaking loudly
    if (widget.volumeLevel > 0.65 && oldWidget.volumeLevel <= 0.65) {
      for (int i = 0; i < _ringCtrls.length; i++) {
        Future.delayed(Duration(milliseconds: i * 140), () {
          if (mounted) {
            _ringCtrls[i].forward(from: 0.0);
          }
        });
      }
    }
  }

  // ── Siri-style colour set based on AI state ───────────────────────────────

  List<Color> get _glowColors {
    if (!widget.isMicActive) {
      return [const Color(0xFF78909C), const Color(0xFF546E7A)];
    }
    switch (widget.aiState) {
      case AssistantState.listening:
        return [const Color(0xFF29B6F6), const Color(0xFF7B2FF7)];
      case AssistantState.speaking:
        return [const Color(0xFF9C27B0), const Color(0xFFE91E63)];
      case AssistantState.processing:
        return [const Color(0xFFFFA726), const Color(0xFFFF5722)];
      case AssistantState.idle:
        return [
          const Color(0xFF4FC3F7),
          const Color(0xFF9575CD),
          const Color(0xFFEC407A),
        ];
    }
  }

  IconData get _icon {
    if (!widget.isMicActive) return Icons.mic_off_rounded;
    switch (widget.aiState) {
      case AssistantState.listening:
        return Icons.graphic_eq_rounded;
      case AssistantState.processing:
        return Icons.hourglass_top_rounded;
      case AssistantState.speaking:
        return Icons.hearing_rounded;
      case AssistantState.idle:
        return Icons.mic_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressScale = 0.92),
      onTapUp: (_) {
        setState(() => _pressScale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressScale = 1.0),
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathAnim, ..._ringCtrls]),
        builder: (_, __) {
          final breath = _breathAnim.value; // 0..1
          final vol = widget.volumeLevel.clamp(0.0, 1.0);
          final activity = widget.isMicActive ? (breath * 0.35 + vol * 0.65) : 0.1;

          // Base orb size breathes gently
          final orbSize = 96.0 + breath * 8 + vol * 18;

          return AnimatedScale(
            scale: _pressScale,
            duration: const Duration(milliseconds: 120),
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Outer Rings — burst on loud voice ──────────────────────
                  ..._buildOuterRings(activity),

                  // ── Glow halo ─────────────────────────────────────────────
                  _buildGlowHalo(orbSize, activity),

                  // ── Orb sphere (BackdropFilter glass) ─────────────────────
                  _buildOrbSphere(orbSize),

                  // ── Icon ──────────────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      _icon,
                      key: ValueKey(_icon),
                      color: Colors.white,
                      size: 34,
                      shadows: const [
                        Shadow(
                          color: Colors.white54,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildOuterRings(double activity) {
    return List.generate(_ringCtrls.length, (i) {
      final t = _ringCtrls[i].value;
      final expand = t * (60 + i * 20);
      final fade = (1.0 - t).clamp(0.0, 1.0);
      final colors = _glowColors;
      return Opacity(
        opacity: fade * activity,
        child: Container(
          width: 96 + expand,
          height: 96 + expand,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.first.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildGlowHalo(double orbSize, double activity) {
    final colors = _glowColors;
    return Container(
      width: orbSize + 30 + activity * 40,
      height: orbSize + 30 + activity * 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35 + activity * 0.30),
            blurRadius: 60 + activity * 30,
            spreadRadius: 10 + activity * 20,
          ),
          if (colors.length > 1)
            BoxShadow(
              color: colors[1].withValues(alpha: 0.20 + activity * 0.20),
              blurRadius: 80,
              spreadRadius: -5,
            ),
          if (colors.length > 2)
            BoxShadow(
              color: colors[2].withValues(alpha: 0.15 + activity * 0.15),
              blurRadius: 100,
              spreadRadius: -15,
            ),
        ],
      ),
    );
  }

  Widget _buildOrbSphere(double orbSize) {
    final colors = _glowColors;
    return SizedBox(
      width: orbSize,
      height: orbSize,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Base gradient tint
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 0.9,
                colors: [
                  colors.first.withValues(alpha: 0.35),
                  colors.last.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Glass highlight — top-left "wet glass" sheen
                Positioned(
                  top: orbSize * 0.08,
                  left: orbSize * 0.10,
                  child: Container(
                    width: orbSize * 0.42,
                    height: orbSize * 0.42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
                // Inner glow highlight (smaller, brighter)
                Positioned(
                  top: orbSize * 0.12,
                  left: orbSize * 0.18,
                  child: Container(
                    width: orbSize * 0.22,
                    height: orbSize * 0.14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
