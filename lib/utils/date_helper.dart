import 'package:intl/intl.dart';

/// date toolkit
/// supports parsing int timestamp (seconds or milliseconds), String date, DateTime
/// and provides various formatting methods
/// 日期工具包 date toolkit
/// 支持解析 int 时间戳（秒或毫秒）、String 时间、DateTime 本身 parsing int timestamp (seconds or milliseconds), String date, DateTime
/// 并提供多种格式化方法 various formatting methods
/// example:
/// ```dart
/// DateFormatHelper.format(DateTime.now(), 'yyyy/MM/dd HH:mm'); // '2021/10/01 12:00'
/// DateFormatHelper.formatFull(1633072800); // '10-01 00:
/// DateFormatHelper.formatDate('2021-10-01T00:00:00Z'); // '2021-10-01'
/// DateFormatHelper.friendly(DateTime.now().subtract(Duration(hours: 5))); // '5 h ago'
/// DateFormatHelper.toTimestamp('2021-10-01T00:00:00Z'); // 1633072800000
/// ```
class DateFormatHelper {
  /// 通用解析器，支持：
  /// int 秒 or 毫秒时间戳、String 时间、DateTime 本身
  static DateTime? _parse(dynamic time) {
    if (time == null) return null;
    print('time: $time, type: ${time.runtimeType}');

    if (time is int) {

      final isSeconds = time.toString().length == 10;
      return DateTime.fromMillisecondsSinceEpoch(
        isSeconds ? time * 1000 : time,
      ).toLocal();
    }

    if (time is String) {
      try {
        return DateTime.parse(time).toLocal();
      } catch (_) {
        return null;
      }
    }

    if (time is DateTime) return time.toLocal();

    return null;
  }

  /// 自由格式化
  static String format(dynamic time, String pattern) {
    final dt = _parse(time);
    if (dt == null) return '';
    return DateFormat(pattern).format(dt);
  }

  static String formatFull(dynamic time) {
    return format(time, 'MM-dd HH:mm:ss yyyy');
  }

  /// 常用：仅日期
  static String formatDate(dynamic time) {
    return format(time, 'yyyy-MM-dd');
  }

  /// 常用：仅时间
  static String formatTime(dynamic time) {
    return format(time, 'HH:mm:ss');
  }

  /// 常用：MM-dd HH:mm
  static String formatMonthDayTime(dynamic time) {
    return format(time, 'MM-dd HH:mm');
  }

  /// 提示类：几分钟前/几小时前/昨天
  static String friendly(dynamic time) {
    final dt = _parse(time);
    if (dt == null) return '';

    final diff = DateTime.now().difference(dt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return formatDate(time);
  }

  /// 转时间戳（毫秒）
  static int toTimestamp(dynamic time) {
    final dt = _parse(time);
    return dt?.millisecondsSinceEpoch ?? 0;
  }
}