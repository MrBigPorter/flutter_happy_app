import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/app/page/transaction/transaction_ui_model.dart';
import 'package:flutter_app/app/page/transaction_record_page.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/core/store/wallet_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

// --- Base & UI Components ---
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart'; // 确保引入 Skeleton 组件
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/utils/format_helper.dart';

// --- Models, Store & Providers ---
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
      ref.read(walletProvider.notifier).fetchBalance();
      ref.read(userProvider.notifier).fetchProfile();

      final state = ref.read(clientPaymentChannelsWithdrawProvider);
      if(state.hasValue && !state.isLoading){
        ref.invalidate(clientPaymentChannelsWithdrawProvider);
      }

    });
  }

  /// 核心逻辑：动态更新金额校验器
  void _updateValidators(double currentBalance) {
    if (_selectedChannel == null) return;

    // 1. 获取 KYC 状态
    final kycStatus = ref.read(userProvider)?.kycStatus ?? 0;
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
    final wallet = ref.watch(walletProvider.select((s) => s));
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
    ref.listen(walletProvider.select((s) => s.realBalance), (prev, next) {
      if (prev != next) _updateValidators(next);
    });

    final isPageLoading = channelsAsync.isLoading && !channelsAsync.hasValue;

    return ReactiveFormConfig(
      validationMessages: kWithdrawValidationMessages,
      child: ReactiveForm(
        formGroup: _form.form,
        child: BaseScaffold(
          title: 'withdraw.title'.tr(),
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
                  //  使用全新的骨架屏加载器
                    _buildSkeletonLoader()
                  else if (channelsAsync.hasError)
                    _buildErrorState()
                  else ...[
                      // 2. 金额输入区
                      _buildAmountInputSection(withdrawable),
                      SizedBox(height: 20.h),

                      // 3. 渠道选择
                      //  国际化
                      Text('withdraw.method_title'.tr(), style: _headerStyle),
                      SizedBox(height: 12.h),
                      _buildChannelList(channelsAsync.value ?? []),
                      SizedBox(height: 20.h),

                      // 4. 账号信息表单
                      //  国际化
                      Text('withdraw.account_details_title'.tr(), style: _headerStyle),
                      SizedBox(height: 12.h),
                      _buildAccountForm(),
                    ],

                  SizedBox(height: 20.h),
                  if (!isPageLoading) _buildSafetyNotice(),
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

  //  优化后的骨架屏加载器
  Widget _buildSkeletonLoader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 模拟金额输入区域
        Skeleton.react(
          width: double.infinity,
          height: 180.h,
          borderRadius: BorderRadius.circular(20.r),
        ),
        SizedBox(height: 20.h),

        // 2. 模拟渠道标题
        Skeleton.react(width: 120.w, height: 16.h, borderRadius: BorderRadius.circular(4.r)),
        SizedBox(height: 12.h),

        // 3. 模拟渠道列表 (3个 item)
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (_, __) => Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.bgPrimary,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Skeleton.react(width: 32.w, height: 32.w, borderRadius: BorderRadius.circular(16.r)),
                SizedBox(width: 12.w),
                Skeleton.react(width: 150.w, height: 14.h, borderRadius: BorderRadius.circular(4.r)),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // 4. 模拟账号表单标题
        Skeleton.react(width: 120.w, height: 16.h, borderRadius: BorderRadius.circular(4.r)),
        SizedBox(height: 12.h),

        // 5. 模拟账号表单 (包含两行输入框)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          decoration: BoxDecoration(
            color: context.bgPrimary,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              // Row 1
              Row(
                children: [
                  Skeleton.react(width: 24.w, height: 24.w, borderRadius: BorderRadius.circular(12.r)),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.react(width: 80.w, height: 10.h, borderRadius: BorderRadius.circular(2.r)),
                      SizedBox(height: 8.h),
                      Skeleton.react(width: 180.w, height: 14.h, borderRadius: BorderRadius.circular(2.r)),
                    ],
                  )
                ],
              ),
              SizedBox(height: 24.h),
              Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              SizedBox(height: 24.h),
              // Row 2
              Row(
                children: [
                  Skeleton.react(width: 24.w, height: 24.w, borderRadius: BorderRadius.circular(12.r)),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.react(width: 80.w, height: 10.h, borderRadius: BorderRadius.circular(2.r)),
                      SizedBox(height: 8.h),
                      Skeleton.react(width: 180.w, height: 14.h, borderRadius: BorderRadius.circular(2.r)),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
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
          //  国际化
          Text(
            'withdraw.balance_label'.tr(),
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
              //  国际化
              Text('withdraw.amount_label'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final channelMax = _selectedChannel?.maxAmount ?? double.infinity;
                  final smartMax = (currentBalance < channelMax) ? currentBalance : channelMax;
                  _form.amountControl.value = smartMax.toStringAsFixed(2);
                },
                child: Text(
                  //  国际化
                  'withdraw.withdraw_all'.tr(),
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
          ),
          const Divider(),
          SizedBox(height: 8.h),
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
                  //  国际化
                  _buildDetailRow('withdraw.fee_label'.tr(), '- ${FormatHelper.formatCurrency(fee)}'),
                  SizedBox(height: 4.h),
                  //  国际化
                  _buildDetailRow(
                    'withdraw.actual_received_label'.tr(),
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
    //  国际化
    if (channels.isEmpty) return Text("withdraw.no_methods".tr());

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
              final currentBalance = ref.read(walletProvider).realBalance;
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
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.borderSecondary),
      ),
      child: Column(
        children: [
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
              //  国际化
              labelText: 'withdraw.label_account_name'.tr(),
              labelStyle: TextStyle(
                color: context.textTertiary600,
                fontSize: 14.sp,
              ),
              //  国际化
              hintText: 'withdraw.hint_account_name'.tr(),
              hintStyle: TextStyle(color: context.utilityGray300),
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
              //  国际化
              ValidationMessage.required: (_) => 'withdraw.error_account_name_required'.tr(),
            },
          ),
          Divider(height: 1, color: context.utilityGray200),
          ReactiveTextField(
            formControlName: WithdrawFormModelForm.accountNumberControlName,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            showErrors: (control) => control.invalid && control.touched,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: context.textPrimary900,
              fontFamily: 'Monospace',
            ),
            decoration: InputDecoration(
              //  国际化
              labelText: 'withdraw.label_account_number'.tr(),
              labelStyle: TextStyle(
                color: context.textTertiary600,
                fontSize: 14.sp,
              ),
              //  国际化
              hintText: 'withdraw.hint_account_number'.tr(),
              hintStyle: TextStyle(color: context.utilityGray300),
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
              //  国际化
              ValidationMessage.required: (_) => 'withdraw.error_account_number_required'.tr(),
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
          final isDisabled = isPageLoading || isSubmitting || _selectedChannel == null;

          return Button(
            loading: isSubmitting,
            width: double.infinity,
            height: 52.h,
            onPressed: isDisabled ? null : _handleWithdraw,
            //  国际化
            child: Text('withdraw.btn_confirm_withdrawal'.tr()),
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
      //  国际化
      title: 'withdraw.dialog_confirm_title'.tr(),
      //  国际化 (使用命名参数动态替换)
      builder: (context, close) => Text(
        'withdraw.dialog_confirm_content'.tr(
          namedArgs: {
            'amount': amount.toString(),
            'channel': _selectedChannel?.name ?? '',
          },
        ),
      ),
      //  国际化
      confirmText: 'common.confirm'.tr(),
      cancelText: 'common.cancel'.tr(),
      onConfirm: (finish) {
        finish();
        _processWithdraw();
      },
    );
  }

  Future<void> _processWithdraw() async {
    final amountVal = _form.amountControl.value;
    final amount = double.tryParse(amountVal ?? '0') ?? 0.0;

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
      ref.read(transactionDirtyProvider(UiTransactionType.withdraw).notifier).state = true;
      ref.read(walletProvider.notifier).fetchBalance();
      final channelName = _selectedChannel?.name ?? 'Wallet';
      final account = _form.accountNumberControl.value ?? '';
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
          //  国际化
          Expanded(child: Text('withdraw.safety_notice'.tr(), style: TextStyle(fontSize: 11.sp, color: context.textSecondary700))),
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

  //  国际化
  Widget _buildErrorState() => SizedBox(height: 100.h, child: Center(child: Text("withdraw.error_load_methods".tr())));

  TextStyle get _headerStyle => TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: context.textSecondary700);
}