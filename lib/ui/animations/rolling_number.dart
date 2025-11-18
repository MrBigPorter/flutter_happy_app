import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// rolling number widget- animate number changes by rolling digits
/// Parameters:
/// - value: Object - The value to display (int, double, String)
/// - duration: Duration - Animation duration
/// - itemHeight: double - Height of each digit item
/// - itemWidth: double - Width of each digit item
/// - enableComma: bool - Whether to enable thousands separator
/// - fractionDigits: int - Number of decimal places for double values
/// - textStyle: TextStyle? - Text style for the digits
/// - prefix: Widget? - Optional prefix widget
/// Usage:
/// ```dart
/// RollingNumber(
/// value: 12345,
/// duration: Duration(milliseconds: 800),
/// itemHeight: 40.0,
/// itemWidth: 12.0,
/// enableComma: true,
/// fractionDigits: 2,
/// textStyle: TextStyle(fontSize: 20, color: Colors.white),
/// prefix: Icon(Icons.monetization_on),
/// )
/// ```
class RollingNumber extends StatefulWidget {
  final Object value;

  final Duration duration;

  final double itemHeight;

  final double itemWidth;

  final bool enableComma;

  final int fractionDigits;

  final TextStyle? textStyle;

  final Widget? prefix;

  const RollingNumber({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 600),
    this.itemHeight = 40.0,
    this.itemWidth = 10.0,
    this.enableComma = false,
    this.fractionDigits = 0,
    this.textStyle,
    this.prefix,
  });

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  /// last formatted text value
  String _oldText = '';

  @override
  void initState() {
    super.initState();

    _oldText = _formatValue(widget.value);

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _anim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);

    // value changed: start animation
    if (oldWidget.value != widget.value) {
      _oldText = _formatValue(oldWidget.value);

      _controller
        ..stop()
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 把任意类型统一格式成字符串：
  /// - int:     "12345"
  /// - double:  按 fractionDigits 保留小数，比如 2 => "12345.67"
  /// - String:  原样 toString()
  /// 然后再：
  /// - 拆出符号位 '-'（如果有）
  /// - 拆出整数部分 / 小数部分
  /// - 给整数部分加千分位逗号（可选）
  String _formatValue(Object v) {
    String raw;

    if (v is int) {
      raw = v.toString();
    } else if (v is double) {
      raw = v.toStringAsFixed(widget.fractionDigits);
    } else {
      raw = v.toString();
    }

    raw = raw.trim();
    if (raw.isEmpty) return '0';

    // 处理负号
    String sign = '';
    if (raw.startsWith('-')) {
      sign = '-';
      raw = raw.substring(1);
    }

    // 拆整数 / 小数
    String integerPart = raw;
    String decimalPart = '';
    final dotIndex = raw.indexOf('.');
    if (dotIndex != -1) {
      integerPart = raw.substring(0, dotIndex);
      decimalPart = raw.substring(dotIndex); // 保留 "." + 小数
    }

    if (widget.enableComma) {
      integerPart = _addThousandsSeparator(integerPart);
    }

    return sign + integerPart + decimalPart;
  }

  /// 简单加千分位逗号： "1234567" -> "1,234,567"
  String _addThousandsSeparator(String digits) {
    // 非纯数字就不搞了，防止奇怪字符串
    if (digits.isEmpty || !RegExp(r'^\d+$').hasMatch(digits)) {
      return digits;
    }
    if (digits.length <= 3) return digits;

    final buffer = StringBuffer();
    final len = digits.length;
    final firstGroupLen = len % 3 == 0 ? 3 : len % 3;

    buffer.write(digits.substring(0, firstGroupLen));
    for (int i = firstGroupLen; i < len; i += 3) {
      buffer.write(',');
      buffer.write(digits.substring(i, i + 3));
    }
    return buffer.toString();
  }

  bool _isDigit(String ch) =>
      ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57; // '0' ~ '9'

  /// 右对齐取字符，不够长度的在左侧补空格
  /// maxLen: 对齐后的总长度
  /// index:  0 ~ maxLen-1
  String _charAtRightAligned(String text, int maxLen, int index) {
    final offset = maxLen - text.length;
    final i = index - offset;
    if (i < 0 || i >= text.length) return ' ';
    return text[i];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final newText = _formatValue(widget.value);

        // old / new 右对齐对齐，保证个位、十位、百位对上
        final maxLen = math.max(_oldText.length, newText.length);

        final baseStyle = (TextStyle(
          fontSize: context.textSm,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        )).merge(widget.textStyle);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.prefix != null) ...[
              widget.prefix!,
              SizedBox(width: 2.w),
            ],

            for (var i = 0; i < maxLen; i++) ...[
              Builder(
                builder: (_) {
                  final oldCh = _charAtRightAligned(_oldText, maxLen, i);
                  final newCh = _charAtRightAligned(newText, maxLen, i);

                  // 不是数字：直接静态显示（包括 '-', '.', ','，以及字母等）
                  if (!_isDigit(oldCh) || !_isDigit(newCh)) {
                    if (newCh == ' ') {
                      // 左侧补位空格：给一个固定宽度避免布局抖动
                      return SizedBox(width: widget.itemWidth);
                    }
                    return SizedBox(
                      width: widget.itemWidth,
                      child: Center(
                        child: Text(
                          newCh,
                          style: baseStyle,
                        ),
                      ),
                    );
                  }

                  // 数字：使用滚动数字组件
                  final from = int.parse(oldCh);
                  final to = int.parse(newCh);

                  return RollingDigitSmooth(
                    from: from,
                    to: to,
                    progress: _anim.value,
                    height: widget.itemHeight,
                    width: widget.itemWidth,
                    textStyle: baseStyle,
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 单个数字列：从 [from] 滚动到 [to]（0~9）
/// - 垂直堆叠 0~9
/// - 通过 [progress] 插值 offset 实现滚动
class RollingDigitSmooth extends StatelessWidget {
  final int from;
  final int to;
  final double progress;
  final double height;
  final double width;
  final TextStyle? textStyle;

  const RollingDigitSmooth({
    super.key,
    required this.from,
    required this.to,
    required this.progress,
    required this.height,
    required this.width,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final itemHeight = height;
    final numbers = List.generate(10, (i) => i);

    // 0 在最上面，往下依次 1,2,...9
    final start = -from * itemHeight;
    final end = -to * itemHeight;

    final dy = start + (end - start) * progress;

    return ClipRect(
      child: SizedBox(
        width: width,
        height: itemHeight,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: itemHeight * 10,
          maxHeight: itemHeight * 10,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final n in numbers)
                  SizedBox(
                    height: itemHeight,
                    child: Center(
                      child: Text(
                        '$n',
                        style: (TextStyle(
                          fontSize: context.textSm,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )).merge(textStyle),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}