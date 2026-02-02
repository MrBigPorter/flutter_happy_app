import 'package:flutter/material.dart';
import 'dart:math';

class DefaultGroupAvatar extends StatelessWidget {
  final int count; // 成员数量
  final double size; // 控件大小

  const DefaultGroupAvatar({
    super.key,
    required this.count,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7), // 仿 iOS 浅灰背景
        borderRadius: BorderRadius.circular(size * 0.12), // 随尺寸变化的圆角
      ),
      child: CustomPaint(
        // 限制最多画 9 个格子，多了画不下
        painter: _NineGridPainter(min(count, 9)),
      ),
    );
  }
}

class _NineGridPainter extends CustomPainter {
  final int count;
  _NineGridPainter(this.count);

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0) return;

    final paint = Paint()
      ..color = const Color(0xFFD1D1D6) // 占位格子的颜色 (深一点的灰)
      ..style = PaintingStyle.fill;

    // === 布局逻辑 (必须与 GroupAvatarService 里的合成逻辑保持一致) ===

    // 1. 计算列数
    int columns = 1;
    if (count >= 2 && count <= 4) columns = 2;
    if (count >= 5) columns = 3;

    // 2. 计算间隙和格子大小
    // 设 gap 为总宽度的 4%
    final double gap = size.width * 0.04;
    // 公式: (总宽 - (列数+1)*间隙) / 列数
    final double cellSize = (size.width - (columns + 1) * gap) / columns;

    // 3. 循环绘制
    for (int i = 0; i < count; i++) {
      int row = i ~/ columns;
      int col = i % columns;

      double x = gap + col * (cellSize + gap);
      double y = gap + row * (cellSize + gap);

      //  特殊处理：如果是 3 张图，第一张图应该居中
      if (count == 3 && i == 0) {
        x = (size.width - cellSize) / 2;
      }

      // 绘制圆角矩形
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, cellSize, cellSize),
        Radius.circular(2), // 小格子的圆角
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NineGridPainter oldDelegate) {
    return oldDelegate.count != count;
  }
}