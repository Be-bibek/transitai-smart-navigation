// ─────────────────────────────────────────────────────────────────────────────
// PixelStreamingController — "Always-On" Architecture
//
// DESIGN PHILOSOPHY:
//   • Microphone initializes IMMEDIATELY on app launch and stays on forever.
//   • Toggle = mute/unmute (audio track enabled/disabled), NOT kill mic.
//   • Text and voice are sent via "fire-and-forget" — no connection gate.
//   • DataChannel messages are queued if not yet open (PixelStreamingService).
//   • Reconnection is infinite — no max attempts, always tries to recover.
//
// Supports BOTH Unreal Engine Pixel Streaming protocols:
//   • Original PS  (UE5 embedded server, port 80)
//   • Pixel Streaming 2 (separate Cirrus/SFU, port 8888)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/assistant_state.dart';
import '../core/config.dart';
import 'pixel_streaming_service.dart';

// ── Connection state ──────────────────────────────────────────────────────────
enum PsConnectionState {
  disconnected,
  connecting,
  waitingForStream,
  streaming,
  error,
}

class PixelStreamingController extends ChangeNotifier {
  // ── Public state ────────────────────────────────────────────────────────────
  PsConnectionState connectionState = PsConnectionState.disconnected;
  AssistantState assistantState = AssistantState.idle;
  String subtitleText = '';
  bool subtitleVisible = false;
  String errorMessage = '';

  /// Messages sent by the user (for local echo in UI).
  final List<String> sentMessages = [];

  // ── RTCVideoRenderer — give to RTCVideoView in the UI ──────────────────────
  final RTCVideoRenderer renderer = RTCVideoRenderer();

  // ── PixelStreamingService — handles DataChannel encode/decode ──────────────
  final PixelStreamingService _psService = PixelStreamingService();

  // ── Private internals ───────────────────────────────────────────────────────
  WebSocketChannel? _ws;
  RTCPeerConnection? _pc;
  RTCDataChannel? _dataChannel;
  MediaStream? _localMicStream;
  bool _micMuted = false; // false = unmuted (mic ON by default)
  bool _disposed = false;

  /// Exposed so MainAIPage can pause/resume during app lifecycle changes.
  MediaStream? get localMicStream => _localMicStream;

