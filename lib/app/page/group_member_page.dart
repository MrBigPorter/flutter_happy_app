import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/group_components/group_item.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/groups.dart';

class GroupMemberPage extends ConsumerStatefulWidget {
  final String groupId;
  final String? groupName;
  const GroupMemberPage({super.key, required this.groupId, this.groupName});
  @override
  ConsumerState<GroupMemberPage> createState() => _GroupMemberPageState();
}

class _GroupMemberPageState extends ConsumerState<GroupMemberPage> {
  @override
  Widget build(BuildContext context) {
    final data = {
      "id": "uuid-v4",
      "createdAt": 1704067200000,
      "groupId": "uuid-v4",
      "userId": "uuid-v4",
      "orderId": "uuid-v4",
      "isOwner": 1,
      "shareCoin": "BTC",
      "shareAmount": "0.005",
      "joinedAt": 1704067200000,
      "user": {
        "id": "uuid-v4",
        "nickname": "alice",
        "avatar": "https://example.com/avatar.png"
      }
    };
    final item = GroupMemberItem.fromJson(data);
    return BaseScaffold(
      title: 'team-list'.tr(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GroupItem(item: item,),
          )
        ],
      ),
    );
  }
}