import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Empty extends StatelessWidget {
  const Empty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/empty.png',
        width: 152.w,
        height: 133.w,
        fit: BoxFit.cover,
      ),
    );
  }
}