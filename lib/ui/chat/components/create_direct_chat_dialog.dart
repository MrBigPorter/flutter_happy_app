import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';

class CreateDirectChatDialog extends ConsumerStatefulWidget {
  const CreateDirectChatDialog({super.key});

  @override
  ConsumerState<CreateDirectChatDialog> createState() => _CreateDirectChatDialogState();
}

class _CreateDirectChatDialogState extends ConsumerState<CreateDirectChatDialog> {
  late final TextEditingController _idCtl;

  @override
  void initState() {
    super.initState();
    _idCtl = TextEditingController();
  }

  @override
  void dispose() {
    _idCtl.dispose(); // ✅ 释放
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(createDirectChatControllerProvider);
    final isLoading = asyncState.isLoading;

    return AlertDialog(
      title: const Text("Direct Chat"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _idCtl,
            decoration: const InputDecoration(
              labelText: "Target User ID",
              hintText: "Enter friend's UUID",
            ),
          ),
          if (asyncState.hasError)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                "${asyncState.error}",
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
              : const Text("Chat"),
        ),
      ],
    );
  }

  Future<void> _onSubmit() async {
    final targetId = _idCtl.text.trim();
    if (targetId.isEmpty) return;

    final res = await ref
        .read(createDirectChatControllerProvider.notifier)
        .createDirectChat(targetId);

    if (res != null && mounted) {
      Navigator.pop(context);
      context.push('/chat/room/${res.conversationId}');
    }
  }
}