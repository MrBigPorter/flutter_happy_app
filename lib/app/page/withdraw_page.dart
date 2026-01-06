import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/app/page/withdraw/withdraw_success_modal.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/providers/wallet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

// 基础组件
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/utils/format_helper.dart';

// 你的表单生成文件
import 'package:flutter_app/utils/form/withdraw_froms/withdraw_form.dart';
import 'package:flutter_app/utils/form/validation/k_withdraw_validation_messages.dart';

import '../../core/models/balance.dart';
import '../../utils/form/validators.dart';

class WithdrawPage extends ConsumerStatefulWidget {
  const WithdrawPage({super.key});

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  // 使用你生成的 FormModel
  late final WithdrawFormModelForm _form = WithdrawFormModelForm(
    WithdrawFormModelForm.formElements(const WithdrawFormModel()),
    null,
  );

  // 模拟系统配置
  final double _minWithdraw = 100.0; // 最小提现
  final double _maxWithdraw = 5000.0; // 单笔最大提现
  final double _feeRate = 0.02; // 2% 费率
  final double _fixedFee = 5.0; // 固定 5 披索手续费

  bool get _isKycVerified {
    final kycStatus = ref.read(
      luckyProvider.select((s) => s.userInfo?.kycStatus),
    );
    return KycStatusEnum.fromStatus(kycStatus ?? 0) == KycStatusEnum.approved;
  }

