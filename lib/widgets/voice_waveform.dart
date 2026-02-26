// voice_waveform.dart
//
// Visual "Voice" Ripples — animated horizontal waveform bars.
// Bars scale their height dynamically based on voice activity.
// When the AI is listening or speaking, bars animate.  When idle, they rest.

import 'dart:math';
import 'package:flutter/material.dart';
import '../core/assistant_state.dart';

class VoiceWaveform extends StatefulWidget {
  final AssistantState aiState;

  /// Optional 0..1 volume level from mic (drives bar height).
  /// If null, uses the AI state to determine animation intensity.
  final double? volumeLevel;

  const VoiceWaveform({
    super.key,
    required this.aiState,
    this.volumeLevel,
  });

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    duration: const Duration(milliseconds: 1200),
    vsync: this,
  )..repeat();

  static const int _barCount = 13;
  static const double _minHeight = 5.0;
  static const double _maxHeight = 50.0;

  // Unique frequency offset per bar for organic feel
  final List<double> _phaseOffsets = List.generate(
    _barCount,
    (i) => i * (2 * pi / _barCount) + Random(i * 7).nextDouble() * pi,
  );

  double get _intensity {
    if (widget.volumeLevel != null) return widget.volumeLevel!.clamp(0.0, 1.0);
    switch (widget.aiState) {
      case AssistantState.listening:
        return 0.75;
      case AssistantState.speaking:
        return 0.85;
      case AssistantState.processing:
        return 0.30;
      case AssistantState.idle:
        return 0.08;
    }
  }

  Color get _barColor {
    switch (widget.aiState) {
      case AssistantState.listening:
        return const Color(0xFF4FC3F7);
      case AssistantState.speaking:
        return const Color(0xFF81D4FA);
      case AssistantState.processing:
        return const Color(0xFFFFA726);
      case AssistantState.idle:
        return Colors.white.withValues(alpha: 0.45);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value * 2 * pi;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_barCount, (i) {
            final phase = _phaseOffsets[i];
            // Combine two sine waves for more organic movement
            final raw = (sin(t * 2.5 + phase) + sin(t * 1.7 + phase * 0.5)) / 2;
            final normalised = (raw + 1) / 2; // 0..1
            final barH = _minHeight +
                (_maxHeight - _minHeight) * normalised * _intensity;

            final isCenter = (i - _barCount ~/ 2).abs() <= 1;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                width: isCenter ? 4.5 : 3.5,
                height: barH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: _barColor,
                  boxShadow: [
                    BoxShadow(
                      color: _barColor.withValues(alpha: 0.55 * _intensity),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
