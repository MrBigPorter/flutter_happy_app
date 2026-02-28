import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';

import '../models/chat_ui_model.dart';
import '../models/conversation.dart';

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
    // Release controller resources
    _idCtl.dispose();
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

      // Optimization Core: Manual pre-insertion for immediate UI feedback.
      // Direct chats should appear instantly in the list.
      // Ideally, the API response (CreateDirectChatResponse) should include the
      // target user's avatar and name. If missing, temporary placeholders are used
      // until synchronized via Socket.
      // Assumption: res.conversationId is accurate.

      final newConv = Conversation(
        id: res.conversationId,
        type: ConversationType.direct,
        name: "User $targetId", // Use ID as placeholder if name is not returned by API
        avatar: null, // To be populated by API or Socket update
        lastMsgContent: "New chat",
        lastMsgTime: DateTime.now().millisecondsSinceEpoch,
        unreadCount: 0,
        lastMsgStatus: MessageStatus.success,
        isPinned: false,
        isMuted: false,
      );

      // Force insertion into the conversation list
      ref.read(conversationListProvider.notifier).addConversation(newConv);

      Navigator.pop(context);
      appRouter.push('/chat/room/${res.conversationId}');
    }
  }
}