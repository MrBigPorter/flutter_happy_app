import 'package:flutter/material.dart';
import 'dart:math';

class DefaultGroupAvatar extends StatelessWidget {
  final int count; // Number of group members
  final double size; // Widget dimensions

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
        color: const Color(0xFFF2F2F7), // Light gray background (iOS style)
        borderRadius: BorderRadius.circular(size * 0.12), // Dynamic corner radius
      ),
      child: CustomPaint(
        // Limit drawing to 9 slots max as per space constraints
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
      ..color = const Color(0xFFD1D1D6) // Placeholder grid color (Darker gray)
      ..style = PaintingStyle.fill;

    // === Layout Logic (Must match the synthesis logic in GroupAvatarService) ===

    // 1. Determine column count
    int columns = 1;
    if (count >= 2 && count <= 4) columns = 2;
    if (count >= 5) columns = 3;

    // 2. Calculate gap and cell dimensions
    // Set gap as 4% of total width
    final double gap = size.width * 0.04;
    // Formula: (Total Width - (Columns + 1) * Gap) / Columns
    final double cellSize = (size.width - (columns + 1) * gap) / columns;

    // 3. Iterative rendering
    for (int i = 0; i < count; i++) {
      int row = i ~/ columns;
      int col = i % columns;

      double x = gap + col * (cellSize + gap);
      double y = gap + row * (cellSize + gap);

      // Special handling: For a 3-item layout, the first item is centered
      if (count == 3 && i == 0) {
        x = (size.width - cellSize) / 2;
      }

      // Draw rounded rectangle for each cell
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, cellSize, cellSize),
        const Radius.circular(2), // Corner radius for individual cells
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NineGridPainter oldDelegate) {
    return oldDelegate.count != count;
  }
}