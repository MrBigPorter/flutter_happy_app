import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/metrics/preload_metrics.dart';

class PerformanceDashboard extends StatefulWidget {
  final Widget child;
  const PerformanceDashboard({super.key, required this.child});

  @override
  State<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 每 500ms 刷新一次面板数据
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- 这是你缺失的方法 ---
  Widget _row(String label, String value, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              "$label: ",
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.normal
              )
          ),
          Text(
              value,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none
              )
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          // 悬浮层
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            right: 10,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _row("📡 Total Preloads", "${PreloadMetrics.totalPreloads}"),
                    _row("🎯 Cache Hits", "${PreloadMetrics.cacheHits}", color: Colors.greenAccent),
                    _row("💀 Cache Misses", "${PreloadMetrics.cacheMisses}", color: Colors.redAccent),
                    const SizedBox(height: 4),
                    Container(height: 1, width: 100, color: Colors.white12),
                    const SizedBox(height: 4),
                    _row("📊 Hit Rate", "${PreloadMetrics.hitRate.toStringAsFixed(1)}%"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}