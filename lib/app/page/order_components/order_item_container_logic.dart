part of 'order_item_container.dart';

/// 统一管理 OrderItemContainer 的所有业务逻辑
class OrderItemLogic {

  /// 处理退款请求逻辑
  static void handleRequestRefund(
      BuildContext context,
      WidgetRef ref,
      OrderItem item,
      VoidCallback? onRefresh,
      ) {
    RadixSheet.show(
      builder: (ctx, close) => RefundRequestSheet(
        orderId: item.orderId,
        amount: '₱${item.finalAmount}',
        onSubmit: (reason) async {
          Navigator.pop(ctx);
          // 调用 Provider 进行退款申请
          final req = RefundApplyReq(orderId: item.orderId, reason: reason);
          final result = await ref.read(orderRefundApplyProvider.notifier).create(req);

          if (result != null) {
            RadixToast.success('Refund request submitted successfully.');
            // 关键：刷新列表和详情，UI 才会变
            ref.invalidate(orderDetailProvider(item.orderId));
            if (onRefresh != null) onRefresh();
          }
        },
      ),
    );
  }

  /// 查看拼团好友
  static void handleViewFriends(OrderItem item) {
    if (item.group != null) {
      appRouter.push('/group-member/?groupId=${item.group!.groupId}');
    }
  }

  /// 查看奖品详情
  static void handleViewRewardDetails(BuildContext context, OrderItem item) {
    Navigator.of(context).push(
      TransparentFadeRoute(
        child: OrderDetailPage(
          orderId: item.orderId,
          imageList: [item.treasure.treasureCoverImg],
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// 继续拼团
  static void handleTeamUp(OrderItem item) {
    appRouter.push('/me/order/${item.orderId}/team-up');
  }

  /// 领奖
  static void handleClaimPrize(OrderItem item) {
    appRouter.push('/me/order/${item.orderId}/claim-prize');
  }
}