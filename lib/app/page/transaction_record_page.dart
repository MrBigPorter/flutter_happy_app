import 'package:flutter/material.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/theme/index.dart'; // 🔥 确保引入了你的主题扩展
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 1. 定义记录类型枚举
enum TransactionType { deposit, refund }

// 2. 模拟数据模型
class TransactionRecord {
  final String id;
  final String title;
  final double amount;
  final DateTime time;
  final String status; // 'SUCCESS', 'PENDING', 'FAILED'
  final TransactionType type;
  final String orderNo;

  TransactionRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.time,
    required this.status,
    required this.type,
    required this.orderNo,
  });
}

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<TransactionRecord> _mockData = [
    TransactionRecord(id: '1', title: 'Deposit via GCash', amount: 100, time: DateTime.now(), status: 'SUCCESS', type: TransactionType.deposit, orderNo: 'DEP20260105001'),
    TransactionRecord(id: '2', title: 'Deposit via GrabPay', amount: 500, time: DateTime.now().subtract(const Duration(hours: 2)), status: 'PENDING', type: TransactionType.deposit, orderNo: 'DEP20260105002'),
    TransactionRecord(id: '3', title: 'Refund: Order Error', amount: 100, time: DateTime.now().subtract(const Duration(days: 1)), status: 'SUCCESS', type: TransactionType.refund, orderNo: 'REF20260104001'),
    TransactionRecord(id: '4', title: 'Refund: System', amount: 50, time: DateTime.now().subtract(const Duration(days: 2)), status: 'FAILED', type: TransactionType.refund, orderNo: 'REF20260103009'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      backgroundColor: context.bgSecondary,
      body: Column(
        children: [
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(TransactionType.deposit),
                _buildList(TransactionType.refund),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: context.bgPrimary, // 🔥 替换：白色背景
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          // 🔥 替换：槽位背景 (通常是浅灰色)
          color: context.bgSecondary, // 或者 context.utilityGray100
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: context.bgPrimary, // 🔥 替换：选中项背景 (白)
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              // 🔥 替换：阴影颜色建议调淡
              BoxShadow(
                  color: context.textPrimary900.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2)
              ),
            ],
          ),
          // 🔥 替换：选中文字颜色 (黑)
          labelColor: context.textPrimary900,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
          // 🔥 替换：未选中文字颜色 (灰)
          unselectedLabelColor: context.textTertiary600,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          padding: EdgeInsets.all(4.w),
          tabs: const [
            Tab(text: "Deposit"),
            Tab(text: "Refund"),
          ],
        ),
      ),
    );
  }

  Widget _buildList(TransactionType type) {
    final filteredList = _mockData.where((e) => e.type == type).toList();

    if (filteredList.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: filteredList.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return _TransactionCard(record: filteredList[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64.w, color: context.utilityGray300), // 🔥 替换
          SizedBox(height: 16.h),
          Text(
              "No records found",
              style: TextStyle(color: context.textTertiary600, fontSize: 14.sp) // 🔥 替换
          ),
        ],
      ),
    );
  }
}

// --- 单条记录卡片组件 ---
class _TransactionCard extends StatelessWidget {
  final TransactionRecord record;

  const _TransactionCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isDeposit = record.type == TransactionType.deposit;

    // 🔥 颜色定义：全部走 Theme
    // 存款用 Success (绿), 退款用 Brand (紫/蓝)
    final amountColor = isDeposit ? context.utilitySuccess500 : context.utilityBrand500;

    // 图标背景：使用 50 或 100 这种极浅色，或者用 withOpacity
    final iconBg = isDeposit
        ? context.utilitySuccess50  // 假设你有 50 的色阶
        : context.utilityBrand50;   // 如果没有，用 context.utilityBrand500.withOpacity(0.1)

    final iconColor = isDeposit ? context.utilitySuccess500 : context.utilityBrand500;

    final iconData = isDeposit ? Icons.account_balance_wallet : Icons.keyboard_return;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.bgPrimary, // 🔥 替换：卡片背景
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: context.textPrimary900.withOpacity(0.02), // 🔥 替换：阴影
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. 左侧图标
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 24.w),
          ),
          SizedBox(width: 12.w),

          // 2. 中间信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary900 // 🔥 替换：主标题色
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  "${record.time.year}-${record.time.month}-${record.time.day} ${record.time.hour}:${record.time.minute.toString().padLeft(2,'0')}",
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textSecondary700 // 🔥 替换：次级标题色
                  ),
                ),
              ],
            ),
          ),

          // 3. 右侧金额与状态
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "+${record.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
              ),
              SizedBox(height: 6.h),
              _buildStatusBadge(context, record.status), // 传 context
            ],
          ),
        ],
      ),
    );
  }

  // 状态胶囊
  Widget _buildStatusBadge(BuildContext context, String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'SUCCESS':
      // 🔥 替换：使用主题色
        bg = context.utilitySuccess50;
        text = context.utilitySuccess500;
        label = 'Success';
        break;
      case 'PENDING':
      // 🔥 替换：使用主题色
        bg = context.utilityWarning50;
        text = context.utilityWarning500;
        label = 'Pending';
        break;
      case 'FAILED':
      // 🔥 替换：使用主题色
        bg = context.utilityError50;
        text = context.utilityError500;
        label = 'Failed';
        break;
      default:
        bg = context.utilityGray100;
        text = context.textSecondary700;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 10.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}