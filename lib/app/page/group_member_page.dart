import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupMemberPage extends ConsumerStatefulWidget {
  final String groupId;
  const GroupMemberPage({super.key, required this.groupId});
  @override
  ConsumerState<GroupMemberPage> createState() => _GroupMemberPageState();
}

class _GroupMemberPageState extends ConsumerState<GroupMemberPage> {
  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'team-list'.tr(),
      body: Center(
        child: Text('Display members of group ${widget.groupId} here.'),
      ),
    );
  }
}