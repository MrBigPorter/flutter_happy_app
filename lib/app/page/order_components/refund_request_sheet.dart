import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/common.dart'; // 你的主题扩展
import 'package:flutter_app/ui/button/button.dart'; // 你的 Button 组件

class RefundRequestSheet extends StatefulWidget {
  final String orderId;
  final String amount;
  final Function(String reason) onSubmit; // 回调选中的原因

  const RefundRequestSheet({
    super.key,
    required this.orderId,
    required this.amount,
    required this.onSubmit,
  });

  @override
  State<RefundRequestSheet> createState() => _RefundRequestSheetState();
}

class _RefundRequestSheetState extends State<RefundRequestSheet> {
  // 预设退款原因 (建议后期从后端配置接口获取)
  final List<String> _reasons = [
    "Bought by mistake",
    "Found a better price",
    "Item out of stock",
    "Product looks different",
    "Other reasons"
  ];

  String? _selectedReason; // 当前选中的原因
  bool _isSubmitting = false; // 防止重复点击

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min, // 高度自适应
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // 2. 标题
          Text(
            "Request Refund",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: context.textPrimary900,
            ),
          ),
          SizedBox(height: 8.w),

          // 3. 退款金额提示
          Text(
            "Refund Amount: ${widget.amount}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.textSecondary700,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 24.w),

          // 4. 原因选择列表标题
          Text(
            "Reason for refund",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: context.textPrimary900,
            ),
          ),
          SizedBox(height: 12.w),

          // 5. 原因列表
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: _reasons.map((reason) => _buildReasonItem(reason)).toList(),
              ),
            ),
          ),

          SizedBox(height: 24.w),

          // 6. 确认按钮
          Button(
            height: 48.w,
            loading: _isSubmitting, // 支持 Loading 状态
            disabled: _selectedReason == null, // 没选原因时禁用！
            onPressed: () async {
              setState(() => _isSubmitting = true);

              // 模拟一点延迟，让用户感觉系统在处理
              await Future.delayed(const Duration(milliseconds: 500));

              if (mounted) {
                widget.onSubmit(_selectedReason!);
                // 注意：这里不要 pop，交给父组件去处理关闭，或者在这里关闭
              }
            },
            child: const Text("Confirm Refund"),
          ),
        ],
      ),
    );
  }

  // 构建单个原因选项
  Widget _buildReasonItem(String reason) {
    final isSelected = _selectedReason == reason;

    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
        decoration: BoxDecoration(
          // 选中时给一个淡淡的品牌色背景
          color: isSelected
              ? context.textBrandPrimary900.withOpacity(0.05)
              : context.bgSecondary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
            // 选中时边框变色
            color: isSelected
                ? context.textBrandPrimary900
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reason,
                style: TextStyle(
                  fontSize: 14.sp,
                  // 选中时文字加粗
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? context.textBrandPrimary900 : context.textPrimary900,
                ),
              ),
            ),
            // 选中显示对勾，未选中显示空圈
            if (isSelected)
              Icon(Icons.check_circle, color: context.textBrandPrimary900, size: 20.w)
            else
              Icon(Icons.circle_outlined, color: context.textTertiary600, size: 20.w),
          ],
        ),
      ),
    );
  }
}