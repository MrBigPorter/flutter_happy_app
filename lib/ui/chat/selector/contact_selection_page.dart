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

  // 内部控制是否开启多选
  late bool _isMultiSelectMode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 初始状态：如果外部传进来就是多选(如拉群)，那就默认多选
    // 如果外部传的是单选(如转发)，默认关闭多选，但允许用户手动开启
    _isMultiSelectMode = widget.args.mode == SelectionMode.multiple;
  }

  // 切换模式逻辑
  void _toggleMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
    });

    // 如果切回单选，清空已选中的人
    if (!_isMultiSelectMode) {
      ref.invalidate(selectionStateProvider);
    }
  }

  void _onConfirm() {
    final selected = ref.read(selectionStateProvider);
    context.pop(selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = ref.watch(selectionStateProvider).length;
    // 判断是否允许切换：只有当原始意图是 Single 时，才显示 Select 按钮
    final bool canSwitch = widget.args.mode == SelectionMode.single;

    return BaseScaffold(
      title: widget.args.title,
      // 1. 顶部按钮 (Select / Cancel)
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
      // 2. 使用 Stack 来模拟 FloatingActionButton
      body: Stack(
        children: [
          // 底层：Tab 和 列表
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
                    // 把 _isMultiSelectMode 传下去
                    _RecentList(args: widget.args, isMultiSelectMode: _isMultiSelectMode),
                    _ContactList(args: widget.args, isMultiSelectMode: _isMultiSelectMode),
                  ],
                ),
              ),
            ],
          ),

          // 上层：悬浮确认按钮 (仅多选模式且有人被选中时显示)
          if (_isMultiSelectMode && selectedCount > 0)
            Positioned(
              right: 20.w,
              bottom: 40.h + MediaQuery.of(context).padding.bottom, // 避开底部安全区
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
// Tab 1: 最近会话
// ----------------------------------------------------
// 将 ConsumerWidget 改为 ConsumerStatefulWidget
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

// 混入 AutomaticKeepAliveClientMixin
class _RecentListState extends ConsumerState<_RecentList> with AutomaticKeepAliveClientMixin {

  //  核心：告诉 Flutter 保持活跃，不要销毁
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); //  必须调用 super.build

    final listAsync = ref.watch(conversationListProvider);

    return listAsync.when(
      data: (list) {
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
      error: (_, __) => const Center(child: Text("Error loading chats")),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

// ----------------------------------------------------
// Tab 2: 通讯录
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
  bool get wantKeepAlive => true; // 保持活跃

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用

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
      error: (_, __) => const Center(child: Text("Error loading contacts")),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

// ----------------------------------------------------
// 核心：复用的列表视图
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
      padding: EdgeInsets.only(bottom: 100.h), // 底部留白给悬浮按钮
      separatorBuilder: (_, __) => Divider(height: 1, indent: 72.w, color: context.bgSecondary),
      itemBuilder: (context, index) {
        final item = entities[index];
        final isSelected = selectedSet.contains(item);

        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Stack(
            children: [
              Container(
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
            ],
          ),
          title: Text(
            item.name,
            style: TextStyle(fontSize: 16.sp, color: context.textPrimary900, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            item.desc ?? "",
            style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
          ),

          //  根据 isMultiSelectMode 显示勾选框
          trailing: isMultiSelectMode
              ? _buildCheckbox(context, isSelected)
              : null,

          onTap: () {
            //  根据 isMultiSelectMode 决定行为
            if (isMultiSelectMode) {
              // 多选模式：切换状态，不返回
              ref.read(selectionStateProvider.notifier).toggle(item, SelectionMode.multiple);
            } else {
              // 单选模式：直接带数据返回
              context.pop([item]);
            }
          },
        );
      },
    );
  }

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