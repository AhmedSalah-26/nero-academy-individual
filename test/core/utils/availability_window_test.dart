import 'package:flutter_test/flutter_test.dart';
import 'package:lms_platform/core/utils/availability_window.dart';

void main() {
  group('AvailabilityWindow', () {
    final now = DateTime.utc(2026, 6, 23, 12);

    test('is active when both boundaries are empty', () {
      expect(AvailabilityWindow.isActive(now: now), isTrue);
    });

    test('is inactive before availableFrom', () {
      expect(
        AvailabilityWindow.isActive(
          availableFrom: now.add(const Duration(minutes: 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('is active inside the availability window', () {
      expect(
        AvailabilityWindow.isActive(
          availableFrom: now.subtract(const Duration(hours: 1)),
          availableUntil: now.add(const Duration(hours: 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('is inactive at and after availableUntil', () {
      expect(
        AvailabilityWindow.isActive(
          availableUntil: now,
          now: now,
        ),
        isFalse,
      );

      expect(
        AvailabilityWindow.isActive(
          availableUntil: now.subtract(const Duration(seconds: 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('reads windows from json', () {
      expect(
        AvailabilityWindow.isJsonActive(
          {
            'available_from':
                now.subtract(const Duration(days: 1)).toIso8601String(),
            'available_until':
                now.add(const Duration(days: 1)).toIso8601String(),
          },
          now: now,
        ),
        isTrue,
      );
    });
  });
}
