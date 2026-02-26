// ─────────────────────────────────────────────────────────────────────────────
// PixelStreamingState — Immutable state for the PixelStreamingBloc.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:equatable/equatable.dart';

import '../core/assistant_state.dart';

/// Overall pipeline connection phase.
enum StreamPhase {
  disconnected,
  connecting,
  waitingForStream,
  streaming,
  error,
}

class PixelStreamingState extends Equatable {
  /// Current connection phase.
  final StreamPhase phase;

  /// AI assistant state (driven by Unreal DataChannel messages).
  final AssistantState assistantState;

  /// Whether the microphone audio track is enabled (true = on, false = muted).
  final bool isMicEnabled;

  /// Last AI response subtitle text.
  final String subtitleText;

  /// Whether the subtitle is currently visible.
  final bool subtitleVisible;

  /// Error message (if any).
  final String errorMessage;

  /// List of texts sent by the user (for local echo display).
  final List<String> sentMessages;

  /// The most recently sent text (for echo bubble).
  final String? lastSentText;

  const PixelStreamingState({
    this.phase = StreamPhase.disconnected,
    this.assistantState = AssistantState.idle,
    this.isMicEnabled = true,
    this.subtitleText = '',
    this.subtitleVisible = false,
    this.errorMessage = '',
    this.sentMessages = const [],
    this.lastSentText,
  });

  PixelStreamingState copyWith({
    StreamPhase? phase,
    AssistantState? assistantState,
    bool? isMicEnabled,
    String? subtitleText,
    bool? subtitleVisible,
    String? errorMessage,
    List<String>? sentMessages,
    String? lastSentText,
  }) {
    return PixelStreamingState(
      phase: phase ?? this.phase,
      assistantState: assistantState ?? this.assistantState,
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      subtitleText: subtitleText ?? this.subtitleText,
      subtitleVisible: subtitleVisible ?? this.subtitleVisible,
      errorMessage: errorMessage ?? this.errorMessage,
      sentMessages: sentMessages ?? this.sentMessages,
      lastSentText: lastSentText ?? this.lastSentText,
    );
  }

  // ── Convenience getters for the UI ─────────────────────────────────────────

  bool get isStreaming => phase == StreamPhase.streaming;

  bool get isLoading =>
      phase == StreamPhase.connecting || phase == StreamPhase.disconnected;

  bool get hasError => phase == StreamPhase.error;

  String get statusLabel {
    switch (phase) {
      case StreamPhase.disconnected:
        return 'Initialising';
      case StreamPhase.connecting:
        return 'Connecting';
      case StreamPhase.waitingForStream:
        return 'Starting';
      case StreamPhase.streaming:
        return 'Ready';
      case StreamPhase.error:
        return 'Reconnecting';
    }
  }

  @override
  List<Object?> get props => [
        phase,
        assistantState,
        isMicEnabled,
        subtitleText,
        subtitleVisible,
        errorMessage,
        sentMessages,
        lastSentText,
      ];
}
