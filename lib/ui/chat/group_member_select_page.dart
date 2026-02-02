import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../toast/radix_toast.dart';
import 'models/chat_ui_model.dart';
import 'models/conversation.dart';

class GroupMemberSelectPage extends ConsumerStatefulWidget {
  // 核心参数：有 ID = 邀请模式；无 ID = 建群模式
  final String? existingGroupId;

  //  [新增] 预选中成员 ID (用于从私聊详情页发起建群)
  final String? preSelectedId;

  const GroupMemberSelectPage({
    super.key,
    this.existingGroupId,
    this.preSelectedId, 
  });

  @override
  ConsumerState<GroupMemberSelectPage> createState() => _GroupMemberSelectPageState();
}

class _GroupMemberSelectPageState extends ConsumerState<GroupMemberSelectPage> {
  final Set<String> _selectedIds = {};

  // 辅助 getter
  bool get isInviteMode => widget.existingGroupId != null;

  @override
  void initState() {
    super.initState();
    //  [核心逻辑] 如果有预选人，进页面直接勾上
    if (widget.preSelectedId != null && widget.preSelectedId!.isNotEmpty) {
      _selectedIds.add(widget.preSelectedId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 数据源：联系人列表
    final contactState = ref.watch(contactListProvider);
    // 2. 动作状态：提交 loading/error
    final actionState = ref.watch(groupMemberActionControllerProvider);

    // 3. 监听动作结果 (用于全局错误提示)
    ref.listen(groupMemberActionControllerProvider, (_, next) {
      if (next.hasError) {
        RadixToast.error(next.error.toString());
      }
    });

    final title = isInviteMode ? "Invite Members" : "New Group";
    final btnText = isInviteMode
        ? "Invite (${_selectedIds.length})"
        : "Next (${_selectedIds.length})";

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: context.textPrimary900,
          ),
        ),
        centerTitle: true,
        actions: [
          // 右上角按钮：根据 Loading 状态 禁用/变身
          TextButton(
            // 注意：如果是建群模式，至少要选一个人 (通常包括自己至少2人，前端限制选1人即可)
            onPressed: (_selectedIds.isEmpty || actionState.isLoading)
                ? null
                : _handleDoneAction,
            child: actionState.isLoading
                ? SizedBox(
              width: 16.w,
              height: 16.w,
              child: CircularProgressIndicator(strokeWidth: 2.r),
            )
                : Text(
              btnText,
              style: TextStyle(
                color: _selectedIds.isEmpty
                    ? context.textDisabled
                    : context.textBrandPrimary900,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: contactState.when(
        loading: () => _buildSkeletonList(context),
        error: (err, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(contactListProvider),
            child: const Text("Load failed, tap to retry"),
          ),
        ),
        data: (friends) {
          if (friends.isEmpty) return const Center(child: Text("No friends found"));

          return ListView.separated(
            itemCount: friends.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final user = friends[index];
              final isSelected = _selectedIds.contains(user.id);

              //  视觉优化：如果是预选中的人，可以加粗或者稍微灰色底色提示用户
              // 但为了简单，这里保持统一的 Checkbox 逻辑

              return CheckboxListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                value: isSelected,
                activeColor: context.utilityGreen500,
                secondary: CircleAvatar(
                  radius: 20.r,
                  backgroundColor: context.bgBrandSecondary,
                  backgroundImage: (user.avatar?.isNotEmpty == true)
                      ? NetworkImage(user.avatar!)
                      : null,
                  child: user.avatar == null ? const Icon(Icons.person) : null,
                ),
                title: Text(
                  user.nickname,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary900,
                  ),
                ),
                onChanged: (bool? checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedIds.add(user.id);
                    } else {
                      _selectedIds.remove(user.id);
                    }
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- 交互逻辑 ---

  void _handleDoneAction() {
    if (isInviteMode) {
      _executeInvite();
    } else {
      _showGroupNameDialog();
    }
  }

  /// 逻辑 A: 邀请
  Future<void> _executeInvite() async {
    // 1. 调用控制器
    final count = await ref
        .read(groupMemberActionControllerProvider.notifier)
        .inviteMember(
      groupId: widget.existingGroupId!,
      memberIds: _selectedIds.toList(),
    );

    // 2. 检查是否有错误
    if (ref.read(groupMemberActionControllerProvider).hasError) {
      return;
    }

    if (!mounted) return;

    // 3. 处理业务结果
    if (count != null && count > 0) {
      RadixToast.success("Successfully invited $count members");
      ref.invalidate(chatDetailProvider(widget.existingGroupId!));
      context.pop();
    } else {
      RadixToast.info("Selected members are already in the group");
      context.pop();
    }
  }

  /// 逻辑 B: 建群
  Future<void> _executeCreate(String name) async {
    // 调用控制器
    final newGroupId = await ref
        .read(groupMemberActionControllerProvider.notifier)
        .createGroup(
      name: name,
      memberIds: _selectedIds.toList(),
    );

    // 成功回调
    if (newGroupId != null && mounted) {
      // [优化核心] 手动抢跑：在 Socket 推送之前，先把群加到列表里
      // 这样用户回退到列表页时，群已经在那了，不需要刷新
      final newConv = Conversation(
        id: newGroupId,
        type: ConversationType.group,
        name: name,
        avatar: null, // 此时还没有头像，会显示灰色九宫格骨架
        lastMsgContent: "Group created",
        lastMsgTime: DateTime.now().millisecondsSinceEpoch,
        unreadCount: 0,
        lastMsgStatus: MessageStatus.success,
        isPinned: false,
        isMuted: false,
      );
      
      // use provider to update conversation list
      ref.read(conversationListProvider.notifier).addConversation(newConv);
      
      // notify success
      RadixToast.success("Group created successfully");
      // go to the new group chat page
      appRouter.go('/chat/room/$newGroupId');
    }
  }

  /// 建群弹窗
  void _showGroupNameDialog() {
    final TextEditingController nameController = TextEditingController();

    RadixModal.show(
      builder: (ctx, _) {
        return Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Enter group name",
                  labelText: "Group Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                "${_selectedIds.length} members selected",
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
            ],
          ),
        );
      },
      confirmText: "Create",
      onConfirm: (close) {
        close();
        final name = nameController.text.trim();
        if (name.isNotEmpty) {
          _executeCreate(name);
        } else {
          RadixToast.error("Name cannot be empty");
        }
      },
    );
  }

  // --- 骨架屏 ---
  Widget _buildSkeletonList(BuildContext context) {
    return ListView.builder(
      itemCount: 15,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Skeleton.react(width: 40.r, height: 40.r, borderRadius: BorderRadius.circular(20.r)),
              SizedBox(width: 12.w),
              Expanded(
                child: Skeleton.react(width: 150.w, height: 16.h, borderRadius: BorderRadius.circular(4.r)),
              ),
              SizedBox(width: 12.w),
              Skeleton.react(width: 20.r, height: 20.r, borderRadius: BorderRadius.circular(4.r))
            ],
          ),
        );
      },
    );
  }
}