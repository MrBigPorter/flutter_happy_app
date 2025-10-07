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
  final Color textColor; // 文案颜色
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
    this.textColor =  Colors.white,
    this.trackHeight = 4,
    this.thumbSize = 8,
    this.duration = const Duration(milliseconds: 220),
    this.tipBuilder,
    this.showTipBg = true,
    this.topPadding = 4,
  });

  /// 将不同类型的进度值解析为double类型
  double _parseRate(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final pct = _parseRate(value).clamp(0, 100); // 将进度值转换为0-100的范围
    final pct01 = pct / 100.0; // 转换为0-1的比例

    return LayoutBuilder(
      builder: (_, constraints) {
        final w = constraints.maxWidth;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // text tip and bubble tip
            _AutoMoveTip(
              topPadding: topPadding,
              thumbSize: thumbSize,
              trackHeight: trackHeight,
              tipBuilder: tipBuilder,
              showTipBg: showTipBg,
              showTip: showTip,
              pct: pct.toDouble(),
              pct01: pct01,
              color: color,
              textColor: textColor,
              duration: duration,
              w:w
            ),
            if(showTip) SizedBox(height: topPadding.h),
            // progress bar with thumb
            TweenAnimationBuilder(
              tween: Tween(begin: 0, end: pct01),
              duration: duration,
              builder: (context, t, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // background track
                    Container(
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 200),
                        borderRadius: BorderRadius.circular(trackHeight),
                      ),
                    ),
                    // filled track
                    FractionallySizedBox(
                      widthFactor: t.toDouble(),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: trackHeight,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(trackHeight),
                        ),
                      ),
                    ),
                    // thumb
                    Positioned(
                       left: (w - thumbSize) * t,
                      child: Container(
                        width: thumbSize.w,
                        height: thumbSize.w,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _AutoMoveTip extends StatefulWidget {
  final bool showTip; // 是否显示气泡
  final Color color; // 进度条颜色
  final Color textColor; // 文案颜色
  final double trackHeight; // 进度条高度
  final double thumbSize; // 拇指大小
  final Duration duration; // 动画持续时间
  final bool showTipBg; // 是否显示气泡背景
  final double topPadding; // 顶部内边距
  final double pct; // 进度值 0-100
  final double pct01; // 进度值 0-100
  final double w; // parent width

  /// 自定义气泡内容构建器
  final Widget Function(double value)? tipBuilder;

  const _AutoMoveTip({
    required this.showTip,
    required this.color,
    required this.textColor,
    required this.trackHeight,
    required this.duration,
    required this.showTipBg,
    required this.thumbSize,
    required this.topPadding,
    this.tipBuilder,
    required this.pct,
    required this.pct01,
    required this.w
});

    @override
  State<_AutoMoveTip> createState() => _AutoMoveTipState();

}

class _AutoMoveTipState extends State<_AutoMoveTip> {
   Size _tipSize = Size.zero;

    @override
    Widget build(BuildContext context){
      if(!widget.showTip) return SizedBox.shrink();

      // default tip width to void layout shift
      final tipW = _tipSize.width > 0 ? _tipSize.width : 36;
      final thumbCenter = (widget.w - widget.thumbSize);
      double left = (widget.pct01 * thumbCenter) - tipW/2 + widget.thumbSize.w/2;
      if(!widget.showTipBg){
        // for text tip, keep it in the progress bar
        left = left.clamp(0, widget.w - tipW);
      }
      // tip text above the progress bar
      if (widget.showTip){
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: Offset(left, 0),
              child: _MeasureSize(
                  onChange:(size){
                    if(size != _tipSize){
                      setState(() {
                        _tipSize = size;
                      });
                    }
                  },
                  child: _TipBubble(
                    key: ValueKey(widget.pct.toStringAsFixed(0)),
                    color: widget.color,
                    showBg: widget.showTipBg,
                    child: widget.tipBuilder != null
                        ? widget.tipBuilder!(widget.pct.toDouble())
                        : Text(
                      '${widget.pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10.w,
                        fontWeight: FontWeight.w600,
                        color: widget.textColor,
                      ),
                    ),
                  )
              ),
            )
          ],
        );
      }
      return SizedBox.shrink();
    }

}


/// _MeasureSize - Widget尺寸测量组件
///
/// 用于测量子Widget的实际渲染尺

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
    // 页面渲染完成后获取尺寸 get size after frame render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(!mounted) return;
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
    super.key,
    required this.child,
    required this.color,
    required this.showBg,
  });

  @override
  Widget build(BuildContext context) {
    // only show text when showBg is false
    if (!showBg) return child;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 气泡主体
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.w),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: child,
        ),
        // 小三角指示器
        CustomPaint(size:  Size(8.w, 4.w), painter: _TrianglePainter(color)),
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
