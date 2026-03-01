import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../modal/dialog/radix_modal.dart';
import '../toast/radix_toast.dart';
import 'models/conversation.dart';

class DirectChatSettingsPage extends ConsumerWidget {
  final String conversationId;

  const DirectChatSettingsPage({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(chatDetailProvider(conversationId));

    return BaseScaffold(
      title: "Chat Info",
      backgroundColor: context.bgSecondary,
      body: asyncDetail.when(
        loading: () => _buildSkeleton(context),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (detail) {
          if (detail.type == ConversationType.group) {
            return const Center(child: Text("This is a group chat."));
          }
          return _buildContent(context, ref, detail);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, ConversationDetail detail) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          Container(
            color: context.bgPrimary,
            padding: EdgeInsets.only(top: 12.h, bottom: 20.h, left: 16.w, right: 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatarItem(context, detail.name, detail.avatar),
                SizedBox(width: 20.w),
                _buildAddButton(context, ref, detail),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          // 👇 这里把 ref 传给设置列表
          _buildSettingsList(context, ref, detail),
          SizedBox(height: 30.h),
          // 👇 这里把 ref 传给底部按钮
          _buildFooterButtons(context, ref, detail),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, WidgetRef ref, ConversationDetail detail) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          label: "Search Chat History",
          onTap: () {
            // 预留的查找记录入口，后续对接
            RadixToast.info("Search UI in progress...");
          },
        ),
        SizedBox(height: 12.h),
        _buildMenuItem(
          context,
          label: "Mute Notifications",
          isSwitch: true,
          switchValue: detail.isMuted,
          onSwitchChanged: (v) async {
            try {
              // TODO: 在这里调用你的免打扰 API 接口
              // await ref.read(conversationActionProvider.notifier).setMute(detail.id, v);
              RadixToast.success(v ? "Notifications Muted" : "Notifications Unmuted");
            } catch (e) {
              RadixToast.error("Failed to update settings");
            }
          },
        ),
        Container(height: 1, color: context.bgSecondary, margin: EdgeInsets.only(left: 16.w)),
        _buildMenuItem(
          context,
          label: "Pin to Top",
          isSwitch: true,
          switchValue: detail.isPinned,
          onSwitchChanged: (v) async {
            try {
              // TODO: 在这里调用你的置顶 API 接口
              // await ref.read(conversationActionProvider.notifier).setPin(detail.id, v);
              RadixToast.success(v ? "Pinned to Top" : "Unpinned");
            } catch (e) {
              RadixToast.error("Failed to update settings");
            }
          },
        ),
      ],
    );
  }

  Widget _buildFooterButtons(BuildContext context, WidgetRef ref, ConversationDetail detail) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Button(
        variant: ButtonVariant.ghost,
        width: double.infinity,
        onPressed: () {
          // 弹出危险操作确认框
          RadixModal.show(
            title: "Clear Chat History",
            confirmText: "Clear",
            cancelText: "Cancel",
            builder: (_,close)=> Container(
              padding: EdgeInsets.all(16.w),
              child: Text(
                "Are you sure you want to clear the chat history? This action cannot be undone.",
                style: TextStyle(color: context.textSecondary700, fontSize: 14.sp),
              ),
            ),
          );
        },
        child: Text(
          "Clear Chat History",
          style: TextStyle(color: context.utilityError500, fontSize: 16.sp),
        ),
      ),
    );
  }

  Widget _buildAvatarItem(BuildContext context, String name, String? avatar) {
    return Column(
      children: [
        Container(
          width: 48.r,
          height: 48.r,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.r),
            color: context.bgSecondary,
            image: avatar != null
                ? DecorationImage(
              image: CachedNetworkImageProvider(
                UrlResolver.resolveImage(
                  context,
                  avatar,
                  logicalWidth: 48,
                ),
              ),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: avatar == null
              ? Icon(Icons.person, color: context.textSecondary700)
              : null,
        ),
        SizedBox(height: 6.h),
        SizedBox(
          width: 50.w,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: context.textSecondary700,
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. 加号按钮 (核心逻辑修改) ---
  Widget _buildAddButton(BuildContext context, WidgetRef ref, ConversationDetail detail) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            // 1. 获取当前登录用户的 ID
            final myId = ref.read(userProvider)?.id;

            // 2. 找到对方 (排除自己)
            // 如果只有2个人，且我知道我的ID，剩下的那个就是对方
            // 容错：如果找不到(理论上不可能)，就返回第一个
            final partner = detail.members.firstWhere(
                    (m) => m.userId != myId,
                orElse: () => detail.members.first
            );

            // 3. 跳转建群选人页，并把对方 ID 传过去
            appRouter.push('/chat/group/select/member?preSelectedId=${partner.userId}');

          },
          child: Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              border: Border.all(color: context.borderPrimary),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Icon(Icons.add, color: context.textSecondary700),
          ),
        ),
        SizedBox(height: 6.h),
      ],
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required String label,
        VoidCallback? onTap,
        bool isSwitch = false,
        bool switchValue = false,
        ValueChanged<bool>? onSwitchChanged,
      }) {
    return InkWell(
      onTap: isSwitch ? null : onTap,
      child: Container(
        color: context.bgPrimary,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 16.sp, color: context.textPrimary900),
              ),
            ),
            if (isSwitch)
              SizedBox(
                height: 24.h,
                child: Switch(
                  value: switchValue,
                  onChanged: onSwitchChanged,
                  activeColor: context.utilityGreen500,
                ),
              )
            else
              Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      children: [
        Container(
            color: context.bgPrimary,
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Skeleton.react(width: 48.r, height: 48.r, borderRadius: BorderRadius.circular(4.r)),
                SizedBox(width: 20.w),
                Skeleton.react(width: 48.r, height: 48.r, borderRadius: BorderRadius.circular(4.r)),
              ],
            )
        ),
        SizedBox(height: 12.h),
        Container(color: context.bgPrimary, height: 50.h, width: double.infinity),
        SizedBox(height: 1.h),
        Container(color: context.bgPrimary, height: 50.h, width: double.infinity),
      ],
    );
  }
}