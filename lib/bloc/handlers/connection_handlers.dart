// ─────────────────────────────────────────────────────────────────────────────
// Connection Handlers — fragmented BLoC handler file
//
// Handles: ConnectStream, ReconnectStream, DisconnectStream,
//          WsStateChanged, AppLifecyclePaused/Resumed
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config.dart';
import '../../services/websocket_service.dart';
import '../../services/webrtc_service.dart';
import '../pixel_streaming_event.dart';
import '../pixel_streaming_state.dart';

/// Mixin providing connection-related event handlers for the BLoC.
mixin ConnectionHandlers on Bloc<PixelStreamingEvent, PixelStreamingState> {
  WebsocketService get wsService;
  WebRTCService get webrtcService;

  void registerConnectionHandlers() {
    on<ConnectStream>(_onConnect);
    on<ReconnectStream>(_onReconnect);
    on<DisconnectStream>(_onDisconnect);
    on<WsStateChanged>(_onWsStateChanged);
    on<AppLifecyclePaused>(_onAppPaused);
    on<AppLifecycleResumed>(_onAppResumed);
  }

  // ── ConnectStream ─────────────────────────────────────────────────────────

  Future<void> _onConnect(
    ConnectStream event,
    Emitter<PixelStreamingState> emit,
  ) async {
    emit(state.copyWith(phase: StreamPhase.connecting, errorMessage: ''));

    // Wire up WebSocket callbacks → BLoC events
    wsService.onMessage = (raw) => add(SignalingMessageReceived(raw));
    wsService.onDisconnected = () {
      if (state.phase == StreamPhase.streaming) {
        add(const IceDisconnected());
      }
    };

    // Wire up WebRTC callbacks → BLoC events
    webrtcService.onVideoTrackReceived = () => add(const VideoTrackReceived());
    webrtcService.onIceDisconnected = () => add(const IceDisconnected());
    webrtcService.onLocalIceCandidate = (candidate) {
      wsService.send({
        'type': 'iceCandidate',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    // Wire up MessageController inbound callbacks
    webrtcService.messageController.onAiResponse = (text) {
      add(AiResponseReceived(text));
    };
    webrtcService.messageController.onStateChange = (value) {
      add(AssistantStateChanged(value));
    };
    webrtcService.messageController.onChannelOpen = () {
      add(const DataChannelOpened());
    };

    // Connect WebSocket
    final ok = await wsService.connect(
      AppConfig.signalingUrl,
      AppConfig.signalingUrlFallback,
    );

    if (!ok) {
      emit(state.copyWith(
        phase: StreamPhase.error,
        errorMessage:
            'Cannot reach signaling server.\n'
            'Tried: ${AppConfig.signalingUrl} and ${AppConfig.signalingUrlFallback}',
      ));
    }
  }

  // ── ReconnectStream ───────────────────────────────────────────────────────

  Future<void> _onReconnect(
    ReconnectStream event,
    Emitter<PixelStreamingState> emit,
  ) async {
    await webrtcService.teardown();
    await wsService.disconnect();
    add(const ConnectStream());
  }

  // ── DisconnectStream ──────────────────────────────────────────────────────

  Future<void> _onDisconnect(
    DisconnectStream event,
    Emitter<PixelStreamingState> emit,
  ) async {
    await webrtcService.teardown();
    await wsService.disconnect();
    emit(state.copyWith(phase: StreamPhase.disconnected));
  }

  // ── WsStateChanged ────────────────────────────────────────────────────────

  void _onWsStateChanged(
    WsStateChanged event,
    Emitter<PixelStreamingState> emit,
  ) {
    final wsState = WsConnectionState.values[event.stateIndex];
    switch (wsState) {
      case WsConnectionState.connecting:
        emit(state.copyWith(phase: StreamPhase.connecting));
        break;
      case WsConnectionState.error:
        emit(state.copyWith(phase: StreamPhase.error));
        break;
      case WsConnectionState.disconnected:
        emit(state.copyWith(phase: StreamPhase.disconnected));
        break;
      case WsConnectionState.connected:
        // WS connected — waiting for signaling messages
        break;
    }
  }

  // ── App Lifecycle ─────────────────────────────────────────────────────────

  void _onAppPaused(
    AppLifecyclePaused event,
    Emitter<PixelStreamingState> emit,
  ) {
    webrtcService.pauseMic();
  }

  void _onAppResumed(
    AppLifecycleResumed event,
    Emitter<PixelStreamingState> emit,
  ) {
    webrtcService.resumeMic();
  }
}
