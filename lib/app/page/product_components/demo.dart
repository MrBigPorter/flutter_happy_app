import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MoveBoxDemo extends StatefulWidget {
  const MoveBoxDemo({super.key});

  @override
  State<MoveBoxDemo> createState() => _MoveBoxDemoState();
}

class _MoveBoxDemoState extends State<MoveBoxDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim; // 0 ~ 1 的进度

  @override
  void initState() {
    super.initState();

    // 1. 时间轴：0 -> 1，耗时 600ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 2. 曲线：让运动更顺一点（不是生硬线性）
    _anim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // 3. 监听：每一帧 setState，一直重建
    _controller.addListener(() {
      setState(() {});
    });

    // 4. 开始播放
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 当前进度 t：0 ~ 1
    final t = _anim.value;

    // 把 t 映射成“位移”，比如从 100 到 0
    final dy = 100 * (1 - t); // t=0 时 100，t=1 时 0

    return Scaffold(
      body: Center(
        child: Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            width: 80,
            height: 40,
            color: Colors.orange,
            alignment: Alignment.center,
            child: const Text('我是方块'),
          ),
        ),
      ),
    );
  }
}