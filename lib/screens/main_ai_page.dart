// ─────────────────────────────────────────────────────────────────────────────
// MainAIPage — AERO Sathi · BLoC-Service Architecture
//
// THE ONLY SCREEN IN THE APP.
//
// Uses BlocBuilder for reactive UI and BlocListener for side effects.
// All interaction goes through BLoC events:
//   • ConnectStream        — boot pipeline
//   • SendTextMessage      — fire-and-forget text
//   • ToggleMic            — mute/unmute (never kills mic)
//   • SendOrbitInput       — camera swipe
//   • QrCodeScanned        — boarding pass
//   • AppLifecyclePaused   — pause mic
//   • AppLifecycleResumed  — resume mic
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/pixel_streaming_bloc.dart';
import '../bloc/pixel_streaming_event.dart';
import '../bloc/pixel_streaming_state.dart';
import '../core/assistant_state.dart';
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
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  bool _showInputBar = false;
  bool _isScanning = false;

  // Bubble state (managed locally for timer-based auto-dismiss)
  String? _bubbleText;
  bool _bubbleVisible = false;
  Timer? _bubbleTimer;

  // Sent echo state
  String? _lastSentText;
  bool _sentEchoVisible = false;
  Timer? _sentEchoTimer;

  // Volume level (animated locally from assistant state)
  double _volumeLevel = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootApp();
  }

  Future<void> _bootApp() async {
    await Permission.microphone.request();
    if (!mounted) return;
    final bloc = context.read<PixelStreamingBloc>();
    await bloc.initialize();
    bloc.add(const ConnectStream());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bloc = context.read<PixelStreamingBloc>();
    if (state == AppLifecycleState.paused) {
      bloc.add(const AppLifecyclePaused());
    } else if (state == AppLifecycleState.resumed) {
      bloc.add(const AppLifecycleResumed());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textCtrl.dispose();
    _textFocus.dispose();
    _bubbleTimer?.cancel();
    _sentEchoTimer?.cancel();
    super.dispose();
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

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

  void _updateVolume(AssistantState aiState) {
    final flicker = (DateTime.now().millisecond / 1000.0);
    switch (aiState) {
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

  StreamingLayerState _toLayerState(StreamPhase phase) {
    switch (phase) {
      case StreamPhase.streaming:
      case StreamPhase.waitingForStream:
        return StreamingLayerState.streaming;
      case StreamPhase.error:
        return StreamingLayerState.error;
      default:
        return StreamingLayerState.connecting;
    }
  }

  // ── Text send handler ─────────────────────────────────────────────────────

  void _onTextSend(String text) {
    if (text.trim().isEmpty) return;
    context.read<PixelStreamingBloc>().add(SendTextMessage(text));
    _showSentEcho(text.trim());
    _textCtrl.clear();
    _textFocus.unfocus();
    HapticFeedback.selectionClick();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final size = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<PixelStreamingBloc, PixelStreamingState>(
      listenWhen: (prev, curr) =>
          prev.subtitleText != curr.subtitleText ||
          prev.assistantState != curr.assistantState,
      listener: (context, state) {
        // Show bubble when AI speaks
        if (state.assistantState == AssistantState.speaking &&
            state.subtitleText.isNotEmpty) {
          _showBubble(state.subtitleText);
        }
        _updateVolume(state.assistantState);
        setState(() {}); // Refresh volume animation
      },
      child: BlocBuilder<PixelStreamingBloc, PixelStreamingState>(
        builder: (context, state) {
          final bloc = context.read<PixelStreamingBloc>();
          _updateVolume(state.assistantState);

          return Scaffold(
            backgroundColor: Colors.black,
            resizeToAvoidBottomInset: false,
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── 1. Video / Fallback background ────────────────────────
                  PixelStreamingLayer(
                    state: _toLayerState(state.phase),
                    renderer: bloc.renderer,
                    onOrbitDelta: (dx, dy) =>
                        bloc.add(SendOrbitInput(dx, dy)),
                  ),

                  // ── 2. Vignette gradients ─────────────────────────────────
                  _buildVignettes(),

                  // ── 3. Status header ──────────────────────────────────────
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: AssistantStatusHeader(state: state.assistantState),
                    ),
                  ),

                  // ── 4. AI speech bubble ───────────────────────────────────
                  Positioned(
                    left: 20, right: 20,
                    top: size.height * 0.22,
                    child: FloatingInfoBubble(
                      text: _bubbleText,
                      visible: _bubbleVisible,
                    ),
                  ),

                  // ── 5. QR scanner overlay ─────────────────────────────────
                  AnimatedOpacity(
                    opacity: _isScanning ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 350),
                    child: IgnorePointer(
                      ignoring: !_isScanning,
                      child: QrScannerOverlay(
                        isVisible: _isScanning,
                        onDetected: (rawValue) {
                          setState(() => _isScanning = false);
                          HapticFeedback.heavyImpact();
                          bloc.add(QrCodeScanned(rawValue));
                          _showBubble(
                              'Boarding pass scanned ✈\nGate A12 · Flight EK202');
                        },
                        onClose: () => setState(() => _isScanning = false),
                      ),
                    ),
                  ),

                  // ── 6. Sent message echo ──────────────────────────────────
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

                  // ── 7. Bottom controls ────────────────────────────────────
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Connection status pill
                          if (!state.isStreaming)
                            _ConnectionStatusPill(
                              label: state.statusLabel,
                              isError: state.hasError,
                            ),
                          const SizedBox(height: 8),

                          // Voice waveform
                          VoiceWaveform(
                            aiState: state.assistantState,
                            volumeLevel: _volumeLevel.clamp(0.0, 1.0),
                          ),
                          const SizedBox(height: 12),

                          // Input bar
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _showInputBar
                                ? Padding(
                                    key: const ValueKey('input-bar'),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18),
                                    child: InputBar(
                                      controller: _textCtrl,
                                      focusNode: _textFocus,
                                      onSend: _onTextSend,
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('input-bar-hidden')),
                          ),
                          const SizedBox(height: 14),

                          // Control row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _KeyboardToggle(
                                active: _showInputBar,
                                onTap: () {
                                  setState(
                                      () => _showInputBar = !_showInputBar);
                                  if (!_showInputBar) _textFocus.unfocus();
                                },
                              ),
                              const SizedBox(width: 24),
                              LiquidGlassOrb(
                                aiState: state.assistantState,
                                isMicActive: state.isMicEnabled,
                                volumeLevel: _volumeLevel.clamp(0.0, 1.0),
                                onTap: () {
                                  // BLoC event — always works, no gates
                                  bloc.add(const ToggleMic());
                                  HapticFeedback.mediumImpact();
                                },
                              ),
                              const SizedBox(width: 24),
                              _ScannerToggle(
                                active: _isScanning,
                                onTap: () {
                                  setState(
                                      () => _isScanning = !_isScanning);
                                  if (_isScanning) {
                                    HapticFeedback.mediumImpact();
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // ── 8. Error toast ────────────────────────────────────────
                  if (state.hasError)
                    _ErrorToast(
                      onReconnect: () =>
                          bloc.add(const ReconnectStream()),
                    ),

                  // ── 9. Loading scrim ──────────────────────────────────────
                  AnimatedOpacity(
                    opacity: state.isLoading ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 700),
                    child: IgnorePointer(
                      ignoring: !state.isLoading,
                      child: _GlassLoadingScrim(label: state.statusLabel),
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
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
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
                colors: [
                  Colors.black.withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets (unchanged visuals, same premium look)
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
                Icon(Icons.send_rounded,
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.7),
                    size: 14),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w400),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
              color: (isError ? Colors.red : Colors.white)
                  .withValues(alpha: 0.15),
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
                  color:
                      isError ? Colors.redAccent : const Color(0xFF4FC3F7),
                ),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      color:
                          isError ? Colors.redAccent : Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
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
          color: active
              ? const Color(0xFF4FC3F7).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: active
                ? const Color(0xFF4FC3F7).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
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
          color: active
              ? const Color(0xFF4FC3F7).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: active
                ? const Color(0xFF4FC3F7).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
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

class _ErrorToast extends StatelessWidget {
  final VoidCallback onReconnect;
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Connection lost. Auto-retrying…',
                      style:
                          TextStyle(color: Colors.white, fontSize: 13)),
                ),
                TextButton(
                  onPressed: onReconnect,
                  child: const Text('Retry',
                      style: TextStyle(color: Color(0xFF4FC3F7))),
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
                        color: const Color(0xFF4FC3F7)
                            .withValues(alpha: 0.3 + breath * 0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child:
                      const Icon(Icons.mic, color: Colors.white, size: 40),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(widget.label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300)),
            const SizedBox(height: 16),
            Text('🎙 Microphone will activate on connect',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w300)),
          ],
        ),
      ),
    );
  }
}
