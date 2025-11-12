
import 'package:flutter/cupertino.dart';

class CardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size){

    final rect = Offset.zero & size;

    final r = RRect.fromRectAndRadius(rect,  Radius.circular(12));

    final shadow = Paint()
    ..color = const Color(0x33000000)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(r.shift(const Offset(0, 1)), shadow); // 微微向下偏移


    // 绘制卡片背景
    final fill = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFFFFFF);
    canvas.drawRRect(r, fill);

    final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFFB0B0B0);
    canvas.drawRRect(r, stroke);
    

    canvas.save();

    canvas.translate(size.width/2, size.height/2);
    canvas.drawCircle(Offset.zero, 6, Paint()..color = const Color(0xFFDC1616));
    canvas.restore();
    
    

  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}