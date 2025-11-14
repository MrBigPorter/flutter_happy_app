import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  int value = 0;
  int oldValue = 0;

  void inc() {
    if (_controller.isAnimating) return;

    oldValue = value;
    value += 1;

    _controller
      ..value = 0
      ..forward();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 👇 AnimatedBuilder 放在「整个数字区域」外面
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final oldStr = oldValue.abs().toString();
                final newStr = value.abs().toString();

                final len = newStr.length;
                final o = oldStr.padLeft(len, '0');
                final n = newStr.padLeft(len, '0');

                final oldDigits = o.split('').map(int.parse).toList();
                final newDigits = n.split('').map(int.parse).toList();

                print(oldDigits);
                print(newDigits);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < len; i++)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: RollingDigit(
                          from: oldDigits[i],
                          to: newDigits[i],
                          progress: _anim.value, // 所有位共用同一进度
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            ElevatedButton(onPressed: inc, child: const Text('add')),
          ],
        ),
      ),
    );
  }
}

class RollingDigit extends StatelessWidget {
  final int from;
  final int to;
  final double progress;
  const RollingDigit({
    super.key,
    required this.progress,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    final itemHeight = 40.w;
    final numbers = List.generate(10, (i) => i);
    final start = -from * itemHeight;
    final end = -to * itemHeight;

    final dy = start + (end - start) * progress;

    return ClipRect(
      child: Container(
        width: 100.w,
        height: itemHeight,
        decoration: BoxDecoration(color: Colors.blue),
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: itemHeight * 10,
          minHeight: itemHeight * 10,
          child: Transform.translate(
            offset: Offset(0, dy), // 假设滚到数字 5
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final n in numbers)
                  SizedBox(
                    height: itemHeight,
                    child: Text(
                      '$n',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
