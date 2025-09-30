import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/theme/index.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 带气泡提示的进度条 BubbleProgress
/// value: 0-100
/// showTip: 是否显示气泡
/// color: 进度条颜色
/// trackHeight: 进度条高度
/// thumbSize: 圆点大小
/// duration: 动画时长
/// tipTextBuilder: 气泡文字生成函数
/// showTipBg: 是否显示气泡背景
/// 默认显示气泡背景 showTipBg = true
/// 如果只想显示文字，可以设置 showTipBg = false
class BubbleProgress extends StatelessWidget {
  final dynamic value; // 0-100
  final bool showTip;
  final Color color;
  final double trackHeight;
  final double thumbSize;
  final Duration duration;
  final bool showTipBg;
  final String Function(double)? tipTextBuilder;

  const BubbleProgress({
    super.key,
    required this.value,
    this.showTip = true,
    this.color = const Color(0xFFFF8A00),
    this.trackHeight = 4,
    this.thumbSize = 8,
    this.duration = const Duration(milliseconds: 220),
    this.tipTextBuilder,
    this.showTipBg = true,
  });

  @override
  Widget build(BuildContext context) {
    final pct = FormatHelper.parseRate(value);
    final pct01 = pct / 100;
    final topPadding = showTip ? 18.0 : 0.0;

    return SizedBox(
      height: (topPadding + trackHeight).h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 背景条
              Container(
                height: trackHeight.h,
                width: w,
                decoration: BoxDecoration(
                  color: context.utilityBrand500.withOpacity(0.4), // background color
                  borderRadius: BorderRadius.circular(trackHeight.h),
                ),
              ),

              // 前景进度条
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct01),
                duration: duration,
                curve: Curves.easeInOut,
                builder: (context, t, _) {
                  return Container(
                    height: trackHeight.h,
                    width: w * t,
                    decoration: BoxDecoration(
                      color: color, // 前景色
                      borderRadius: BorderRadius.circular(trackHeight.h),
                    ),
                  );
                },
              ),

              // 气泡跟随 thumb
              _ThumbWithTip(
                percent01: pct01,
                color: color,
                showTip: showTip,
                trackHeight: trackHeight,
                thumbSize: thumbSize,
                topOffsetForTip: topPadding,
                duration: duration,
                tipText: (tipTextBuilder ?? ((v) => "${v.toStringAsFixed(0)}%"))(pct),
                showTipBg: showTipBg,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThumbWithTip extends StatelessWidget {
  final double percent01;
  final Color color;
  final bool showTip;
  final double trackHeight;
  final bool showTipBg;
  final double thumbSize;
  final double topOffsetForTip;
  final Duration duration;
  final String tipText;

  const _ThumbWithTip({
    required this.percent01,
    required this.color,
    required this.showTip,
    required this.trackHeight,
    required this.thumbSize,
    required this.topOffsetForTip,
    required this.duration,
    required this.tipText,
    required this.showTipBg,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final endX = w * percent01;

        // 预估气泡宽度（可根据实际情况调节或测量）
        const bubbleWidth = 40.0;

        double left = endX - bubbleWidth / 2;
        if (left < 0) left = 0;
        if (left > w - bubbleWidth) left = w - bubbleWidth;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (showTip)
              AnimatedPositioned(
                duration: duration,
                curve: Curves.easeInOut,
                left: left,
                top: -(topOffsetForTip),
                child: _TipBubble(
                  text: tipText,
                  color: color,
                  showBg: showTipBg,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TipBubble extends StatelessWidget {
  final String text;
  final Color color;
  final bool showBg;

  const _TipBubble({
    required this.text,
    required this.color,
    required this.showBg,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBg) {
      // 只显示文字，轻量版 only text
      return Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          text
        ),
      );
    }

    //胶囊 + 小三角
    return Column(
      children: [
        Transform.translate(
          offset: const Offset(-16, 0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryOnBrand,
              ),
            ),
          ),
        ),
        // 小三角 triangle
        Transform.translate(
          offset: Offset(0, -1),
          child: CustomPaint(
            size: Size(8, 4),
            painter: _TrianglePainter(color),
          ),
        ),
      ],
    );
  }
}

/// 小三角 painter
class _TrianglePainter extends CustomPainter {
  final Color color;

  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
