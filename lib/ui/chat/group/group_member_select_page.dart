import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/chat/providers/chat_group_provider.dart'; // 引入合并后的 ChatGroup
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../toast/radix_toast.dart';

class GroupMemberSelectPage extends ConsumerStatefulWidget {
  final String? existingGroupId;
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

  bool get isInviteMode => widget.existingGroupId != null;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedId != null && widget.preSelectedId!.isNotEmpty) {
      _selectedIds.add(widget.preSelectedId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactState = ref.watch(contactListProvider);

    final bool isLoading;
    if (isInviteMode) {
      // 邀请模式：监听特定群组的加载状态
      isLoading = ref.watch(chatGroupProvider(widget.existingGroupId!)).isLoading;
    } else {
      // 建群模式：监听创建控制器的状态
      isLoading = ref.watch(groupCreateControllerProvider).isLoading;
    }

    final title = isInviteMode ? "Invite Members" : "New Group";
    final btnText = isInviteMode
        ? "Invite (${_selectedIds.length})"
        : "Next (${_selectedIds.length})";

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        title: Text(title, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: (_selectedIds.isEmpty || isLoading) ? null : _handleDoneAction,
            child: isLoading
                ? SizedBox(width: 16.w, height: 16.w, child: CircularProgressIndicator(strokeWidth: 2.r))
                : Text(btnText, style: TextStyle(
              color: _selectedIds.isEmpty ? context.textDisabled : context.textBrandPrimary900,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            )),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: contactState.when(
        loading: () => _buildSkeletonList(context),
        error: (err, _) => Center(child: Text("Load failed")),
        data: (friends) {
          if (friends.isEmpty) return const Center(child: Text("No friends found"));
          return ListView.separated(
            itemCount: friends.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final user = friends[index];
              return CheckboxListTile(
                value: _selectedIds.contains(user.id),
                activeColor: context.utilityGreen500,
                title: Text(user.nickname),
                onChanged: (bool? checked) {
                  setState(() {
                    if (checked == true) _selectedIds.add(user.id);
                    else _selectedIds.remove(user.id);
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleDoneAction() {
    if (isInviteMode) _executeInvite();
    else _showGroupNameDialog();
  }

  ///  逻辑 A: 邀请 (整合进 ChatGroup)
  Future<void> _executeInvite() async {
    final success = await ref
        .read(chatGroupProvider(widget.existingGroupId!).notifier)
        .inviteMembers(_selectedIds.toList());

    if (!mounted) return;

    if (success) {
      RadixToast.success("Invitation sent");
      context.pop();
    } else {
      RadixToast.error("Failed to invite members");
    }
  }

  /// 逻辑 B: 建群 (使用 GroupCreateController)
  Future<void> _executeCreate(String name) async {
    final newGroupId = await ref
        .read(groupCreateControllerProvider.notifier)
        .create(name: name, memberIds: _selectedIds.toList());

    if (newGroupId != null && mounted) {
      RadixToast.success("Group created successfully");
      // 自动导航到新房间
      context.go('/chat/room/$newGroupId');
    }
  }

  // --- 弹窗与骨架屏代码基本保持不变 ---
  void _showGroupNameDialog() {
    final TextEditingController nameController = TextEditingController();
    RadixModal.show(
      title: "New Group",
      builder: (ctx, _) => Material(
        color: Colors.transparent,
        child: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter group name"),
        ),
      ),
      confirmText: "Create",
      onConfirm: (close) {
        close();
        final name = nameController.text.trim();
        if (name.isNotEmpty) _executeCreate(name);
      },
    );
  }

  Widget _buildSkeletonList(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => ListTile(
        leading: Skeleton.react(width: 40.r, height: 40.r, borderRadius: BorderRadius.circular(20.r)),
        title: Skeleton.react(width: 150.w, height: 16.h),
      ),
    );
  }
}