
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DotsWaveLoading extends StatefulWidget{
   const DotsWaveLoading({super.key});

   @override
    State<DotsWaveLoading> createState() => _DotsWaveLoadingState();
}

class _DotsWaveLoadingState extends State<DotsWaveLoading> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late List<Animation<double>> _animations;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<Color?>> _colorAnimations;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState(){
    super.initState();
    // 创建节拍器 create ticker
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
    )..repeat();

    // 定义每个点的波动区间
    _animations = List.generate(5, (i){
      final start = i * 0.15; // 每个点延迟一点
      final end = (start + 0.6).clamp(0.0, 1.0); // 每个点持续0.6秒
      return Tween(begin: 0.0,end: -8.0 - i * 0.5).animate(
        CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeInOutSine))
      ); 
    });

    // scale animation
    _scaleAnimations = List.generate(5, (i){
      final start = i * 0.15;
      final end = (start + 0.6).clamp(0.1, 1.0);
      return Tween(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeInOutSine))
      );
    });

    // color animation
    _colorAnimations = List.generate(5, (i){
      final start = i * 0.15;
      final end = (start + 0.6).clamp(0.0, 1.0);

      return ColorTween(
        begin: Colors.grey.shade400,
        end: Colors.orange,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Interval(start, end, curve: Curves.easeInOutSine))
      );
    });


    // opacity animation
    _opacityAnimations = List.generate(5, (i){
      final start = i * 0.15;
      final end = (start + 0.6).clamp(0.0, 1.0);
       return Tween(begin: 0.7, end:1.0).animate(
         CurvedAnimation(
             parent: _controller,
             curve: Interval(start, end, curve: Interval(start, end, curve: Curves.easeInOutSine))
         ),
       );
    });

  }



  @override
  void dispose(){
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20.w,
      child: Row(
        mainAxisSize: MainAxisSize.min,//不占满整行
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        //生成5个点
        children: List.generate(5, (i){
          //根据数值去移动
          return AnimatedBuilder(
              animation: _controller,
              builder: (_,__){
                return Transform.translate(
                  //根据动画的数值去“挪动点的位置”
                  offset: Offset(0, _animations[i].value),
                  child: Transform.scale(
                    scale: _scaleAnimations[i].value,
                    child:Opacity(
                      opacity: _opacityAnimations[i].value,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 3.w),
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: _colorAnimations[i].value,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }
          );
        }),
      ),
    );
  }
}

/// 创建组件骨架 _dot create component skeleton
class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w ),
      child: Container(
        width: 8.w,
        height: 8.w,
        decoration:  BoxDecoration(
          color: context.bgBrandSolid,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}