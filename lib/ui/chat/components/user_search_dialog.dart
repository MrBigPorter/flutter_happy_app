import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart'; // Ensure Skeleton component is imported
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
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
    // Watch search results state
    final searchState = ref.watch(userSearchProvider(_keyword));

    return AlertDialog(
      title: Text("Add Friend", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
      backgroundColor: context.bgPrimary,
      surfaceTintColor: Colors.transparent, // Remove default Material 3 tint
      contentPadding: EdgeInsets.all(20.w), // Adjust padding for a cleaner layout
      content: SizedBox(
        width: 360.w,
        height: 400.h,
        child: Column(
          children: [
            // Search Input Field
            TextField(
              controller: _searchCtl,
              decoration: InputDecoration(
                hintStyle: TextStyle(fontSize: 14.sp, color: context.textSecondary700),
                hintText: "Search nickname/phone",
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: context.borderPrimary),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: context.textBrandPrimary900),
                  onPressed: () => setState(() => _keyword = _searchCtl.text),
                ),
              ),
              onSubmitted: (v) => setState(() => _keyword = v),
            ),

            SizedBox(height: 16.h), // Spacing between search bar and list

            // Results Area
            Expanded(
              child: searchState.when(
                // 1. Loading: Display skeleton screen
                loading: () => _buildSkeletonList(context),

                // 2. Error handling
                error: (e, _) => Center(
                  child: Text("Search failed", style: TextStyle(color: context.textSecondary700)),
                ),

                // 3. Data rendering
                data: (users) {
                  if (users.isEmpty) {
                    return Center(
                      child: Text(
                        _keyword.isEmpty ? "Enter keyword to search" : "No user found",
                        style: TextStyle(color: context.textSecondary700),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (ctx, i) {
                      final user = users[i];
                      // Watch the state of the "Add Friend" action (loading state)
                      final addActionState = ref.watch(addFriendControllerProvider(user.id));

                      return ListTile(
                        contentPadding: EdgeInsets.zero, // Fully custom layout
                        leading: CircleAvatar(
                          radius: 20.r,
                          backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                          backgroundColor: context.bgSecondary,
                          child: user.avatar == null
                              ? Icon(Icons.person, color: context.textSecondary700, size: 20.r)
                              : null,
                        ),
                        title: Text(
                            user.nickname,
                            style: TextStyle(fontSize: 16.sp, color: context.textPrimary900, fontWeight: FontWeight.w500)
                        ),
                        trailing: Button(
                          width: 64.w,
                          height: 32.h,
                          radius: 6.r,
                          loading: addActionState.isLoading,
                          onPressed: addActionState.isLoading
                              ? null
                              : () async {
                            final success = await ref
                                .read(addFriendControllerProvider(user.id).notifier)
                                .execute();

                            // Refresh conversation list upon success
                            ref.invalidate(conversationListProvider);

                            if (success && mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text("Add", style: TextStyle(fontSize: 12.sp)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build skeleton screen for loading state
  Widget _buildSkeletonList(BuildContext context) {
    return ListView.separated(
      itemCount: 6, // Show 6 placeholder items by default
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling during loading
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return Row(
          children: [
            // Left: Avatar skeleton
            Skeleton.react(
                width: 40.r,
                height: 40.r,
                borderRadius: BorderRadius.circular(20.r)
            ),
            SizedBox(width: 16.w),
            // Center: Nickname and ID skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.react(width: 120.w, height: 16.h),
                  SizedBox(height: 6.h),
                  Skeleton.react(width: 80.w, height: 12.h), // Placeholder for secondary info
                ],
              ),
            ),
            SizedBox(width: 16.w),
            // Right: Button skeleton
            Skeleton.react(
                width: 64.w,
                height: 32.h,
                borderRadius: BorderRadius.circular(6.r)
            ),
          ],
        );
      },
    );
  }
}