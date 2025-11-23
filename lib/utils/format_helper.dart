import 'package:easy_localization/easy_localization.dart';

class FormatHelper {
  /// 金额格式化（带千分号，保留2位小数) formatCurrency(1234567.89) => ₱1,234,567.89
  /// [amount] 金额数值 amount value
  /// [symbol] 货币符号，默认 '₱' default is '₱'
  /// 返回格式化后的字符串 returns formatted currency string
  static String formatCurrency(num? amount, {String symbol = '₱'}) {
    if (amount == null) return '${symbol}0.00';
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// 数字格式化（千分号，无小数） formatNumber(1234567) => 1,234,567
  /// [number] 数值 number value
  /// 返回格式化后的字符串 returns formatted number string
  static String formatWithCommas(num? number) {
    if (number == null) return '0';
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(number);
  }

  /// 百分比格式化（保留2位小数） formatPercentage(0.1234) => 12.34%
  /// [value] 百分比数值 percentage value (0.0 to 1
  /// 返回格式化后的字符串 returns formatted percentage string
  static String formatPercentage(num? value) {
    if (value == null) return '0.00%';
    final formatter = NumberFormat.percentPattern('en_US');
    return formatter.format(value);
  }

  /// 数字格式化（千分号，带小数）
  /// formatNumberWithDecimals(1234567.89) => 1,234,567.89
  /// [number] 数值 number value
  /// [decimalDigits] 小数位数 decimal places
  /// 返回格式化后的字符串 returns formatted number string
  static String formatWithCommasAndDecimals(
    num? number, {
    int decimalDigits = 2,
  }) {
    if (number == null) return '0.00';
    final formatter = NumberFormat('#,##0.${'0' * decimalDigits}', 'en_US');
    return formatter.format(number);
  }

  /// 缩写（K/M/B），无小数
  /// formatAbbreviatedNumber(1234567) => 1.2M
  /// [number] 数值 number value
  /// 返回格式化后的字符串 returns formatted abbreviated number string
  static String formatCompact(num? n) {
    if (n == null) return '0';
    return NumberFormat.compact(locale: 'en_US').format(n);
  }

  /// 缩写（K/M/B），带小数
  /// formatCompactDecimal(1234567) => 1.23M
  /// [number] 数值 number value
  /// [decimalDigits] 小数位数 decimal places
  /// 返回格式化后的字符串 returns formatted abbreviated number string
  static String formatCompactDecimal(num? n, {int decimalDigits = 2}) {
    if (n == null) return '0';
    return NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: '', // 不要货币符号，只要 K/M
      decimalDigits: decimalDigits,
    ).format(n);
  }

  /// 解析百分比字符串为小数 parseRate('78.00') => 78
  static double parseRate(dynamic value, {target = '.00'}) {
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


