// ─────────────────────────────────────────────────────────────────────────────
// AppConfig — single source of truth for all network endpoints.
//
// Environment:
//   Laptop (UE5 host) IP  : 192.168.29.106
//   Signaling server port : 8888  (standalone Cirrus / PS2 Node.js server)
//   Protocol              : ws:// (plain WebSocket, NOT wss — local network)
//
// UE5.5 launch parameter:  -PixelStreamingURL=ws://127.0.0.1:8888
//   → 127.0.0.1 is fine for Unreal talking to its OWN signaling server.
//   → The Flutter phone app MUST use the laptop's LAN IP (192.168.29.106),
//     never 127.0.0.1 (which would resolve to the phone itself and fail).
//
// How the controller uses these:
//   1. Tries  signalingUrl          (ws://192.168.29.106:8888) first.
//   2. Falls back to signalingUrlFallback (ws://192.168.29.106:80) if that
//      fails — covers the rare case of the UE5 embedded HTTP server on :80.
// ─────────────────────────────────────────────────────────────────────────────

class AppConfig {
  /// LAN IP of the Windows laptop running Unreal Engine 5.5.
  /// ⚠️  Change this if your Wi-Fi assigns a different DHCP address.
  static const String _ip = '192.168.29.106';

  /// HTTP URL where the UE5 Pixel Streaming web frontend is served (optional).
  static const String pixelStreamUrl = 'http://$_ip:8888';

  // ── WebSocket signaling URLs ───────────────────────────────────────────────

  /// PRIMARY — UE5 embedded Pixel Streaming signaling server (port 80).
  /// Confirmed working: WebSocket connected on ws://192.168.29.106:80.
  static const String signalingUrl = 'ws://$_ip:80';

  /// FALLBACK — Standalone Cirrus / Pixel Streaming 2 server (port 8888).
  /// Only tried if port 80 fails.
  static const String signalingUrlFallback = 'ws://$_ip:8888';
}
