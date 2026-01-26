import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/contact_provider.dart';

class UserSearchDialog extends ConsumerStatefulWidget {
  const UserSearchDialog({super.key});
  @override
  ConsumerState<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends ConsumerState<UserSearchDialog> {
  final _searchCtl = TextEditingController();
  String _keyword = "";

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(userSearchProvider(_keyword));


    return AlertDialog(
      title: Text("Add Friend", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
      backgroundColor: context.bgPrimary,
      content: SizedBox(
        width: 300.w, height: 400.h,
        child: Column(
          children: [
            TextField(
              controller: _searchCtl,
              decoration: InputDecoration(
                hintStyle: TextStyle(fontSize: 14.sp, color: context.textSecondary700),
                hintText: "Search nickname/phone",
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: context.textBrandPrimary900),
                  onPressed: () => setState(() => _keyword = _searchCtl.text),
                ),
              ),
              onSubmitted: (v) => setState(() => _keyword = v),
            ),
            Expanded(
              child: searchState.when(
                data: (users) => ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (ctx, i) {
                    final user = users[i];
                    final addActionState = ref.watch(addFriendControllerProvider(user.id));
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                        backgroundColor: context.bgSecondary,
                      ),
                      title: Text(user.nickname, style: TextStyle(fontSize: 16.sp, color: context.textSecondary700)),
                      trailing: Button(
                        width: 60.w, height: 36.h,
                        loading: addActionState.isLoading,
                        onPressed: addActionState.isLoading
                            ? null
                            : () async {
                          //  调用方法名 execute 对齐
                          final success = await ref
                              .read(addFriendControllerProvider(user.id).notifier)
                              .execute();
                          ref.invalidate(conversationListProvider);
                          if (success && mounted) Navigator.pop(context);
                        },
                        child: const Text("Add"),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}