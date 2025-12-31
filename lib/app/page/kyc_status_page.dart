import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart'; // 引入 Cupertino 图标，更有质感
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/providers/kyc_provider.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// KYC 状态结果页
/// 场景：提交成功后跳转、或从首页点击“KYC状态”进入
class KycStatusPage extends ConsumerStatefulWidget {
  const KycStatusPage({super.key});

  @override
  ConsumerState<KycStatusPage> createState() => _KycStatusPageState();
}

class _KycStatusPageState extends ConsumerState<KycStatusPage> {

  @override
  void initState() {
    super.initState();
    // 每次进入页面，强制刷新一次最新状态，确保数据实时
   /* WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.refresh(kycMeProvider);
    });*/
  }

  // -------------------------------------------------------
  // 1. 拦截返回键逻辑 (Product Requirement: Dead-end Page)
  // -------------------------------------------------------
  void _onPopInvoked(bool didPop) {
    if (didPop) return;
    // 既然来了这个页面，就不允许物理回退。
    // 这里什么都不做，就是“屏蔽”返回键。
  }

  // -------------------------------------------------------
  // 2. 路由跳转逻辑
  // -------------------------------------------------------
  void _goHome() {
    // 清空路由栈，回到首页
    appRouter.go('/home');
  }

  void _retryKyc() {
    // 重新开始 KYC 流程，清除之前的堆栈，防止回退循环
    appRouter.go('/me/kyc/verify');
  }

  @override
  Widget build(BuildContext context) {
    final kycAsync = ref.watch(kycMeProvider);

    // 使用 PopScope 拦截物理返回键 (Android 14 / Flutter 3.12+)
    return PopScope(
      canPop: false, // 禁止返回
      onPopInvoked: _onPopInvoked,
      child: BaseScaffold(
        showBack: false,
        // 关键点：隐藏 AppBar 左上角的返回箭头，强制用户看页面内容
        title: 'verify-process'.tr(),
        // 允许用户手动刷新状态 (Dev Bonus Feature)
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(kycMeProvider),
          )
        ],
        body: kycAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => _buildErrorView(err.toString()),
          data: (kycMe) => RefreshIndicator(
            onRefresh: () => ref.refresh(kycMeProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(minHeight: 0.8.sh),
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: _buildStatusContent(kycMe),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // 3. 状态分发工厂 (UI State Machine)
  // -------------------------------------------------------
  Widget _buildStatusContent(KycMe data) {
    // 将后端状态映射为枚举
    final status = KycStatusEnum.fromStatus(data.kycStatus);
    

    switch (status) {
      case KycStatusEnum.reviewing:
        return _StatusView(
          //  橙色沙漏：代表时间流逝、等待
          iconData: CupertinoIcons.hourglass,
          themeColor: context.utilityBrand200,
          title: 'Under Review',
          description: 'We have received your documents.\nThe review process usually takes 1-3 business days.\nPlease check back later.',
          primaryButtonText: 'Back to Home',
          onPrimaryPressed: _goHome,
        );

      case KycStatusEnum.approved:
        return _StatusView(
          // 绿色盾牌打钩：代表安全、通过
          iconData: CupertinoIcons.checkmark_shield_fill,
          themeColor: context.utilityGreen200,
          title: 'Verification Successful!',
          description: 'Congratulations! Your identity has been verified. You now have full access to all features.',
          primaryButtonText: 'Start Trading',
          onPrimaryPressed: _goHome,
        );

      case KycStatusEnum.rejected:
      case KycStatusEnum.autoRejected:
        return _StatusView(
          //  红色大叉：代表错误、停止
          iconData: CupertinoIcons.clear_circled_solid,
          themeColor: context.utilityError200,
          title: 'Verification Failed',
          // 重点：必须展示拒绝原因，否则用户会很困惑
          description: 'Sorry, your application was rejected.\n\nReason: ${data.rejectReason ?? "Document unclear or invalid."}\n\nPlease fix the issues and try again.',
          primaryButtonText: 'Try Again',
          onPrimaryPressed: _retryKyc,
          secondaryButtonText: 'Back to Home',
          onSecondaryPressed: _goHome,
        );

      case KycStatusEnum.needMore:
        return _StatusView(
          //  蓝色文档：代表需要补充材料
          iconData: CupertinoIcons.doc_text_search,
          themeColor: context.utilityBlue200,
          title: 'Action Required',
          description: 'We need some additional information to complete your verification.\n\nNote: ${data.rejectReason ?? "Please check your details."}',
          primaryButtonText: 'Update Information',
          onPrimaryPressed: _retryKyc,
          secondaryButtonText: 'Back to Home',
          onSecondaryPressed: _goHome,
        );

      default:
      // Draft 或其他未知状态
        return _StatusView(
          iconData: CupertinoIcons.person_crop_circle_badge_exclam,
          themeColor: context.utilityGray200,
          title: 'Status: ${status.label}',
          description: 'Please complete your verification to unlock full features.',
          primaryButtonText: 'Continue Verification',
          onPrimaryPressed: _retryKyc,
        );
    }
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64.w, color: Colors.grey),
          SizedBox(height: 16.h),
          Text('Failed to load status', style: TextStyle(color: Colors.grey[600], fontSize: 14.sp)),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () => ref.refresh(kycMeProvider),
            child: const Text('Tap to Retry'),
          )
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// 4. 通用状态组件 (UI Component - Premium Design)
// -------------------------------------------------------
class _StatusView extends StatelessWidget {
  final IconData iconData;
  final Color themeColor;
  final String title;
  final String description;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;

  const _StatusView({
    required this.iconData,
    required this.themeColor,
    required this.title,
    required this.description,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    // 移除 Spacer，使用 MainAxisAlignment.center 居中
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. 顶部留白 (原本是 Spacer flex: 2)
        SizedBox(height: 60.h),

        // --- ✨ 图标区域 ---
        _buildPremiumIcon(),

        SizedBox(height: 32.h),

        // --- 标题 ---
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: context.textPrimary900,
          ),
        ),

        SizedBox(height: 12.h),

        // --- 描述 ---
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              color: context.textTertiary600,
              height: 1.5,
            ),
          ),
        ),

        // 2. 中间留白 (原本是 Spacer flex: 3)
        // 这一块可以大一点，把按钮顶下去
        SizedBox(height: 80.h),

        // --- 按钮 ---
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: Button(
            onPressed: onPrimaryPressed,
            child: Text(
              primaryButtonText,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        if (secondaryButtonText != null) ...[
          SizedBox(height: 12.h),
          TextButton(
            onPressed: onSecondaryPressed,
            child: Text(
              secondaryButtonText!,
              style: TextStyle(
                fontSize: 15.sp,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        // 3. 底部留白 (原本是 Spacer flex: 1)
        SizedBox(height: 40.h),
      ],
    );
  }

  Widget _buildPremiumIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeColor.withOpacity(0.1),
          ),
        ),
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: themeColor.withOpacity(0.2),
          ),
        ),
        Icon(
          iconData,
          size: 48.w,
          color: themeColor,
        ),
      ],
    );
  }
}