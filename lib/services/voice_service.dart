import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Voice recognition result
// ─────────────────────────────────────────────────────────────────────────────
class VoiceResult {
  final String text;
  final bool isFinal;
  final String? detectedKeyword;

  const VoiceResult({
    required this.text,
    required this.isFinal,
    this.detectedKeyword,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// VoiceService – thin wrapper around speech_to_text
// ─────────────────────────────────────────────────────────────────────────────
class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  // ── Keyword registry (longest phrases first for greedy matching) ───────────
  static const List<String> scanKeywords = [
    'scan boarding pass',
    'open boarding pass',
    'show boarding pass',
    'boarding pass',
    'scan qr code',
    'open scanner',
    'scan qr',
    'qr code',
    'scan',
  ];

  // ── Public state ───────────────────────────────────────────────────────────
  bool get isAvailable => _initialized;
  bool get isListening => _speech.isListening;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Call once at app start. Returns `true` on success.
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onStatus: (_) {},
      onError: (SpeechRecognitionError _) {},
    );
    return _initialized;
  }

  // ── Listening ──────────────────────────────────────────────────────────────

  /// Start STT. Callbacks fire on every partial and final result.
  ///
  /// [onResult] – fired continuously with (text, isFinal, keyword or null).
  /// [onDone]   – fired when listening ends naturally (pause / timeout).
  /// [onError]  – fired on speech error.
  Future<void> startListening({
    required void Function(VoiceResult result) onResult,
    void Function()? onDone,
    void Function(String message)? onError,
    Duration listenFor = const Duration(seconds: 20),
    Duration pauseFor = const Duration(seconds: 4),
  }) async {
    if (!_initialized) return;
    if (_speech.isListening) await _speech.cancel();

    await _speech.listen(
      onResult: (SpeechRecognitionResult r) {
        final text = r.recognizedWords;
        final keyword = _detectKeyword(text.toLowerCase().trim());
        onResult(VoiceResult(
          text: text,
          isFinal: r.finalResult,
          detectedKeyword: keyword,
        ));
      },
      listenFor: listenFor,
      pauseFor: pauseFor,
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.dictation,
      onSoundLevelChange: null,
    );

    // Natural end callback
    if (onDone != null) {
      _awaitCompletion(onDone);
    }
  }

  /// Stop listening gracefully.
  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }

  /// Cancel immediately without firing callbacks.
  Future<void> cancel() async {
    if (_speech.isListening) await _speech.cancel();
  }

  // ── Keyword detection ──────────────────────────────────────────────────────

  /// Returns the first matching keyword found in [text], or `null`.
  static String? detectKeyword(String text) {
    return _detectKeyword(text.toLowerCase().trim());
  }

  static String? _detectKeyword(String lower) {
    for (final kw in scanKeywords) {
      if (lower.contains(kw)) return kw;
    }
    return null;
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _awaitCompletion(void Function() callback) async {
    // Poll until STT reports it has finished
    while (_speech.isListening) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    callback();
  }

  void dispose() {
    _speech.cancel();
  }
}
