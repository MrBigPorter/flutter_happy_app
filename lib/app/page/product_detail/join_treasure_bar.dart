import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/providers/purchase_state_provider.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/animations/rolling_number.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/components/render_countdown.dart';

import '../../../utils/helper.dart';
import '../../../utils/time/server_time_helper.dart';

class JoinTreasureBar extends ConsumerWidget {
  final String treasureId;
  final String? groupId;

  const JoinTreasureBar({
    super.key,
    required this.treasureId,
    this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听整个 State，因为我们需要 state, time, stock, entries 等多个字段
    final purchaseState = ref.watch(purchaseProvider(treasureId));
    final notifier = ref.read(purchaseProvider(treasureId).notifier);

    return Container(
      padding: EdgeInsets.only(bottom: ViewUtils.bottomBarHeight),
      decoration: BoxDecoration(color: context.bgPrimary),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 余额提示条 (保持不变)
          _buildBalanceTip(context, notifier.coinsCanUse, 0), // coinAmountCap逻辑根据你实际provider调整

          // 2. 核心操作区
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
            decoration: BoxDecoration(
              color: context.bgPrimary,
              border: Border(top: BorderSide(color: context.borderSecondary, width: 1.w)),
            ),
            child: _buildActionBody(context, ref, purchaseState),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceTip(BuildContext context, double coinsCanUse, num coinAmount) {
    // ... (代码保持原样，省略以节省空间) ...
    // 只是为了演示结构，这里放一个占位
    return Container(
      height: 30.w,
      color: context.bgSecondary,
      child: Center(child: Text("Balance Tip: $coinsCanUse")),
    );
  }

  Widget _buildActionBody(BuildContext context, WidgetRef ref, PurchaseState state) {
    final now = ServerTimeHelper.nowMilliseconds;

    // 1. 判断是否已下架 (读 Provider 里的实时状态)
    if (state.productState != 1) {
      return Button(
        width: double.infinity,
        height: 44.w,
        disabled: true,
        child: const Text('Offline'),
      );
    }

    // 2. 判断是否过期
    if (state.salesEndAt != null && state.salesEndAt! < now) {
      return Button(
        width: double.infinity,
        height: 44.w,
        disabled: true,
        child: const Text('Sold Out / Expired'),
      );
    }

    // 3. ✨ 判断是否是预售 (Pre-sale)
    if (state.salesStartAt != null && state.salesStartAt! > now) {
      return Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 16.w, color: context.fgBrandPrimary),
                SizedBox(width: 4.w),
                Text('Starts in: ', style: TextStyle(color: context.fgBrandPrimary, fontWeight: FontWeight.bold)),
                RenderCountdown(
                  lotteryTime: state.salesStartAt!,
                  renderCountdown: (time) => Text(time, style: TextStyle(color: context.fgBrandPrimary, fontWeight: FontWeight.bold)),
                  renderEnd: (days) => Text('Days left: $days', style: TextStyle(color: context.fgBrandPrimary, fontWeight: FontWeight.bold)),
                  renderSoldOut: () => Text('common.activity_ended'.tr(), style: TextStyle(color: context.fgBrandPrimary, fontWeight: FontWeight.bold)),
                  onFinished: () {
                    ref.invalidate(purchaseProvider(treasureId));
                  },
                ),
              ],
            ),
          ),
          Button(
            width: double.infinity,
            height: 44.w,
            disabled: true,
            child: Text('Coming Soon'),
          ),
        ],
      );
    }

    // 4. ✅ 正常购买状态：显示步进器 + 购买按钮
    // 结构优化：把 Button 提出来，和步进器并列，不再藏在 _Stepper 里
    return Column(
      children: [
        // 纯粹的输入组件
        _StepperInput(treasureId: treasureId),

        SizedBox(height: 20.w),

        // 购买按钮
        Button(
          disabled: state.stockLeft <= 0 || state.isSubmitting,
          loading: state.isSubmitting, // 加上 loading 状态
          width: double.infinity,
          height: 44.w,
          alignment: MainAxisAlignment.spaceBetween,
          paddingX: 18.w,
          onPressed: () {
            // 路由跳转或提交逻辑
            appRouter.pushNamed(
              'payment',
              queryParameters: {
                'entries': '${state.entries}',
                'treasureId': treasureId,
                'paymentMethod': '1', // 这里的逻辑根据你的 PaymentMethod 调整
                if (groupId != null) 'groupId': groupId!,
              },
            );
          },
          trailing: RollingNumber(
            value: state.subtotal,
            fractionDigits: 2,
            prefix: Text('₱', style: TextStyle(fontSize: context.textSm, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          child: Text('common.join.group'.tr()),
        ),
      ],
    );
  }
}

/// ♻️ 重构：只负责输入数字，不负责提交
class _StepperInput extends ConsumerStatefulWidget {
  final String treasureId;

  const _StepperInput({required this.treasureId});

  @override
  ConsumerState<_StepperInput> createState() => _StepperInputState();
}

class _StepperInputState extends ConsumerState<_StepperInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // 初始值
    final initialEntries = ref.read(purchaseProvider(widget.treasureId)).entries;
    _controller = TextEditingController(text: '$initialEntries');
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitText() {
    final action = ref.read(purchaseProvider(widget.treasureId).notifier);
    action.setEntriesFromText(_controller.text);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // ✨ 监听 sync：当外部（如库存不足自动调整）改变 entries 时，同步回输入框
    ref.listen(purchaseProvider(widget.treasureId).select((s) => s.entries), (prev, next) {
      final text = next.toString();
      if (_controller.text != text && !_focusNode.hasFocus) {
        _controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });

    final action = ref.read(purchaseProvider(widget.treasureId).notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Button(
          width: 44.w,
          height: 44.w,
          variant: ButtonVariant.outline,
          onPressed: () => action.dec((val) {}),
          child: Icon(Icons.remove, size: 24.w),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Container(
            height: 44.w,
            decoration: BoxDecoration(
              color: context.buttonSecondaryBg,
              borderRadius: BorderRadius.circular(context.radiusSm),
              border: Border.all(color: context.borderSecondary),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submitText(),
              onTapOutside: (_) => _submitText(),
              style: TextStyle(fontSize: context.textMd, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Button(
          width: 44.w,
          height: 44.w,
          variant: ButtonVariant.outline,
          onPressed: () => action.inc((val) {}),
          child: Icon(Icons.add, size: 24.w),
        ),
      ],
    );
  }
}