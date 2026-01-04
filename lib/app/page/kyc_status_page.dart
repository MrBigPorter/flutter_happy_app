import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/providers/kyc_provider.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KycStatusPage extends ConsumerStatefulWidget {
  const KycStatusPage({super.key});

  @override
  ConsumerState<KycStatusPage> createState() => _KycStatusPageState();
}

class _KycStatusPageState extends ConsumerState<KycStatusPage> {
  void _onPopInvoked(bool didPop) {
    if (didPop) return;
  }

  void _goHome() => appRouter.go('/home');
  void _retryKyc() => appRouter.go('/me/kyc/verify');

  @override
  Widget build(BuildContext context) {
    final kycAsync = ref.watch(kycMeProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: _onPopInvoked,
      child: BaseScaffold(
        showBack: false,
        title: 'verify-process'.tr(),
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

  Widget _buildStatusContent(KycMe data) {
    final status = KycStatusEnum.fromStatus(data.kycStatus);

    switch (status) {
      case KycStatusEnum.reviewing:
        return _StatusView(
          status: status,
          iconData: CupertinoIcons.hourglass,
          themeColor: context.utilityBrand200,
          title: 'Under Review',
          description: 'We have received your documents.\nThe review process usually takes 1-3 business days.',
          primaryButtonText: 'Back to Home',
          onPrimaryPressed: _goHome,
        );

      case KycStatusEnum.approved:
        return _StatusView(
          status: status,
          iconData: CupertinoIcons.checkmark_shield_fill,
          themeColor: context.utilityGreen200,
          title: 'Verification Successful!',
          description: 'Congratulations! Your identity has been verified.',
          primaryButtonText: 'Start Trading',
          onPrimaryPressed: _goHome,
        );

      case KycStatusEnum.rejected:
      case KycStatusEnum.autoRejected:
        return _StatusView(
          status: status,
          iconData: CupertinoIcons.clear_circled_solid,
          themeColor: context.utilityError200,
          title: 'Verification Failed',
          description: 'Reason: ${data.rejectReason ?? "Document invalid."}',
          primaryButtonText: 'Try Again',
          onPrimaryPressed: _retryKyc,
          secondaryButtonText: 'Back to Home',
          onSecondaryPressed: _goHome,
        );

      default:
        return _StatusView(
          status: status,
          iconData: CupertinoIcons.person_crop_circle_badge_exclam,
          themeColor: context.utilityGray200,
          title: 'Status: ${status.label}',
          description: 'Please complete your verification.',
          primaryButtonText: 'Continue',
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
          Text('Failed to load status', style: TextStyle(color: Colors.grey[600])),
          TextButton(onPressed: () => ref.refresh(kycMeProvider), child: const Text('Retry')),
        ],
      ),
    );
  }
}

// --- 核心动画组件 ---
class _AnimatedStatusIcon extends StatefulWidget {
  final Widget child;
  final KycStatusEnum status;

  const _AnimatedStatusIcon({required this.child, required this.status});

  @override
  State<_AnimatedStatusIcon> createState() => _AnimatedStatusIconState();
}

class _AnimatedStatusIconState extends State<_AnimatedStatusIcon> with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 旋转动画控制 (用于审核中)
    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // 缩放动画控制 (用于入场)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _playAnimation();
  }

  void _playAnimation() {
    _scaleController.forward();
    if (widget.status == KycStatusEnum.reviewing) {
      _rotateController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedStatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      _playAnimation();
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget current = ScaleTransition(scale: _scaleAnimation, child: widget.child);

    // 如果是审核中，增加旋转效果
    if (widget.status == KycStatusEnum.reviewing) {
      current = RotationTransition(turns: _rotateController, child: current);
    }

    return current;
  }
}

class _StatusView extends StatelessWidget {
  final KycStatusEnum status;
  final IconData iconData;
  final Color themeColor;
  final String title;
  final String description;
  final String primaryButtonText;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;

  const _StatusView({
    required this.status,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 60.h),

        // 使用动画包装图标
        _AnimatedStatusIcon(
          status: status,
          child: _buildIconStack(),
        ),

        SizedBox(height: 32.h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: context.textPrimary900),
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15.sp, color: context.textTertiary600, height: 1.5),
          ),
        ),
        SizedBox(height: 80.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: Button(
            onPressed: onPrimaryPressed,
            child: Text(primaryButtonText, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
          ),
        ),
        if (secondaryButtonText != null) ...[
          SizedBox(height: 12.h),
          TextButton(
            onPressed: onSecondaryPressed,
            child: Text(secondaryButtonText!, style: const TextStyle(color: Color(0xFF6B7280))),
          ),
        ],
        SizedBox(height: 40.h),
      ],
    );
  }

  Widget _buildIconStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(shape: BoxShape.circle, color: themeColor.withOpacity(0.1)),
        ),
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(shape: BoxShape.circle, color: themeColor.withOpacity(0.2)),
        ),
        Icon(iconData, size: 48.w, color: themeColor),
      ],
    );
  }
}