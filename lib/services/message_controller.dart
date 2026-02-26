// ─────────────────────────────────────────────────────────────────────────────
// MessageController — Binary encoding + Fire-and-Forget queue
//
// Encodes strings into Pixel Streaming UIInteraction binary format:
//   [0]      uint8   – Message type  = 50  (UIInteraction)
//   [1..2]   uint16  – String length in UTF-16 code units (little-endian)
//   [3..]    uint16* – String as UTF-16LE code units
//
// Messages are queued when the DataChannel is not yet open and
// auto-flushed when attachDataChannel() is called.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../core/constants.dart';

/// Callbacks for inbound DataChannel messages from Unreal Engine.
typedef OnAiResponseCallback = void Function(String text);
typedef OnStateChangeCallback = void Function(String value);

class MessageController {
  RTCDataChannel? _dataChannel;

  /// Messages queued before the DataChannel opened.
  final Queue<String> _pendingMessages = Queue<String>();

  // ── Inbound callbacks ──────────────────────────────────────────────────────
  OnAiResponseCallback? onAiResponse;
  OnStateChangeCallback? onStateChange;

  /// Called when the DataChannel opens.
  VoidCallback? onChannelOpen;

  // ── Channel management ────────────────────────────────────────────────────

  /// Attach an open [RTCDataChannel]. Immediately flushes any queued messages.
  void attachDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;

    _dataChannel!.onMessage = (RTCDataChannelMessage message) {
      _handleIncoming(message);
    };

    // Flush any messages that were queued while waiting for the channel.
    _flushPending();
    onChannelOpen?.call();
  }

  /// Whether the DataChannel is attached and in the open state.
  bool get isConnected =>
      _dataChannel != null &&
      _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen;

  // ── Outbound API — Fire-and-Forget ─────────────────────────────────────────

  /// Sends [jsonString] to Unreal as a UIInteraction binary payload.
  ///
  /// If the channel is not open, the message is **queued** and will be sent
  /// automatically once [attachDataChannel] is called. Always returns `true`.
  bool sendUIInteraction(String jsonString) {
    if (isConnected) {
      _sendBinary(jsonString);
    } else {
      _pendingMessages.add(jsonString);
      debugPrint('MessageController: queued message (channel not ready)');
    }
    return true;
  }

  /// Convenience: encode a Map to JSON and send.
  bool sendMap(Map<String, dynamic> payload) =>
      sendUIInteraction(jsonEncode(payload));

  // ── Binary encoding ───────────────────────────────────────────────────────

  void _sendBinary(String text) {
    try {
      final bytes = encodeUIInteraction(text);
      _dataChannel!.send(RTCDataChannelMessage.fromBinary(bytes));
    } catch (e) {
      debugPrint('MessageController: send failed — $e');
    }
  }

  /// Encodes [text] into the Pixel Streaming UIInteraction binary format.
  ///
  /// This is a public static method so it can be unit tested independently.
  static Uint8List encodeUIInteraction(String text) {
    final units = text.codeUnits; // UTF-16LE code units
    final totalBytes = 1 + 2 + units.length * 2;

    final buffer = ByteData(totalBytes);
    buffer.setUint8(0, PsMessageType.uiInteraction);
    buffer.setUint16(1, units.length, Endian.little);
    for (int i = 0; i < units.length; i++) {
      buffer.setUint16(3 + i * 2, units[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  // ── Queue flush ───────────────────────────────────────────────────────────

  void _flushPending() {
    if (!isConnected) return;
    while (_pendingMessages.isNotEmpty) {
      final msg = _pendingMessages.removeFirst();
      debugPrint('MessageController: flushing queued message');
      _sendBinary(msg);
    }
  }

  // ── Inbound handling ──────────────────────────────────────────────────────

  void _handleIncoming(RTCDataChannelMessage raw) {
    try {
      final String jsonStr =
          raw.isBinary ? utf8.decode(raw.binary) : raw.text;

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
          // Unknown inbound message — silently ignored.
          break;
      }
    } catch (_) {
      // Malformed JSON — silently ignored.
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void dispose() {
    _dataChannel = null;
    _pendingMessages.clear();
    onAiResponse = null;
    onStateChange = null;
    onChannelOpen = null;
  }
}
