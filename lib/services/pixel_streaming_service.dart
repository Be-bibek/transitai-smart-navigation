import 'dart:convert';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Handles bidirectional communication with Unreal Engine over the Pixel
/// Streaming WebRTC DataChannel.
///
/// ── Outbound (Flutter → Unreal) ──────────────────────────────────────────────
/// Wire format mirrors player.html's `emitUIInteraction()`:
///   [0]      uint8   – Message type  = 50  (UIInteraction)
///   [1..2]   uint16  – String length in UTF-16 code units (little-endian)
///   [3..]    uint16* – String as UTF-16LE code units
///
/// ── Inbound (Unreal → Flutter) ────────────────────────────────────────────────
/// Unreal sends plain UTF-8 JSON strings over the same DataChannel.
/// Expected formats:
///   { "type": "ai_response", "text": "..spoken sentence.." }
///   { "type": "state",       "value": "idle | listening | processing | speaking" }
///
/// FIRE-AND-FORGET ARCHITECTURE:
///   Messages are queued when the DataChannel is not yet open.
///   Once attached and open, the queue flushes automatically.
///   This removes the "logic block" that prevented sending before streaming.
class PixelStreamingService {
  // ── Message type constants ────────────────────────────────────────────────

  /// Pixel Streaming message-type for UI interactions (outbound).
  static const int _kUIInteraction = 50;

  // ── Internal state ────────────────────────────────────────────────────────

  RTCDataChannel? _dataChannel;

  /// Messages queued before the DataChannel opened.
  final Queue<String> _pendingMessages = Queue<String>();

  // ── Public callbacks ──────────────────────────────────────────────────────

  /// Called when Unreal sends an AI response text.
  /// `{ "type": "ai_response", "text": "…" }`
  void Function(String text)? onAiResponse;

  /// Called when Unreal reports a state change.
  /// `{ "type": "state", "value": "idle | listening | processing | speaking" }`
  void Function(String value)? onStateChange;

  /// Called when the DataChannel opens (so the controller can react).
  VoidCallback? onChannelOpen;

  // ── Channel management ────────────────────────────────────────────────────

  /// Attach an open [RTCDataChannel] so messages can be sent and received.
  void attachDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;

    // Listen for messages arriving FROM Unreal Engine.
    _dataChannel!.onMessage = (RTCDataChannelMessage message) {
      _handleIncomingMessage(message);
    };

    // Flush any queued messages now that the channel is open.
    _flushPending();

    onChannelOpen?.call();
  }

  /// Returns `true` when a channel is attached and open.
  bool get isConnected =>
      _dataChannel != null &&
      _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen;

  // ── Outbound API ──────────────────────────────────────────────────────────

  /// Sends [jsonString] to Unreal Engine as a UI-interaction event.
  ///
  /// FIRE-AND-FORGET: if the channel is not ready, the message is queued
  /// and will be sent automatically once the channel opens.
  /// Always returns `true` (message accepted).
  bool emitUIInteraction(String jsonString) {
    if (isConnected) {
      _sendRaw(jsonString);
    } else {
      // Queue the message — it will be sent when the channel opens.
      _pendingMessages.add(jsonString);
      debugPrint('PixelStreamingService: queued message (channel not ready)');
    }
    return true;
  }

  void _sendRaw(String jsonString) {
    try {
      final bytes = _encodeUIInteraction(jsonString);
      _dataChannel!.send(RTCDataChannelMessage.fromBinary(bytes));
    } catch (e) {
      debugPrint('PixelStreamingService: send failed — $e');
    }
  }

  void _flushPending() {
    if (!isConnected) return;
    while (_pendingMessages.isNotEmpty) {
      final msg = _pendingMessages.removeFirst();
      debugPrint('PixelStreamingService: flushing queued message');
      _sendRaw(msg);
    }
  }

  // ── Inbound handling ──────────────────────────────────────────────────────

  void _handleIncomingMessage(RTCDataChannelMessage raw) {
    try {
      // Unreal sends plain text JSON strings.  If binary, decode as UTF-8.
      final String jsonStr = raw.isBinary
          ? utf8.decode(raw.binary)
          : raw.text;

      final Map<String, dynamic> msg =
          jsonDecode(jsonStr) as Map<String, dynamic>;

      final String? type = msg['type'] as String?;

      switch (type) {
        case 'ai_response':
          final text = msg['text'] as String? ?? '';
          if (text.isNotEmpty) onAiResponse?.call(text);
          break;

        case 'state':
          final value = msg['value'] as String? ?? 'idle';
          onStateChange?.call(value);
          break;

        default:
          // Unknown message type – silently ignored.
          break;
      }
    } catch (_) {
      // Malformed JSON or unexpected binary payload – silently ignored.
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Encodes [text] into the Pixel Streaming UIInteraction binary format.
  Uint8List _encodeUIInteraction(String text) {
    final units = text.codeUnits; // UTF-16LE code units
    final totalBytes = 1 + 2 + units.length * 2;

    final buffer = ByteData(totalBytes);
    buffer.setUint8(0, _kUIInteraction);              // Message type
    buffer.setUint16(1, units.length, Endian.little); // String length
    for (int i = 0; i < units.length; i++) {
      buffer.setUint16(3 + i * 2, units[i], Endian.little); // UTF-16LE chars
    }

    return buffer.buffer.asUint8List();
  }

  void dispose() {
    _dataChannel = null;
    _pendingMessages.clear();
    onAiResponse = null;
    onStateChange = null;
    onChannelOpen = null;
  }
}
