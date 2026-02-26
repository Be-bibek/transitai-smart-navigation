// ─────────────────────────────────────────────────────────────────────────────
// MainAIPage — AERO Sathi
//
// THE ONLY SCREEN IN THE APP.
//
// Everything auto-starts in initState:
//   • PixelStreaming WebRTC session connects automatically
//   • Microphone stays open continuously (voice-first)
//   • Speech-to-Text listener runs continuously for QR keyword detection
//   • No Connect / Disconnect buttons anywhere
//
// Stack layers (bottom → top):
//   1  PixelStreamingLayer   — full-screen video / animated fallback bg
//   2  Gradient vignettes    — top + bottom dark fade
//   3  AssistantStatusHeader — top glassmorphic pill
//   4  FloatingInfoBubble    — AI speech bubble (7-second auto-dismiss)
//   5  QrScannerOverlay      — AnimatedOpacity, voice-triggered
//   6  Bottom glass controls — VoiceWaveform + LiquidGlassOrb + InputBar
//   7  Error toast           — auto-retry glass pill (no hard error screen)
//   8  Loading glass scrim   — fades out the instant video arrives
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  final SpeechToText _stt = SpeechToText();
  bool _sttAvailable = false;
  Timer? _sttRestartTimer;

  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  bool _showInputBar = false;

  bool _isScanning = false;

  String? _bubbleText;
  bool _bubbleVisible = false;
  Timer? _bubbleTimer;

  double _volumeLevel = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = PixelStreamingController();
    _bootApp();
  }

  Future<void> _bootApp() async {
    await Permission.microphone.request();
    await _ctrl.initialize();
    _ctrl.addListener(_onControllerUpdate);
    await _ctrl.connect();
    await _initStt();
  }

  Future<void> _initStt() async {
    _sttAvailable = await _stt.initialize(
      onError: (_) => _schedulesSttRestart(),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _schedulesSttRestart();
        }
      },
    );
    if (!_sttAvailable) return;
    _beginSttSession();
  }

  void _schedulesSttRestart() {
    _sttRestartTimer?.cancel();
    _sttRestartTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && _sttAvailable) _beginSttSession();
    });
  }

  void _beginSttSession() {
    if (!_sttAvailable || !mounted || _stt.isListening) return;
    _stt.listen(
      onResult: (result) {
        final words = result.recognizedWords.toLowerCase();
        if ((words.contains('scan') || words.contains('boarding pass')) &&
            !_isScanning) {
          setState(() => _isScanning = true);
          HapticFeedback.mediumImpact();
        }
        if (result.hasConfidenceRating && result.confidence > 0) {
          if (mounted) {
            setState(() => _volumeLevel = result.confidence.clamp(0.0, 1.0));
          }
        }
      },
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
      ),
    );
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

  void _onQrDetected(String rawValue) {
    setState(() => _isScanning = false);
    HapticFeedback.heavyImpact();
    _ctrl.sendTextToConvai(
      'User has scanned a boarding pass. '
      'Gate: A12, Flight: EK202. '
      'Please confirm these details with the user warmly.',
    );
    _showBubble('Boarding pass scanned ✈\nGate A12 · Flight EK202');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _ctrl.localMicStream?.getAudioTracks().forEach((t) => t.enabled = false);
      _stt.stop();
      _sttRestartTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_ctrl.isMicEnabled) {
        _ctrl.localMicStream?.getAudioTracks().forEach((t) => t.enabled = true);
      }
      _beginSttSession();
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
    _sttRestartTimer?.cancel();
    _stt.stop();
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

  bool get _isStreaming =>
      _ctrl.connectionState == PsConnectionState.streaming;

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
        return 'Retry';
    }
  }

  void _onTextSend(String text) {
    if (!_isStreaming) return;
    _ctrl.sendTextToConvai(text);
    _textCtrl.clear();
    _textFocus.unfocus();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PixelStreamingLayer(
              state: _layerState,
              renderer: _ctrl.renderer,
              onOrbitDelta: _isStreaming ? _ctrl.sendOrbitInput : null,
            ),
            _buildVignettes(),
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                bottom: false,
                child: AssistantStatusHeader(state: _ctrl.assistantState),
              ),
            ),
            Positioned(
              left: 20, right: 20,
              top: size.height * 0.22,
              child: FloatingInfoBubble(
                text: _bubbleText,
                visible: _bubbleVisible,
              ),
            ),
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
            SafeArea(
              top: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VoiceWaveform(
                    aiState: _ctrl.assistantState,
                    volumeLevel: _volumeLevel.clamp(0.0, 1.0),
                  ),
                  const SizedBox(height: 12),
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
                          if (_isStreaming) {
                            _ctrl.toggleMic();
                            HapticFeedback.mediumImpact();
                          }
                        },
                      ),
                      const SizedBox(width: 74),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            if (_showError) _ErrorToast(onReconnect: _ctrl.connect),
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
                    'Connection lost. Retrying...',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: onReconnect,
                  child: const Text('Try Again', style: TextStyle(color: Color(0xFF4FC3F7))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
          ],
        ),
      ),
    );
  }
}
