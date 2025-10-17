import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';

class LuckyRefreshHeaderPro extends StatelessWidget {
  final PullToRefreshScrollNotificationInfo? info;
  final DateTime lastRefreshTime;

  /// 触发刷新的距离（和 PullToRefreshNotification 的 maxDragOffset 对齐体验更好）
  final double triggerOffset;

  /// 主题色（箭头 / 进度 / 勾）
  final Color activeColor;

  /// 文案颜色
  final Color textColor;

  final double height;

  const LuckyRefreshHeaderPro({
    super.key,
    required this.info,
    required this.lastRefreshTime,
    this.triggerOffset = 100,
    this.height = 100,

    this.activeColor = Colors.grey,
    this.textColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    final mode = info?.mode;
    double offset = (info?.dragOffset ?? 0).clamp(0, 100);
    final progress = (offset / triggerOffset).clamp(0.0, 1.0);

    // 文案
    String tip;
    switch (mode) {
      case PullToRefreshIndicatorMode.drag:
        tip = progress >= 1 ? 'Release to refresh' : 'Pull down to refresh';
        break;
      case PullToRefreshIndicatorMode.armed:
        tip = 'Release to refresh';
        break;
      case PullToRefreshIndicatorMode.refresh:
        tip = 'Refreshing...';
        break;
      case PullToRefreshIndicatorMode.done:
        tip = 'Refresh complete';
        break;
      default:
        tip = '';
    }

    double calcHeight(double offset){
      const double minHeight = 0;
      const double maxHeight = 100;
      final double t = (offset / triggerOffset).clamp(0.0, 1.0);

      return minHeight + (maxHeight - minHeight) * Curves.easeInOut.transform(t);
    }

    return SizedBox(
      height: calcHeight(offset),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 中心内容
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              child: Padding(
                padding: EdgeInsets.only(top: 5.w),
                child: _buildCenter(mode, progress),
              ),
            ),
          ),

          // 底部文案
          if (offset > 18)
            SizedBox(
              height: offset,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: ClipRect(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tip,
                              style: TextStyle(
                                fontSize: 14.w,
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Last refreshed：${DateFormat('HH:mm:ss').format(lastRefreshTime)}',
                              style: TextStyle(
                                fontSize: 12.w,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCenter(PullToRefreshIndicatorMode? mode, double progress) {
    switch (mode) {
      case PullToRefreshIndicatorMode.refresh:
        return const _Spinner(size: 22, stroke: 2.6);
      case PullToRefreshIndicatorMode.done:
        return const _SuccessBurst(); // 勾 + 彩点爆裂
      default:
        // 箭头：跟随 progress 旋转，逼近阈值时做一点弹性缩放
        final turns = progress * math.pi; // 0 → 180°
        final scale = 0.9 + (0.1 * Curves.easeOut.transform(progress));
        return Transform.rotate(
          key: const ValueKey('arrow'),
          angle: turns,
          child: Transform.scale(
            scale: scale,
            child: const Icon(Icons.arrow_downward_rounded, size: 22, color: Colors.orange),
          ),
        );
    }
  }
}

/// 轻量加载圈（不抢主题色）
class _Spinner extends StatelessWidget {
  final double size;
  final double stroke;

  const _Spinner({required this.size, required this.stroke});

  @override
  Widget build(BuildContext context) {
    final color = Colors.orange;
    return SizedBox(
      key: const ValueKey('spinner'),
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: stroke,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// 完成：打勾 + 彩点爆裂（短动画，0 依赖）
class _SuccessBurst extends StatefulWidget {
  const _SuccessBurst();

  @override
  State<_SuccessBurst> createState() => _SuccessBurstState();
}

class _SuccessBurstState extends State<_SuccessBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  )..forward();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.orange;

    return SizedBox(
      key: const ValueKey('success'),
      width: 60,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 勾：scale + fade
          ScaleTransition(
            scale: CurvedAnimation(parent: _ctl, curve: Curves.easeOutBack),
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _ctl, curve: Curves.easeOut),
              child: Icon(Icons.check_circle_rounded, size: 22, color: color),
            ),
          ),
          // 彩点爆裂
          _DotBurst(animation: _ctl, color: color),
        ],
      ),
    );
  }
}

class _DotBurst extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const _DotBurst({required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: const SizedBox.shrink(),
      builder: (_, __) {
        final t = Curves.easeOut.transform(animation.value);
        final dots = <Widget>[];
        const count = 7;
        for (int i = 0; i < count; i++) {
          final theta = (2 * math.pi / count) * i;
          final r = 6 + 14 * t; // 半径
          final dx = r * math.cos(theta);
          final dy = r * math.sin(theta);
          dots.add(
            Positioned(
              left: 30 + dx - 2,
              top: 20 + dy - 2,
              child: Opacity(
                opacity: (1 - t).clamp(0, 1),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        }
        return Stack(children: dots);
      },
    );
  }
}
