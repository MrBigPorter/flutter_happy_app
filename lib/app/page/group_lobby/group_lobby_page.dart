import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/services/socket/socket_service.dart';
import 'package:flutter_app/ui/img/app_image.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/list.dart';
import 'package:flutter_app/core/models/groups.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/utils/format_helper.dart';

import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/features/share/models/share_content.dart';
import 'package:flutter_app/features/share/services/app_share_manager.dart';
import 'package:flutter_app/ui/button/button.dart';

part 'group_lobby_logic.dart';
part 'group_lobby_ui.dart';

class GroupLobbyPage extends ConsumerStatefulWidget {
  final String? treasureId;

  const GroupLobbyPage({super.key, this.treasureId});

  @override
  ConsumerState<GroupLobbyPage> createState() => _GroupLobbyPageState();
}

class _GroupLobbyPageState extends ConsumerState<GroupLobbyPage>
    with AutomaticKeepAliveClientMixin, GroupLobbyLogic {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    initLobbyLogic(); // 调用 Logic 中的初始化
  }

  @override
  void dispose() {
    disposeLobbyLogic(); // 调用 Logic 中的销毁
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final productAsync = isGlobalMode ? null : ref.watch(productDetailProvider(widget.treasureId!));

    return BaseScaffold(
      title: isGlobalMode ? 'group_lobby.title_plaza'.tr() : 'group_lobby.title_active'.tr(),
      bottomNavigationBar: isGlobalMode ? null : _buildBottomBar(context),
      body: listCtl.wrapWithNotification(
        child: ExtendedVisibilityDetector(
          uniqueKey: Key('group_lobby_${widget.treasureId ?? 'global'}'),
          child: RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await listCtl.refresh();
            },
            color: const Color(0xFFFF4D4F),
            backgroundColor: Colors.white,
            displacement: 40.h,
            child: CustomScrollView(
              key: PageStorageKey('group_lobby_storage_${widget.treasureId ?? 'global'}'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (!isGlobalMode && productAsync != null)
                  SliverToBoxAdapter(
                    child: productAsync.when(
                      data: (product) => _ProductHeaderInfo(product: product),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                PageListViewPro<GroupForTreasureItem>(
                  controller: listCtl,
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
                      child: const GroupLobbySkeleton(showProductInfo: false),
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

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.w, 16.w, 34.w),
      decoration: BoxDecoration(color: context.bgPrimary),
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
            'group_lobby.btn_start_new'.tr(),
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: context.textPrimary900),
          ),
        ),
      ),
    );
  }
}