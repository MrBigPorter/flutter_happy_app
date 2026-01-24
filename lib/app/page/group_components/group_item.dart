import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/group_components/group_user_item.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/core/models/groups.dart';

class GroupItem extends StatefulWidget {
  final GroupForTreasureItem item;
  final int index;

  const GroupItem({super.key, required this.item, required this.index});

  @override
  State<GroupItem> createState() => _GroupItemState();
}

class _GroupItemState extends State<GroupItem>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final index = widget.index;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(context.radiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: SizedBox(
                height: 72.w,
                child: Row(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontSize: context.textSm,
                            height: context.leadingMd,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary900,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Team ${item.creator.nickname}',
                              style: TextStyle(
                                fontSize: context.textSm,
                                height: context.leadingMd,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary900,
                              ),
                            ),
                            SizedBox(height: 4.w),
                            Text(
                              'Members: ${item.currentMembers}',
                              style: TextStyle(
                                fontSize: context.textXs,
                                height: context.leadingSm,
                                fontWeight: FontWeight.w800,
                                color: context.textSecondary700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Spacer(),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 24.w,
                        color: context.fgPrimary900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...[
            AnimatedSize(
              duration: Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: ClipRect(
                child: Align(
                  heightFactor: isExpanded ? 1.0 : 0.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: item.members.map((member) {
                      return GroupUserItem(
                        item: member,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
          ],
        ),
      ),
    );
  }
}
