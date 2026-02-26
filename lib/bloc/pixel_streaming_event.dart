// ─────────────────────────────────────────────────────────────────────────────
// PixelStreamingEvent — All events for the PixelStreamingBloc.
//
// Events are immutable and extend Equatable for proper deduplication.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:equatable/equatable.dart';

sealed class PixelStreamingEvent extends Equatable {
  const PixelStreamingEvent();

  @override
  List<Object?> get props => [];
}

// ── Connection Events ────────────────────────────────────────────────────────

/// Boot the entire pipeline: initialize renderer, connect WS, etc.
class ConnectStream extends PixelStreamingEvent {
  const ConnectStream();
}

/// Manually trigger a reconnect (e.g. from error toast).
class ReconnectStream extends PixelStreamingEvent {
  const ReconnectStream();
}

/// Cleanly disconnect everything.
class DisconnectStream extends PixelStreamingEvent {
  const DisconnectStream();
}

// ── User Interaction Events ──────────────────────────────────────────────────

/// Send a text message to Unreal Engine via DataChannel (fire-and-forget).
class SendTextMessage extends PixelStreamingEvent {
  final String text;
  const SendTextMessage(this.text);

  @override
  List<Object?> get props => [text];
}

/// Toggle microphone mute/unmute (never kills the mic process).
class ToggleMic extends PixelStreamingEvent {
  const ToggleMic();
}

/// Send orbit camera input from a swipe gesture.
class SendOrbitInput extends PixelStreamingEvent {
  final double deltaX;
  final double deltaY;
  const SendOrbitInput(this.deltaX, this.deltaY);

  @override
  List<Object?> get props => [deltaX, deltaY];
}

/// QR code was scanned — send boarding pass data.
class QrCodeScanned extends PixelStreamingEvent {
  final String rawValue;
  const QrCodeScanned(this.rawValue);

  @override
  List<Object?> get props => [rawValue];
}

// ── Internal WebRTC Status Events ────────────────────────────────────────────
// These are emitted internally by the BLoC from service callbacks.

/// A signaling message was received from the WebSocket.
class SignalingMessageReceived extends PixelStreamingEvent {
  final dynamic raw;
  const SignalingMessageReceived(this.raw);

  @override
  List<Object?> get props => [];
}

/// WebSocket connection state changed.
class WsStateChanged extends PixelStreamingEvent {
  final int stateIndex; // WsConnectionState ordinal
  const WsStateChanged(this.stateIndex);

  @override
  List<Object?> get props => [stateIndex];
}

/// Video track received from Unreal — streaming is live.
class VideoTrackReceived extends PixelStreamingEvent {
  const VideoTrackReceived();
}

/// ICE connection failed/disconnected — trigger reconnect.
class IceDisconnected extends PixelStreamingEvent {
  const IceDisconnected();
}

/// DataChannel opened — flush queue and send start_listening.
class DataChannelOpened extends PixelStreamingEvent {
  const DataChannelOpened();
}

/// AI response text received from Unreal.
class AiResponseReceived extends PixelStreamingEvent {
  final String text;
  const AiResponseReceived(this.text);

  @override
  List<Object?> get props => [text];
}

/// Assistant state change received from Unreal.
class AssistantStateChanged extends PixelStreamingEvent {
  final String value;
  const AssistantStateChanged(this.value);

  @override
  List<Object?> get props => [value];
}

/// App lifecycle events.
class AppLifecyclePaused extends PixelStreamingEvent {
  const AppLifecyclePaused();
}

class AppLifecycleResumed extends PixelStreamingEvent {
  const AppLifecycleResumed();
}
