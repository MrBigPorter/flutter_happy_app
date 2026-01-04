import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 引入触感反馈
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 你的项目依赖
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/app/routes/app_router.dart';

class InsufficientBalanceSheet extends StatelessWidget {
  final VoidCallback close;

  const InsufficientBalanceSheet({super.key, required this.close});

  @override
  Widget build(BuildContext context) {
    // 移除 decoration，背景色和圆角完全由父级 BottomSheet 控制
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Stack(
        clipBehavior: Clip.none, // 关键：允许图标超出顶部边界
        children: [
          // -----------------------------------------------------------
          // 1. 顶部悬浮图标 (核心视觉中心)
          // -----------------------------------------------------------
          Positioned(
            top: -40.h, // 向上破位
            left: 0,
            right: 0,
            child: Center(
              child: _buildFloatingIcon(context)
                  // [Layer 1] 持续呼吸动画 (循环播放)
                  // 等入场动画做完(约800ms)后再开始呼吸，避免冲突
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scaleXY(
                    begin: 1.0,
                    end: 1.1,
                    duration: 2.seconds,
                    curve: Curves.easeOut,
                    delay: 800.ms,
                  )
                  // [Layer 2] 持续流光动画 (循环播放)
                  // 每隔3秒闪过一道光，保持关注度
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                    duration: 1800.ms,
                    color: Colors.white54,
                    delay: 3.seconds,
                  )
                  // [Layer 3] 入场掉落动画 (只播一次)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(
                    begin: -1.5, // 提得更高，掉下来的冲击感更强
                    end: 0.0,
                    duration: 800.ms,
                    curve: Curves.easeOutBack, // Q弹的回弹曲线
                  )
                  // 添加轻微震动反馈，提升触感体验
                  .callback(callback: (_)=>HapticFeedback.lightImpact())
            ),
          ),

          // -----------------------------------------------------------
          // 2. 内容区域
          // -----------------------------------------------------------
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 为顶部图标留出空间 (40w 悬浮 + 额外视觉缓冲区)
              SizedBox(height: 55.h),

              // 标题：加粗 + 入场位移
              Text(
                'wallet.balance.insufficient'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textPrimary900,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800, // 增加字重，提升权威感
                  letterSpacing: -0.5,
                )
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3,end: 0.0,duration: 500.ms,curve: Curves.easeOutQuad),

              SizedBox(height: 12.h),

              // 描述：大行高 + 灰色
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  'wallet.balance.insufficient.tip'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textTertiary600,
                    fontSize: 14.sp,
                    height: 1.6, // 增加行高，提升阅读舒适度
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              SizedBox(height: 32.h),

              // -----------------------------------------------------------
              // 3. 操作按钮区
              // -----------------------------------------------------------

              // 主按钮：带流光引导
              Button(
                width: double.infinity,
                height: 52.h,
                onPressed: () {
                  close();
                  appRouter.push('/me/wallet');
                },
                child: Text(
                  'common.to.recharge'.tr(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              // 按钮也加一个微妙的循环光效，暗示“点我”
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(delay: 4.seconds,duration: 1200.ms,color: Colors.white24)
              // 按钮入场动画
              .animate()
              .fadeIn(delay: 600.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 800.ms, curve: Curves.elasticOut),
              SizedBox(height: 12.h),

              // 次按钮：降级为纯文本链接
              _buildSecondaryButton(context)
              .animate().fadeIn(delay: 800.ms),

              // 底部安全距离 + 留白
              SizedBox(height: 32.h + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ],
      )
      // 整体卡片的一个轻微上滑入场，配合 ModalBottomSheet 自带的动画会更丝滑
      .animate().slideY(
        begin: 0.1,
        end: 0.0,
        duration: 300.ms,
        curve: Curves.easeOut,
      )
    );
  }

  // --- 组件封装 ---

  Widget _buildFloatingIcon(BuildContext context) {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        // 必须给图标加背景色，遮挡住弹窗顶部的线条
        color: context.bgPrimary,
        shape: BoxShape.circle,
        boxShadow: [
          // 柔和的阴影，制造悬浮感
          BoxShadow(
            color: context.utilityBrand500.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: context.utilityBrand500.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.account_balance_wallet_rounded,
          size: 36.w,
          color: context.utilityBrand500,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return InkWell(
      onTap: close,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
        // 增加点击热区
        child: Text(
          'common.cancel'.tr(),
          style: TextStyle(
            color: context.textQuaternary500, // 使用更淡的颜色
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
