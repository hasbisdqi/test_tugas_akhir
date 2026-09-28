import 'package:intl/intl.dart';

class TimezoneInfo {
  final String code;
  final String name;
  final int offsetHours;
  final String region;

  const TimezoneInfo({
    required this.code,
    required this.name,
    required this.offsetHours,
    required this.region,
  });
}

class TimezoneService {
  static const List<TimezoneInfo> supportedZones = [
    TimezoneInfo(code: 'WIB', name: 'Waktu Indonesia Barat', offsetHours: 7, region: 'Jakarta / Sumatra / Java'),
    TimezoneInfo(code: 'WITA', name: 'Waktu Indonesia Tengah', offsetHours: 8, region: 'Bali / Nusa Tenggara / Sulawesi'),
    TimezoneInfo(code: 'WIT', name: 'Waktu Indonesia Timur', offsetHours: 9, region: 'Maluku / Papua'),
    TimezoneInfo(code: 'GMT', name: 'London Greenwich Mean Time', offsetHours: 0, region: 'London / UK'),
    TimezoneInfo(code: 'EST', name: 'Eastern Standard Time', offsetHours: -5, region: 'New York / US East'),
    TimezoneInfo(code: 'JST', name: 'Japan Standard Time', offsetHours: 9, region: 'Tokyo / Japan'),
  ];

  /// Get current time in specified offset hours from UTC
  static DateTime getTimeInOffset(DateTime baseUtc, int offsetHours) {
    return baseUtc.toUtc().add(Duration(hours: offsetHours));
  }

  /// Converts a given local/specific time in fromOffset to toOffset
  static DateTime convertTime({
    required DateTime inputTime,
    required int fromOffsetHours,
    required int toOffsetHours,
  }) {
    // Determine the UTC equivalent
    final utcTime = inputTime.subtract(Duration(hours: fromOffsetHours));
    return utcTime.add(Duration(hours: toOffsetHours));
  }

  /// Formats datetime for display: HH:mm:ss dd MMM yyyy
  static String formatFullTime(DateTime dt) {
    return DateFormat('HH:mm:ss  -  EEE, dd MMM yyyy').format(dt);
  }

  /// Formats only clock time: HH:mm:ss
  static String formatClockTime(DateTime dt) {
    return DateFormat('HH:mm:ss').format(dt);
  }
}
