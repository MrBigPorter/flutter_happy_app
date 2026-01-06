import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/button/button.dart';

class RefundRequestSheet extends StatefulWidget {
  final String orderId;
  final String amount;
  final Function(String reason) onSubmit;

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
  // 预设退款原因
  final List<String> _reasons = [
    "Bought by mistake",
    "Found a better price",
    "Item out of stock",
    "Product looks different",
    "Other reasons" // 选中这个会显示输入框
  ];

  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  // 提交逻辑
  void _handleSubmit() async {
    setState(() => _isSubmitting = true);

    // 1. 确定最终提交的文本
    String finalReason = _selectedReason!;
    // 如果选的是"Other"，则使用输入框的内容
    if (_selectedReason == "Other reasons") {
      final input = _otherReasonController.text.trim();
      if (input.isNotEmpty) {
        finalReason = "Other: $input";
      } else {
        // 如果没填具体的其他原因，也可以直接传 "Other reasons" 或者拦截提示
        finalReason = "Other reasons";
      }
    }


    if (mounted) {
      widget.onSubmit(finalReason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      // 底部 padding 加上键盘高度，保证内容不被遮挡
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- 头部 ---
          Padding(
            padding: EdgeInsets.only(top: 16.w, bottom: 8.w),
            child: Text(
              "Request Refund",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: context.textPrimary900,
              ),
            ),
          ),

          Text(
            "Refund Amount: ${widget.amount}",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.textSecondary700,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20.w),

          // --- 标题 ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              "Reason for refund",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: context.textPrimary900,
              ),
            ),
          ),
          SizedBox(height: 12.w),

          // --- 列表区域 (使用 Flexible 防止高度溢出) ---
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  ..._reasons.map((reason) => _buildReasonItem(reason)),


                  if (_selectedReason == "Other reasons")
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.w, left: 4.w, right: 4.w),
                      child: TextField(
                        controller: _otherReasonController,
                        maxLines: 3,
                        maxLength: 200,
                        decoration: InputDecoration(
                          hintText: "Please describe your reason...",
                          hintStyle: TextStyle(color: context.textSecondary700, fontSize: 13.sp),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.w),
                            borderSide: BorderSide(color: context.borderPrimary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.w),
                            borderSide: BorderSide(color: context.borderPrimary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.w),
                            borderSide: BorderSide(color: context.textBrandPrimary900),
                          ),
                          contentPadding: EdgeInsets.all(12.w),
                          filled: true,
                          fillColor: context.bgSecondary.withOpacity(0.3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.w),

          // --- 底部按钮 ---
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w + MediaQuery.of(context).padding.bottom), // 适配 iPhone 底部条
            child: Button(
              height: 48.w,
              loading: _isSubmitting,
              disabled: _selectedReason == null,
              onPressed: _handleSubmit,
              child: const Text("Confirm Refund"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonItem(String reason) {
    final isSelected = _selectedReason == reason;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = reason;
          // 如果切走了，清空输入框内容？视需求而定，这里不清空体验好点
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.w),
        decoration: BoxDecoration(
          color: isSelected
              ? context.textBrandPrimary900.withOpacity(0.05)
              : context.bgSecondary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(
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
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? context.textBrandPrimary900 : context.textPrimary900,
                ),
              ),
            ),
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