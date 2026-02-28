import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../models/conversation.dart';
import '../models/selection_types.dart';
import '../providers/selection_provider.dart';

class ContactSelectionPage extends ConsumerStatefulWidget {
  final ContactSelectionArgs args;

  const ContactSelectionPage({super.key, required this.args});

  @override
  ConsumerState<ContactSelectionPage> createState() => _ContactSelectionPageState();
}

class _ContactSelectionPageState extends ConsumerState<ContactSelectionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Internal state to track if the UI is currently in multiple selection mode
  late bool _isMultiSelectMode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Default to multiple selection if specified by arguments; otherwise start in single mode.
    _isMultiSelectMode = widget.args.mode == SelectionMode.multiple;
  }

  /// Toggles between single and multiple selection modes and clears state if needed.
  void _toggleMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
    });

    // Invalidate the selection provider when returning to single mode to prevent accidental bulk actions.
    if (!_isMultiSelectMode) {
      ref.invalidate(selectionStateProvider);
    }
  }

  /// Finalizes the selection and returns the list of selected entities to the caller.
  void _onConfirm() {
    final selected = ref.read(selectionStateProvider);
    context.pop(selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = ref.watch(selectionStateProvider).length;

    // Only allow mode switching if the original intent was a single selection.
    final bool canSwitch = widget.args.mode == SelectionMode.single;

    return BaseScaffold(
      title: widget.args.title,
      // 1. Navigation Actions (Switching Selection Logic)
      actions: [
        if (canSwitch)
          TextButton(
            onPressed: _toggleMode,
            child: Text(
              _isMultiSelectMode ? "Cancel" : "Select",
              style: TextStyle(
                fontSize: 16.sp,
                color: context.textBrandPrimary900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
      // 2. Main Content Body with Floating Confirmation Button overlay
      body: Stack(
        children: [
          // Bottom Layer: Tabs and Entity Lists
          Column(
            children: [
              Container(
                color: context.bgPrimary,
                child: TabBar(
                  controller: _tabController,
                  labelColor: context.textBrandPrimary900,
                  unselectedLabelColor: context.textSecondary700,
                  indicatorColor: context.textBrandPrimary900,
                  tabs: const [
                    Tab(text: "Recent Chats"),
                    Tab(text: "Contacts"),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _RecentList(args: widget.args, isMultiSelectMode: _isMultiSelectMode),
                    _ContactList(args: widget.args, isMultiSelectMode: _isMultiSelectMode),
                  ],
                ),
              ),
            ],
          ),

          // Top Layer: Floating Confirmation Button (Visible only in multi-select mode)
          if (_isMultiSelectMode && selectedCount > 0)
            Positioned(
              right: 20.w,
              bottom: 40.h + MediaQuery.of(context).padding.bottom,
              child: FloatingActionButton.extended(
                onPressed: _onConfirm,
                backgroundColor: context.textBrandPrimary900,
                icon: const Icon(Icons.send, color: Colors.white),
                label: Text(
                  "${widget.args.confirmText ?? 'Send'} ($selectedCount)",
                  style: const TextStyle(color: Colors.white),
                ),
                elevation: 4,
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Tab 1: Recent Conversations
// ----------------------------------------------------
class _RecentList extends ConsumerStatefulWidget {
  final ContactSelectionArgs args;
  final bool isMultiSelectMode;

  const _RecentList({
    super.key,
    required this.args,
    required this.isMultiSelectMode
  });

  @override
  ConsumerState<_RecentList> createState() => _RecentListState();
}

class _RecentListState extends ConsumerState<_RecentList> with AutomaticKeepAliveClientMixin {
  /// Ensures the tab content is preserved during navigation between tabs.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final listAsync = ref.watch(conversationListProvider);

    return listAsync.when(
      data: (list) {
        // Map conversation items to unified SelectionEntities
        final entities = list.map((c) => SelectionEntity(
          id: c.id,
          name: c.name,
          avatar: c.avatar,
          type: c.type == ConversationType.group ? EntityType.group : EntityType.user,
          desc: c.type == ConversationType.group ? "Group" : "Recent",
        )).where((e) => !widget.args.excludeIds.contains(e.id)).toList();

        return _SelectionListView(
            entities: entities,
            args: widget.args,
            isMultiSelectMode: widget.isMultiSelectMode
        );
      },
      error: (err, _) => Center(child: Text("Load failed: $err")),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

// ----------------------------------------------------
// Tab 2: Contact List
// ----------------------------------------------------
class _ContactList extends ConsumerStatefulWidget {
  final ContactSelectionArgs args;
  final bool isMultiSelectMode;

  const _ContactList({
    super.key,
    required this.args,
    required this.isMultiSelectMode
  });

  @override
  ConsumerState<_ContactList> createState() => _ContactListState();
}

class _ContactListState extends ConsumerState<_ContactList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final contactsAsync = ref.watch(contactListProvider);

    return contactsAsync.when(
      data: (contacts) {
        final entities = contacts.map((u) => SelectionEntity(
          id: u.id,
          name: u.nickname,
          avatar: u.avatar,
          type: EntityType.user,
          desc: "Contact",
        )).where((e) => !widget.args.excludeIds.contains(e.id)).toList();

        return _SelectionListView(
            entities: entities,
            args: widget.args,
            isMultiSelectMode: widget.isMultiSelectMode
        );
      },
      error: (err, _) => Center(child: Text("Load failed: $err")),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

// ----------------------------------------------------
// Core: Reusable Selection List View
// ----------------------------------------------------
class _SelectionListView extends ConsumerWidget {
  final List<SelectionEntity> entities;
  final ContactSelectionArgs args;
  final bool isMultiSelectMode;

  const _SelectionListView({
    required this.entities,
    required this.args,
    required this.isMultiSelectMode
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSet = ref.watch(selectionStateProvider);

    return ListView.separated(
      itemCount: entities.length,
      padding: EdgeInsets.only(bottom: 100.h), // Extra padding to avoid occlusion by FAB
      separatorBuilder: (_, __) => Divider(height: 1, indent: 72.w, color: context.bgSecondary),
      itemBuilder: (context, index) {
        final item = entities[index];
        final isSelected = selectedSet.contains(item);

        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              color: context.bgSecondary,
              image: item.avatar != null
                  ? DecorationImage(
                image: CachedNetworkImageProvider(
                  UrlResolver.resolveImage(context, item.avatar!, logicalWidth: 48),
                ),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: item.avatar == null
                ? Icon(
              item.type == EntityType.group ? Icons.groups : Icons.person,
              color: context.textSecondary700,
            ) : null,
          ),
          title: Text(
            item.name,
            style: TextStyle(fontSize: 16.sp, color: context.textPrimary900, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            item.desc ?? "",
            style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
          ),
          // Conditional trailing checkbox based on current selection mode
          trailing: isMultiSelectMode
              ? _buildCheckbox(context, isSelected)
              : null,
          onTap: () {
            if (isMultiSelectMode) {
              // Toggle state in multi-selection mode
              ref.read(selectionStateProvider.notifier).toggle(item, SelectionMode.multiple);
            } else {
              // Direct pop with result in single-selection mode
              context.pop([item]);
            }
          },
        );
      },
    );
  }

  /// Builds a custom circular checkbox reflecting the selection status
  Widget _buildCheckbox(BuildContext context, bool isChecked) {
    return Container(
      width: 24.r,
      height: 24.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isChecked ? context.textBrandPrimary900 : Colors.transparent,
        border: Border.all(
          color: isChecked ? context.textBrandPrimary900 : context.textSecondary700,
          width: 1.5,
        ),
      ),
      child: isChecked
          ? Icon(Icons.check, size: 16.r, color: Colors.white)
          : null,
    );
  }
}