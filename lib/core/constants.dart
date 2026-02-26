// ─────────────────────────────────────────────────────────────────────────────
// Pixel Streaming Protocol Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Pixel Streaming binary message type IDs (outbound).
class PsMessageType {
  PsMessageType._();

  /// UIInteraction — JSON string sent to Unreal's OnPixelStreamingInputEvent.
  static const int uiInteraction = 50;

  /// UIDescriptor — less commonly used, reserved for future.
  static const int uiDescriptor = 51;
}

/// Reconnection strategy constants.
class ReconnectConfig {
  ReconnectConfig._();

  /// Base delay between reconnect attempts (seconds).
  static const int baseDelaySec = 2;

  /// Maximum delay between reconnect attempts (seconds).
  static const int maxDelaySec = 30;

  /// Multiplier for exponential backoff.
  static const double backoffMultiplier = 1.5;

  /// WebSocket ready timeout (seconds).
  static const int wsReadyTimeoutSec = 6;

  /// Signaling handshake timeout (seconds).
  static const int handshakeTimeoutSec = 20;
}
