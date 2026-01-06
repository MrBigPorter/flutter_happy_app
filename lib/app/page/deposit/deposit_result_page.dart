import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';

class DepositResultPage extends ConsumerStatefulWidget {
  final String orderNo;
  const DepositResultPage({super.key, required this.orderNo});

  @override
  ConsumerState<DepositResultPage> createState() => _DepositResultPageState();
}

class _DepositResultPageState extends ConsumerState<DepositResultPage> {
  Timer? _timer;       // 轮询定时器
  Timer? _textTimer;   // 文案轮播定时器

  // 状态：processing, success, failed, timeout
  String _status = 'processing';

  int _retryCount = 0;
  final int _maxRetries = 10; // 30秒超时

  // 动态文案索引
  int _loadingTextIndex = 0;
  final List<String> _loadingKeys = [
    "deposit_process_step_1", // Connecting...
    "deposit_process_step_2", // Verifying...
    "deposit_process_step_3", // Waiting...
    "deposit_process_step_4", // Finalizing...
  ];

  @override
  void initState() {
    super.initState();
    _startPolling();
    _startTextRotation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textTimer?.cancel();
    super.dispose();
  }

  // 启动文字轮播
  void _startTextRotation() {
    _textTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted || _status != 'processing') {
        timer.cancel();
        return;
      }
      setState(() {
        _loadingTextIndex = (_loadingTextIndex + 1) % _loadingKeys.length;
      });
    });
  }

  // 启动状态轮询
  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // 超时判断
      if (_retryCount >= _maxRetries) {
        timer.cancel();
        if (mounted) setState(() => _status = 'timeout');
        return;
      }
      _retryCount++;

      try {
        // --- 真实业务逻辑 (请解开注释并适配你的API) ---
        /*
        final order = await Api.getRechargeOrderDetail(widget.orderNo);
        if (order.status == 'SUCCESS') {
          _handleSuccess();
          timer.cancel();
        } else if (order.status == 'FAILED' || order.status == 'EXPIRED') {
          if (mounted) setState(() => _status = 'failed');
          timer.cancel();
        }
        */
        // -------------------------------------------

        // ---  模拟测试逻辑 (测试通过后请删除) ---
        print("Polling check $_retryCount: ${widget.orderNo}");
        if (_retryCount > 2) {
          _handleSuccess();
          timer.cancel();
        }
        // ---------------------------------------

      } catch (e) {
        print("Polling error: $e");
      }
    });
  }

  void _handleSuccess() {
    if (!mounted) return;
    // 刷新余额
    ref.read(luckyProvider.notifier).updateWalletBalance();
    setState(() => _status = 'success');
  }

  void _onExit() {
    // 回到首页/钱包页
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // 拦截物理返回键，防止轮询中断
    return PopScope(
      canPop: _status != 'processing',
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStateContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent() {
    switch (_status) {
      case 'success':
        return _buildSuccessView();
      case 'failed':
        return _buildFailedView();
      case 'timeout':
        return _buildTimeoutView();
      default:
        return _buildProcessingView();
    }
  }

  // --- 视图组件 1: 处理中 (高级呼吸动效) ---
  Widget _buildProcessingView() {
    return Column(
      key: const ValueKey('processing'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. 呼吸光晕动画
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.utilityBrand500.withOpacity(0.1),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 1000.ms),

            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.utilityBrand500.withOpacity(0.15),
              ),
            ),

            Icon(
              Icons.lock_clock,
              size: 40.w,
              color: context.utilityBrand500,
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.5)),
          ],
        ),

        SizedBox(height: 40.h),

        // 2. 动态轮播标题
        SizedBox(
          height: 30.h, // 固定高度防止抖动
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
                child: child,
              ));
            },
            child: Text(
              _loadingKeys[_loadingTextIndex].tr(),
              key: ValueKey<int>(_loadingTextIndex),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18.sp,
                  color: context.textPrimary900,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),
        ),

        SizedBox(height: 12.h),

        // 3. 固定说明
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            "deposit_result_processing_desc".tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary700, fontSize: 13.sp, height: 1.5),
          ),
        ),

        SizedBox(height: 32.h),

        // 4. 收据样式订单号
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: context.bgSecondary,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: context.utilityGray200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long, size: 16.sp, color: context.textTertiary600),
              SizedBox(width: 8.w),
              Expanded(child: Text(
                "${'deposit_result_order_no'.tr()} ${widget.orderNo}",
                style: TextStyle(
                    color: context.textSecondary700,
                    fontSize: 14.sp,
                    fontFamily: 'Monospace', // 等宽字体
                    fontWeight: FontWeight.w500
                ),
              ),)
            ],
          ),
        ),
      ],
    );
  }

  // --- 视图组件 2: 成功 ---
  Widget _buildSuccessView() {
    return Column(
      key: const ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle, color: const Color(0xFF00C853), size: 100.w)
            .animate()
            .scale(duration: 500.ms, curve: Curves.elasticOut),
        SizedBox(height: 24.h),
        Text(
          "deposit_result_success_title".tr(),
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w800, color: context.textPrimary900),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        SizedBox(height: 8.h),
        Text(
          "deposit_result_success_desc".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textSecondary700, fontSize: 16.sp),
        ).animate().fadeIn(delay: 400.ms),
        SizedBox(height: 48.h),
        Button(
          width: double.infinity,
          height: 50.h,
          onPressed: _onExit,
          child: Text("deposit_result_done_btn".tr()),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  // --- 视图组件 3: 失败 ---
  Widget _buildFailedView() {
    return Column(
      key: const ValueKey('failed'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cancel, color: Colors.redAccent, size: 100.w)
            .animate().shake(duration: 500.ms),
        SizedBox(height: 24.h),
        Text(
          "deposit_result_failed_title".tr(),
          style: TextStyle(fontSize: 24.sp, color: context.textPrimary900, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        Text(
          "deposit_result_failed_desc".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textSecondary700, fontSize: 16.sp),
        ),
        SizedBox(height: 48.h),
        Button(
          width: double.infinity,
          onPressed: () => Navigator.of(context).pop(),
          child: Text("deposit_result_retry_btn".tr()),
        ),
      ],
    );
  }

  // --- 视图组件 4: 超时 ---
  Widget _buildTimeoutView() {
    return Column(
      key: const ValueKey('timeout'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.access_time_filled, color: Colors.orange, size: 100.w),
        SizedBox(height: 24.h),
        Text(
          "deposit_result_timeout_title".tr(),
          style: TextStyle(fontSize: 22.sp, color: context.textPrimary900, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        Text(
          "deposit_result_timeout_desc".tr(),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textSecondary700, fontSize: 14.sp),
        ),
        SizedBox(height: 48.h),
        Button(
          variant: ButtonVariant.outline,
          width: double.infinity,
          onPressed: _onExit,
          child: Text("deposit_result_understand_btn".tr()),
        ),
        SizedBox(height: 12.h),
        TextButton(
          onPressed: _onExit,
          child: Text(
            "deposit_result_contact_support".tr(),
            style: TextStyle(color: context.textSecondary700),
          ),
        )
      ],
    );
  }
}