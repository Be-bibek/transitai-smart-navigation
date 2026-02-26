// pixel_streaming_layer.dart
//
// Renders the Unreal Engine Pixel Streaming video feed with:
//   • Locked 16:9 Cine Camera aspect ratio (AspectRatio + FittedBox)
//   • GestureDetector for Spring Arm orbit camera control
//   • Animated fallback background when not yet streaming
//
// Data Flow: swipe delta → onOrbitDelta callback → PixelStreamingController
//            → DataChannel → Unreal Spring Arm rotator

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Streaming background state shared with this widget.
enum StreamingLayerState { connecting, streaming, error }

/// PixelStreamingLayer
///
/// Renders the Unreal Engine MetaHuman video feed when [state] is
/// [StreamingLayerState.streaming], locked to a 16:9 cinematic aspect ratio.
/// Falls back to a premium animated dark background when connecting or on error.
///
/// [onOrbitDelta] — called with (deltaX, deltaY) when the user swipes over the
/// video. Wire this up to PixelStreamingController.sendOrbitInput() to rotate
/// Vivian's Spring Arm camera.
class PixelStreamingLayer extends StatelessWidget {
  final StreamingLayerState state;
  final RTCVideoRenderer renderer;

  /// Callback fired on every swipe update over the video.
  /// deltaX and deltaY are raw pointer-delta pixels.
  final void Function(double deltaX, double deltaY)? onOrbitDelta;

  const PixelStreamingLayer({
    super.key,
    required this.state,
    required this.renderer,
    this.onOrbitDelta,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case StreamingLayerState.streaming:
        return _StreamingVideoView(
          renderer: renderer,
          onOrbitDelta: onOrbitDelta,
        );

      case StreamingLayerState.connecting:
        return const _AnimatedFallbackBackground(
          child: Center(
                // Scrim in MainAIPage handles loading UI
                child: SizedBox.shrink(),
          ),
        );

      case StreamingLayerState.error:
        return const _AnimatedFallbackBackground();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streaming video view — 16:9 Cine Camera aspect ratio + orbit gesture
// ─────────────────────────────────────────────────────────────────────────────
class _StreamingVideoView extends StatelessWidget {
  final RTCVideoRenderer renderer;
  final void Function(double dx, double dy)? onOrbitDelta;

  const _StreamingVideoView({required this.renderer, this.onOrbitDelta});

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder ensures AspectRatio always receives bounded constraints.
    // AspectRatio inside a Stack without Positioned.fill gets unbounded
    // constraints and throws a render error — LayoutBuilder prevents that.
    Widget videoContent = LayoutBuilder(
      builder: (context, constraints) {
        // If somehow still unbounded (edge case), fall back to full screen size
        final w = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final h = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;

        // Compute the 16:9 box that fits inside the available space
        const targetRatio = 16.0 / 9.0;
        double boxW, boxH;
        if (w / h > targetRatio) {
          // Parent is wider than 16:9 — constrain by height
          boxH = h;
          boxW = h * targetRatio;
        } else {
          // Parent is taller than 16:9 — constrain by width
          boxW = w;
          boxH = w / targetRatio;
        }

        return SizedBox(
          width: w,
          height: h,
          child: Center(
            child: SizedBox(
              width: boxW,
              height: boxH,
              child: RTCVideoView(
                renderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              ),
            ),
          ),
        );
      },
    );

    if (onOrbitDelta == null) return videoContent;

    // GestureDetector captures swipe motion and forwards (dx, dy) to Unreal
    // through the DataChannel as a remote_input / orbit_camera event.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        onOrbitDelta!(details.delta.dx, details.delta.dy);
      },
      child: videoContent,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated fallback background
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedFallbackBackground extends StatefulWidget {
  final Widget? child;
  const _AnimatedFallbackBackground({this.child});

  @override
  State<_AnimatedFallbackBackground> createState() =>
      _AnimatedFallbackBackgroundState();
}

class _AnimatedFallbackBackgroundState
    extends State<_AnimatedFallbackBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    duration: const Duration(seconds: 8),
    vsync: this,
  )..repeat();

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
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                sin(_ctrl.value * 2 * pi) * 0.4,
                cos(_ctrl.value * 2 * pi) * 0.4,
              ),
              radius: 1.6,
              colors: const [
                Color(0xFF0D1B2A),
                Color(0xFF0A2540),
                Color(0xFF061220),
              ],
            ),
          ),
          child: Stack(
            children: [
              ..._buildOrbs(_ctrl.value),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }

  static List<Widget> _buildOrbs(double t) {
    final orbConfigs = [
      _OrbConfig(
        x: 0.2 + sin(t * 2 * pi) * 0.15,
        y: 0.3 + cos(t * 2 * pi * 0.7) * 0.15,
        size: 280,
        color: const Color(0xFF4FC3F7),
        opacity: 0.12,
      ),
      _OrbConfig(
        x: 0.75 + cos(t * 2 * pi * 0.9) * 0.1,
        y: 0.6 + sin(t * 2 * pi * 1.1) * 0.1,
        size: 350,
        color: const Color(0xFF0288D1),
        opacity: 0.10,
      ),
      _OrbConfig(
        x: 0.5 + sin(t * 2 * pi * 0.5) * 0.2,
        y: 0.8 + cos(t * 2 * pi * 0.3) * 0.08,
        size: 200,
        color: const Color(0xFF80DEEA),
        opacity: 0.08,
      ),
    ];

    return orbConfigs.map((o) {
      return Positioned.fill(
        child: Align(
          alignment: Alignment(o.x * 2 - 1, o.y * 2 - 1),
          child: Container(
            width: o.size,
            height: o.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  o.color.withValues(alpha: o.opacity),
                  o.color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _OrbConfig {
  final double x, y, size, opacity;
  final Color color;
  const _OrbConfig({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.opacity,
  });
}
