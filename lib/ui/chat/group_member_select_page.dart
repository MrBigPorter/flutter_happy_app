import 'package:flutter/material.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';


class GroupMemberSelectPage extends ConsumerStatefulWidget {
  const GroupMemberSelectPage({super.key});

  @override
  ConsumerState<GroupMemberSelectPage> createState() => _GroupMemberSelectPageState();
}

class _GroupMemberSelectPageState extends ConsumerState<GroupMemberSelectPage> {
  // 核心状态：已选中的用户 ID 集合
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    //  监听真实的联系人列表状态 (AsyncNotifierProvider)
    final contactState = ref.watch(contactListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Members"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _showGroupNameDialog(context),
            child: Text(
              "Done (${_selectedIds.length})",
              style: TextStyle(
                color: _selectedIds.isEmpty ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      //  使用 AsyncValue 的 when 模式处理三种状态
      body: contactState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Error: $err"),
              TextButton(
                onPressed: () => ref.invalidate(contactListProvider),
                child: const Text("Retry"),
              )
            ],
          ),
        ),
        data: (friends) {
          if (friends.isEmpty) {
            return const Center(child: Text("No friends found"));
          }
          return ListView.separated(
            itemCount: friends.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final user = friends[index];
              final isSelected = _selectedIds.contains(user.id);

              return CheckboxListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                value: isSelected,
                activeColor: Colors.green,
                secondary: CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Colors.grey[200],
                  // 对接真实字段 avatar
                  backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                      ? NetworkImage(user.avatar!)
                      : null,
                  child: user.avatar == null ? const Icon(Icons.person) : null,
                ),
                title: Text(
                  user.nickname, // 对接真实字段 nickname
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
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

  void _showGroupNameDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Group"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: "Enter group name",
                labelText: "Group Name",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            SizedBox(height: 10.h),
            Text(
              "${_selectedIds.length} members selected",
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                _handleCreateGroup(name); // 调用真实创建逻辑
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  //  真实的建群逻辑处理
  Future<void> _handleCreateGroup(String groupName) async {
    // 1. 显示全局 Loading (防止二次点击)
    if(mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // 2. 调用 AsyncNotifier 中的副作用方法
      final result = await ref.read(contactListProvider.notifier).createGroup(
        name: groupName,
        memberIds: _selectedIds.toList(),
      );

      if (mounted) Navigator.pop(context); // 关闭 Loading

      if (result != null && mounted) {
        // 3. 成功逻辑：跳转到新创建的聊天室
        // 注意：这里路径要根据你的路由配置来，通常是 /chat/:id
        context.pushReplacement('/chat/${result.id}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Group '$groupName' created!")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // 关闭 Loading
      // 处理错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create group: $e")),
      );
    }
  }
}