import 'dart:convert';

/// Represents structured boarding pass data parsed from a QR code.
class BoardingPassData {
  final String passengerName;
  final String gateNumber;
  final String flightTime;

  const BoardingPassData({
    required this.passengerName,
    required this.gateNumber,
    required this.flightTime,
  });

  // ── Factories ──────────────────────────────────────────────────────────────

  /// Parses from a JSON map (e.g. decoded from QR payload).
  factory BoardingPassData.fromJson(Map<String, dynamic> json) {
    return BoardingPassData(
      passengerName: (json['passenger_name'] as String?)?.trim() ??
          'Unknown Passenger',
      gateNumber: (json['gate_number'] as String?)?.trim() ?? 'N/A',
      flightTime: (json['flight_time'] as String?)?.trim() ?? 'N/A',
    );
  }

  /// Attempts to parse a raw QR string.
  ///
  /// Supports:
  ///   • Full JSON: `{"passenger_name":"…","gate_number":"…","flight_time":"…"}`
  ///   • Partial JSON with any of the three keys present.
  ///   • Fallback: wraps the raw string as the flight_time field.
  factory BoardingPassData.fromRawQr(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return BoardingPassData.fromJson(decoded);
      }
    } catch (_) {
      // Not valid JSON – fall through to fallback
    }

    // Fallback: treat the raw value as an opaque identifier
    return BoardingPassData(
      passengerName: 'Passenger',
      gateNumber: 'See Desk',
      flightTime: raw.length > 40 ? '${raw.substring(0, 40)}…' : raw,
    );
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'passenger_name': passengerName,
        'gate_number': gateNumber,
        'flight_time': flightTime,
      };

  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() =>
      'BoardingPassData(passenger: $passengerName, gate: $gateNumber, time: $flightTime)';
}
