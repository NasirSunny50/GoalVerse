import 'package:intl/intl.dart';

/// Shared date/time formatting helpers.
class Dates {
  Dates._();

  static final _day = DateFormat('EEE, d MMM');
  static final _dayLong = DateFormat('EEEE, d MMMM');
  static final _time = DateFormat('h:mm a'); // 12-hour, e.g. 6:00 PM
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _weekday = DateFormat('EEE');
  static final _weekdayLong = DateFormat('EEEE');
  static final _kickoff = DateFormat('EEE d MMM • h:mm a');

  static String day(DateTime d) => _day.format(d);
  static String dayLong(DateTime d) => _dayLong.format(d);
  static String time(DateTime d) => _time.format(d);
  static String monthYear(DateTime d) => _monthYear.format(d);
  static String weekday(DateTime d) => _weekday.format(d);
  static String weekdayLong(DateTime d) => _weekdayLong.format(d);
  static String kickoff(DateTime d) => _kickoff.format(d);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "2d 4h 12m" style compact countdown.
  static String countdown(Duration d) {
    if (d.isNegative) return 'LIVE';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    if (days > 0) return '${days}d ${hours}h ${mins}m';
    if (hours > 0) return '${hours}h ${mins}m ${secs}s';
    return '${mins}m ${secs}s';
  }

  static String relativeDay(DateTime d, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff < 7) return weekday(d);
    return day(d);
  }
}
