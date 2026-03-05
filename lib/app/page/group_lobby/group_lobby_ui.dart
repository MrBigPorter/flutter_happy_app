part of 'group_lobby_page.dart';

// =========================================================
// 单个拼团卡片
// =========================================================
class GroupLobbyCard extends StatelessWidget {
  final GroupForTreasureItem item;
  final String treasureId;
  final bool showProductInfo;

  const GroupLobbyCard({
    super.key,
    required this.item,
    required this.treasureId,
    this.showProductInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final int endTime = item.adjustedEndTime;
    final treasure = item.treasure;

    //  核心状态推断
    final bool isCompleted = item.isCompleted;
    // 注意：请确保后端返回了 isJoined 字段，如果没有，需让后端加上
    final bool isJoined = item.isJoined ?? false;

    // --- 动态计算按钮 UI 与事件 ---
    String btnText;
    Color btnColor;
    VoidCallback? onTapAction;

    if (isCompleted) {
      // 1. 已完成/已满员
      btnText = 'group_lobby.btn_full'.tr(); // "Full"
      btnColor = Colors.grey[400]!;
      onTapAction = null; // 禁用点击
    } else if (isJoined) {
      // 2. 已参与 -> 邀请裂变
      btnText = 'Invite';
      btnColor = const Color(0xFFFF8A00); // 橘色，区别于红色的购买
      onTapAction = () {
        ShareManager.startShare(
          context,
          ShareContent.group(
            id: treasureId,
            groupId: item.groupId,
            title: treasure?.treasureName ?? '',
            imageUrl: treasure?.treasureCoverImg ?? '',
            desc: "I just joined this group! We need more people, let's win together!",
          ),
        );
      };
    } else {
      // 3. 未参与 -> 立即加入
      btnText = 'group_lobby.btn_join_now'.tr(); // "Join Now"
      btnColor = const Color(0xFFFF4D4F); // 品牌红
      onTapAction = () {
        appRouter.push('/payment?treasureId=$treasureId&groupId=${item.groupId}&isGroupBuy=true');
      };
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          if (showProductInfo && treasure != null) _buildProductSection(context, treasure),
          Row(
            children: [
              AppCachedImage(
                item.creator.avatar,
                width: 40.w, height: 40.h, fit: BoxFit.cover,
                radius: BorderRadius.circular(20.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.creator.nickname ?? 'group_lobby.default_user'.tr(),
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textPrimary900),
                    ),
                    SizedBox(height: 4.h),
                    isCompleted
                        ? Text('group_lobby.status_success'.tr(), style: TextStyle(fontSize: 12.sp, color: const Color(0xFF52C41A), fontWeight: FontWeight.bold))
                        : RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
                        children: [
                          TextSpan(text: 'group_lobby.short_of'.tr()),
                          TextSpan(text: '${item.maxMembers - item.currentMembers}', style: const TextStyle(color: Color(0xFFFF4D4F), fontWeight: FontWeight.bold)),
                          TextSpan(text: 'group_lobby.people_count_suffix'.tr()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  isCompleted
                      ? Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 14.sp, color: const Color(0xFF52C41A)),
                        SizedBox(width: 2.w),
                        Text('group_lobby.status_done'.tr(), style: TextStyle(fontSize: 12.sp, color: const Color(0xFF52C41A))),
                      ],
                    ),
                  )
                      : CountdownTimer(
                    endTime: endTime,
                    widgetBuilder: (_, time) {
                      if (time == null) return Text('group_lobby.status_ended'.tr(), style: TextStyle(fontSize: 11.sp, color: context.textDisabled));
                      String pad(int? n) => (n ?? 0).toString().padLeft(2, '0');
                      return Row(
                        children: [
                          Icon(Icons.access_time, size: 12.sp, color: context.textSecondary700),
                          SizedBox(width: 4.w),
                          Text('${pad(time.hours)}:${pad(time.min)}:${pad(time.sec)}', style: TextStyle(fontSize: 12.sp, color: context.textSecondary700, fontWeight: FontWeight.w500)),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 8.h),
                  //  动态渲染配置好的按钮
                  SizedBox(
                    height: 30.h,
                    child: ElevatedButton(
                      onPressed: onTapAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        disabledBackgroundColor: btnColor, // 满员时保持灰色
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                        elevation: 0,
                      ),
                      child: Text(btnText, style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(BuildContext context, dynamic treasure) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => appRouter.push('/product/${treasure.treasureId}'),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: AppCachedImage(treasure.treasureCoverImg, width: 48.w, height: 48.w, fit: BoxFit.cover),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(treasure.treasureName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: context.textPrimary900)),
                    SizedBox(height: 2.h),
                    Text(FormatHelper.formatCurrency(treasure.unitAmount), style: TextStyle(fontSize: 14.sp, color: context.textBrandPrimary900, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 16.h, color: context.borderPrimary),
      ],
    );
  }
}

// =========================================================
// 顶部商品头 (针对单品详情的大厅)
// =========================================================
class _ProductHeaderInfo extends StatelessWidget {
  final dynamic product;
  const _ProductHeaderInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: context.bgPrimary, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(4.r), child: AppCachedImage(product.treasureCoverImg, width: 40.w, height: 40.w, fit: BoxFit.cover)),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.treasureName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                Text('group_lobby.header_subtitle'.tr(), style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 骨架屏
// =========================================================
class GroupLobbySkeleton extends StatelessWidget {
  final bool showProductInfo;
  const GroupLobbySkeleton({super.key, this.showProductInfo = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: context.bgPrimary, borderRadius: BorderRadius.circular(12.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProductInfo) ...[
            Row(
              children: [
                Skeleton.react(width: 48.w, height: 48.w, borderRadius: BorderRadius.circular(4.r)),
                SizedBox(width: 10.w),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Skeleton.react(width: 120.w, height: 14.sp), SizedBox(height: 6.h), Skeleton.react(width: 60.w, height: 14.sp)])),
              ],
            ),
            SizedBox(height: 16.h),
          ],
          Row(
            children: [
              Skeleton.react(width: 40.w, height: 40.w, borderRadius: BorderRadius.circular(4.r)),
              SizedBox(width: 12.w),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Skeleton.react(width: 80.w, height: 14.sp), SizedBox(height: 6.h), Skeleton.react(width: 100.w, height: 12.sp)])),
              Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Skeleton.react(width: 50.w, height: 10.sp), SizedBox(height: 8.h), Skeleton.react(width: 80.w, height: 30.h, borderRadius: BorderRadius.circular(15.r))]),
            ],
          ),
        ],
      ),
    );
  }
}