import 'package:easy_localization/easy_localization.dart';

class FormatHelper {
  /// 通用：把传进来的东西转成 num
  /// 支持 num / String，其他情况返回 null
  static num? _toNum(Object? value) {
    if (value == null) return null;
    if (value is num) return value;

    if (value is String) {
      // 去掉可能的货币符号、逗号空格之类（看需要，可以更严格）
      final clean = value.replaceAll(',', '').trim();
      final parsed = double.tryParse(clean);
      return parsed;
    }

    return null;
  }

  /// 金额格式化（带千分号，保留2位小数)
  /// 支持传 num / String
  static String formatCurrency(Object? amount, {String symbol = '₱'}) {
    final n = _toNum(amount);
    if (n == null) return '${symbol}0.00';

    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(n);
  }

  /// 数字格式化（千分号，无小数）
  static String formatWithCommas(Object? number) {
    final n = _toNum(number);
    if (n == null) return '0';

    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(n);
  }

  /// 百分比格式化（保留2位小数） value 可以是 num / String
  static String formatPercentage(Object? value) {
    final n = _toNum(value);
    if (n == null) return '0.00%';

    final formatter = NumberFormat.percentPattern('en_US');
    return formatter.format(n);
  }

  /// 数字格式化（千分号，带小数）
  static String formatWithCommasAndDecimals(
      Object? number, {
        int decimalDigits = 2,
      }) {
    final n = _toNum(number);
    if (n == null) {
      return decimalDigits == 0 ? '0' : '0.${'0' * decimalDigits}';
    }

    final formatter = NumberFormat('#,##0.${'0' * decimalDigits}', 'en_US');
    return formatter.format(n);
  }

  /// 缩写（K/M/B），无小数
  static String formatCompact(Object? n) {
    final v = _toNum(n);
    if (v == null) return '0';
    return NumberFormat.compact(locale: 'en_US').format(v);
  }

  /// 缩写（K/M/B），带小数
  static String formatCompactDecimal(Object? n, {int decimalDigits = 2}) {
    final v = _toNum(n);
    if (v == null) return '0';
    return NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: decimalDigits,
    ).format(v);
  }

  /// 解析百分比字符串为 0~100 的数值
  static double parseRate(dynamic value, {String target = '.00'}) {
    if (value == null) return 0;

    if (value is num) return value.toDouble().clamp(0, 100);

    if (value is String) {
      final clean = value.replaceAll(target, '');
      final parsed = double.tryParse(clean) ?? 0;
      return parsed.clamp(0, 100);
    }
    return 0;
  }
}