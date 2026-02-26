// ─────────────────────────────────────────────────────────────────────────────
// WebRTCService — PeerConnection, Always-On Audio Track, DataChannel
//
// Pure service — no state management.
// Responsibilities:
//   1. Create RTCPeerConnection from ICE config.
//   2. Create DataChannel (label: "datachannel", id: 1).
//   3. Acquire persistent microphone → attach as MediaStreamTrack.
//   4. Handle offer/answer SDP exchange.
//   5. Handle ICE candidates (local → callback, remote → addCandidate).
//   6. Expose RTCVideoRenderer for video display.
//   7. Provide mute/unmute for the mic audio track (never kills the stream).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'message_controller.dart';

class WebRTCService {
  RTCPeerConnection? _pc;
  RTCDataChannel? _dataChannel;
  MediaStream? _localMicStream;
  bool _micMuted = false;

  final RTCVideoRenderer renderer = RTCVideoRenderer();
  final MessageController messageController = MessageController();

  // ── Callbacks ──────────────────────────────────────────────────────────────

  /// Fired when a local ICE candidate is generated (send to signaling server).
  void Function(RTCIceCandidate candidate)? onLocalIceCandidate;

  /// Fired when a remote video track is received (streaming started).
  VoidCallback? onVideoTrackReceived;

  /// Fired when ICE connection fails or disconnects.
  VoidCallback? onIceDisconnected;

  /// true = mic is ON (unmuted), false = muted.
  bool get isMicEnabled => !_micMuted;

  MediaStream? get localMicStream => _localMicStream;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    await renderer.initialize();
  }

  // ── PeerConnection Setup ──────────────────────────────────────────────────

  /// Creates the RTCPeerConnection, DataChannel, and attaches the microphone.
  Future<void> setupPeerConnection(Map<String, dynamic> configMsg) async {
    final pco =
        configMsg['peerConnectionOptions'] as Map<String, dynamic>? ??
            configMsg;
    final rawServers = pco['iceServers'] as List? ?? [];

    final iceServers = rawServers.map((s) {
      final server = s as Map<String, dynamic>;
      return <String, dynamic>{
        'urls': server['urls'],
        if (server['username'] != null) 'username': server['username'],
        if (server['credential'] != null) 'credential': server['credential'],
      };
    }).toList();

    if (iceServers.isEmpty) {
      iceServers.add({'urls': 'stun:stun.l.google.com:19302'});
    }

    final configuration = <String, dynamic>{
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
      'iceTransportPolicy': 'all',
    };

    _pc = await createPeerConnection(configuration);

    // ── DataChannel — MUST be created before answer ──────────────────────────
    final dcInit = RTCDataChannelInit()
      ..ordered = true
      ..id = 1;
    _dataChannel = await _pc!.createDataChannel('datachannel', dcInit);

    _dataChannel!.onDataChannelState = (state) {
      debugPrint('WebRTCService: DataChannel → $state');
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        messageController.attachDataChannel(_dataChannel!);
      }
    };

    // Fallback: onMessage may fire before onDataChannelState
    _dataChannel!.onMessage = (_) {
      if (!messageController.isConnected) {
        messageController.attachDataChannel(_dataChannel!);
      }
    };

    // ── Always-On Microphone ─────────────────────────────────────────────────
    await _attachMicrophone();

    // ── Remote video track → renderer ────────────────────────────────────────
    _pc!.onTrack = (event) {
      if (event.track.kind == 'video') {
        debugPrint('WebRTCService: video track received → streaming!');
        renderer.srcObject =
            event.streams.isNotEmpty ? event.streams.first : null;
        onVideoTrackReceived?.call();
      }
    };

    // ── Local ICE candidates → signaling ─────────────────────────────────────
    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      onLocalIceCandidate?.call(candidate);
    };

    // ── ICE connection state monitoring ──────────────────────────────────────
    _pc!.onIceConnectionState = (state) {
      debugPrint('WebRTCService: ICE → $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        onIceDisconnected?.call();
      }
    };

    debugPrint('WebRTCService: PeerConnection created');
  }

  // ── Microphone ────────────────────────────────────────────────────────────

  Future<void> _attachMicrophone() async {
    try {
      _localMicStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      for (final track in _localMicStream!.getAudioTracks()) {
        track.enabled = !_micMuted;
        await _pc!.addTrack(track, _localMicStream!);
      }
      debugPrint('WebRTCService: mic track attached (muted=$_micMuted)');
    } catch (e) {
      debugPrint('WebRTCService: mic access denied (non-fatal): $e');
    }
  }

  /// Toggle mute/unmute — track stays alive, only enabled flag changes.
  void toggleMic() {
    _micMuted = !_micMuted;
    _localMicStream?.getAudioTracks().forEach((t) {
      t.enabled = !_micMuted;
    });
    debugPrint('WebRTCService: mic ${_micMuted ? "MUTED" : "UNMUTED"}');
  }

  /// Pause mic (app lifecycle pause).
  void pauseMic() {
    _localMicStream?.getAudioTracks().forEach((t) => t.enabled = false);
  }

  /// Resume mic if not muted (app lifecycle resume).
  void resumeMic() {
    if (!_micMuted) {
      _localMicStream?.getAudioTracks().forEach((t) => t.enabled = true);
    }
  }

  // ── SDP Handshake ─────────────────────────────────────────────────────────

  /// Processes an SDP offer from Unreal and returns the SDP answer string.
  Future<String> handleOffer(String sdp) async {
    if (_pc == null) {
      await setupPeerConnection({});
    }

    await _pc!.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    debugPrint('WebRTCService: answer generated');
    return answer.sdp ?? '';
  }

  /// Adds a remote ICE candidate.
  Future<void> addRemoteIceCandidate(Map<String, dynamic> candidateMap) async {
    if (_pc == null) return;
    try {
      await _pc!.addCandidate(RTCIceCandidate(
        candidateMap['candidate'] as String? ?? '',
        candidateMap['sdpMid'] as String?,
        candidateMap['sdpMLineIndex'] as int?,
      ));
    } catch (e) {
      debugPrint('WebRTCService: failed to add ICE candidate — $e');
    }
  }

  // ── Teardown ──────────────────────────────────────────────────────────────

  /// Tears down PeerConnection and DataChannel, but keeps mic alive.
  Future<void> teardown() async {
    await _pc?.close();
    _pc = null;
    _dataChannel = null;
    renderer.srcObject = null;
    debugPrint('WebRTCService: teardown (mic stream preserved)');
  }

  /// Full dispose — including mic stream and renderer.
  void dispose() {
    _pc?.close();
    _localMicStream?.dispose();
    renderer.dispose();
    messageController.dispose();
    onLocalIceCandidate = null;
    onVideoTrackReceived = null;
    onIceDisconnected = null;
  }
}
