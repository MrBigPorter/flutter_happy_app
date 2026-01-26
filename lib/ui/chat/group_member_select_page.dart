import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        title:  Text("Select Members",style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: context.textPrimary900
        )),
        surfaceTintColor: context.bgSecondary,
        centerTitle: true,

        actions: [
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _showGroupNameDialog(context),
            child: Text(
              "Done (${_selectedIds.length})",
              style: TextStyle(
                color: _selectedIds.isEmpty ? context.textDisabled : context.textBrandPrimary900,
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
        loading: () => _buildSkeletonList(context),
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
                activeColor: context.utilityGreen500,
                secondary: CircleAvatar(
                  radius: 20.r,
                  backgroundColor: context.bgBrandSecondary,
                  // 对接真实字段 avatar
                  backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                      ? NetworkImage(user.avatar!)
                      : null,
                  child: user.avatar == null ? const Icon(Icons.person) : null,
                ),
                title: Text(
                  user.nickname, // 对接真实字段 nickname
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: context.textPrimary900),
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

  // 抽离骨架屏列表
  Widget _buildSkeletonList(BuildContext context) {
    return ListView.builder(
      itemCount: 20, // 预设显示 8 个占位项
      physics: const NeverScrollableScrollPhysics(), // 加载时禁止滚动
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              // 1. 头像占位
              Skeleton.react(width: 20.w, height: 20.h, borderRadius: BorderRadius.circular(20.r)),
              SizedBox(width: 12.w),
              // 2. 昵称占位
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.react(
                      width: 180.w,
                      height: 16.h,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ],
                ),
              ),
              // 3. 复选框占位
              Skeleton.react(
                width: 20.w,
                height: 20.h,
                borderRadius: BorderRadius.circular(4.r),
              )
            ],
          ),
        );
      },
    );
  }

  void _showGroupNameDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    RadixModal.show(
      builder:(ctx,_){
        return Material(
          type: MaterialType.transparency,
          child: Column(
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
        );
      },
      confirmText:"Create",
      cancelText:"Cancel",
      onConfirm: (_){
        final name = nameController.text.trim();
        if (name.isNotEmpty) {
          _handleCreateGroup(name); // 调用真实创建逻辑
        }
      }

    );
  }


  Future<void> _handleCreateGroup(String groupName) async {
    // 1. 调用专门的建群控制器，而不是 ContactList
   final createResult =  await ref.read(createGroupControllerProvider.notifier).execute(
        groupName,
        _selectedIds.toList()
    );


    if (createResult != null&& mounted) {
      final gid = createResult.id;
      appRouter.go('/chat/$gid');
      RadixToast.success("Group '$groupName' created successfully");
    }
  }

}