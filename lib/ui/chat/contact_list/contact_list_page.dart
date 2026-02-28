import 'dart:ui';
import 'package:azlistview/azlistview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpinyin/lpinyin.dart';

import '../core/repositories/contact_repository.dart';
import '../models/conversation.dart';

// Declare the logic layer mixin file
part 'contact_list_logic.dart';

class ContactEntity extends ISuspensionBean {
  final ChatUser user;
  String tagIndex;
  ContactEntity({required this.user, this.tagIndex = ""});

  @override
  String getSuspensionTag() => tagIndex;
}

class ContactListPage extends ConsumerStatefulWidget {
  const ContactListPage({super.key});

  @override
  ConsumerState<ContactListPage> createState() => _ContactListPageState();
}

// Mixing in the logic layer
class _ContactListPageState extends ConsumerState<ContactListPage> with ContactListLogic {
  @override
  Widget build(BuildContext context) {
    final asyncContacts = ref.watch(contactListProvider);
    final asyncRequests = ref.watch(friendRequestListProvider);
    final int requestCount = asyncRequests.valueOrNull?.length ?? 0;

    // Aggressive optimization: Manually extract the latest available data from the Provider
    // to handle edge cases where the value might be lost during initial loading moments.
    final List<ChatUser>? currentData = asyncContacts.valueOrNull ??
        ref.read(contactListProvider).asData?.value;

    return BaseScaffold(
      title: "Contacts",
      actions: _buildActions(),
      body: RefreshIndicator(
        color: context.utilityBrand500,
        backgroundColor: context.bgPrimary,
        onRefresh: handleRefresh, // Invoke logic layer method
        child: Container(
          color: context.bgSecondary,
          width: double.infinity,
          height: double.infinity,
          child: asyncContacts.when(
            skipLoadingOnRefresh: true,
            // Cache-first: Display content if warmed-up data exists, even during loading
            loading: () => asyncContacts.hasValue
                ? _buildMainContent(asyncContacts.value!, requestCount)
                : _buildSkeleton(),
            error: (err, _) => _buildErrorState(err),
            data: (contacts) => _buildMainContent(contacts, requestCount),
          ),
        ),
      ),
    );
  }

  // --- UI Sub-modules (Presentation Only) ---

  Widget _buildMainContent(List<ChatUser> contacts, int requestCount) {
    if (contacts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [_buildEmptyState(requestCount)],
      );
    }

    // Process data using logic layer method
    final List<ContactEntity> contactModels = processData(contacts);
    final List<String> indexData = SuspensionUtil.getTagIndexList(contactModels);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
          child: _buildActionSection(requestCount),
        ),
        Expanded(
          child: AzListView(
            physics: const AlwaysScrollableScrollPhysics(),
            data: contactModels,
            itemCount: contactModels.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildContactItem(contactModels[index].user),
            ),
            susItemBuilder: (context, index) => _buildHeader(contactModels[index].tagIndex),
            indexBarData: indexData,
            indexBarOptions: IndexBarOptions(
              needRebuild: true,
              selectTextStyle: TextStyle(fontSize: 10.sp, color: context.textWhite, fontWeight: FontWeight.bold),
              selectItemDecoration: BoxDecoration(shape: BoxShape.circle, color: context.utilityBrand500),
              textStyle: TextStyle(fontSize: 10.sp, color: context.textSecondary700),
            ),
            indexHintBuilder: (context, tag) => _buildIndexHint(tag),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    return [
      IconButton(
        icon: Icon(Icons.search_rounded, size: 24.sp, color: context.textPrimary900),
        onPressed: navigateToLocalSearch,
      ),
      IconButton(
        icon: Icon(Icons.person_add_alt_1_rounded, size: 24.sp, color: context.textPrimary900),
        onPressed: navigateToGlobalSearch,
      ),
      SizedBox(width: 8.w),
    ];
  }

  Widget _buildContactItem(ChatUser user) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.bgSecondary, width: 0.5),
      ),
      child: ListTile(
        onTap: () => navigateToProfile(user),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: CircleAvatar(
          radius: 22.r,
          backgroundColor: context.bgBrandSecondary,
          backgroundImage: user.avatar != null
              ? CachedNetworkImageProvider(UrlResolver.resolveImage(context, user.avatar!, logicalWidth: 44))
              : null,
          child: user.avatar == null ? Text(user.nickname.isNotEmpty ? user.nickname[0] : "?") : null,
        ),
        title: Text(user.nickname, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: context.textPrimary900)),
        trailing: Icon(Icons.chevron_right_rounded, size: 18.sp, color: context.textSecondary700.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildActionSection(int count) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: navigateToNewFriends,
        leading: const Icon(Icons.person_add_rounded, color: Colors.orange),
        title: const Text("New Friends", style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count > 0) Badge(label: Text("$count"), backgroundColor: Colors.red),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Text(tag, style:  TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary900)),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 10,
      padding: EdgeInsets.all(16.r),
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Row(
          children: [
            Skeleton.react(width: 44.r, height: 44.r, borderRadius: BorderRadius.circular(22.r)),
            SizedBox(width: 16.w),
            Skeleton.react(width: 150.w, height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(int requestCount) {
    return Center(
      child: Column(
        children: [
          _buildActionSection(requestCount),
          SizedBox(height: 100.h),
          const Text("No Contacts", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildIndexHint(String tag) {
    return Container(
      alignment: Alignment.center,
      width: 80.r, height: 80.r,
      decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: Text(tag, style: TextStyle(color: Colors.white, fontSize: 30.sp)),
    );
  }
}