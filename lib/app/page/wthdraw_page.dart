import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/common.dart'; // 假设包含你的主题 colors
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

// 模拟的数据模型
class BankAccount {
  final String id;
  final String name;
  final String number;
  final String icon; // 银行Logo URL

  BankAccount({required this.id, required this.name, required this.number, required this.icon});
}

class WithdrawPage extends ConsumerStatefulWidget {
  const WithdrawPage({super.key});

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  final TextEditingController _amountCtrl = TextEditingController();
  final double _balance = 25400.50; // 模拟余额，实际应从 Provider 获取
  final double _minWithdraw = 100.0;

  // 模拟选中的银行卡
  final BankAccount? _selectedBank = BankAccount(
      id: '1',
      name: 'BDO Unibank',
      number: '**** 1234',
      icon: 'assets/images/bank_bdo.png'
  );

  double _fee = 0.0;
  double _receiveAmount = 0.0;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_onAmountChanged);
  }

  void _onAmountChanged() {
    final val = double.tryParse(_amountCtrl.text) ?? 0.0;

    // 简单的费率逻辑：例如 1% 手续费
    final fee = val * 0.01;

    setState(() {
      _fee = fee;
      _receiveAmount = val - fee;
      _isValid = val >= _minWithdraw && val <= _balance;
    });
  }

  // 点击全部提现
  void _onMaxTap() {
    _amountCtrl.text = _balance.toStringAsFixed(2);
    _onAmountChanged(); // 触发计算
  }

  // 提交逻辑
  void _onSubmit() {
    if (!_isValid) return;

    // 审核关键点：必须弹出确认框或者跳转到密码输入页
    // 这里展示一个底部确认单（Bottom Sheet）
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConfirmWithdrawSheet(
        amount: _amountCtrl.text,
        fee: _fee,
        bankName: _selectedBank?.name ?? "",
        accountNumber: _selectedBank?.number ?? "",
        onConfirm: () {
          Navigator.pop(context);
          // TODO: 跳转到 PIN 码验证或生物识别
          // VerifyPinPage(...)
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Processing withdrawal..."))
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgSecondary,
      appBar: AppBar(
        title: Text("withdraw.title".tr(), style: TextStyle(color: context.textPrimary900, fontWeight: FontWeight.bold)),
        backgroundColor: context.bgPrimary,
        elevation: 0,
        leading: BackButton(color: context.textPrimary900),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 收款账户选择卡片 (显得正规)
            Text("withdraw.bank_account".tr(), style: TextStyle(fontSize: 14.sp, color: context.textSecondary700)),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.bgPrimary,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: InkWell(
                onTap: () {
                  // TODO: 打开银行选择列表
                },
                child: Row(
                  children: [
                    Container(
                      width: 40.w, height: 40.w,
                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.account_balance, color: Colors.blue, size: 24.w), // 占位图
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedBank?.name ?? "withdraw.select_bank".tr(),
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                          if (_selectedBank != null)
                            Text(_selectedBank!.number,
                                style: TextStyle(fontSize: 14.sp, color: context.textSecondary700)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: context.textSecondary700),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // 2. 金额输入核心区域
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: context.bgPrimary,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("withdraw.withdraw_amount".tr(), style: TextStyle(fontSize: 14.sp, color: context.textSecondary700)),
                      Text(
                          "${"withdraw.available_balance".tr()}: ${FormatHelper.formatCurrency(_balance)}",
                          style: TextStyle(fontSize: 12.sp, color: context.textSecondary700)
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 输入框
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("₱", style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold)),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "0.00",
                            hintStyle: TextStyle(color: context.textSecondary700.withOpacity(0.3)),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                      // 全部按钮
                      GestureDetector(
                        onTap: _onMaxTap,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
                          decoration: BoxDecoration(
                            color: context.bgSecondary,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text("MAX", style: TextStyle(color: context.textBrandPrimary900, fontWeight: FontWeight.bold, fontSize: 12.sp)),
                        ),
                      )
                    ],
                  ),
                  Divider(height: 24.w, color: context.borderSecondary),

                  // 错误提示或最低限额提示
                  if ((double.tryParse(_amountCtrl.text) ?? 0) > _balance)
                    Text("withdraw.max_amount_error".tr(), style: TextStyle(color: context.utilityError500, fontSize: 12.sp))
                        .animate().shake(duration: 300.ms),

                  if ((double.tryParse(_amountCtrl.text) ?? 0) <= _balance)
                    Text(
                        "withdraw.min_amount_hint".tr(namedArgs: {"amount": "₱$_minWithdraw"}),
                        style: TextStyle(color: context.textTertiary600, fontSize: 12.sp)
                    ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // 3. 费用明细 (Transparency - 审核加分项)
            if (_isValid) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Column(
                  children: [
                    _FeeRow(label: "withdraw.fee".tr(), value: "-${FormatHelper.formatCurrency(_fee)}"),
                    SizedBox(height: 8.h),
                    _FeeRow(
                        label: "withdraw.receive_amount".tr(),
                        value: FormatHelper.formatCurrency(_receiveAmount),
                        isTotal: true
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.5, end: 0),
            ],

            SizedBox(height: 40.h),

            // 4. 提交按钮
            SizedBox(
              width: double.infinity,
              height: 56.w,
              child: ElevatedButton(
                onPressed: _isValid ? _onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.textBrandPrimary900,
                  disabledBackgroundColor: context.textSecondary700.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  elevation: _isValid ? 4 : 0,
                ),
                child: Text(
                  "withdraw.confirm_btn".tr(),
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // 5. 底部合规声明 (Policy Notice - 审核必备)
            Center(
              child: Text(
                "withdraw.processing_time".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary700, fontSize: 12.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _FeeRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.textSecondary700, fontSize: 14.sp)),
        Text(
            value,
            style: TextStyle(
                color: isTotal ? context.textBrandPrimary900 : context.textPrimary900,
                fontSize: isTotal ? 16.sp : 14.sp,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal
            )
        ),
      ],
    );
  }
}

/// -----------------------------
/// 二次确认弹窗 (Bottom Sheet)
/// -----------------------------
class _ConfirmWithdrawSheet extends StatelessWidget {
  final String amount;
  final double fee;
  final String bankName;
  final String accountNumber;
  final VoidCallback onConfirm;

  const _ConfirmWithdrawSheet({
    required this.amount,
    required this.fee,
    required this.bankName,
    required this.accountNumber,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Confirm Withdraw", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 24.h),

          // 明细列表
          _DetailItem(label: "To", value: "$bankName ($accountNumber)"),
          _DetailItem(label: "Amount", value: "₱$amount"),
          _DetailItem(label: "Service Fee", value: "₱${fee.toStringAsFixed(2)}"),
          Divider(height: 32.h),
          _DetailItem(label: "Total Deducted", value: "₱${(double.parse(amount)).toStringAsFixed(2)}", isBold: true),

          SizedBox(height: 32.h),

          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.textBrandPrimary900,
              padding: EdgeInsets.symmetric(vertical: 16.w),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            child: const Text("Confirm & Transfer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailItem({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.textSecondary700, fontSize: 14.sp)),
          Text(value, style: TextStyle(color: context.textPrimary900, fontSize: 14.sp, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}