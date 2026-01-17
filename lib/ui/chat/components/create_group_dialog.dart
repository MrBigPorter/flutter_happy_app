import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  // 🔥 Controller 在这里定义，随 Widget 销毁而释放
  late final TextEditingController _nameCtl;
  late final TextEditingController _memberCtl;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController();
    _memberCtl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _memberCtl.dispose(); // ✅ 必须释放！
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听 Provider 状态
    final asyncState = ref.watch(createGroupControllerProvider);
    final isLoading = asyncState.isLoading;

    return AlertDialog(
      title: const Text("Create Group"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtl,
            decoration: const InputDecoration(
              labelText: "Group Name",
              hintText: "e.g. Party Group",
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _memberCtl,
            decoration: const InputDecoration(
              labelText: "Member IDs",
              hintText: "id1,id2 (comma separated)",
            ),
          ),
          if (asyncState.hasError)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                "Error: ${asyncState.error}",
                style: TextStyle(color: Colors.red, fontSize: 12.sp),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _onSubmit,
          child: isLoading
              ? SizedBox(
            width: 16.w,
            height: 16.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text("Create"),
        ),
      ],
    );
  }

  Future<void> _onSubmit() async {
    final name = _nameCtl.text.trim();
    final members = _memberCtl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (name.isEmpty) return;

    final res = await ref
        .read(createGroupControllerProvider.notifier)
        .createGroup(name, members);

    if (res != null && mounted) {
      Navigator.pop(context);
      context.push(
        '/chat/${res.conversationId}?title=${Uri.encodeComponent(name)}',
      );
    }
  }
}