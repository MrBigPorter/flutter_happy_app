import 'dart:async' as async;
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/utils/helper.dart';

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
  async.Timer? _timer;
  DateTime? _target;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _target = _toDateTime(widget.lotteryTime);
    _start();
  }

  @override
  void didUpdateWidget(covariant RenderCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if(oldWidget.lotteryTime != widget.lotteryTime){
      _target = _toDateTime(widget.lotteryTime);
      _start();
    }

  }

  void _start() {
    _timer?.cancel();
    _tick();
    _timer = async.Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final t = _target;
    if (t == null) {
      if (mounted) {
        setState(() {
          _left = Duration.zero;
        });
      }
      return;
    }
    final now = DateTime.now();
    final d = t.difference(now);
    if (mounted) {
      setState(() {
        _left = (d.isNegative ? Duration.zero : d);
      });
    }
  }

  DateTime? _toDateTime(Object? v) {
    if(v.isNullOrEmpty) return null;
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
      // ISO 8601，如 "2025-10-02T12:00:00Z"
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
    /// overtime
    if (_target == null || _left <= Duration.zero) {
      return widget.renderSoldOut();
    }

    /// last 24 hours show hh:mm:ss
    if (_left >= const Duration(days: 1)) {
      final days = _pad2(
        _left.inDays,
      ); // 左侧补零保持两位 add leading zero to keep two digits
      return widget.renderEnd(days);
    }

    /// show hh:mm:ss
    final hh = _pad2(_left.inHours % 24);
    final mm = _pad2(_left.inMinutes % 60);
    final ss = _pad2(_left.inSeconds % 60);

    return widget.renderCountdown('$hh:$mm:$ss');
  }
}
