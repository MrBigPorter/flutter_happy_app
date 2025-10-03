import 'package:flutter/material.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// BubbleProgress - 带气泡提示的进度条组件
///
/// 主要功能：
/// 1. 显示一个横向进度条
/// 2. 可选显示带气泡的进度提示
/// 3. 支持自定义气泡内容和样式
///
/// 参数说明:
/// - value: 进度值(0~100)
/// - showTip: 是否显示气泡提示
/// - color: 进度条颜色
/// - trackHeight: 进度条高度
/// - thumbSize: 拇指大小
/// - duration: 动画持续时间
/// - showTipBg: 是否显示气泡背景
/// - topPadding: 顶部内边距
/// - tipBuilder: 自定义气泡内容构建器
class BubbleProgress extends StatelessWidget {
  final dynamic value; // 进度值(0~100)
  final bool showTip; // 是否显示气泡
  final Color color; // 进度条颜色
  final double trackHeight; // 进度条高度
  final double thumbSize; // 拇指大小
  final Duration duration; // 动画持续时间
  final bool showTipBg; // 是否显示气泡背景
  final double topPadding; // 顶部内边距

  /// 自定义气泡内容构建器
  final Widget Function(double value)? tipBuilder;

  const BubbleProgress({
    super.key,
    required this.value,
    this.showTip = true,
    this.color = const Color(0xFFFF8A00),
    this.trackHeight = 4,
    this.thumbSize = 8,
    this.duration = const Duration(milliseconds: 220),
    this.tipBuilder,
    this.showTipBg = true,
    this.topPadding = 18,
  });

  @override
  Widget build(BuildContext context) {
    final pct = _parseRate(value).clamp(0, 100); // 将进度值转换为0-100的范围
    final pct01 = pct / 100.0; // 转换为0-1的比例
    final top = showTip ? topPadding : 0.0;

    return SizedBox(
      height: trackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 背景轨道 - 使用透明度较低的进度条颜色
          Container(
            width: double.infinity,
            height: trackHeight,
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: BorderRadius.circular(trackHeight),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct01),
              duration: duration,
              curve: Curves.easeInOut,
              builder: (context, t, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: t,
                  child: Container(
                    height: trackHeight,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(trackHeight),
                    ),
                  ),
                );
              },
            ),
          ),

          // 气泡提示层
          if (showTip)
            Positioned.fill(
              child: _TipFollower(
                percent01: pct01,
                duration: duration,
                topOffsetForTip: top,
                trackHeight: trackHeight,
                thumbSize: thumbSize,
                color: color,
                tip: _TipBubble(
                  color: color,
                  showBg: showTipBg,
                  child: tipBuilder != null
                      ? tipBuilder!(pct.toDouble())
                      : Text(
                    "${pct.toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 将不同类型的进度值解析为double类型
  double _parseRate(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

/// _TipFollower - 自动跟随进度的气泡容器
///
/// 负责根据进度位置计算和更新气泡位置
class _TipFollower extends StatelessWidget {
  final double percent01; // 进度比例(0-1)
  final Duration duration; // 动画时长
  final double topOffsetForTip; // 气泡顶部偏移
  final Widget tip; // 气泡内容
  final double trackHeight; // 进度条高度
  final double thumbSize; // 拇指大小
  final Color color; // 气泡颜色

  const _TipFollower({
    required this.percent01,
    required this.duration,
    required this.topOffsetForTip,
    required this.tip,
    required this.trackHeight,
    required this.thumbSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final endX = w * percent01;

        return _MeasureSize(
          onChange: (tipSize) {
            // 测量气泡尺寸用于位置调整
          },
          child: _MeasuredTip(
            percent01: percent01,
            duration: duration,
            topOffsetForTip: topOffsetForTip,
            endX: endX,
            tip: tip,
            trackHeight: trackHeight,
            thumbSize: thumbSize,
            color: color,
          ),
        );
      },
    );
  }
}

/// _MeasuredTip - 带尺寸测量的气泡组件
///
/// 负责:
/// 1. 计算气泡实际尺寸
/// 2. 控制气泡动画
/// 3. 防止气泡超出边界
class _MeasuredTip extends StatefulWidget {
  final double percent01;
  final Duration duration;
  final double topOffsetForTip;
  final double endX;
  final Widget tip;

  final double trackHeight;
  final double thumbSize;
  final Color color;

  const _MeasuredTip({
    required this.percent01,
    required this.duration,
    required this.topOffsetForTip,
    required this.endX,
    required this.tip,
    required this.trackHeight,
    required this.thumbSize,
    required this.color,
  });

  @override
  State<_MeasuredTip> createState() => _MeasuredTipState();
}

class _MeasuredTipState extends State<_MeasuredTip> {
  Size _tipSize = Size.zero; // 气泡尺寸

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        final tipW = _tipSize.width > 0 ? _tipSize.width : 40.0;

        // 计算气泡位置,确保不超出边界
        double left = widget.endX - tipW / 2;
        if (left < 0) left = 0;
        if (left > w - tipW) left = w - tipW;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 气泡
            AnimatedPositioned(
              duration: widget.duration,
              curve: Curves.easeInOut,
              left: left,
              top: -widget.topOffsetForTip,
              child: _MeasureSize(
                onChange: (size) {
                  if (size != _tipSize) {
                    setState(() => _tipSize = size);
                  }
                },
                child: widget.tip,
              ),
            ),
            // 拇指
            Positioned(
              left: widget.endX - 4,
              top: (widget.trackHeight / 2) - (widget.thumbSize / 2) ,
              child: Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: context.utilityBrand500,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// _MeasureSize - Widget尺寸测量组件
///
/// 用于测量子Widget的实际渲染尺寸
class _MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const _MeasureSize({required this.child, required this.onChange});

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

/// _MeasureSizeState - 尺寸测量状态管理
class _MeasureSizeState extends State<_MeasureSize> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = context.size;
      if (size != null) {
        widget.onChange(size);
      }
    });
    return widget.child;
  }
}

/// _TipBubble - 气泡外观组件
///
/// 定义气泡的视觉样式,包括:
/// - 圆角矩形背景
/// - 小三角指示器
class _TipBubble extends StatelessWidget {
  final Widget child;
  final Color color;
  final bool showBg;

  const _TipBubble({
    required this.child,
    required this.color,
    required this.showBg,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBg) return child;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 气泡主体
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: child,
        ),
        // 小三角指示器
        CustomPaint(size: const Size(8, 4), painter: _TrianglePainter(color)),
      ],
    );
  }
}

/// _TrianglePainter - 小三角绘制器
///
/// 使用CustomPainter绘制气泡底部的三角形指示器
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
