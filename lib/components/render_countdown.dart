import 'dart:async' as async;
import 'package:flutter/widgets.dart';

import '../utils/time/server_time_helper.dart';

/// ---------------------------------------------------------------------------
/// 1. 全局心跳管理 (单例)
/// 核心优化：确保页面上所有倒计时整秒同步跳动，全局仅需一个 Timer。
/// ---------------------------------------------------------------------------
class _Heartbeat {
  _Heartbeat._();
  static final _Heartbeat I = _Heartbeat._();

  async.Timer? _t;
  final _ctrl = async.StreamController<DateTime>.broadcast();

  /// 获取心跳流
  Stream<DateTime> get stream {
    _ensure();
    return _ctrl.stream;
  }

  void _ensure() {
    if (_t != null) return;
    // 对齐到下一秒的开始，让所有倒计时数字同步切换，增加视觉高级感
    final now = ServerTimeHelper.now;
    final delay = Duration(milliseconds: 1000 - now.millisecond);

    async.Future.delayed(delay, () {
      _t?.cancel();
      _t = async.Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_ctrl.isClosed) _ctrl.add(ServerTimeHelper.now);
      });
    });
  }

  void dispose() {
    _t?.cancel();
    _t = null;
    _ctrl.close();
  }
}

/// ---------------------------------------------------------------------------
/// 2. 智能高性能倒计时组件
/// ---------------------------------------------------------------------------
class RenderCountdown extends StatefulWidget {
  /// 支持 DateTime, num (秒或毫秒), String (数字或ISO格式)
  final Object? lotteryTime;

  /// 归零或无数据时的占位 (如显示：Activity Ended)
  final Widget Function() renderSoldOut;

  /// 超过 1 天时的显示逻辑 (days2 为格式化后的天数)
  final Widget Function(String days2) renderEnd;

  /// 1 天以内的倒计时显示 (hhmmss 为 00:00:00 格式)
  final Widget Function(String hhmmss) renderCountdown;

  /// 倒计时结束回调：用于通知父组件刷新状态（如从“预售”变为“立即拼团”）
  final VoidCallback? onFinished;

  const RenderCountdown({
    super.key,
    required this.lotteryTime,
    required this.renderSoldOut,
    required this.renderEnd,
    required this.renderCountdown,
    this.onFinished,
  });

  @override
  State<RenderCountdown> createState() => _RenderCountdownState();
}

class _RenderCountdownState extends State<RenderCountdown> {
  async.StreamSubscription<DateTime>? _sub;
  DateTime? _target;

  /// ✨ 性能优化 A: 使用 ValueNotifier 实现局部刷新。
  /// 心跳触发时，只刷新显示文字的小插件，不触发整个 State 的 build。
  late final ValueNotifier<Duration> _leftNotifier;

  @override
  void initState() {
    super.initState();
    _leftNotifier = ValueNotifier(Duration.zero);
    _initTarget();
  }

  void _initTarget() {
    _target = _toDateTime(widget.lotteryTime);
    _resubscribe();
  }

  @override
  void didUpdateWidget(covariant RenderCountdown old) {
    super.didUpdateWidget(old);
    // 当目标时间变化时（例如业务从“预售”切到“开团”），重置倒计时
    if (old.lotteryTime != widget.lotteryTime) {
      _initTarget();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _leftNotifier.dispose(); // 必须销毁，防止内存泄漏
    super.dispose();
  }

  void _resubscribe() {
    _sub?.cancel();
    final t = _target;
    if (t == null) {
      _leftNotifier.value = Duration.zero;
      return;
    }

    final now = ServerTimeHelper.now;
    final left = t.difference(now);

    if (left.isNegative || left == Duration.zero) {
      _leftNotifier.value = Duration.zero;
      _handleFinished();
      return;
    }

    _leftNotifier.value = left;
    // 订阅全局单例心跳，不再单独开启 Timer
    _sub = _Heartbeat.I.stream.listen((_) => _tick());
  }

  void _tick() {
    final t = _target;
    if (t == null) return;

    final now = ServerTimeHelper.now;
    final d = t.difference(now);

    if (d.isNegative || d.inSeconds <= 0) {
      _sub?.cancel();
      _leftNotifier.value = Duration.zero;
      _handleFinished();
    } else {
      // ✨ 性能优化 B: 只有值真正改变时才触发刷新
      if (d.inSeconds != _leftNotifier.value.inSeconds) {
        _leftNotifier.value = d;
      }
    }
  }

  void _handleFinished() {
    if (mounted) {
      // 触发回调，让外部组件（如 ProductCard）更新状态
      widget.onFinished?.call();
    }
  }

  /// 智能识别：自动判断秒、毫秒、时间对象或字符串
  DateTime? _toDateTime(Object? v) {
    if (v == null || v == '') return null;
    if (v is DateTime) return v;

    if (v is num) {
      final n = v.toInt();
      // 逻辑判断：100亿以下认为是秒(10位)，以上认为是毫秒(13位)
      return DateTime.fromMillisecondsSinceEpoch(n < 10000000000 ? n * 1000 : n);
    }

    if (v is String) {
      final asInt = int.tryParse(v);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt < 10000000000 ? asInt * 1000 : asInt);
      }
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _pad2(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    // ✨ 性能优化 C: 使用 ValueListenableBuilder 替代 setState。
    // 这确保了每秒的心跳只重绘 Builder 内部的 Text，而卡片其他部分保持静止。
    return ValueListenableBuilder<Duration>(
      valueListenable: _leftNotifier,
      builder: (context, left, _) {
        if (_target == null || left <= Duration.zero) {
          return widget.renderSoldOut();
        }

        // 超过 1 天的显示模式 (例如：02 Days Left)
        if (left >= const Duration(days: 1)) {
          return widget.renderEnd(_pad2(left.inDays));
        }

        // 1 天以内的显示模式 (例如：12:30:45)
        final hh = _pad2(left.inHours);
        final mm = _pad2(left.inMinutes % 60);
        final ss = _pad2(left.inSeconds % 60);

        // ✨ 性能优化 D: 加入 RepaintBoundary
        // 告诉渲染引擎，这部分数字是独立变化的，不要影响到周围组件的重绘。
        return RepaintBoundary(
          child: widget.renderCountdown('$hh:$mm:$ss'),
        );
      },
    );
  }
}