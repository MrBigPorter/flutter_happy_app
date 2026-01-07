import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

// --- Base & UI Components ---
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/utils/format_helper.dart';

// --- Models, Store & Providers ---
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/core/models/balance.dart';
import 'package:flutter_app/core/models/kyc.dart';
import 'package:flutter_app/core/providers/wallet_provider.dart';

// --- Forms & Validation ---
import 'package:flutter_app/utils/form/validators.dart';
import 'package:flutter_app/utils/form/withdraw_froms/withdraw_form.dart';
import '../../utils/form/validation/k_withdraw_validation_messages.dart';

// --- Modals ---
import 'package:flutter_app/app/page/withdraw/withdraw_success_modal.dart';

class WithdrawPage extends ConsumerStatefulWidget {
  const WithdrawPage({super.key});

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  // 当前选中的渠道
  PaymentChannelConfigItem? _selectedChannel;

  // 表单实例
  late final WithdrawFormModelForm _form = WithdrawFormModelForm(
    WithdrawFormModelForm.formElements(const WithdrawFormModel()),
    null,
  );

  @override
  void initState() {
    super.initState();
    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(luckyProvider.notifier).refreshAll();
      ref.refresh(clientPaymentChannelsWithdrawProvider);
    });
  }

  /// 核心逻辑：动态更新金额校验器
  void _updateValidators(double currentBalance) {
    if (_selectedChannel == null) return;

    // 1. 获取 KYC 状态
    final kycStatus = ref.read(luckyProvider).userInfo?.kycStatus ?? 0;
    final isVerified = KycStatusEnum.fromStatus(kycStatus) == KycStatusEnum.approved;

    // 2. 获取金额控制器
    final amountControl = _form.amountControl;

    // 3. 设置动态校验规则
    amountControl.setValidators([
      Validators.required,
      WithdrawAmount(
        // 渠道限额
        minAmount: _selectedChannel!.minAmount,
        maxAmount: _selectedChannel!.maxAmount,
        // 实时余额
        withdrawableBalance: currentBalance,
        // 费率信息
        feeRate: _selectedChannel!.feeRate,
        fixedFee: _selectedChannel!.feeFixed,
        // 用户状态
        isAccountVerified: isVerified,
      )
    ]);

    // 4. 强制刷新校验状态 (让UI立即响应)
    amountControl.updateValueAndValidity();
  }

  @override
  Widget build(BuildContext context) {
    // 监听数据
    final wallet = ref.watch(luckyProvider.select((s) => s.balance));
    final withdrawable = wallet.realBalance;
    final channelsAsync = ref.watch(clientPaymentChannelsWithdrawProvider);

    // 逻辑：数据加载完成后，自动选中第一个渠道
    ref.listen<AsyncValue<List<PaymentChannelConfigItem>>>(
      clientPaymentChannelsWithdrawProvider,
          (prev, next) {
        next.whenData((channels) {
          if (channels.isNotEmpty && _selectedChannel == null) {
            setState(() {
              _selectedChannel = channels.first;
              _updateValidators(withdrawable);
            });
          }
        });
      },
    );

    // 逻辑：余额变化时，重新运行校验逻辑
    ref.listen(luckyProvider.select((s) => s.balance.realBalance), (prev, next) {
      if (prev != next) _updateValidators(next);
    });

    final isPageLoading = channelsAsync.isLoading && !channelsAsync.hasValue;

    return ReactiveFormConfig(
      validationMessages: kWithdrawValidationMessages,
      child: ReactiveForm(
        formGroup: _form.form,
        child: BaseScaffold(
          title: 'Withdraw'.tr(),
          resizeToAvoidBottomInset: true,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. 余额卡片
                  _buildBalanceCard(withdrawable),
                  SizedBox(height: 20.h),

                  if (isPageLoading)
                    _buildSkeletonLoader()
                  else if (channelsAsync.hasError)
                    _buildErrorState()
                  else ...[
                      // 2. 金额输入区 (传入余额用于计算最大值)
                      _buildAmountInputSection(withdrawable),
                      SizedBox(height: 20.h),

                      // 3. 渠道选择
                      Text('Withdraw Method', style: _headerStyle),
                      SizedBox(height: 12.h),
                      _buildChannelList(channelsAsync.value ?? []),
                      SizedBox(height: 20.h),

                      // 4. 账号信息表单
                      Text('Account Details', style: _headerStyle),
                      SizedBox(height: 12.h),
                      _buildAccountForm(),
                    ],

                  SizedBox(height: 20.h),
                  _buildSafetyNotice(),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomAction(isPageLoading),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.bgBrandPrimary, context.bgBrandPrimary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: context.bgBrandPrimary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
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

  Widget _buildAmountInputSection(double currentBalance) {
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
              Text('Withdraw Amount'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // 逻辑：取 余额 和 渠道限额 中较小的一个
                  final channelMax = _selectedChannel?.maxAmount ?? double.infinity;
                  final smartMax = (currentBalance < channelMax) ? currentBalance : channelMax;

                  // 必须转为字符串
                  _form.amountControl.value = smartMax.toStringAsFixed(2);
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
            showErrors: (control) => control.invalid && control.touched,
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
            ),
            // 注意：这里删除了 validationMessages，因为已经在全局 ReactiveFormConfig 中配置了
          ),
          const Divider(),
          SizedBox(height: 8.h),
          // 动态费用显示
          ReactiveValueListenableBuilder<String>(
            formControlName: WithdrawFormModelForm.amountControlName,
            builder: (context, control, child) {
              final amount = double.tryParse(control.value ?? '0') ?? 0.0;
              final feeRate = _selectedChannel?.feeRate ?? 0.0;
              final fixedFee = _selectedChannel?.feeFixed ?? 0.0;

              double fee = 0.0;
              if (amount > 0) {
                fee = (amount * feeRate) + fixedFee;
              }
              final actual = (amount - fee > 0) ? amount - fee : 0.0;

              return Column(
                children: [
                  _buildDetailRow('Fee', '- ${FormatHelper.formatCurrency(fee)}'),
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

  Widget _buildChannelList(List<PaymentChannelConfigItem> channels) {
    if (channels.isEmpty) return const Text("No withdrawal methods available");

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: channels.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final channel = channels[index];
        final isSelected = _selectedChannel?.id == channel.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedChannel = channel;
              final currentBalance = ref.read(luckyProvider).balance.realBalance;
              _updateValidators(currentBalance);
            });
          },
          child: AnimatedContainer(
            duration: 200.ms,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.bgPrimary,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSelected ? context.textBrandPrimary900 : context.borderSecondary,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(color: context.bgSecondary, shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.network(
                      channel.icon ?? '',
                      errorBuilder: (_, __, ___) => Icon(Icons.account_balance_wallet, size: 20.w),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(channel.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: context.textBrandPrimary900),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountForm() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.bgPrimary, // 与金额卡片背景一致
        borderRadius: BorderRadius.circular(20.r), // 与金额卡片圆角一致
        border: Border.all(color: context.borderSecondary), // 统一边框颜色
      ),
      child: Column(
        children: [
          // --- 1. 户名输入 ---
          ReactiveTextField(
            formControlName: WithdrawFormModelForm.accountNameControlName,
            textInputAction: TextInputAction.next,
            showErrors: (control) => control.invalid && control.touched,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.textPrimary900,
            ),
            decoration: InputDecoration(
              labelText: 'Account Name'.tr(),
              labelStyle: TextStyle(
                color: context.textTertiary600,
                fontSize: 14.sp,
              ),
              hintText: 'e.g. Juan Dela Cruz',
              hintStyle: TextStyle(color: context.utilityGray300),
              // 🔥 核心修改：去掉边框，加入图标
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: context.textTertiary600,
                size: 22.w,
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 40.w),
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            validationMessages: {
              ValidationMessage.required: (_) => 'Account name is required',
            },
          ),

          // --- 分割线 ---
          Divider(height: 1, color: context.utilityGray200),

          // --- 2. 账号输入 ---
          ReactiveTextField(
            formControlName: WithdrawFormModelForm.accountNumberControlName,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            showErrors: (control) => control.invalid && control.touched,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.textPrimary900,
              fontFamily: 'Monospace', // 账号建议用等宽字体，看起来更像银行卡号
            ),
            decoration: InputDecoration(
              labelText: 'Account Number'.tr(),
              labelStyle: TextStyle(
                color: context.textTertiary600,
                fontSize: 14.sp,
              ),
              hintText: 'e.g. 09171234567',
              hintStyle: TextStyle(color: context.utilityGray300),
              // 🔥 核心修改：去掉边框，加入图标
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              prefixIcon: Icon(
                Icons.credit_card_outlined,
                color: context.textTertiary600,
                size: 22.w,
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 40.w),
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            validationMessages: {
              ValidationMessage.required: (_) => 'Account number is required',
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(bool isPageLoading) {
    final createWithdrawState = ref.watch(createWithdrawProvider);
    final isSubmitting = createWithdrawState.isLoading;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final height = keyboardHeight > 0 ? keyboardHeight : MediaQuery.of(context).padding.bottom + 12.h;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, height),
      color: context.bgPrimary,
      child: ReactiveFormConsumer(
        builder: (context, form, child) {
          // 按钮禁用条件：页面加载中 OR 正在提交 OR 表单无效 OR 未选渠道
          final isDisabled = isPageLoading || isSubmitting  || _selectedChannel == null;

          return Button(
            loading: isSubmitting,
            width: double.infinity,
            height: 52.h,
            onPressed: _handleWithdraw,
            child: Text('Confirm Withdrawal'.tr()),
          );
        },
      ),
    );
  }

  // --- Handlers ---

  void _handleWithdraw() {
    FocusScope.of(context).unfocus();

    _form.form.markAllAsTouched();

    if (_form.form.invalid || _selectedChannel == null) {
      return;
    }

    final amount = _form.amountControl.value;

    RadixModal.show(
      title: 'Confirm Withdrawal?'.tr(),
      builder: (context, close) => Text('Are you sure you want to withdraw ₱$amount via ${_selectedChannel?.name}?'),
      confirmText: 'Confirm',
      cancelText: 'Cancel',
      onConfirm: (finish) {
        finish();
        _processWithdraw();
      },
    );
  }

  Future<void> _processWithdraw() async {
    final amountVal = _form.amountControl.value;
    final amount = double.tryParse(amountVal ?? '0') ?? 0.0;

    // 费用计算用于展示
    final feeRate = _selectedChannel?.feeRate ?? 0.0;
    final fixedFee = _selectedChannel?.feeFixed ?? 0.0;
    final fee = (amount * feeRate) + fixedFee;
    final actual = amount - fee;

    final result = await ref.read(createWithdrawProvider.notifier).create(
      WalletWithdrawApplyDto(
        amount: amount,
        channelId: _selectedChannel!.id,
        account: _form.accountNumberControl.value ?? '',
        accountName: _form.accountNameControl.value ?? '',
        bankName: _selectedChannel!.name,
      ),
    );

    if (result != null) {
      ref.read(luckyProvider.notifier).updateWalletBalance();
      final channelName = _selectedChannel?.name ?? 'Wallet';
      final account = _form.accountNumberControl.value ?? '';
      // 重置表单
      _form.form.reset();

      if (mounted) {
        RadixSheet.show(
          builder: (context, close) => WithdrawSuccessModal(
            amount: amount,
            fee: fee,
            actual: actual,
            channelName: channelName,
            account: account,
            close: close,
          ),
        );
      }
    }
  }

  // --- Helpers ---
  Widget _buildSafetyNotice() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: context.bgSecondary, borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16.sp, color: context.textSecondary700),
          SizedBox(width: 8.w),
          Expanded(child: Text('withdraw.safety.notice'.tr(), style: TextStyle(fontSize: 11.sp, color: context.textSecondary700))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.sp, color: context.textTertiary600)),
        Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? context.utilitySuccess600 : context.textPrimary900)),
      ],
    );
  }

  Widget _buildSkeletonLoader() => SizedBox(height: 200.h, child: const Center(child: CircularProgressIndicator()));

  Widget _buildErrorState() => SizedBox(height: 100.h, child: const Center(child: Text("Failed to load methods")));

  TextStyle get _headerStyle => TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: context.textSecondary700);
}