// ─────────────────────────────────────────────────────────────────────────────
// MainAIPage — AERO Sathi · "Always-On" Architecture
//
// THE ONLY SCREEN IN THE APP.
//
// Everything auto-starts in initState:
//   • Microphone initializes IMMEDIATELY and stays on FOREVER
//   • Pixel Streaming WebRTC session connects automatically
//   • Text sends are FIRE-AND-FORGET — no connection gate
//   • LiquidGlassOrb tap = MUTE/UNMUTE (never kills mic)
//   • Input bar is always visible at the bottom
//
// Stack layers (bottom → top):
//   1  PixelStreamingLayer   — full-screen video / animated fallback bg
//   2  Gradient vignettes    — top + bottom dark fade
//   3  AssistantStatusHeader — top glassmorphic pill
//   4  FloatingInfoBubble    — AI speech bubble (7-second auto-dismiss)
//   5  QrScannerOverlay      — AnimatedOpacity, toggle-triggered
//   6  Sent message echo     — shows last sent text
//   7  Bottom glass controls — VoiceWaveform + LiquidGlassOrb + toggles
//   8  InputBar              — always visible text input
//   9  Connection status pill — shows connection state
//   10 Loading glass scrim   — fades out the instant video arrives
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/assistant_state.dart';
import '../services/pixel_streaming_controller.dart';
import '../widgets/assistant_status_header.dart';
import '../widgets/floating_info_bubble.dart';
import '../widgets/input_bar.dart';
import '../widgets/liquid_glass_orb.dart';
import '../widgets/pixel_streaming_layer.dart';
import '../widgets/qr_scanner_overlay.dart';
import '../widgets/voice_waveform.dart';

class MainAIPage extends StatefulWidget {
  const MainAIPage({super.key});

  @override
  State<MainAIPage> createState() => _MainAIPageState();
}

