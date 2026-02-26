// ─────────────────────────────────────────────────────────────────────────────
// PixelStreamingBloc — James Rhys Potter BLoC-Service Architecture
//
// The BLoC owns the services and delegates event handling to fragmented
// handler mixins (ConnectionHandlers + WebrtcHandlers).
//
// Services (pure, no state management):
//   • WebsocketService — exponential backoff reconnection
//   • WebRTCService    — PeerConnection, always-on mic, DataChannel
//   • MessageController — binary encoding + fire-and-forget queue (inside WebRTCService)
//
// The UI reads state via BlocBuilder and triggers events via context.read<>.add().
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/websocket_service.dart';
import '../services/webrtc_service.dart';
import 'handlers/connection_handlers.dart';
import 'handlers/webrtc_handlers.dart';
import 'pixel_streaming_event.dart';
import 'pixel_streaming_state.dart';

class PixelStreamingBloc
    extends Bloc<PixelStreamingEvent, PixelStreamingState>
    with ConnectionHandlers, WebrtcHandlers {
  // ── Services — owned by the BLoC ──────────────────────────────────────────

  @override
  final WebsocketService wsService = WebsocketService();

  @override
  final WebRTCService webrtcService = WebRTCService();

  // ── Constructor ───────────────────────────────────────────────────────────

  PixelStreamingBloc() : super(const PixelStreamingState()) {
    // Register fragmented handlers
    registerConnectionHandlers();
    registerWebrtcHandlers();
  }

  // ── Public accessors for the UI ───────────────────────────────────────────

  /// The RTCVideoRenderer for RTCVideoView in the widget tree.
  get renderer => webrtcService.renderer;

  /// Initialize the renderer before the first build.
  Future<void> initialize() async {
    await webrtcService.initialize();
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  Future<void> close() async {
    disposeWebrtcHandlers();
    wsService.dispose();
    webrtcService.dispose();
    return super.close();
  }
}
