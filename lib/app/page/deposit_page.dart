import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

// 你的项目特定 import，请根据实际路径调整
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/providers/wallet_provider.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/utils/form/deposit_form/deposit_form.dart';
import 'package:flutter_app/utils/format_helper.dart';
import '../../core/models/balance.dart'; // 确保这里面有 PaymentChannelConfigItem
import '../../core/store/lucky_store.dart';
import '../../utils/form/validation/k_deposit_validation_messages.dart';
import '../../utils/form/validators.dart';
import 'deposit/payment_webview_page.dart';

class DepositPage extends ConsumerStatefulWidget {
  const DepositPage({super.key});

  @override
  ConsumerState<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends ConsumerState<DepositPage> {
  // 当前选中的渠道
  PaymentChannelConfigItem? _selectedChannel;

  // 默认快捷金额 (当后端没配或加载失败时显示)
  final List<num> _defaultAmounts = [100, 200, 500, 1000, 2000, 5000];

  late final DepositFormModelForm _form = DepositFormModelForm(
    DepositFormModelForm.formElements(const DepositFormModel()),
    null,
  );

  @override
  void initState() {
    super.initState();
    // 页面初始化时刷新数据
    Future.microtask(() => ref.refresh(clientPaymentChannelsRechargeProvider));
  }

  // 更新表单校验规则 (Min/Max)
  void _updateValidators() {
    if (_selectedChannel == null) return;

    final control = _form.form.control('amount');
    control.setValidators([
      DepositAmount(
          minAmount: _selectedChannel!.minAmount,
          maxAmount: _selectedChannel!.maxAmount
      )
    ]);
    control.updateValueAndValidity();
  }

  Future<void> _onSubmit() async {
    if (_form.form.valid && _selectedChannel != null) {
      FocusScope.of(context).unfocus();
      final amount = _form.form.control('amount').value;

      try {
        // 调用创建订单接口
        final response = await ref.read(createRechargeProvider.notifier).create(
          CreateRechargeDto(
            amount: num.parse(amount),
            channelId: _selectedChannel!.id,
          ),
        );

        if (response != null && response.payUrl.isNotEmpty) {
          if (!mounted) return;
          // 跳转 Webview 支付
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PaymentWebViewPage(
                url: response.payUrl,
                orderNo: response.rechargeNo,
              ),
            ),
          );
        } else {
          throw 'Payment URL is empty';
        }
      } catch (e) {
        if (!mounted) return;
        debugPrint('Deposit Error: $e');
        // 这里可以加 Toast
      } finally {
        if (mounted) {
          ref.read(luckyProvider.notifier).updateWalletBalance();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听渠道配置 Provider
    final channelsAsync = ref.watch(clientPaymentChannelsRechargeProvider);

    //  逻辑优化：监听数据变化，设置默认选中项
    ref.listen<AsyncValue<List<PaymentChannelConfigItem>>>(
      clientPaymentChannelsRechargeProvider,
          (previous, next) {
        next.whenData((channels) {
          // 如果列表不为空，且当前没有选中项，默认选中第一个
          if (channels.isNotEmpty && _selectedChannel == null) {
            setState(() {
              _selectedChannel = channels.first;
              _updateValidators();
            });
          }
        });
      },
    );

    // 判断是否正在加载 (且没有旧数据)
    final bool isPageLoading = channelsAsync.isLoading && !channelsAsync.hasValue;

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
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),

                  // 1. 金额输入框 (加载时禁止点击，防止误操作)
                  IgnorePointer(
                    ignoring: isPageLoading,
                    child: _buildAmountInputCard(),
                  ),

                  SizedBox(height: 24.h),

                  // 2. 根据状态显示内容：骨架屏 OR 错误页 OR 真实内容
                  if (isPageLoading)
                    _buildLoadingSkeleton()
                  else if (channelsAsync.hasError)
                    _buildErrorState()
                  else
                    _buildMainContent(channelsAsync.value ?? []),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
          // 底部按钮
          bottomNavigationBar: _buildBottomBar(isPageLoading),
        ),
      ),
    );
  }

  // ==========================================
  // 组件区域
  // ==========================================

  /// 骨架屏：模拟页面结构
  Widget _buildLoadingSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 模拟 "Quick Select" 标题
        _buildSkeletonRect(width: 100.w, height: 20.h),
        SizedBox(height: 12.h),
        // 模拟 快捷选择网格
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 2.4,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => Skeleton.react(
            width: double.infinity,
            height: 40.h,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        SizedBox(height: 24.h),
        // 模拟 "Payment Method" 标题
        _buildSkeletonRect(width: 140.w, height: 20.h),
        SizedBox(height: 12.h),
        // 模拟 渠道列表
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (_, __) => Container(
            height: 72.h,
            decoration: BoxDecoration(
              color: context.utilityGray100,
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
        ),
      ],
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.5));
  }

  /// 简单的骨架占位块
  Widget _buildSkeletonRect({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.utilityGray200,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  /// 错误状态
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48.w, color: context.utilityGray400),
            SizedBox(height: 16.h),
            Text('Failed to load channels', style: TextStyle(color: context.textSecondary700)),
            SizedBox(height: 8.h),
            Button(
              variant: ButtonVariant.ghost,
              height: 36.h,
              onPressed: () => ref.refresh(clientPaymentChannelsRechargeProvider),
              child: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }

  /// 真实内容区域
  Widget _buildMainContent(List<PaymentChannelConfigItem> channels) {
    if (channels.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("No payment channels available"),
      ));
    }

    final List<num> displayOptions =
    (_selectedChannel?.fixedAmounts != null && _selectedChannel!.fixedAmounts!.isNotEmpty)
        ? _selectedChannel!.fixedAmounts!
        : _defaultAmounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayOptions.isNotEmpty) ...[
          Text(
            'Quick Select',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: context.textSecondary700,
            ),
          ).animate().fadeIn(duration: 400.ms),
          SizedBox(height: 12.h),
          _buildQuickGrid(displayOptions),
          SizedBox(height: 24.h),
        ],

        Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: context.textSecondary700,
          ),
        ).animate().fadeIn(delay: 200.ms),
        SizedBox(height: 12.h),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: channels.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) => _buildChannelItem(channels[index]),
        ),
      ],
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
            color: Colors.black.withOpacity(0.05),
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
              if (_selectedChannel != null)
                Text(
                  'Min ₱${FormatHelper.formatCurrency(_selectedChannel!.minAmount, decimalDigits: 0, symbol: '')}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  readOnly: !(_selectedChannel?.isCustom ?? true),
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary900,
                    height: 1.2,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    contentPadding: EdgeInsets.zero,
                    errorStyle: const TextStyle(height: 0),
                    hintStyle: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: context.utilityGray300,
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
          Container(
            margin: EdgeInsets.only(top: 8.h),
            height: 1,
            color: context.utilityGray200,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutBack);
  }

  Widget _buildQuickGrid(List<num> options) {
    return Padding(
      padding: EdgeInsets.zero,
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
            itemCount: options.length,
            itemBuilder: (context, index) {
              final amount = options[index];
              final amountStr = amount.toStringAsFixed(0);
              final isSelected = currentValStr == amountStr;

              return _QuickSelectChip(
                amount: amount.toInt(),
                isSelected: isSelected,
                index: index,
                onTap: () {
                  HapticFeedback.selectionClick();
                  control.value = amountStr;
                  FocusScope.of(context).unfocus();
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChannelItem(PaymentChannelConfigItem channel) {
    final isSelected = _selectedChannel?.id == channel.id;

    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        setState(() {
          _selectedChannel = channel;
          _form.form.control('amount').value = '';
          _updateValidators();
        });
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? context.utilityBrand500 : Colors.transparent,
            width: 1.5,
          ),
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
                color: context.bgSecondary,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                // 图标兜底逻辑
                child: (channel.icon != null && channel.icon!.isNotEmpty)
                    ? Image.network(
                  channel.icon!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.account_balance_wallet,
                    size: 24.w,
                    color: context.utilityBrand500,
                  ),
                )
                    : Icon(
                  Icons.account_balance_wallet,
                  size: 24.w,
                  color: context.utilityBrand500,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary900,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "Instant • Fee 0%",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.utilitySuccess500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 24.w, color: context.utilityBrand500)
            else
              Icon(Icons.circle_outlined, size: 24.w, color: context.utilityGray300),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isPageLoading) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final rechargeState = ref.watch(createRechargeProvider);

    // 如果正在拉取渠道数据，或者正在提交订单，都算作 loading
    final bool isBusy = isPageLoading || rechargeState.isLoading;

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
          final isEnabled = !isPageLoading && form.valid && _selectedChannel != null;

          return Button(
            loading: isBusy,
            disabled: !isEnabled,
            onPressed: isEnabled ? _onSubmit : null,
            width: double.infinity,
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
      ),
    );
  }
}

// 独立的 Chip 组件
class _QuickSelectChip extends StatelessWidget {
  final int amount;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const _QuickSelectChip({
    required this.amount,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: GestureDetector(
        onTap: onTap,
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
        .animate()
        .fadeIn(delay: (50 * index).ms, duration: 300.ms)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutQuad);
  }
}