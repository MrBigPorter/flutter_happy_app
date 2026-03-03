import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/models/user_coupon.dart';
import 'package:flutter/cupertino.dart';

import '../../core/providers/coupon_provider.dart';

class MyVouchersPage extends StatefulWidget {
  const MyVouchersPage({super.key});

  @override
  State<MyVouchersPage> createState() => _MyVouchersPageState();
}

class _MyVouchersPageState extends State<MyVouchersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['Valid', 'Used', 'Invalid'];
  // 对应的状态枚举：0-可用, 1-已使用, 2-已过期
  final List<int> _tabStatus = [0, 1, 2];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'My Vouchers',
      elevation: 0,
      body: Column(
        children: [
          Container(
            color: context.bgPrimary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: context.textBrandPrimary900,
              labelColor: context.textBrandPrimary900,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3.w,
              labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabStatus.map((status) {
                return _VoucherTabContent(status: status);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 每个 Tab 的独立列表组件
// =========================================================================
class _VoucherTabContent extends ConsumerWidget {
  final int status;

  const _VoucherTabContent({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 根据状态分别获取各自的数据流
    final asyncData = ref.watch(myCouponsByStatusProvider(status));

    return asyncData.when(
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No vouchers found',
              style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            ),
          );
        }

        // 渲染纵向列表
        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.w),
          itemBuilder: (context, index) {
            final item = list[index];
            return _VerticalCouponCard(item: item, status: status);
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

// =========================================================================
// 纵向大尺寸的优惠券卡片 (列表里的每一项)
// =========================================================================
class _VerticalCouponCard extends StatelessWidget {
  final UserCoupon item;
  final int status;

  const _VerticalCouponCard({required this.item, required this.status});

  @override
  Widget build(BuildContext context) {
    final isInvalid = status != 0;

    return Container(
      height: 100.w,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(8.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // 左侧：金额区
          Container(
            width: 100.w,
            decoration: BoxDecoration(
              color: isInvalid ? context.bgQuaternary : context.utilityBrand500,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(8.w)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.couponType == 2 ? '${item.discountValue}%' : '₱${item.discountValue}',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: isInvalid ? context.textSecondary700 : context.textWhite,
                  ),
                ),
                SizedBox(height: 4.w),
                Text(
                  'Min ₱${item.minPurchase}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isInvalid ? context.textSecondary700 : context.textWhite,
                  ),
                ),
              ],
            ),
          ),

          // 右侧：信息区
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.couponName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isInvalid ? context.textSecondary700 : context.textPrimary900,
                    ),
                  ),
                  Text(
                    'Valid until: ${DateTime.fromMillisecondsSinceEpoch(item.validEndAt).toString().substring(0, 10)}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.textPlaceholder,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}