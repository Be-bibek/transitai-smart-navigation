// ─────────────────────────────────────────────────────────────────────────────
// WebRTC Handlers — fragmented BLoC handler file
//
// Handles: SignalingMessageReceived, VideoTrackReceived, IceDisconnected,
//          DataChannelOpened, SendTextMessage, ToggleMic, SendOrbitInput,
//          QrCodeScanned, AiResponseReceived, AssistantStateChanged
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/assistant_state.dart';
import '../../core/constants.dart';
import '../../services/websocket_service.dart';
import '../../services/webrtc_service.dart';
import '../pixel_streaming_event.dart';
import '../pixel_streaming_state.dart';

/// Mixin providing WebRTC + interaction event handlers for the BLoC.
mixin WebrtcHandlers on Bloc<PixelStreamingEvent, PixelStreamingState> {
  WebsocketService get wsService;
  WebRTCService get webrtcService;

  Timer? _handshakeTimer;
  Timer? _subtitleTimer;

  void registerWebrtcHandlers() {
    on<SignalingMessageReceived>(_onSignalingMessage);
    on<VideoTrackReceived>(_onVideoTrack);
    on<IceDisconnected>(_onIceDisconnected);
    on<DataChannelOpened>(_onDataChannelOpened);
    on<SendTextMessage>(_onSendText);
    on<ToggleMic>(_onToggleMic);
    on<SendOrbitInput>(_onSendOrbit);
    on<QrCodeScanned>(_onQrScanned);
    on<AiResponseReceived>(_onAiResponse);
    on<AssistantStateChanged>(_onAssistantStateChanged);
  }

  void disposeWebrtcHandlers() {
    _handshakeTimer?.cancel();
    _subtitleTimer?.cancel();
  }

  // ── Signaling Message Dispatch ────────────────────────────────────────────

  Future<void> _onSignalingMessage(
    SignalingMessageReceived event,
    Emitter<PixelStreamingState> emit,
  ) async {
    // Decode: UE5 may send binary WebSocket frames
    String rawStr;
    if (event.raw is String) {
      rawStr = event.raw as String;
    } else if (event.raw is List<int>) {
      rawStr = utf8.decode(event.raw as List<int>);
    } else {
      rawStr = event.raw.toString();
    }

    debugPrint('BLoC [RAW RECV] '
        '${rawStr.length > 300 ? rawStr.substring(0, 300) : rawStr}');

    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(rawStr) as Map<String, dynamic>;
    } catch (_) {
      return; // Non-JSON (ping frame etc.)
    }

    final type = msg['type'] as String? ?? '';
    debugPrint('BLoC: ← $type');

    switch (type) {
      // PS2: streamer list → subscribe
      case 'streamerList':
        final streamers = (msg['ids'] as List?) ?? [];
        final id =
            streamers.isNotEmpty ? streamers.first.toString() : 'DefaultStreamer';
        wsService.send({'type': 'subscribe', 'streamerId': id});
        break;

      // Config → subscribe + create PeerConnection
      case 'config':
        debugPrint('BLoC: config received — subscribing immediately');
        wsService.send({'type': 'subscribe', 'streamerId': 'DefaultStreamer'});

        // Start handshake timeout
        _handshakeTimer?.cancel();
        _handshakeTimer = Timer(
          Duration(seconds: ReconnectConfig.handshakeTimeoutSec),
          () {
            if (state.phase != StreamPhase.streaming) {
              emit(state.copyWith(
                phase: StreamPhase.error,
                errorMessage: 'Signaling handshake timed out.',
              ));
            }
          },
        );

        await webrtcService.setupPeerConnection(msg);
        emit(state.copyWith(phase: StreamPhase.connecting));
        break;

      // SDP Offer → generate answer
      case 'offer':
        debugPrint('BLoC: offer received, generating answer');
        final sdp = msg['sdp'] as String? ?? '';
        final answerSdp = await webrtcService.handleOffer(sdp);
        wsService.send({'type': 'answer', 'sdp': answerSdp});
        emit(state.copyWith(phase: StreamPhase.waitingForStream));
        break;

      // ICE candidate from Unreal
      case 'iceCandidate':
        final c = msg['candidate'] as Map<String, dynamic>? ?? msg;
        await webrtcService.addRemoteIceCandidate(c);
        break;

      // Ping/pong
      case 'ping':
        wsService.send({'type': 'pong'});
        break;

      // PS2 identify handshake
      case 'identify':
        wsService.send({'type': 'endpointIdConfirm', 'id': 'player'});
        break;

      case 'playerConnected':
      case 'playerCount':
        break;

      default:
        debugPrint('BLoC: unknown signaling type "$type"');
        break;
    }
  }

  // ── Video Track Received ──────────────────────────────────────────────────

  void _onVideoTrack(
    VideoTrackReceived event,
    Emitter<PixelStreamingState> emit,
  ) {
    _handshakeTimer?.cancel();
    wsService.resetReconnectCounter();
    emit(state.copyWith(phase: StreamPhase.streaming));

    // Voice-first: notify Unreal that mic is active
    Future.delayed(const Duration(milliseconds: 500), () {
      if (state.isMicEnabled) {
        webrtcService.messageController.sendMap({'type': 'start_listening'});
      }
    });
  }

  // ── ICE Disconnected ──────────────────────────────────────────────────────

  Future<void> _onIceDisconnected(
    IceDisconnected event,
    Emitter<PixelStreamingState> emit,
  ) async {
    debugPrint('BLoC: ICE disconnected — triggering reconnect');
    emit(state.copyWith(phase: StreamPhase.error));
    // Reconnect will be handled by WebsocketService's exponential backoff
    await webrtcService.teardown();
    add(const ConnectStream());
  }

  // ── DataChannel Opened ────────────────────────────────────────────────────

  void _onDataChannelOpened(
    DataChannelOpened event,
    Emitter<PixelStreamingState> emit,
  ) {
    debugPrint('BLoC: DataChannel opened — start_listening');
    if (state.isMicEnabled) {
      webrtcService.messageController.sendMap({'type': 'start_listening'});
    }
  }

  // ── Send Text Message (Fire-and-Forget) ────────────────────────────────────

  void _onSendText(
    SendTextMessage event,
    Emitter<PixelStreamingState> emit,
  ) {
    final text = event.text.trim();
    if (text.isEmpty) return;

    // Queue for local echo
    final updatedSent = List<String>.from(state.sentMessages)..add(text);
    if (updatedSent.length > 20) updatedSent.removeAt(0);

    // Fire-and-forget: send regardless of connection state
    webrtcService.messageController.sendMap({
      'type': 'text_input',
      'text': text,
    });

    emit(state.copyWith(
      sentMessages: updatedSent,
      lastSentText: text,
    ));
  }

  // ── Toggle Mic (Mute/Unmute) ──────────────────────────────────────────────

  void _onToggleMic(
    ToggleMic event,
    Emitter<PixelStreamingState> emit,
  ) {
    webrtcService.toggleMic();
    final isNowEnabled = webrtcService.isMicEnabled;

    // Notify Unreal (fire-and-forget)
    webrtcService.messageController.sendMap({
      'type': isNowEnabled ? 'start_listening' : 'stop_listening',
    });

    emit(state.copyWith(isMicEnabled: isNowEnabled));
  }

  // ── Send Orbit Input ──────────────────────────────────────────────────────

  void _onSendOrbit(
    SendOrbitInput event,
    Emitter<PixelStreamingState> emit,
  ) {
    webrtcService.messageController.sendMap({
      'type': 'remote_input',
      'x': event.deltaX,
      'y': event.deltaY,
    });
  }

  // ── QR Code Scanned ───────────────────────────────────────────────────────

  void _onQrScanned(
    QrCodeScanned event,
    Emitter<PixelStreamingState> emit,
  ) {
    webrtcService.messageController.sendMap({
      'type': 'text_input',
      'text':
          'User has scanned a boarding pass. '
          'Gate: A12, Flight: EK202. '
          'Please confirm these details with the user warmly.',
    });
  }

  // ── AI Response Received ──────────────────────────────────────────────────

  void _onAiResponse(
    AiResponseReceived event,
    Emitter<PixelStreamingState> emit,
  ) {
    emit(state.copyWith(
      subtitleText: event.text,
      subtitleVisible: true,
    ));

    // Auto-hide after 5 seconds
    _subtitleTimer?.cancel();
    _subtitleTimer = Timer(const Duration(seconds: 5), () {
      if (state.subtitleText == event.text) {
        // ignore: invalid use of visible for testing member
        // We can't emit from a Timer in BLoC, so we use add() instead
        // This is handled by a separate event if needed.
        // For simplicity, subtitle visibility is managed in the UI layer.
      }
    });
  }

  // ── Assistant State Changed ───────────────────────────────────────────────

  void _onAssistantStateChanged(
    AssistantStateChanged event,
    Emitter<PixelStreamingState> emit,
  ) {
    emit(state.copyWith(
      assistantState: assistantStateFromString(event.value),
    ));
  }
}
