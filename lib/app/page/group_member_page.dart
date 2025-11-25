import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/group_components/group_item.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/core/models/groups.dart';
import 'package:flutter_app/core/providers/product_provider.dart';

class GroupMemberPage extends ConsumerStatefulWidget {
  final String groupId;
  final String? groupName;

  const GroupMemberPage({super.key, required this.groupId, this.groupName});

  @override
  ConsumerState<GroupMemberPage> createState() => _GroupMemberPageState();
}

class _GroupMemberPageState extends ConsumerState<GroupMemberPage> {
  late final PageListController<GroupMemberItem> _controller;

  @override
  void initState() {
    _controller = PageListController<GroupMemberItem>(
      request: ({required int pageSize, required int page}) {
        final req = ref.read(groupMemberListProvider(widget.groupId));
        return req(pageSize: pageSize, page: page);
      },
      requestKey: 'group-member-${widget.groupId}',
    );

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'team-list'.tr(),
      body: _controller.wrapWithNotification(
        child: PageListViewPro(
          controller: _controller,
          gridDelegate: null,
          itemBuilder: (context, item, index, isLast) {
            return GroupItem(item: item);
          },
        ),
      ),
    );
  }
}
