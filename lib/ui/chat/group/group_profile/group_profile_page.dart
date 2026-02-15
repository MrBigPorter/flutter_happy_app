import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/utils/upload/global_upload_service.dart';
import 'package:flutter_app/utils/upload/upload_types.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/core/store/user_store.dart';

import 'package:flutter_app/ui/modal/dialog/radix_modal.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_app/ui/chat/providers/chat_group_provider.dart';
import 'package:flutter_app/ui/chat/core/extensions/chat_permissions.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';
import 'package:flutter_app/ui/chat/models/group_role.dart';

import '../group_qr_page.dart';

part 'group_profile_widgets.dart';
part 'group_profile_logic.dart';

// 改为 ConsumerStatefulWidget 以维持搜索状态
class GroupProfilePage extends ConsumerStatefulWidget {
  final String conversationId;

  const GroupProfilePage({super.key, required this.conversationId});

  @override
  ConsumerState<GroupProfilePage> createState() => _GroupProfilePageState();
}

class _GroupProfilePageState extends ConsumerState<GroupProfilePage> {
  // [修改 2] 搜索状态
  String _searchKeyword = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(chatGroupProvider(widget.conversationId));
    final myUserId = ref.watch(userProvider.select((s) => s?.id)) ?? '';

    return BaseScaffold(
      title: asyncDetail.valueOrNull != null
          ? (asyncDetail.value!.type == ConversationType.group
          ? "Group Chat (${asyncDetail.value!.memberCount})"
          : "Details")
          : "Loading...",
      backgroundColor: context.bgSecondary,
      body: asyncDetail.when(
        loading: () => const _GroupSkeleton(),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (detail) {
          if (detail.type != ConversationType.group) {
            return const Center(child: Text("This is not a group."));
          }

          final me = detail.members.findMember(myUserId);
          final isMember = me != null;

          // [修改 3] 执行本地过滤逻辑
          final displayMembers = _searchKeyword.isEmpty
              ? detail.members
              : detail.members.where((m) => m.nickname
              .toLowerCase()
              .contains(_searchKeyword.toLowerCase())).toList();

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // =================================================
                // 1. 顶部区域：根据身份区分
                // =================================================
                if (isMember)
                // 成员：看九宫格 (带搜索框)
                  Container(
                    color: context.bgPrimary,
                    padding: EdgeInsets.only(top: 16.h, bottom: 20.h),
                    child: Column(
                      children: [
                        // [新增] 搜索框
                        if (detail.memberCount > 5) // 人少的时候没必要显示搜索框
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchKeyword = val),
                              decoration: InputDecoration(
                                hintText: "Search members",
                                prefixIcon: Icon(Icons.search,
                                    size: 20.r, color: context.textSecondary700),
                                filled: true,
                                fillColor: context.bgSecondary,
                                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12.w),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),

                        SizedBox(height: 12.h),

                        // [修改 4] 传入过滤后的 displayMembers
                        _MemberGrid(
                          detail: detail,
                          myUserId: myUserId,
                          members: displayMembers,
                        ),
                      ],
                    ),
                  )
                else
                // 陌生人：看大头像名片
                  _PublicGroupHeader(detail: detail),

                SizedBox(height: 12.h),

                // =================================================
                // 2. 内容/设置区域
                // =================================================
                if (isMember) ...[
                  _MenuSection(detail: detail, myUserId: myUserId),
                  SizedBox(height: 30.h),
                ] else ...[
                  _AnnouncementCard(detail: detail),
                  SizedBox(height: 30.h),
                ],

                // =================================================
                // 3. 底部按钮
                // =================================================
                _FooterButtons(detail: detail, myUserId: myUserId),

                SizedBox(height: 50.h),
              ],
            ),
          );
        },
      ),
    );
  }
}