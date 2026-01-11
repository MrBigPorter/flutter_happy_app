import 'package:easy_localization/easy_localization.dart'; // 🔥 必须引入
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 项目内部依赖
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/list.dart'; // PageListController, PageListViewPro
import 'package:flutter_app/core/models/groups.dart';
import 'package:flutter_app/core/providers/index.dart'; // productDetailProvider
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/utils/format_helper.dart';

import '../../ui/button/button.dart';


// 2. 页面主体
// =========================================================
class GroupLobbyPage extends ConsumerStatefulWidget {
  final String? treasureId;

  const GroupLobbyPage({super.key, this.treasureId});

  @override
  ConsumerState<GroupLobbyPage> createState() => _GroupLobbyPageState();
}

class _GroupLobbyPageState extends ConsumerState<GroupLobbyPage>
    with AutomaticKeepAliveClientMixin {

  late PageListController<GroupForTreasureItem> _ctl;

  // 辅助 getter：是否是全品类广场模式
  bool get isGlobalMode => widget.treasureId == null;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _ctl = PageListController<GroupForTreasureItem>(
      requestKey: widget.treasureId ?? 'global_group_lobby',
      request: ({required int pageSize, required int page}) {
        // 修正：建议直接传 widget.treasureId，让 Provider 处理空值逻辑
        final requestFunc = ref.read(groupsPageListProvider(widget.treasureId ?? ''));
        return requestFunc(pageSize: pageSize, page: page);
      },
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 只有在单品模式下，才去监听商品详情
    final productAsync = isGlobalMode
        ? null
        : ref.watch(productDetailProvider(widget.treasureId!));

    return BaseScaffold(
      // 🌐 国际化：标题
      title: isGlobalMode
          ? 'group_lobby.title_plaza'.tr()
          : 'group_lobby.title_active'.tr(),

      bottomNavigationBar: isGlobalMode ? null : Container(
        padding: EdgeInsets.fromLTRB(16.w, 10.w, 16.w, 34.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 44.h,
          child: Button(
            radius: 22.r,
            onPressed: () {
              if (widget.treasureId != null) {
                appRouter.push('/payment?treasureId=${widget.treasureId}&isGroupBuy=true');
              }
            },
            child: Text(
              // 🌐 国际化：发起拼团按钮
              'group_lobby.btn_start_new'.tr(),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: context.textPrimary900),
            ),
          ),
        ),
      ),

      body: _ctl.wrapWithNotification(
        child: ExtendedVisibilityDetector(
          uniqueKey: Key('group_lobby_${widget.treasureId ?? 'global'}'),
          child: RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await _ctl.refresh();
            },
            color: const Color(0xFFFF4D4F),
            backgroundColor: Colors.white,
            displacement: 40.h,

            child: CustomScrollView(
              key: PageStorageKey('group_lobby_storage_${widget.treasureId ?? 'global'}'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 只有单品模式才显示顶部的 Product Header
                if (!isGlobalMode && productAsync != null)
                  SliverToBoxAdapter(
                    child: productAsync.when(
                      data: (product) => _buildProductHeader(product),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                // 分页列表
                PageListViewPro<GroupForTreasureItem>(
                  controller: _ctl,
                  sliverMode: true,
                  separatorSpace: 10.h,
                  padding: EdgeInsets.all(12.w),

                  itemBuilder: (context, item, index, isLast) {
                    return GroupLobbyCard(
                      item: item,
                      treasureId: widget.treasureId ?? item.treasureId,
                      showProductInfo: isGlobalMode,
                    );
                  },

                  skeletonBuilder: (context, {bool isLast = false}) {
                    return Padding(
                      padding: EdgeInsets.only(top: 20.h),
                      child: const GroupLobbySkeleton(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader(dynamic product) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: AppCachedImage(
              product.treasureCoverImg,
              width: 40.w,
              height: 40.w,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.treasureName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
                Text(
                  // 🌐 国际化：头部副标题
                  'group_lobby.header_subtitle'.tr(),
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// =========================================================
// 3. 列表项组件 (支持显示商品信息)
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
    final int endTime = item.expireAt < 10000000000 ? item.expireAt * 1000 : item.expireAt;
    final treasure = item.treasure;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          //  1. 商品信息区
          if (showProductInfo && treasure != null) ...[
            GestureDetector(
              onTap: () {
                appRouter.push('/product/${treasure.treasureId}');
              },
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: AppCachedImage(
                      treasure.treasureCoverImg,
                      width: 48.w,
                      height: 48.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          treasure.treasureName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: context.textPrimary900),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          FormatHelper.formatCurrency(treasure.unitAmount),
                          style: TextStyle(fontSize: 14.sp, color: context.textBrandPrimary900, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 16.h, color: context.borderPrimary),
          ],

          //  2. 拼团核心信息
          Row(
            children: [
              AppCachedImage(
                item.creator.avatar,
                width: 40.w,
                height: 40.h,
                fit: BoxFit.cover,
                radius: BorderRadius.circular(20.r),
                error: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: context.bgSecondary,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(Icons.person, size: 24.sp, color: context.textSecondary700),
                ),
                placeholder:  Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: context.textSecondary700,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(Icons.person, size: 24.sp, color: context.bgPrimary),
                ),
              ),
              SizedBox(width: 12.w),

              // 中间信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // 🌐 国际化：用户名 fallback
                      item.creator.nickname ?? 'group_lobby.default_user'.tr(),
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textPrimary900),
                    ),
                    SizedBox(height: 4.h),
                    // 🌐 国际化：差几人 (RichText)
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
                        children: [
                          TextSpan(text: 'group_lobby.short_of'.tr()), // "Short of "
                          TextSpan(
                            text: '${item.maxMembers - item.currentMembers}',
                            style: const TextStyle(color: Color(0xFFFF4D4F), fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: 'group_lobby.people_count_suffix'.tr()), // " people"
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 右侧倒计时 + 按钮
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CountdownTimer(
                    endTime: endTime,
                    widgetBuilder: (_, time) {
                      // 🌐 国际化：倒计时结束
                      if (time == null) return Text('group_lobby.status_ended'.tr(), style: TextStyle(fontSize: 11.sp, color: context.textDisabled));
                      String pad(int? n) => (n ?? 0).toString().padLeft(2, '0');
                      return Row(
                        children: [
                          Icon(Icons.access_time, size: 12.sp, color: context.textSecondary700),
                          SizedBox(width: 4.w),
                          Text(
                            '${pad(time.hours)}:${pad(time.min)}:${pad(time.sec)}',
                            style: TextStyle(fontSize: 12.sp, color: context.textSecondary700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 30.h,
                    child: Button(
                      width: 80.w,
                      onPressed: () {
                        appRouter.push('/payment?treasureId=$treasureId&groupId=${item.groupId}&isGroupBuy=true');
                      },
                      radius: 15.r,
                      child: Text(
                        // 🌐 国际化：加入按钮
                          'group_lobby.btn_join_now'.tr(),
                          style: TextStyle(fontSize: 12.sp)
                      ),
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
}

// 骨架屏无需国际化，保持原样即可
class GroupLobbySkeleton extends StatelessWidget {
  final bool showProductInfo;

  const GroupLobbySkeleton({
    super.key,
    this.showProductInfo = false
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProductInfo) ...[
            Row(
              children: [
                Skeleton.react(width: 48.w, height: 48.w, borderRadius: BorderRadius.circular(4.r),),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.react(width: 120.w, height: 14.sp),
                      SizedBox(height: 6.h),
                      Skeleton.react(width: 60.w, height: 14.sp),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: 16.h),
          ],
          Row(
            children: [
              Skeleton.react(width: 40.w, height: 40.w, borderRadius: BorderRadius.circular(4.r),),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.react(width: 80.w, height: 14.sp),
                    SizedBox(height: 6.h),
                    Skeleton.react(width: 100.w, height: 12.sp),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Skeleton.react(width: 50.w, height: 10.sp),
                  SizedBox(height: 8.h),
                  Skeleton.react(width: 80.w, height: 30.h, borderRadius: BorderRadius.circular(15.r),),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}