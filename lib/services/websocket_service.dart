// ─────────────────────────────────────────────────────────────────────────────
// WebsocketService — Exponential Backoff Reconnection
//
// Pure service — no state management, no business logic.
// Responsibilities:
//   1. Connect to a WebSocket URL with timeout.
//   2. On disconnect/error, automatically reconnect with exponential backoff.
//   3. Forward raw messages to a callback for the BLoC to handle.
//   4. Provide a send() method for outbound signaling messages.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/constants.dart';

/// Connection state of the WebSocket layer.
enum WsConnectionState { disconnected, connecting, connected, error }

class WebsocketService {
  WebSocketChannel? _ws;
  StreamSubscription? _subscription;

  WsConnectionState _state = WsConnectionState.disconnected;
  WsConnectionState get state => _state;

  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  String? _activeUrl;
  String? _fallbackUrl;

  /// Called when a raw message (String or bytes) arrives.
  void Function(dynamic raw)? onMessage;

  /// Called when connection state changes.
  void Function(WsConnectionState state)? onStateChange;

  /// Called when the WebSocket connection is lost unexpectedly.
  VoidCallback? onDisconnected;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Attempts to connect to [primaryUrl], falls back to [fallbackUrl].
  /// Returns `true` if a connection was established.
  Future<bool> connect(String primaryUrl, String fallbackUrl) async {
    _activeUrl = primaryUrl;
    _fallbackUrl = fallbackUrl;
    _reconnectTimer?.cancel();

    _setState(WsConnectionState.connecting);

    // Try primary first
    bool ok = await _tryConnect(primaryUrl);
    if (!ok) {
      debugPrint('WebsocketService: primary failed, trying fallback…');
      ok = await _tryConnect(fallbackUrl);
    }

    if (!ok) {
      _setState(WsConnectionState.error);
      _scheduleReconnect();
    }

    return ok;
  }

  /// Sends a JSON-encodable map over the WebSocket.
  void send(Map<String, dynamic> msg) {
    try {
      _ws?.sink.add(jsonEncode(msg));
    } catch (e) {
      debugPrint('WebsocketService: send error — $e');
    }
  }

  /// Cleanly close the WebSocket without triggering reconnect.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    await _close();
    _setState(WsConnectionState.disconnected);
  }

  /// Reset the reconnect counter (e.g. after a successful stream).
  void resetReconnectCounter() {
    _reconnectAttempts = 0;
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _close();
    onMessage = null;
    onStateChange = null;
    onDisconnected = null;
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<bool> _tryConnect(String url) async {
    try {
      debugPrint('WebsocketService: connecting → $url');
      final uri = Uri.parse(url);
      final ws = WebSocketChannel.connect(uri);

      await ws.ready.timeout(
        Duration(seconds: ReconnectConfig.wsReadyTimeoutSec),
        onTimeout: () => throw TimeoutException('WS connect timeout'),
      );

      _ws = ws;

      _subscription = _ws!.stream.listen(
        (raw) => onMessage?.call(raw),
        onError: (e) {
          debugPrint('WebsocketService: stream error — $e');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('WebsocketService: stream closed');
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      debugPrint('WebsocketService: connected → $url');
      _setState(WsConnectionState.connected);
      _reconnectAttempts = 0;
      return true;
    } on TimeoutException catch (e) {
      debugPrint('WebsocketService: timeout on $url — $e');
      return false;
    } catch (e) {
      debugPrint('WebsocketService: failed on $url — $e');
      return false;
    }
  }

  void _handleDisconnect() {
    if (_state == WsConnectionState.disconnected) return;
    onDisconnected?.call();
    _scheduleReconnect();
  }

  /// Exponential backoff: delay = base * (multiplier ^ attempt), capped.
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    final delaySec = min(
      ReconnectConfig.maxDelaySec,
      (ReconnectConfig.baseDelaySec *
              pow(ReconnectConfig.backoffMultiplier, _reconnectAttempts - 1))
          .round(),
    );

    debugPrint(
      'WebsocketService: reconnect #$_reconnectAttempts in ${delaySec}s '
      '(exponential backoff)',
    );

    _setState(WsConnectionState.error);

    _reconnectTimer = Timer(Duration(seconds: delaySec), () async {
      if (_activeUrl != null && _fallbackUrl != null) {
        await _close();
        await connect(_activeUrl!, _fallbackUrl!);
      }
    });
  }

  Future<void> _close() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _ws?.sink.close();
    } catch (_) {}
    _ws = null;
  }

  void _setState(WsConnectionState s) {
    if (_state == s) return;
    _state = s;
    onStateChange?.call(s);
  }
}
