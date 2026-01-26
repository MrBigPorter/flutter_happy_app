import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

// 临时定义的简单的用户模型 (后续会被真实的 User Model 替换)
class SimpleUser {
  final String id;
  final String nickname;
  final String avatar;
  SimpleUser({required this.id, required this.nickname, required this.avatar});
}

// 模拟好友数据 Provider (P1 阶段我们会替换成真实的 API 调用)
final mockFriendsProvider = FutureProvider.autoDispose<List<SimpleUser>>((ref) async {
  // 模拟网络延迟
  await Future.delayed(const Duration(milliseconds: 500));
  // 返回模拟数据
  return List.generate(15, (index) => SimpleUser(
    id: 'user_$index',
    nickname: 'Friend $index',
    avatar: 'https://i.pravatar.cc/150?u=$index',
  ));
});

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
    final asyncFriends = ref.watch(mockFriendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Members"),
        centerTitle: true,
        actions: [
          // 右上角 "完成" 按钮
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null // 没选人时不可点
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
      body: asyncFriends.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
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
                activeColor: Colors.green, // 微信风格绿
                secondary: CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: NetworkImage(user.avatar),
                ),
                title: Text(
                  user.nickname,
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

  // 选完人后，弹窗输入群名
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
                Navigator.pop(ctx); // 关闭弹窗
                _createGroupSimulation(name);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroupSimulation(String groupName) async {
    // ⬇️ [P1] 这里将来会调用真实的 Api.createGroup
    debugPrint("🚀 Creating group: '$groupName' with members: $_selectedIds");

    // 模拟 loading
    if(mounted) showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context); // 关掉 loading
      context.pop(); // 关掉选人页，返回列表

      // 这里的逻辑将来可以改成：直接跳转到新创建的 ChatPage
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Group '$groupName' created!")),
      );
    }
  }
}