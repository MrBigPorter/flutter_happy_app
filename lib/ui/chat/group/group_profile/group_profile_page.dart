import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/utils/upload/global_upload_service.dart';
import 'package:flutter_app/utils/upload/upload_types.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/core/store/user_store.dart';

import 'package:flutter_app/ui/modal/dialog/radix_modal.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_app/ui/chat/providers/chat_group_provider.dart';
import 'package:flutter_app/ui/chat/core/extensions/chat_permissions.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';
import 'package:flutter_app/ui/chat/models/group_role.dart';

import '../group_qr_page.dart';

part 'group_profile_widgets.dart';
part 'group_profile_logic.dart';

class GroupProfilePage extends ConsumerStatefulWidget {
  final String conversationId;

  const GroupProfilePage({super.key, required this.conversationId});

  @override
  ConsumerState<GroupProfilePage> createState() => _GroupProfilePageState();
}

class _GroupProfilePageState extends ConsumerState<GroupProfilePage> {
  // Local search state management for filtering members
  String _searchKeyword = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch group details provider
    final asyncDetail = ref.watch(chatGroupProvider(widget.conversationId));
    final myUserId = ref.watch(userProvider.select((s) => s?.id)) ?? '';

    return BaseScaffold(
      title: asyncDetail.valueOrNull != null
          ? (asyncDetail.value!.type == ConversationType.group
          ? "Group Chat (${asyncDetail.value!.memberCount})"
          : "Details")
          : "Loading...",
      backgroundColor: context.bgSecondary,
      body: asyncDetail.when(
        loading: () => const _GroupSkeleton(),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (detail) {
          if (detail.type != ConversationType.group) {
            return const Center(child: Text("Invalid conversation type."));
          }

          final me = detail.members.findMember(myUserId);
          final isMember = me != null;

          // Local filtering logic: filter member list based on search keyword
          final displayMembers = _searchKeyword.isEmpty
              ? detail.members
              : detail.members.where((m) => m.nickname
              .toLowerCase()
              .contains(_searchKeyword.toLowerCase())).toList();

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // =================================================
                // 1. Top Section: Conditional UI based on Membership
                // =================================================
                if (isMember)
                // Member view: Grid layout with search capability
                  Container(
                    color: context.bgPrimary,
                    padding: EdgeInsets.only(top: 16.h, bottom: 20.h),
                    child: Column(
                      children: [
                        // Search bar: only visible when member count exceeds threshold
                        if (detail.memberCount > 5)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchKeyword = val),
                              decoration: InputDecoration(
                                hintText: "Search members",
                                prefixIcon: Icon(Icons.search,
                                    size: 20.r, color: context.textSecondary700),
                                filled: true,
                                fillColor: context.bgSecondary,
                                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12.w),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),

                        SizedBox(height: 12.h),

                        // Pass filtered list to the grid widget
                        _MemberGrid(
                          detail: detail,
                          myUserId: myUserId,
                          members: displayMembers,
                        ),
                      ],
                    ),
                  )
                else
                // Stranger view: Public profile card layout
                  _PublicGroupHeader(detail: detail),

                SizedBox(height: 12.h),

                // =================================================
                // 2. Settings / Content Section
                // =================================================
                if (isMember) ...[
                  _MenuSection(detail: detail, myUserId: myUserId),
                  SizedBox(height: 30.h),
                ] else ...[
                  _AnnouncementCard(detail: detail),
                  SizedBox(height: 30.h),
                ],

                // =================================================
                // 3. Bottom Action Buttons
                // =================================================
                _FooterButtons(detail: detail, myUserId: myUserId),

                SizedBox(height: 50.h),
              ],
            ),
          );
        },
      ),
    );
  }
}