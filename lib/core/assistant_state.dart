// ─────────────────────────────────────────────────────────────────────────────
// AssistantState – canonical four-state enum for the AI assistant.
//
// All conversational logic is controlled by Unreal Engine. Flutter only
// visualises state transitions received via the Pixel Streaming DataChannel.
// ─────────────────────────────────────────────────────────────────────────────

/// The four states the AI assistant can be in.
///
/// Transitions are driven by Unreal Engine sending JSON messages of the form:
///   `{ "type": "state", "value": "listening | processing | speaking | idle" }`
enum AssistantState {
  /// Mic is in normal standby.  No animations active.
  idle,

  /// User audio is being captured and forwarded to the AI backend.
  /// Mic button shows a pulsing waveform animation.
  listening,

  /// Unreal is processing the user request.
  /// Subtle loading-glow animation on the mic button.
  processing,

  /// Unreal's MetaHuman is speaking. Subtitle box is visible.
  /// Mic button shows an active speaking glow.
  speaking,
}

/// Convenience: parse a raw string value from the DataChannel message.
/// Accepts both 'processing' and 'thinking' for the thinking state so
/// Unreal can send either form.
AssistantState assistantStateFromString(String value) {
  switch (value.toLowerCase().trim()) {
    case 'listening':
      return AssistantState.listening;
    case 'processing':
    case 'thinking':         // alias: Unreal may send either
      return AssistantState.processing;
    case 'speaking':
      return AssistantState.speaking;
    default:
      return AssistantState.idle;
  }
}
