import 'package:flutter/material.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  double _lastOffset = 0;
  double _lastDelta = 0;
  double _speed = 0;
  double _accel = 0;
  String _status = "静止";

  // 👇 可调参数
  double _accelThreshold = -10;
  double _speedThreshold = 20;

  void _onScroll(ScrollNotification n) {
    final current = n.metrics.pixels;
    final delta = current - _lastOffset;
    final accel = delta - _lastDelta;

    _lastOffset = current;
    _lastDelta = delta;
    _speed = delta;
    _accel = accel;

    String s;
    if (accel > 5) {
      s = "🟢 风变强";
    } else if (accel < _accelThreshold && delta.abs() > _speedThreshold) {
      s = "🟡 风变弱";
    } else if (accel < _accelThreshold && delta.abs() < _speedThreshold) {
      s = "🔴 预测反滑";
    } else {
      s = "⚪ 匀速";
    }

    setState(() => _status = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🌬️ 风阻仪表调试器")),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                _onScroll(n);
                return false;
              },
              child: ListView.builder(
                itemCount: 80,
                itemBuilder: (context, i) => ListTile(
                  title: Text("Item $i"),
                ),
              ),
            ),
          ),
          _buildDashboard(),
          _buildSliders(),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(12),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Speed: ${_speed.toStringAsFixed(2)}"),
            Text("Accel: ${_accel.toStringAsFixed(2)}"),
            Text("Status: $_status"),
          ],
        ),
      ),
    );
  }

  Widget _buildSliders() {
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("风衰减阈值（acceleration）: ${_accelThreshold.toStringAsFixed(1)}",
              style: const TextStyle(color: Colors.white)),
          Slider(
            value: _accelThreshold,
            min: -50,
            max: 0,
            divisions: 50,
            label: _accelThreshold.toStringAsFixed(1),
            onChanged: (v) => setState(() => _accelThreshold = v),
          ),
          const SizedBox(height: 10),
          Text("风停阈值（speed）: ${_speedThreshold.toStringAsFixed(1)}",
              style: const TextStyle(color: Colors.white)),
          Slider(
            value: _speedThreshold,
            min: 5,
            max: 100,
            divisions: 20,
            label: _speedThreshold.toStringAsFixed(1),
            onChanged: (v) => setState(() => _speedThreshold = v),
          ),
        ],
      ),
    );
  }
}