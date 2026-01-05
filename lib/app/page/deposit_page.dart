import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/providers/wallet_provider.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/utils/form/deposit_form/deposit_form.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/balance.dart';
import '../../core/store/lucky_store.dart';
import '../../utils/form/validation/k_deposit_validation_messages.dart';
import 'deposit/payment_webview_page.dart';

class DepositPage extends ConsumerStatefulWidget {
  const DepositPage({super.key});

  @override
  ConsumerState<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends ConsumerState<DepositPage> {
  final List<int> _quickAmounts = [100, 200, 500, 1000, 2000, 5000];

  late final DepositFormModelForm _form = DepositFormModelForm(
    DepositFormModelForm.formElements(const DepositFormModel()),
    null,
  );

  Future<void> _onSubmit() async {
    if (_form.form.valid) {
      // 提交时收起键盘，体验更好
      FocusScope.of(context).unfocus();
      final amount = _form.form.control('amount').value;

      try{
        final response = await ref.read(createRechargeProvider.notifier).create(
          CreateRechargeDto(
            amount: int.parse(amount),
          ),
        );
        if(response != null && response.payUrl.isNotEmpty){
          if(!mounted) return;
          final payUrl = Uri.parse(response.payUrl);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PaymentWebViewPage(
                url: response.payUrl,
                orderNo: response.rechargeNo,
              ),
            )
          );
        }else {
          // 接口成功了但没给 URL (极少见，兜底逻辑)
          throw 'Payment URL is empty';
        }
      }catch(e){
        if(!mounted) return;
        //RadixToast.error('Failed to create deposit order: ${e.toString()}');
      }finally{
        if(mounted){
          // 刷新余额
          ref.read(luckyProvider.notifier).updateWalletBalance();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveFormConfig(
      validationMessages: kDepositValidationMessages,
      child: ReactiveForm(
        formGroup: _form.form,
        child: BaseScaffold(
          title: 'Deposit',
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(horizontal: 16.w), // 统一给 Body 加边距
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),
                  _buildAmountInputCard(),
                  SizedBox(height: 24.h),
                  Text(
                    'Quick Select',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondary700,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
                  SizedBox(height: 12.h),
                  _buildQuickGrid(),
                  SizedBox(height: 24.h),
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: context.textSecondary700,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  SizedBox(height: 12.h),
                  _buildPaymentMethodTile(),
                  SizedBox(height: 40.h), // 底部留白增加一点，防止误触
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildAmountInputCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Opacity 写法更通用
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enter Amount',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary700,
                ),
              ),
              Text(
                'Min deposit ₱100',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  // 辅助信息颜色淡一点
                  color: context.textTertiary600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₱',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary900,
                  height: 1.2,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ReactiveTextField<String>(
                  formControlName: 'amount',
                  keyboardType: TextInputType.number,
                  //设置键盘动作为“完成”
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_)=> FocusScope.of(context).unfocus(),
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary900,
                    height: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    contentPadding: EdgeInsets.zero,
                    errorStyle: const TextStyle(height: 0), // 隐藏默认错误文字
                    // [Fix 3]: Hint 颜色要淡，否则像已经填了数字
                    hintStyle: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: context.utilityGray300 ?? Colors.grey[300],
                    ),
                    border: InputBorder.none,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                ),
              ),
            ],
          ),
          // [Fix 1]: 必须移出 Row，放在 Column 里，才能作为底部横线
          Container(
            margin: EdgeInsets.only(top: 8.h),
            height: 1,
            color: context.utilityGray200,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(
      begin: 0.2,
      end: 0.0,
      duration: 500.ms,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildQuickGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.w), // Padding 交给 GridView 自己或外层处理
      child: ReactiveValueListenableBuilder<String>(
        formControlName: 'amount',
        builder: (context, control, child) {
          final currentValStr = control.value ?? '';

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 2.4,
            ),
            itemCount: _quickAmounts.length,
            itemBuilder: (context, index) {
              final amount = _quickAmounts[index];
              final amountStr = amount.toString();
              final isSelected = currentValStr == amountStr;

              // 使用封装好的带动画组件
              return _QuickSelectChip(
                amount: amount,
                isSelected: isSelected,
                index: index, // 用于入场动画延时
                onTap: () {
                  HapticFeedback.selectionClick(); // 震动
                  control.value = amountStr; // 赋值
                  FocusScope.of(context).unfocus(); // 收起键盘
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodTile() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(20.r),
        // 默认选中给个高亮边框
        border: Border.all(color: context.utilityBrand500, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: context.utilityBrand500.withOpacity(0.1),
              shape: BoxShape.circle, // 圆形图标
            ),
            child: Icon(
              Icons.account_balance_wallet,
              size: 24.w,
              color: context.utilityBrand500,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "E-Wallet / Online Banking",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Instant Arrival • Fee 0%",
                  style: TextStyle(
                    fontSize: 12.sp,
                    // 绿色强调无手续费
                    color: context.utilitySuccess500 ?? Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, size: 24.w, color: context.utilityBrand500),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildBottomBar() {

    final bottom = MediaQuery.of(context).padding.bottom;
    final rechargeState = ref.watch(createRechargeProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 12.h,
        bottom: 12.h + bottom,
      ),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(top: BorderSide(color: context.utilityGray100)),
      ),
      child: ReactiveFormConsumer(
        builder: (context, form, child) {
          final isEnabled = form.valid;
          return Button(
            loading: rechargeState.isLoading,
            onPressed: isEnabled ? _onSubmit : null,
            width: double.infinity, // 确保按钮撑满宽度
            height: 52.h,
            child: Text(
              'Deposit Now',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          );
        },
      ).animate(onPlay: (controller) => controller.repeat())
          .shimmer(delay: 3.seconds, duration: 1.seconds, color: Colors.white24),
    );
  }
}


class _QuickSelectChip extends StatelessWidget {
  final int amount;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const _QuickSelectChip({
    super.key,
    required this.amount,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 使用 AnimatedScale 处理点击缩放 (Q弹效果，无倒带 Bug)
    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: GestureDetector(
        onTap: onTap,
        // 2. 使用 AnimatedContainer 处理背景色
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? context.utilityBrand500 : context.bgPrimary,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? Colors.transparent : context.utilityGray200,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: context.utilityBrand500.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          alignment: Alignment.center,

          // 3. 只有 isSelected 为 true 时，才挂载流光组件
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                FormatHelper.formatCurrency(amount, decimalDigits: 0),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : context.textPrimary900,
                ),
              ),

              // 关键：只有选中时才渲染流光，避免未选中时乱闪
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(
                    duration: 1200.ms,
                    color: Colors.white.withOpacity(0.3),
                    angle: -0.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    )
    // 4. 入场动画 (仅一次)
        .animate()
        .fadeIn(delay: (50 * index).ms, duration: 300.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutQuad);
  }
}