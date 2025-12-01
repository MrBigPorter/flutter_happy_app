import 'dart:ui'; // 用于 ImageFilter
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 引入上面写好的文件
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/button/button.dart';
import '../../core/providers/order_provider.dart';
import '../../core/models/index.dart'; // 假设你的 Model 在这
import '../../utils/date_helper.dart'; // 假设你的工具在这

// 你的 Banner 组件 (假设路径)
import 'package:flutter_app/components/swiper_banner.dart';

import 'order_components/airbnb_scaffold.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;
  final List<String> imageList;
  final VoidCallback onClose;

  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.imageList,
    required this.onClose,
  });

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  // 记录滚动距离，用于 Header 变色
  double _scrollOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    final orderDetailAsyncValue = ref.watch(orderDetailProvider(widget.orderId));
    final double bottomBarHeight = 80.w;

    return orderDetailAsyncValue.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Error: $e')),
      ),
      data: (orderDetail) {
        return AirbnbStyleScaffold(
          heroTag: 'order_card_${widget.orderId}',
          onDismiss: widget.onClose,

          // 底部按钮栏
          bottomBar: _buildBottomBar(context, orderDetail.treasureId, bottomBarHeight),

          // 悬浮 Header (重点！)
          // 传入当前的 scrollOffset 以便内部计算透明度和颜色
          floatingHeader: AirbnbDynamicHeader(
            scrollOffset: _scrollOffset,
            title: orderDetail.treasure.treasureName,
            onClose: widget.onClose,
          ),

          // 页面主体内容
          bodyBuilder: (context, scrollController, physics) {
            // 监听滚动，更新 Header 状态
            // 注意：这里使用 NotificationListener 可以更高效地监听，避免频繁 rebuild 整个 Scaffold
            return NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) {
                // 只有当 scrollOffset 变化显著时才 setState，优化性能
                if (notification.metrics.axis == Axis.vertical) {
                  final newOffset = notification.metrics.pixels;
                  // 简单的节流或者阈值判断，避免每一帧都 setState
                  // 这里为了流畅度直接 set，Flutter 这一层通常能扛得住
                  if ((newOffset - _scrollOffset).abs() > 1) {
                    // 使用微任务，防止 build 周期冲突
                    if (mounted) {
                      setState(() => _scrollOffset = newOffset);
                    }
                  }
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: scrollController,
                physics: physics,
                padding: EdgeInsets.zero, // 顶部不要留白，Banner 要顶头
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner 区域
                    SizedBox(
                      height: 356.w,
                      child: SwiperBanner(
                        banners: widget.imageList,
                        height: 356.w,
                        showIndicator: true,
                        borderRadius: 0, // Banner 直角，因为在最顶端
                      ),
                    ),

                    // 详情内容
                    _OrderDetailBody(orderDetail: orderDetail),

                    // 底部垫高
                    SizedBox(height: bottomBarHeight + MediaQuery.of(context).padding.bottom + 16.w),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, String treasureId, double height) {
    return Container(
      height: height + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.fromLTRB(32.w, 16.w, 32.w, 16.w + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Button(
            width: 150.w,
            onPressed: () => appRouter.push('/product/$treasureId'),
            child: Text('common.view.friends'.tr()),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// Airbnb 风格的动态 Header
/// ---------------------------------------------------------
class AirbnbDynamicHeader extends StatelessWidget {
  final double scrollOffset;
  final String title;
  final VoidCallback onClose;

  const AirbnbDynamicHeader({
    super.key,
    required this.scrollOffset,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top;
    const height = kToolbarHeight;

    // 计算渐变进度
    // 0 ~ 100px 之间发生渐变
    final double opacity = (scrollOffset / 120.0).clamp(0.0, 1.0);

    // 颜色插值：从白色变为黑色
    // 0.0 (顶部) -> 白色
    // 1.0 (滚动后) -> 黑色
    final Color iconColor = Color.lerp(Colors.white, Colors.black, opacity)!;

    // 阴影：只有在白色图标时(顶部)才需要阴影，变黑后阴影消失
    final List<Shadow>? iconShadow = opacity < 0.5
        ? [const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))]
        : null;

    return Container(
      height: paddingTop + height,
      padding: EdgeInsets.only(top: paddingTop),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity), // 背景逐渐变白
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.15 * opacity), // 分割线也渐显
            width: 1,
          ),
        ),
      ),
      child: NavigationToolbar(
        // 左侧：返回按钮
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            alignment: Alignment.centerLeft,
            child: Icon(
              Icons.arrow_back,
              color: iconColor,
              size: 24,
              shadows: iconShadow,
            ),
          ),
        ),

        // 中间：标题 (渐显)
        middle: Opacity(
          opacity: opacity, // 标题跟随背景一起渐显
          child: Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
            ),
          ),
        ),

        // 右侧：分享按钮
        trailing: GestureDetector(
          onTap: () {
            // Share logic
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.ios_share,
              color: iconColor,
              size: 22,
              shadows: iconShadow,
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------
/// 商品内容展示组件 (保持不变或微调)
/// ---------------------------------------------------------
class _OrderDetailBody extends StatelessWidget {
  final OrderDetailItem orderDetail;

  const _OrderDetailBody({required this.orderDetail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderDetail.treasure.treasureName,
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8.w),
              Text(
                '${orderDetail.buyQuantity} items',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey[200]),
        // ... 继续你的订单信息展示 ...
        // 模拟长内容
        for(var i=0; i<5; i++)
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text("Detailed info line $i ...", style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }
}