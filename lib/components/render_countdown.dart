import 'dart:async' as async;
import 'package:flutter/widgets.dart';
import 'package:flutter_app/utils/helper.dart';

class _Heartbeat {
  _Heartbeat._();
  static final _Heartbeat I = _Heartbeat._();

  async.Timer? _t;
  final _ctrl = async.StreamController<DateTime>.broadcast();

  Stream<DateTime> get stream {
    _ensure();
    return _ctrl.stream;
  }

  void _ensure() {
    if (_t != null) return;
    // 对齐到整秒再开始
    final now = DateTime.now();
    final delay = Duration(milliseconds: 1000 - now.millisecond);
    async.Future.delayed(delay, () {
      _t?.cancel();
      _t = async.Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_ctrl.isClosed) _ctrl.add(DateTime.now());
      });
    });
  }

  void dispose() {
    _t?.cancel();
    _t = null;
    _ctrl.close();
  }
}

class RenderCountdown extends StatefulWidget {
  final Object? lotteryTime;
  final Widget Function() renderSoldOut;
  final Widget Function(String days2) renderEnd;
  final Widget Function(String hhmmss) renderCountdown;

  const RenderCountdown({
    super.key,
    required this.lotteryTime,
    required this.renderSoldOut,
    required this.renderEnd,
    required this.renderCountdown,
  });

  @override
  State<RenderCountdown> createState() => _RenderCountdownState();
}

class _RenderCountdownState extends State<RenderCountdown> {
  async.StreamSubscription<DateTime>? _sub;
  DateTime? _target;
  Duration _left = Duration.zero;

  int _lastShownDays = -1;
  int _lastShownSec  = -1;

  @override
  void initState() {
    super.initState();
    _target = _toDateTime(widget.lotteryTime);
    _resubscribe();
  }

  @override
  void didUpdateWidget(covariant RenderCountdown old) {
    super.didUpdateWidget(old);
    if (old.lotteryTime != widget.lotteryTime) {
      _target = _toDateTime(widget.lotteryTime);
      _resubscribe();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _resubscribe() {
    _sub?.cancel();

    final t = _target;
    final now = DateTime.now();
    final left = (t == null) ? Duration.zero : t.difference(now);
    _applyLeft(left.isNegative ? Duration.zero : left);

    if (_left <= Duration.zero) return;

    if (_left >= const Duration(days: 1)) {
      // 不订阅全局心跳；等到跨入 <1 天再来
      final hours = _left - Duration(days: _left.inDays);
      async.Timer(hours > Duration.zero ? hours : const Duration(hours: 1), () {
        if (!mounted) return;
        _resubscribe();
      });
    } else {
      // 订阅全局 1Hz 心跳
      _sub = _Heartbeat.I.stream.listen((_) => _tick());
    }
  }

  void _tick() {
    final t = _target;
    if (t == null) {
      if (mounted) setState(() => _left = Duration.zero);
      return;
    }
    final d = t.difference(DateTime.now());
    final clamped = d.isNegative ? Duration.zero : d;
    _applyLeft(clamped);
  }

  void _applyLeft(Duration left) {
    if (left >= const Duration(days: 1)) {
      final d = left.inDays;
      if (d != _lastShownDays) {
        _lastShownDays = d;
        _lastShownSec  = -1;
        if (mounted) setState(() => _left = left);
      } else {
        _left = left;
      }
    } else {
      final s = left.inSeconds;
      if (s != _lastShownSec) {
        _lastShownSec  = s;
        _lastShownDays = -1;
        if (mounted) setState(() => _left = left);
      } else {
        _left = left;
      }
    }
  }

  DateTime? _toDateTime(Object? v) {
    if (v.isNullOrEmpty) return null;
    if (v is DateTime) return v;
    if (v is num) {
      final n = v.toDouble();
      final ms = n < 1e12 ? (n * 1000).toInt() : n.toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    if (v is String) {
      final asInt = int.tryParse(v);
      if (asInt != null) {
        final ms = asInt < 1000000000000 ? (asInt * 1000) : asInt;
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
      try { return DateTime.parse(v); } catch (_) { return null; }
    }
    return null;
  }

  String _pad2(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    if (_target == null || _left <= Duration.zero) {
      return widget.renderSoldOut();
    }
    if (_left >= const Duration(days: 1)) {
      return widget.renderEnd(_pad2(_left.inDays));
    }
    final hh = _pad2(_left.inHours % 24);
    final mm = _pad2(_left.inMinutes % 60);
    final ss = _pad2(_left.inSeconds % 60);
    return widget.renderCountdown('$hh:$mm:$ss');
  }
}