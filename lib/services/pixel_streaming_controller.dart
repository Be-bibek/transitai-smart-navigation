// ─────────────────────────────────────────────────────────────────────────────
// PixelStreamingController
//
// Supports BOTH Unreal Engine Pixel Streaming protocols:
//   • Original PS  (UE5 embedded server, port 80):
//     Server drives: config → offer → client answers → ICE
//   • Pixel Streaming 2 (separate Cirrus/SFU, port 8888):
//     Client: listStreamers → subscribe → server: config → offer → ...
//
// The controller auto-detects which protocol the server uses based on
// the first message it receives, so the same code works for both.
//
// Architecture: ChangeNotifier — no extra state package required.
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

  // ── RTCVideoRenderer — give to RTCVideoView in the UI ──────────────────────
  final RTCVideoRenderer renderer = RTCVideoRenderer();

  // ── PixelStreamingService — handles DataChannel encode/decode ──────────────
  final PixelStreamingService _psService = PixelStreamingService();

  // ── Private internals ───────────────────────────────────────────────────────
  WebSocketChannel? _ws;
  RTCPeerConnection? _pc;
  RTCDataChannel? _dataChannel;
  MediaStream? _localMicStream;
  bool _micEnabled = true;
  bool _disposed = false;

  /// Exposed so AiStreamScreen can pause/resume during app lifecycle changes.
  MediaStream? get localMicStream => _localMicStream;

  // Reconnect bookkeeping
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  Timer? _connectTimeoutTimer;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    await renderer.initialize();
    _psService.onAiResponse = _onAiResponse;
    _psService.onStateChange = _onAssistantStateChange;
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

  /// Toggle device microphone mute; notifies Unreal via DataChannel.
  /// Default state is UNMUTED (voice-first) — the user opts OUT by tapping.
  void toggleMic() {
    _micEnabled = !_micEnabled;
    _localMicStream?.getAudioTracks().forEach((t) {
      t.enabled = _micEnabled;
    });
    _psService.emitUIInteraction(jsonEncode({
      'type': _micEnabled ? 'start_listening' : 'stop_listening',
    }));
    notifyListeners();
  }

  /// Sends swipe-delta to Unreal as a remote_input event so the Spring Arm
  /// rotates the Cine Camera around Vivian.
  ///
  /// Call this from the GestureDetector onPanUpdate in PixelStreamingLayer.
  void sendOrbitInput(double deltaX, double deltaY) {
    _psService.emitUIInteraction(jsonEncode({
      'type': 'remote_input',
      'x': deltaX,
      'y': deltaY,
    }));
  }

  /// Sends a plain-text string to Unreal's Convai component via the
  /// DataChannel.  Use this from the InputBar text field.
  bool sendTextToConvai(String text) {
    if (text.trim().isEmpty) return false;
    return _psService.emitUIInteraction(jsonEncode({
      'type': 'text_input',
      'text': text.trim(),
    }));
  }

  bool get isMicEnabled => _micEnabled;

  /// Send boarding-pass data (passenger_name, gate_number, flight_time) to UE.
  /// Maps to Unreal's OnPixelStreamingInputEvent Blueprint event.
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

  /// Tries to connect to [url]. Returns true if the WebSocket opened
  /// successfully (does NOT wait for signaling to complete).
  Future<bool> _tryConnect(String url) async {
    try {
      debugPrint('PixelStreamingController: trying WebSocket → $url');
      final uri = Uri.parse(url);
      final ws = WebSocketChannel.connect(uri);

      // Wait for the channel to be ready (throws if refused).
      await ws.ready.timeout(
        const Duration(seconds: 6),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );

      _ws = ws;

      // -- PASSIVE LISTEN: UE5 sends config -> offer automatically ──────────
      // The UE5 embedded Pixel Streaming server (port 80) initiates the
      // handshake: it sends {"type":"config",...} immediately after the
      // WebSocket connects, then {"type":"offer",...} right after.
      //
      // We must NOT send any messages first (listStreamers / subscribe).
      // Sending unsolicited messages caused UE5 to drop/reset the session.
      //
      // Protocol flow (UE5 PS embedded, port 80):
      //   UE5 -> config   (ICE server settings)
      //   UE5 -> offer    (SDP offer)
      //   Flutter -> answer (SDP answer)    <- we send this in _handleOffer
      //   ICE candidates exchanged -> video stream begins
      debugPrint('PixelStreamingController: passive mode — waiting for UE5 config+offer');

      // ── Start a 20-second overall connection timeout ────────────────────────
      // If we never receive a valid offer+answer, declare error.
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
          // ── FIX: handle close in ANY state, not just streaming ───────────────
          if (_disposed) return;
          if (connectionState == PsConnectionState.streaming) {
            debugPrint('PixelStreamingController: stream closed — scheduling reconnect');
            _scheduleReconnect();
          } else if (connectionState != PsConnectionState.disconnected) {
            // Closed before we got a stream — treat as error
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
  //
  // Protocol auto-detection:
  //   • If first message is 'config'  → Original Pixel Streaming (server-initiated offer)
  //   • If first message is 'streamerList' → Pixel Streaming 2 (subscribe required)

  Future<void> _onWsMessage(dynamic raw) async {
    if (_disposed) return;
    // ── Decode frame: UE5 PS sends binary WebSocket frames (Uint8List) not text.
    // raw as String throws when the frame is binary, silently dropping every
    // message. We must convert List<int> → String via utf8.decode first.
    String rawStr;
    if (raw is String) {
      rawStr = raw;
    } else if (raw is List<int>) {
      rawStr = utf8.decode(raw);
    } else {
      rawStr = raw.toString();
    }

    // RAW WIRE LOG — shows the decoded text so we can trace the protocol
    debugPrint('PixelStreamingController [RAW RECV] '
        '${rawStr.length > 300 ? rawStr.substring(0, 300) : rawStr}');

    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(rawStr) as Map<String, dynamic>;
    } catch (_) {
      return; // Ignore non-JSON frames (e.g. ping)
    }

    final type = msg['type'] as String? ?? '';
    debugPrint('PixelStreamingController: ← $type');

    switch (type) {
      // ── PS2: streamer list received → subscribe ────────────────────────────
      case 'streamerList':
        final streamers = (msg['ids'] as List?) ?? [];
        final id = streamers.isNotEmpty ? streamers.first.toString() : 'DefaultStreamer';
        debugPrint('PixelStreamingController: streamerList received -> re-subscribing to "$id"');
        _wsSend({'type': 'subscribe', 'streamerId': id});
        break;

      // ── Both protocols: ICE server config received ────────────────────────
      // ── config: create PeerConnection then send subscribe to wake UE5 ───────
      // Flow (Cirrus/UE5 embedded):
      //   server -> config   (ICE settings)
      //   client -> subscribe (tells server a player is ready)
      //   server -> playerConnected to UE5
      //   UE5    -> offer    (SDP offer forwarded via server)
      // ── config: subscribe IMMEDIATELY, then set up the PeerConnection ───────
      // CRITICAL timing: UE5's signaling server drops the connection if the
      // client doesn't respond (subscribe) within ~1-2 seconds of config.
      // _createPeerConnection() acquires the mic which can take >1s on web.
      // Solution: send subscribe FIRST so UE5 triggers the offer, THEN build
      // the PeerConnection in parallel — the offer will be processed once PC
      // is ready because it arrives as a subsequent WebSocket message.
      case 'config':
        debugPrint('PixelStreamingController: config received — subscribing immediately');
        // Step 1: Subscribe RIGHT NOW before anything async (keeps UE5 alive)
        _wsSend({'type': 'subscribe', 'streamerId': 'DefaultStreamer'});
        debugPrint('PixelStreamingController: -> subscribe sent (before PC setup)');
        // Step 2: Now build the PeerConnection — offer will arrive while we do this
        await _createPeerConnection(msg);
        debugPrint('PixelStreamingController: PC ready — waiting for offer');
        break;

      // ── Both protocols: SDP offer from Unreal ────────────────────────────
      case 'offer':
        debugPrint('PixelStreamingController: received offer, generating answer');
        await _handleOffer(msg);
        break;

      // ── ICE candidate from Unreal ─────────────────────────────────────────
      case 'iceCandidate':
        await _handleRemoteIce(msg);
        break;

      // ── Ping / pong ───────────────────────────────────────────────────────
      case 'ping':
        _wsSend({'type': 'pong'});
        break;

      // ── playerConnected / playerCount — informational, ignore ─────────────
      // ── identify: PS2 server (port 8888) asks for our endpoint ID ───────────
      // Respond with endpointIdConfirm so the server knows we are a player.
      case 'identify':
        debugPrint('PixelStreamingController: identify received -> sending endpointIdConfirm');
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
    // Support both flat and nested ICE server config formats
    final pco =
        configMsg['peerConnectionOptions'] as Map<String, dynamic>? ??
        configMsg;
    final rawServers = pco['iceServers'] as List? ?? [];

    final iceServers = rawServers.map((s) {
      final server = s as Map<String, dynamic>;
      return <String, dynamic>{
        'urls': server['urls'],
        if (server['username'] != null) 'username': server['username'],
        if (server['credential'] != null) 'credential': server['credential'],
      };
    }).toList();

    // Always ensure at least one STUN server for LAN ICE gathering
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
    // Label "datachannel" is required by UE5 Pixel Streaming Input Component.
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

    // Also handle messages directly in case onDataChannelState fires late
    _dataChannel!.onMessage = (_) => _psService.attachDataChannel(_dataChannel!);

    // ── Attach local microphone (non-fatal if denied) ─────────────────────────
    try {
      _localMicStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      for (final track in _localMicStream!.getAudioTracks()) {
        await _pc!.addTrack(track, _localMicStream!);
      }
      debugPrint('PixelStreamingController: mic track attached');
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
        _reconnectAttempts = 0; // Reset on successful stream
        _setState(PsConnectionState.streaming);
        notifyListeners();

        // ── VOICE-FIRST: mic is enabled by default. Notify Unreal immediately
        // so Convai starts in listening mode without any user action.
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_disposed && _micEnabled) {
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
      // Offer arrived before config — create a basic peer connection first
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

  // ── DataChannel → PixelStreamingService callbacks ────────────────────────

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

  // ── Error / Reconnect ─────────────────────────────────────────────────────

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
    if (_disposed || _reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: 3 * _reconnectAttempts); // backoff
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
    _localMicStream?.dispose();
    _localMicStream = null;
    _dataChannel = null;
    renderer.srcObject = null;
  }

  void _setState(PsConnectionState s) {
    connectionState = s;
  }

  /// Direct UI-interaction shortcut for the screen layer.
  bool emitUIInteraction(Map<String, dynamic> payload) =>
      _psService.emitUIInteraction(jsonEncode(payload));
}
