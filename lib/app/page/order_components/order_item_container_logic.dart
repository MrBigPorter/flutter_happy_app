part of 'order_item_container.dart';

/// Manages all business logic for OrderItemContainer
class OrderItemLogic {

  /// Handle Refund Request logic
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
          // Call Provider to submit the refund request
          final req = RefundApplyReq(orderId: item.orderId, reason: reason);
          final result = await ref.read(orderRefundApplyProvider.notifier).create(req);

          if (result != null) {
            RadixToast.success('Refund request submitted successfully.');
            // Crucial: Invalidate the provider to refresh UI
            ref.invalidate(orderDetailProvider(item.orderId));
            if (onRefresh != null) onRefresh();
          }
        },
      ),
    );
  }

  /// View Group Friends / Progress
  static void handleViewFriends(OrderItem item) {
    if (item.group != null) {
      // Redirect to the Group Room (better conversion & sharing features)
      appRouter.push('/group-room?groupId=${item.group!.groupId}');
    }
  }

  /// View Prize/Reward Details
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

  /// Continue Teaming Up
  static void handleTeamUp(OrderItem item) {
    appRouter.push('/me/order/${item.orderId}/team-up');
  }

  /// Claim Prize
  static void handleClaimPrize(OrderItem item) {
    appRouter.push('/me/order/${item.orderId}/claim-prize');
  }
}