/// Shared availability-window helpers for courses and lessons.
class AvailabilityWindow {
  const AvailabilityWindow._();

  static DateTime? parse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static bool isActive({
    DateTime? availableFrom,
    DateTime? availableUntil,
    DateTime? now,
  }) {
    final current = (now ?? DateTime.now()).toUtc();
    final from = availableFrom?.toUtc();
    final until = availableUntil?.toUtc();

    if (from != null && current.isBefore(from)) return false;
    if (until != null && !current.isBefore(until)) return false;
    return true;
  }

  static bool isJsonActive(Map<String, dynamic> json, {DateTime? now}) {
    return isActive(
      availableFrom: parse(json['available_from']),
      availableUntil: parse(json['available_until']),
      now: now,
    );
  }
}
