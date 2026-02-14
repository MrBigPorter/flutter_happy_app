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

// 引入拆分文件
part 'group_profile_widgets.dart';
part 'group_profile_logic.dart';

class GroupProfilePage extends ConsumerWidget {
  final String conversationId;

  const GroupProfilePage({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(chatGroupProvider(conversationId));
    final myUserId = ref.watch(userProvider.select((s) => s?.id)) ?? '';

    return BaseScaffold(
      // 标题动态变化
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

          //  核心判断：我是不是成员？
          final me = detail.members.findMember(myUserId);
          final isMember = me != null;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // =================================================
                // 1. 顶部区域：根据身份区分
                // =================================================
                if (isMember)
                // 成员：看九宫格
                  Container(
                    color: context.bgPrimary,
                    padding: EdgeInsets.only(top: 16.h, bottom: 20.h),
                    child: _MemberGrid(detail: detail, myUserId: myUserId),
                  )
                else
                // 陌生人：看大头像名片
                  _PublicGroupHeader(detail: detail),

                SizedBox(height: 12.h),

                // =================================================
                // 2. 内容/设置区域
                // =================================================
                if (isMember) ...[
                  // 成员：完整设置菜单
                  _MenuSection(detail: detail, myUserId: myUserId),
                  SizedBox(height: 30.h),
                ] else ...[
                  // 陌生人：只看公告
                  _AnnouncementCard(detail: detail),
                  SizedBox(height: 30.h),
                ],

                // =================================================
                // 3. 底部按钮 (Join / Chat)
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