import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/button/button.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = ref.watch(selectionStateProvider).length;
    final isMulti = widget.args.mode == SelectionMode.multiple;

    return BaseScaffold(
      title: widget.args.title,
      // 只有多选模式才显示右上角确认按钮
      actions: isMulti
          ? [
        Padding(
          padding: EdgeInsets.only(right: 16.w, top: 10.h, bottom: 10.h),
          child: Button(
            width: 80.w,
            height: 32.h,
            disabled: selectedCount == 0,
            onPressed: () => _onConfirm(),
            child: Text("${widget.args.confirmText ?? 'Done'} ($selectedCount)"),
          ),
        )
      ]
          : null,
      body: Column(
        children: [
          // Tab Bar
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
          // List Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RecentList(args: widget.args),
                _ContactList(args: widget.args),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onConfirm() {
    final selected = ref.read(selectionStateProvider);
    context.pop(selected.toList());
  }
}

// ----------------------------------------------------
// Tab 1: 最近会话 (复用 ConversationListProvider)
// ----------------------------------------------------
class _RecentList extends ConsumerWidget {
  final ContactSelectionArgs args;
  const _RecentList({required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取最近会话列表
    final listAsync = ref.watch(conversationListProvider);

    return listAsync.when(
      data: (list) {
        // 转换数据模型
        final entities = list.map((c) => SelectionEntity(
          id: c.id,
          name: c.name,
          avatar: c.avatar,
          type: c.type == ConversationType.group ? EntityType.group : EntityType.user,
          desc: c.type == ConversationType.group ? "Group" : "Recent",
        )).where((e) => !args.excludeIds.contains(e.id)).toList();

        return _SelectionListView(entities: entities, args: args);
      },
      error: (_, __) => const Center(child: Text("Error loading chats")),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

// ----------------------------------------------------
// Tab 2: 通讯录 (复用 ContactListProvider)
// ----------------------------------------------------
class _ContactList extends ConsumerWidget {
  final ContactSelectionArgs args;
  const _ContactList({required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 假设你有一个 contactListProvider 返回 List<ChatUser>
    // 这里需要根据你的实际 ContactProvider 修改
    final contactsAsync = ref.watch(contactListProvider);

    return contactsAsync.when(
      data: (contacts) {
        final entities = contacts.map((u) => SelectionEntity(
          id: u.id,
          name: u.nickname,
          avatar: u.avatar,
          type: EntityType.user,
          desc: "Contact",
        )).where((e) => !args.excludeIds.contains(e.id)).toList();

        return _SelectionListView(entities: entities, args: args);
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

  const _SelectionListView({required this.entities, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSet = ref.watch(selectionStateProvider);

    return ListView.separated(
      itemCount: entities.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 72.w, color: context.bgSecondary),
      itemBuilder: (context, index) {
        final item = entities[index];
        final isSelected = selectedSet.contains(item);

        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Stack(
            children: [
              // 头像
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
                  )
                      : null,
                ),
                child: item.avatar == null
                    ? Icon(
                  item.type == EntityType.group ? Icons.groups : Icons.person,
                  color: context.textSecondary700,
                )
                    : null,
              ),
              // 多选模式下的勾选框 (放在头像上或右边都可以，仿微信通常在右边，这里为了简单用 leading/trailing)
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
          trailing: args.mode == SelectionMode.multiple
              ? _buildCheckbox(context, isSelected) // 多选显示勾选框
              : null, // 单选不显示
          onTap: () {
            if (args.mode == SelectionMode.single) {
              // 单选模式：点击直接返回结果
              context.pop([item]);
            } else {
              // 多选模式：切换状态
              ref.read(selectionStateProvider.notifier).toggle(item, args.mode);
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