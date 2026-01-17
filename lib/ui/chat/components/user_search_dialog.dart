import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';

import '../models/conversation.dart';

class UserSearchDialog extends ConsumerStatefulWidget {
  const UserSearchDialog({super.key});

  @override
  ConsumerState<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends ConsumerState<UserSearchDialog> {
  late final TextEditingController _searchCtl;

  @override
  void initState() {
    super.initState();
    _searchCtl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听搜索结果
    final searchState = ref.watch(userSearchControllerProvider);

    return AlertDialog(
      title: const Text("Add Friend"),
      content: SizedBox(
        width: 300.w, // 限制宽度
        height: 400.h, // 限制高度，让列表可以滚动
        child: Column(
          children: [
            // 1. 搜索框
            TextField(
              controller: _searchCtl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Search email / nickname",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _doSearch, // 点击箭头搜索
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12.w),
              ),
              onSubmitted: (_) => _doSearch(), // 回车搜索
            ),
            SizedBox(height: 16.h),

            // 2. 结果展示区域
            Expanded(
              child: searchState.when(
                data: (users) {
                  if (users.isEmpty) {
                    return Center(
                      child: Text("No users found",
                          style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                    );
                  }
                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, index) => _buildUserItem(users[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text("Error: $err")),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }

  // 执行搜索
  void _doSearch() {
    final keyword = _searchCtl.text.trim();
    if (keyword.isNotEmpty) {
      ref.read(userSearchControllerProvider.notifier).search(keyword);
    }
  }

  // 渲染单个用户行
  Widget _buildUserItem(ChatSender user) {
    // 监听建房状态 (防止重复点击)
    final createChatState = ref.watch(createDirectChatControllerProvider);
    final isCreating = createChatState.isLoading;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
            ? NetworkImage(user.avatar!)
            : null,
        child: user.avatar == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user.nickname),
      // subtitle: Text(user.id), // debug用，实际不用显示ID
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(60.w, 30.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
        ),
        onPressed: isCreating
            ? null
            : () => _onChat(user.id),
        child: isCreating
            ? SizedBox(width: 12.w, height: 12.w, child: const CircularProgressIndicator(strokeWidth: 2))
            : const Text("Chat", style: TextStyle(fontSize: 12)),
      ),
    );
  }

  // 点击 Chat 按钮：创建会话并跳转
  Future<void> _onChat(String targetUserId) async {
    final res = await ref
        .read(createDirectChatControllerProvider.notifier)
        .createDirectChat(targetUserId);

    if (res != null && mounted) {
      Navigator.pop(context); // 关弹窗
      // 跳转到聊天页
      context.push('/chat/${res.conversationId}');
    }
  }
}