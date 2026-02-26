import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/assistant_state.dart';

/// AssistantStatusHeader
///
/// Glassmorphic top bar displaying the AI assistant title and a live status
/// indicator that reacts to all four [AssistantState] values.
///
/// Architecture role: **UI Layer** – reads state, never mutates it.
class AssistantStatusHeader extends StatefulWidget {
  final AssistantState state;

  const AssistantStatusHeader({super.key, required this.state});

  @override
  State<AssistantStatusHeader> createState() => _AssistantStatusHeaderState();
}

class _AssistantStatusHeaderState extends State<AssistantStatusHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotCtrl = AnimationController(
    duration: const Duration(milliseconds: 900),
    vsync: this,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _dotCtrl.dispose();
    super.dispose();
  }

  String get _statusLabel {
    switch (widget.state) {
      case AssistantState.listening:
        return 'Listening…';
      case AssistantState.processing:
        return 'Thinking…';
      case AssistantState.speaking:
        return 'Speaking…';
      case AssistantState.idle:
        return 'Ready';
    }
  }

  Color get _statusColor {
    switch (widget.state) {
      case AssistantState.listening:
        return const Color(0xFF4FC3F7);  // sky-blue
      case AssistantState.processing:
        return const Color(0xFFFFA726);  // amber
      case AssistantState.speaking:
        return const Color(0xFF81D4FA);  // light-blue
      case AssistantState.idle:
        return Colors.white38;
    }
  }

  bool get _showDot => widget.state != AssistantState.idle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // ── Logo icon ────────────────────────────────────────────────
              _AirportIcon(state: widget.state),
              const SizedBox(width: 14),

              // ── Title + live status row ───────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'AERO Sathi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (_showDot)
                          AnimatedBuilder(
                            animation: _dotCtrl,
                            builder: (_, __) => Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _statusColor.withValues(
                                    alpha: 0.4 + _dotCtrl.value * 0.6),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _statusColor.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _statusColor,
                            letterSpacing: 0.4,
                          ),
                          child: Text(_statusLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Processing spinner (only while processing) ───────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: widget.state == AssistantState.processing
                    ? SizedBox(
                        key: const ValueKey('spinner'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFFFFA726),
                          backgroundColor:
                              const Color(0xFFFFA726).withValues(alpha: 0.2),
                        ),
                      )
                    : const SizedBox(key: ValueKey('no-spinner')),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo icon — glows amber while processing
// ─────────────────────────────────────────────────────────────────────────────
class _AirportIcon extends StatelessWidget {
  final AssistantState state;
  const _AirportIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    final bool isProcessing = state == AssistantState.processing;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isProcessing
              ? [const Color(0xFFFFA726), const Color(0xFFE65100)]
              : [const Color(0xFF4FC3F7), const Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isProcessing
                    ? const Color(0xFFFFA726)
                    : const Color(0xFF4FC3F7))
                .withValues(alpha: 0.5),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(
        Icons.flight_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}


