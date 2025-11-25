import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/page/group_components/group_item.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/list.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/providers/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductGroupPage extends ConsumerStatefulWidget {
  final String treasureId;

  const ProductGroupPage({super.key, required this.treasureId});

  @override
  ConsumerState<ProductGroupPage> createState() => _ProductGroupPageState();
}

class _ProductGroupPageState extends ConsumerState<ProductGroupPage> {
  late final PageListController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _controller = PageListController(
      request: ({required int pageSize, required int page}) {
        final req = ref.read(groupsPageListProvider(widget.treasureId));
        return req(pageSize: pageSize, page: page);
      },
      requestKey: 'product-group-${widget.treasureId}',
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final treasureId = widget.treasureId;

    return BaseScaffold(
      title: 'draw-team'.tr(),
      body: _controller.wrapWithNotification(
        child: PageListViewPro(
          controller: _controller,
          padding: EdgeInsets.only(top: 4.w, bottom: 16.w),
          itemBuilder: (context, item, index, isLast) {
            return GroupItem(item: item, index: index);
          },
          skeletonCount: 10,
          skeletonBuilder: (context) {
            return _GroupItemSkeleton();
          },
        ),
      ),
    );
  }
}

class _GroupItemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            SizedBox(
              height: 72.w,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Skeleton.react(
                          width: 20.w,
                          height: 20.w,
                          borderRadius: BorderRadius.zero,
                        ),
                        SizedBox(width: 8.w),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Skeleton.react(
                              width: 100.w,
                              height: 16.w,
                              borderRadius: BorderRadius.zero,
                            ),
                            SizedBox(height: 8.w),
                            Skeleton.react(
                              width: 200.w,
                              height: 14.w,
                              borderRadius: BorderRadius.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Skeleton.react(
                        width: 20.w,
                        height: 20.w,
                        borderRadius: BorderRadius.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
