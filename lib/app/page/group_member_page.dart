import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/group_components/group_item.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/list.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/core/models/groups.dart';
import 'package:flutter_app/core/providers/product_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
          skeletonBuilder: (context){
            return _GroupItemSkeleton();
          },
          itemBuilder: (context, item, index, isLast) {
            return GroupItem(item: item);
          },
        ),
      ),
    );
  }
}

class _GroupItemSkeleton extends StatelessWidget {
  const _GroupItemSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton.circle(width: 50.w, height: 50.w),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Skeleton.react(width: 120.w, height: 16.h, borderRadius: BorderRadius.zero,),
                    Spacer(),
                    Skeleton.react(width: 60.w, height: 16.h, borderRadius: BorderRadius.zero,),
                  ],
                ),
                SizedBox(height: 8),
                GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8.w,
                      crossAxisSpacing: 8.w,
                      childAspectRatio: 143.w / 30.w,
                    ),
                    itemBuilder: (context, index){
                      return Skeleton.react(width:143.w, height: 16.h, borderRadius: BorderRadius.all(Radius.circular(4.w)),);
                    },
                    itemCount: 6,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}