  @override
  void initState() {
    super.initState();

    // 1. 触发异步更新请求
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(luckyProvider.notifier).refreshAll();
    });

    // 2. 先用当前缓存的余额初始化一次（防止页面刚进来看不到东西或报错）
    final currentBalance = ref.read(luckyProvider).balance.realBalance;
    final kycStatus = ref.read(
      luckyProvider.select((s) => s.userInfo?.kycStatus),
    );

    _updateAmountValidator(currentBalance);
  }

  ///  核心方法：更新校验器
  /// 每次余额变化或 KYC 状态变化时调用
  void _updateAmountValidator(double currentBalance) {
    _form.amountControl.setValidators([
      Validators.required,
      WithdrawAmount(
        minAmount: _minWithdraw,
        maxAmount: _maxWithdraw,
        withdrawableBalance: currentBalance,
        // 注入最新的余额
        feeRate: _feeRate,
        fixedFee: _fixedFee,
        isAccountVerified: _isKycVerified,
      ),
    ]);
    // 强制刷新校验状态，让 UI 立即响应（比如去红字或亮按钮）
    _form.amountControl.updateValueAndValidity();
  }

  @override
  Widget build(BuildContext context) {
    // 监听实时余额
    final wallet = ref.watch(luckyProvider.select((s) => s.balance));
    final withdrawable = wallet.realBalance;

    // 关键步骤：监听余额异步更新 (逻辑校验用)
    // 当 updateWalletBalance 接口返回新数据时，这里会执行
    ref.listen(luckyProvider.select((s) => s.balance.realBalance), (
      previous,
      next,
    ) {
      if (previous == next) return;
      _updateAmountValidator(next);
    });

    return ReactiveFormConfig(
      validationMessages: kWithdrawValidationMessages,
      child: ReactiveForm(
        formGroup: _form.form,
        child: BaseScaffold(
          title: 'Withdraw'.tr(),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.all(16.w),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. 顶部余额卡片
                          _buildBalanceCard(withdrawable),
                          SizedBox(height: 20.h),

                          // 2. 金额输入区
                          _buildInputSection(withdrawable),
                          SizedBox(height: 20.h),

                          // 3. 提现方式选择
                          _buildMethodSelector(),
                          SizedBox(height: 16.h),

                          // 4. 安全提示
                          _buildSafetyNotice(),

                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: _buildBottomAction(withdrawable),
          resizeToAvoidBottomInset: true,
        ),
      ),
    );
  }

  // 1. 顶部余额卡片
  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.bgBrandPrimary,
            context.bgBrandPrimary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: context.bgBrandPrimary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Withdrawable Balance'.tr(),
            style: TextStyle(color: Colors.white70, fontSize: 13.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            FormatHelper.formatCurrency(balance),
            style: TextStyle(
              color: Colors.white,
              fontSize: 30.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // 2. 金额输入区
  Widget _buildInputSection(double maxAmount) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.borderSecondary),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Withdraw Amount'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              // 全部提现功能
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // 因为是 String 类型，需转成字符串
                  _form.amountControl.updateValue(maxAmount.toStringAsFixed(2));
                },
                child: Text(
                  'Withdraw All'.tr(),
                  style: TextStyle(
                    color: context.textBrandPrimary900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ReactiveTextField<String>(
            formControlName: WithdrawFormModelForm.amountControlName,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: context.textPrimary900,
            ),
            decoration: InputDecoration(
              prefixText: '₱ ',
              prefixStyle: TextStyle(
                fontSize: 24.sp,
                color: context.textPrimary900,
                fontWeight: FontWeight.bold,
              ),
              hintText: '0.00',
              border: InputBorder.none,
              errorStyle: TextStyle(
                color: context.textErrorPrimary600,
                fontSize: 12.sp,
              ),
              // 清除按钮
              suffixIcon: ReactiveValueListenableBuilder<String>(
                formControlName: WithdrawFormModelForm.amountControlName,
                builder: (context, control, child) {
                  final val = control.value ?? '';
                  if (val.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: Icon(Icons.cancel_outlined),
                    color: context.textPrimary900,
                    onPressed: () => control.reset(),
                  );
                },
              ),
            ),
            showErrors: (control) => control.invalid && control.touched,
          ),
          const Divider(),
          SizedBox(height: 8.h),
          // 动态计算手续费
          ReactiveValueListenableBuilder<String>(
            formControlName: WithdrawFormModelForm.amountControlName,
            builder: (context, control, child) {
              final amountStr = control.value ?? '0';
              final amount = double.tryParse(amountStr) ?? 0.0;

              // 计算逻辑：百分比费率 + 固定费用
              double fee = 0.0;
              if (amount > 0) {
                fee = (amount * _feeRate) + _fixedFee;
              }

              final actual = amount - fee > 0 ? amount - fee : 0.0;

              return Column(
                children: [
                  // 显示费率描述，比如 "2% + ₱5"
                  _buildDetailRow(
                    'Fee (2% + ₱5)',
                    '- ${FormatHelper.formatCurrency(fee)}',
                  ),
                  SizedBox(height: 4.h),
                  _buildDetailRow(
                    'Actual Received',
                    FormatHelper.formatCurrency(actual),
                    isBold: true,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: context.textTertiary600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? context.utilitySuccess600 : context.textPrimary900,
          ),
        ),
      ],
    );
  }

  // 3. 提现方式
  Widget _buildMethodSelector() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.textBrandPrimary900, width: 1.5),
      ),
      child: Row(
        children: [
           Icon(Icons.wallet, color: Colors.green, size: 32.w),
          SizedBox(width: 12.w),
          const Expanded(
            child: Text(
              'GCash (0917 **** 888)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Icon(Icons.check_circle, color: context.textBrandPrimary900),
        ],
      ),
    );
  }

  Widget _buildSafetyNotice() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        'withdraw.safety.notice'.tr(),
        style: TextStyle(fontSize: 11.sp, color: context.textSecondary700),
      ),
    );
  }

  // 4. 底部确认按钮
  Widget _buildBottomAction(double maxBalance) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final paddingBottom = keyboardHeight > 0
        ? keyboardHeight
        : MediaQuery.of(context).padding.bottom;

    final createWithdrawState = ref.watch(createWithdrawProvider);

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, paddingBottom + 12.h),
      child: ReactiveFormConsumer(
        builder: (context, form, child) {
          final amountStr =
              form.control(WithdrawFormModelForm.amountControlName).value
                  as String? ??
              '0';
          final amount = double.tryParse(amountStr) ?? 0.0;

          return Button(
            loading: createWithdrawState.isLoading,
            width: double.infinity,
            height: 52.h,
            onPressed: _handleWithdraw,
            child: Text('Confirm Withdrawal'.tr()),
          );
        },
      ),
    );
  }

  void _handleWithdraw() {
    _form.form.markAllAsTouched();

    if (!_form.form.valid) {
      return;
    }

    // 收起键盘
    FocusScope.of(context).unfocus();

    RadixModal.show(
      title: 'Confirm Withdrawal?'.tr(),
      builder: (context, close) => Text(
        'Are you sure you want to withdraw ₱${_form.amountControl.value}?',
      ),
      confirmText: 'common.confirm'.tr(),
      cancelText: 'common.cancel'.tr(),
      onConfirm: (finish) {
        finish();
        _processWithdraw();
      },
    );
  }

  // 真正的提现处理逻辑
  Future<void> _processWithdraw() async {
    final amountStr = _form.amountControl.value ?? '0';
    final amount = double.tryParse(amountStr) ?? 0.0;

    // 2. 提前计算好展示数据
    final fee = (amount * _feeRate) + _fixedFee;
    final actualReceived = amount - fee;

    final result = await ref
        .read(createWithdrawProvider.notifier)
        .create(
          WalletWithdrawApplyDto(
            amount: amount,
            withdrawMethod: 1,
            account: '10011111112222',
            // 模拟账号
            accountName: 'Juan Dela Cruz',
            // 模拟户名
            bankName: 'GCash',
          ),
        );

    if (result != null) {
      // 可以在这里刷新一下余额，因为钱扣了
      ref.read(luckyProvider.notifier).updateWalletBalance();
      // 重置表单，防止重复提交
      _form.form.reset();
      if (mounted) {
        RadixSheet.show(
          builder: (context, close) => WithdrawSuccessModal(
            amount: amount,
            fee: fee,
            actual: actualReceived,
            close: close,
          ),
        );
      }
    }
  }
}