class _MainAIPageState extends State<MainAIPage>
    with WidgetsBindingObserver {
  late final PixelStreamingController _ctrl;

  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  bool _showInputBar = false;

  bool _isScanning = false;

  String? _bubbleText;
  bool _bubbleVisible = false;
  Timer? _bubbleTimer;

  // Sent message echo
  String? _lastSentText;
  bool _sentEchoVisible = false;
  Timer? _sentEchoTimer;

  double _volumeLevel = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = PixelStreamingController();
    _bootApp();
  }

  Future<void> _bootApp() async {
    // Request mic permission FIRST
    await Permission.microphone.request();
    await _ctrl.initialize();
    _ctrl.addListener(_onControllerUpdate);
    // Connect — mic starts immediately via WebRTC getUserMedia
    await _ctrl.connect();
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    if (_ctrl.assistantState == AssistantState.speaking &&
        _ctrl.subtitleText.isNotEmpty) {
      _showBubble(_ctrl.subtitleText);
    }
    _updateVolumeFromState();
    setState(() {});
  }

  void _updateVolumeFromState() {
    final flicker = (DateTime.now().millisecond / 1000.0);
    switch (_ctrl.assistantState) {
      case AssistantState.listening:
        _volumeLevel = 0.50 + flicker * 0.35;
      case AssistantState.speaking:
        _volumeLevel = 0.65 + flicker * 0.30;
      case AssistantState.processing:
        _volumeLevel = 0.20 + flicker * 0.10;
      case AssistantState.idle:
        if (_volumeLevel > 0.02) _volumeLevel = _volumeLevel * 0.90;
    }
  }

  void _showBubble(String text) {
    _bubbleTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _bubbleText = text;
      _bubbleVisible = true;
    });
    _bubbleTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _bubbleVisible = false);
    });
  }

  void _showSentEcho(String text) {
    _sentEchoTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _lastSentText = text;
      _sentEchoVisible = true;
    });
    _sentEchoTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _sentEchoVisible = false);
    });
  }

  void _onQrDetected(String rawValue) {
    setState(() => _isScanning = false);
    HapticFeedback.heavyImpact();
    // Fire-and-forget: no connection check
    _ctrl.sendTextToConvai(
      'User has scanned a boarding pass. '
      'Gate: A12, Flight: EK202. '
      'Please confirm these details with the user warmly.',
    );
    _showBubble('Boarding pass scanned ✈\nGate A12 · Flight EK202');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mic is PERSISTENT. On pause, mute the track. On resume, restore.
    if (state == AppLifecycleState.paused) {
      _ctrl.localMicStream?.getAudioTracks().forEach((t) => t.enabled = false);
    } else if (state == AppLifecycleState.resumed) {
      if (_ctrl.isMicEnabled) {
        _ctrl.localMicStream?.getAudioTracks().forEach((t) => t.enabled = true);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    _textCtrl.dispose();
    _textFocus.dispose();
    _bubbleTimer?.cancel();
    _sentEchoTimer?.cancel();
    super.dispose();
  }

  StreamingLayerState get _layerState {
    switch (_ctrl.connectionState) {
      case PsConnectionState.streaming:
      case PsConnectionState.waitingForStream:
        return StreamingLayerState.streaming;
      case PsConnectionState.error:
        return StreamingLayerState.error;
      default:
        return StreamingLayerState.connecting;
    }
  }

  bool get _showLoading =>
      _ctrl.connectionState == PsConnectionState.connecting ||
      _ctrl.connectionState == PsConnectionState.disconnected;

  bool get _showError => _ctrl.connectionState == PsConnectionState.error;

  String get _statusLabel {
    switch (_ctrl.connectionState) {
      case PsConnectionState.disconnected:
        return 'Initialising';
      case PsConnectionState.connecting:
        return 'Connecting';
      case PsConnectionState.waitingForStream:
        return 'Starting';
      case PsConnectionState.streaming:
        return 'Ready';
      case PsConnectionState.error:
        return 'Reconnecting';
    }
  }

  // FIRE-AND-FORGET: no connection gate!
  void _onTextSend(String text) {
    if (text.trim().isEmpty) return;
    _ctrl.sendTextToConvai(text);
    _showSentEcho(text.trim());
    _textCtrl.clear();
    _textFocus.unfocus();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final size = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Video / Fallback background ────────────────────────────
            PixelStreamingLayer(
              state: _layerState,
              renderer: _ctrl.renderer,
              onOrbitDelta: _ctrl.sendOrbitInput,
            ),

            // ── 2. Vignette gradients ─────────────────────────────────────
            _buildVignettes(),

            // ── 3. Status header ──────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                bottom: false,
                child: AssistantStatusHeader(state: _ctrl.assistantState),
              ),
            ),

            // ── 4. AI speech bubble ───────────────────────────────────────
            Positioned(
              left: 20, right: 20,
              top: size.height * 0.22,
              child: FloatingInfoBubble(
                text: _bubbleText,
                visible: _bubbleVisible,
              ),
            ),

            // ── 5. QR scanner overlay ────────────────────────────────────
            AnimatedOpacity(
              opacity: _isScanning ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 350),
              child: IgnorePointer(
                ignoring: !_isScanning,
                child: QrScannerOverlay(
                  isVisible: _isScanning,
                  onDetected: _onQrDetected,
                  onClose: () => setState(() => _isScanning = false),
                ),
              ),
            ),

            // ── 6. Sent message echo ─────────────────────────────────────
            if (_lastSentText != null)
              Positioned(
                left: 40, right: 40,
                bottom: _showInputBar ? 310 + bottomPadding : 250,
                child: AnimatedOpacity(
                  opacity: _sentEchoVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _SentMessageEcho(text: _lastSentText!),
                ),
              ),

            // ── 7. Bottom controls ────────────────────────────────────────
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Connection status pill (when not streaming)
                    if (_ctrl.connectionState != PsConnectionState.streaming)
                      _ConnectionStatusPill(
                        label: _statusLabel,
                        isError: _showError,
                      ),
                    const SizedBox(height: 8),

                    // Voice waveform
                    VoiceWaveform(
                      aiState: _ctrl.assistantState,
                      volumeLevel: _volumeLevel.clamp(0.0, 1.0),
                    ),
                    const SizedBox(height: 12),

                    // Input bar (animated show/hide)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showInputBar
                          ? Padding(
                              key: const ValueKey('input-bar'),
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: InputBar(
                                controller: _textCtrl,
                                focusNode: _textFocus,
                                onSend: _onTextSend,
                              ),
                            )
                          : const SizedBox(key: ValueKey('input-bar-hidden')),
                    ),
                    const SizedBox(height: 14),

                    // Control row: keyboard toggle, orb, scanner toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _KeyboardToggle(
                          active: _showInputBar,
                          onTap: () {
                            setState(() => _showInputBar = !_showInputBar);
                            if (!_showInputBar) _textFocus.unfocus();
                          },
                        ),
                        const SizedBox(width: 24),
                        LiquidGlassOrb(
                          aiState: _ctrl.assistantState,
                          isMicActive: _ctrl.isMicEnabled,
                          volumeLevel: _volumeLevel.clamp(0.0, 1.0),
                          onTap: () {
                            // ALWAYS works — mute/unmute, no connection gate
                            _ctrl.toggleMic();
                            HapticFeedback.mediumImpact();
                          },
                        ),
                        const SizedBox(width: 24),
                        _ScannerToggle(
                          active: _isScanning,
                          onTap: () {
                            setState(() => _isScanning = !_isScanning);
                            if (_isScanning) HapticFeedback.mediumImpact();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── 9. Error toast ────────────────────────────────────────────
            if (_showError) _ErrorToast(onReconnect: _ctrl.connect),

            // ── 10. Loading scrim ─────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 700),
              child: IgnorePointer(
                ignoring: !_showLoading,
                child: _GlassLoadingScrim(label: _statusLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVignettes() {
    return Stack(
      children: [
        Positioned(
          top: 0, left: 0, right: 0, height: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0, height: 350,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sent Message Echo — shows what the user typed
// ─────────────────────────────────────────────────────────────────────────────
class _SentMessageEcho extends StatelessWidget {
  final String text;
  const _SentMessageEcho({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF4FC3F7).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.send_rounded,
                  color: const Color(0xFF4FC3F7).withValues(alpha: 0.7),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

// ─────────────────────────────────────────────────────────────────────────────
// Connection Status Pill
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectionStatusPill extends StatelessWidget {
  final String label;
  final bool isError;
  const _ConnectionStatusPill({required this.label, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: (isError ? Colors.red : Colors.white).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isError ? Colors.red : Colors.white).withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: isError ? Colors.redAccent : const Color(0xFF4FC3F7),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isError ? Colors.redAccent : Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keyboard Toggle
// ─────────────────────────────────────────────────────────────────────────────
class _KeyboardToggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _KeyboardToggle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 50, height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0xFF4FC3F7).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: active ? const Color(0xFF4FC3F7).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Icon(
          active ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded,
          color: active ? const Color(0xFF4FC3F7) : Colors.white54,
          size: 22,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanner Toggle
// ─────────────────────────────────────────────────────────────────────────────
class _ScannerToggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _ScannerToggle({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 50, height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0xFF4FC3F7).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: active ? const Color(0xFF4FC3F7).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Icon(
          active ? Icons.qr_code_scanner : Icons.qr_code,
          color: active ? const Color(0xFF4FC3F7) : Colors.white54,
          size: 22,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Toast
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorToast extends StatelessWidget {
  final Future<void> Function() onReconnect;
  const _ErrorToast({required this.onReconnect});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 120, left: 24, right: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Connection lost. Auto-retrying…',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: onReconnect,
                  child: const Text('Retry', style: TextStyle(color: Color(0xFF4FC3F7))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Loading Scrim
// ─────────────────────────────────────────────────────────────────────────────
class _GlassLoadingScrim extends StatefulWidget {
  final String label;
  const _GlassLoadingScrim({required this.label});

  @override
  State<_GlassLoadingScrim> createState() => _GlassLoadingScrimState();
}

class _GlassLoadingScrimState extends State<_GlassLoadingScrim>
    with TickerProviderStateMixin {
  late final AnimationController _breathCtrl = AnimationController(
    duration: const Duration(milliseconds: 2600),
    vsync: this,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _breathCtrl,
              builder: (context, child) {
                final breath = _breathCtrl.value;
                return Container(
                  width: 100 + breath * 10,
                  height: 100 + breath * 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4FC3F7).withValues(alpha: 0.3 + breath * 0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 40),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 2,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 16),
            // Mic status hint
            Text(
              '🎙 Microphone will activate on connect',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