  // Reconnect bookkeeping — infinite retries
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _connectTimeoutTimer;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    await renderer.initialize();
    _psService.onAiResponse = _onAiResponse;
    _psService.onStateChange = _onAssistantStateChange;
    _psService.onChannelOpen = _onChannelOpen;
  }

  Future<void> connect() async {
    if (connectionState == PsConnectionState.connecting ||
        connectionState == PsConnectionState.streaming) {
      return;
    }

    _reconnectTimer?.cancel();
    _connectTimeoutTimer?.cancel();
    _setState(PsConnectionState.connecting);
    errorMessage = '';
    notifyListeners();

    // ── Try primary URL first, then fallback ──────────────────────────────────
    bool connected = await _tryConnect(AppConfig.signalingUrl);
    if (!connected && !_disposed) {
      debugPrint('PixelStreamingController: primary URL failed, trying fallback…');
      connected = await _tryConnect(AppConfig.signalingUrlFallback);
    }

    if (!connected && !_disposed) {
      _handleError(
        'Cannot reach signaling server.\n'
        'Tried: ${AppConfig.signalingUrl} and ${AppConfig.signalingUrlFallback}\n'
        'Make sure UE5 Pixel Streaming is running and the device is on the same Wi-Fi.',
      );
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _connectTimeoutTimer?.cancel();
    await _teardown();
    _setState(PsConnectionState.disconnected);
    notifyListeners();
  }

  /// Toggle microphone MUTE/UNMUTE.
  /// The mic process stays alive — only the audio track is enabled/disabled.
  void toggleMic() {
    _micMuted = !_micMuted;
    _localMicStream?.getAudioTracks().forEach((t) {
      t.enabled = !_micMuted;
    });
    // Fire-and-forget: tell Unreal about mic state regardless of connection
    _psService.emitUIInteraction(jsonEncode({
      'type': _micMuted ? 'stop_listening' : 'start_listening',
    }));
    notifyListeners();
  }

  /// Sends swipe-delta to Unreal as a remote_input event.
  void sendOrbitInput(double deltaX, double deltaY) {
    _psService.emitUIInteraction(jsonEncode({
      'type': 'remote_input',
      'x': deltaX,
      'y': deltaY,
    }));
  }

  /// Sends a plain-text string to Unreal's Convai component.
  /// FIRE-AND-FORGET: always accepts the message, queues if channel not ready.
  /// Returns true always.
  bool sendTextToConvai(String text) {
    if (text.trim().isEmpty) return false;
    final trimmed = text.trim();

    // Local echo — show immediately in UI
    sentMessages.add(trimmed);
    if (sentMessages.length > 20) sentMessages.removeAt(0); // Keep last 20

    // Fire-and-forget to Unreal
    _psService.emitUIInteraction(jsonEncode({
      'type': 'text_input',
      'text': trimmed,
    }));
    notifyListeners();
    return true;
  }

  /// true = mic is ON (unmuted), false = mic is muted
  bool get isMicEnabled => !_micMuted;

  /// Send boarding-pass data to UE.
  bool sendBoardingData(Map<String, dynamic> data) {
    return _psService.emitUIInteraction(jsonEncode(data));
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _connectTimeoutTimer?.cancel();
    _ws?.sink.close();
    _pc?.close();
    _localMicStream?.dispose();
    renderer.dispose();
    _psService.dispose();
    super.dispose();
  }

  // ── WebSocket connection ───────────────────────────────────────────────────

  Future<bool> _tryConnect(String url) async {
    try {
      debugPrint('PixelStreamingController: trying WebSocket → $url');
      final uri = Uri.parse(url);
      final ws = WebSocketChannel.connect(uri);

      await ws.ready.timeout(
        const Duration(seconds: 6),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );

      _ws = ws;

      debugPrint('PixelStreamingController: passive mode — waiting for UE5 config+offer');

      // 20-second handshake timeout
      _connectTimeoutTimer = Timer(const Duration(seconds: 20), () {
        if (!_disposed && connectionState != PsConnectionState.streaming) {
          _handleError(
            'Signaling handshake timed out.\n'
            'Connected to $url but Unreal did not send an offer.',
          );
        }
      });

      _ws!.stream.listen(
        _onWsMessage,
        onError: (e) => _handleError('WebSocket error: $e'),
        onDone: () {
          if (_disposed) return;
          if (connectionState == PsConnectionState.streaming) {
            debugPrint('PixelStreamingController: stream closed — scheduling reconnect');
            _scheduleReconnect();
          } else if (connectionState != PsConnectionState.disconnected) {
            _handleError('Signaling server closed the connection ($url).');
          }
        },
        cancelOnError: false,
      );

      debugPrint('PixelStreamingController: WebSocket connected → $url');
      return true;
    } on TimeoutException catch (e) {
      debugPrint('PixelStreamingController: timeout on $url — $e');
      return false;
    } catch (e) {
      debugPrint('PixelStreamingController: failed on $url — $e');
      return false;
    }
  }

  void _wsSend(Map<String, dynamic> msg) {
    try {
      _ws?.sink.add(jsonEncode(msg));
    } catch (_) {}
  }

  // ── Signaling message handler ─────────────────────────────────────────────

  Future<void> _onWsMessage(dynamic raw) async {
    if (_disposed) return;

    String rawStr;
    if (raw is String) {
      rawStr = raw;
    } else if (raw is List<int>) {
      rawStr = utf8.decode(raw);
    } else {
      rawStr = raw.toString();
    }

    debugPrint('PixelStreamingController [RAW RECV] '
        '${rawStr.length > 300 ? rawStr.substring(0, 300) : rawStr}');

    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(rawStr) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = msg['type'] as String? ?? '';
    debugPrint('PixelStreamingController: ← $type');

    switch (type) {
      case 'streamerList':
        final streamers = (msg['ids'] as List?) ?? [];
        final id = streamers.isNotEmpty ? streamers.first.toString() : 'DefaultStreamer';
        debugPrint('PixelStreamingController: streamerList → subscribing to "$id"');
        _wsSend({'type': 'subscribe', 'streamerId': id});
        break;

      case 'config':
        debugPrint('PixelStreamingController: config received — subscribing immediately');
        _wsSend({'type': 'subscribe', 'streamerId': 'DefaultStreamer'});
        debugPrint('PixelStreamingController: → subscribe sent (before PC setup)');
        await _createPeerConnection(msg);
        debugPrint('PixelStreamingController: PC ready — waiting for offer');
        break;

      case 'offer':
        debugPrint('PixelStreamingController: received offer, generating answer');
        await _handleOffer(msg);
        break;

      case 'iceCandidate':
        await _handleRemoteIce(msg);
        break;

      case 'ping':
        _wsSend({'type': 'pong'});
        break;

      case 'identify':
        debugPrint('PixelStreamingController: identify → endpointIdConfirm');
        _wsSend({'type': 'endpointIdConfirm', 'id': 'player'});
        break;

      case 'playerConnected':
      case 'playerCount':
        break;

      default:
        debugPrint('PixelStreamingController: unknown message type "$type"');
        break;
    }
  }

  // ── RTCPeerConnection setup ───────────────────────────────────────────────

  Future<void> _createPeerConnection(Map<String, dynamic> configMsg) async {
    final pco = configMsg['peerConnectionOptions'] as Map<String, dynamic>? ?? configMsg;
    final rawServers = pco['iceServers'] as List? ?? [];

    final iceServers = rawServers.map((s) {
      final server = s as Map<String, dynamic>;
      return <String, dynamic>{
        'urls': server['urls'],
        if (server['username'] != null) 'username': server['username'],
        if (server['credential'] != null) 'credential': server['credential'],
      };
    }).toList();

    if (iceServers.isEmpty) {
      iceServers.add({'urls': 'stun:stun.l.google.com:19302'});
    }

    final configuration = <String, dynamic>{
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
      'iceTransportPolicy': 'all',
    };

    _pc = await createPeerConnection(configuration);

    // ── DataChannel — MUST be created BEFORE generating the answer ────────────
    final dcInit = RTCDataChannelInit()
      ..ordered = true
      ..id = 1;
    _dataChannel = await _pc!.createDataChannel('datachannel', dcInit);

    _dataChannel!.onDataChannelState = (state) {
      debugPrint('PixelStreamingController: DataChannel → $state');
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _psService.attachDataChannel(_dataChannel!);
      }
    };

    _dataChannel!.onMessage = (_) => _psService.attachDataChannel(_dataChannel!);

    // ── PERSISTENT MICROPHONE — always on, never killed ─────────────────────
    try {
      _localMicStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      for (final track in _localMicStream!.getAudioTracks()) {
        track.enabled = !_micMuted; // Respect current mute state
        await _pc!.addTrack(track, _localMicStream!);
      }
      debugPrint('PixelStreamingController: mic track attached (muted=$_micMuted)');
    } catch (e) {
      debugPrint('PixelStreamingController: mic access denied (non-fatal): $e');
    }

    // ── Remote video track → renderer ────────────────────────────────────────
    _pc!.onTrack = (event) {
      if (event.track.kind == 'video') {
        debugPrint('PixelStreamingController: video track received → streaming!');
        renderer.srcObject =
            event.streams.isNotEmpty ? event.streams.first : null;
        _connectTimeoutTimer?.cancel();
        _reconnectAttempts = 0;
        _setState(PsConnectionState.streaming);
        notifyListeners();

        // VOICE-FIRST: mic is on by default. Notify Unreal immediately.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_disposed && !_micMuted) {
            _psService.emitUIInteraction(jsonEncode({'type': 'start_listening'}));
            debugPrint('PixelStreamingController: voice-first — start_listening emitted');
          }
        });
      }
    };

    // ── Local ICE → signaling server ─────────────────────────────────────────
    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      _wsSend({
        'type': 'iceCandidate',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    // ── ICE connection state ──────────────────────────────────────────────────
    _pc!.onIceConnectionState = (state) {
      debugPrint('PixelStreamingController: ICE → $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        if (!_disposed && connectionState == PsConnectionState.streaming) {
          _scheduleReconnect();
        }
      }
    };
  }

  // ── Offer / Answer handshake ──────────────────────────────────────────────

  Future<void> _handleOffer(Map<String, dynamic> msg) async {
    if (_pc == null) {
      await _createPeerConnection({});
    }

    final sdp = msg['sdp'] as String? ?? '';
    await _pc!.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    _wsSend({'type': 'answer', 'sdp': answer.sdp});

    debugPrint('PixelStreamingController: answer sent, waiting for video track…');
    _setState(PsConnectionState.waitingForStream);
    notifyListeners();
  }

  Future<void> _handleRemoteIce(Map<String, dynamic> msg) async {
    if (_pc == null) return;
    try {
      final c = msg['candidate'] as Map<String, dynamic>? ?? msg;
      await _pc!.addCandidate(RTCIceCandidate(
        c['candidate'] as String? ?? '',
        c['sdpMid'] as String?,
        c['sdpMLineIndex'] as int?,
      ));
    } catch (_) {}
  }

  // ── DataChannel callbacks ────────────────────────────────────────────────

  void _onAiResponse(String text) {
    subtitleText = text;
    subtitleVisible = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 5), () {
      if (!_disposed && subtitleText == text) {
        subtitleVisible = false;
        notifyListeners();
      }
    });
  }

  void _onAssistantStateChange(String value) {
    assistantState = assistantStateFromString(value);
    notifyListeners();
  }

  /// Called when the DataChannel opens — notify Unreal about mic state.
  void _onChannelOpen() {
    if (!_disposed && !_micMuted) {
      _psService.emitUIInteraction(jsonEncode({'type': 'start_listening'}));
      debugPrint('PixelStreamingController: channel open — start_listening emitted');
    }
  }

  // ── Error / Reconnect — INFINITE retries ──────────────────────────────────

  void _handleError(String msg) {
    if (_disposed) return;
    debugPrint('PixelStreamingController ERROR: $msg');
    _connectTimeoutTimer?.cancel();
    errorMessage = msg;
    _setState(PsConnectionState.error);
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectAttempts++;
    // Backoff: 3s, 6s, 9s, 12s, max 15s
    final delaySec = (_reconnectAttempts * 3).clamp(3, 15);
    final delay = Duration(seconds: delaySec);
    debugPrint(
      'PixelStreamingController: reconnect attempt $_reconnectAttempts '
      'in ${delay.inSeconds}s…',
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (!_disposed) {
        await _teardown();
        await connect();
      }
    });
  }

  Future<void> _teardown() async {
    _connectTimeoutTimer?.cancel();
    await _pc?.close();
    _pc = null;
    _ws?.sink.close();
    _ws = null;
    // NOTE: We do NOT dispose _localMicStream on teardown.
    // The mic stays persistent. Only disposed in dispose().
    _dataChannel = null;
    renderer.srcObject = null;
  }

  void _setState(PsConnectionState s) {
    connectionState = s;
  }

  /// Direct UI-interaction shortcut.
  bool emitUIInteraction(Map<String, dynamic> payload) =>
      _psService.emitUIInteraction(jsonEncode(payload));
}
