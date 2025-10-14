import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/anime_count.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/list.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/providers/winners_provider.dart';
import 'package:flutter_app/ui/custom_cupertino_sliver_refresh_control.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_app/utils/format_helper.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'package:flutter/cupertino.dart';

/// Winners Page
/// Displays banners, total winners, latest winners, and categorized winners list.
/// Uses Riverpod for state management and data fetching.

class WinnersPage extends ConsumerStatefulWidget {
  const WinnersPage({super.key});

  @override
  ConsumerState<WinnersPage> createState() => _WinnersPageState();
}

class _WinnersPageState extends ConsumerState<WinnersPage> with SingleTickerProviderStateMixin {

  late final ScrollController _scrollController;
  late final PageListController<ActWinnersMonth> _listController;
  TabController? _tabController;
  List<ActMonthTab> _tabs = const [];
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _listController = PageListController<ActWinnersMonth>(
      request:  ({required int pageSize, required int current}) {
        final currentMonth = ref.read(activeMonthProvider)?.value??1;
        final pageRequest =  ref.read(actWinnersMonthsProvider(currentMonth));
        return pageRequest(pageSize: pageSize, current: current);
      },
      preprocess: preProcessWinnersData,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _listController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(winnersBannerProvider);
    final quantity = ref.watch(winnersQuantityProvider);
    final winnersLasts = ref.watch(winnersLastsProvider);
    final actMonthNum = ref.watch(actMonthNumProvider);


    ref.listen<ActMonthTab?>(activeMonthProvider, (prev, next) async {
      if (prev?.value != next?.value) {
        await _listController.refresh();
      }
    });

    Future<void> onRefresh() async {
      ref.invalidate(winnersBannerProvider);
      ref.invalidate(winnersQuantityProvider);
      ref.invalidate(winnersLastsProvider);
      ref.invalidate(actMonthNumProvider);
      _listController.refresh();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return BaseScaffold(
      showBack: false,
      body:  NestedScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics()
      ),
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: MultiSliver(
              children: [
                //下拉动画
                CustomCupertinoSliverRefreshControl(onRefresh: onRefresh),
                // banner
                SliverToBoxAdapter(
                  child: banners.when(
                    data: (list) => _Banner(list: list),
                    error: (_, __) => _Banner(list: []),
                    loading: () => _Banner(list: []),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 32.w)),
                // total winners
                SliverToBoxAdapter(
                  child: quantity.when(
                    data: (data) => _TotalWinners(totalWinners: data.awardTotalQuantity),
                    error: (_, __) => _TotalWinners(totalWinners: 0),
                    loading: () => _TotalWinners(totalWinners: 0),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 32.w)),
                // latest winners list
                SliverToBoxAdapter(
                  child: winnersLasts.when(
                    data: (data) => LatestWinners(list: data),
                    error: (_, __) => LatestWinners(list: []),
                    loading: () => LatestWinners(list: []),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 60.w)),
                SliverToBoxAdapter(child: _ListTitle()),
                SliverToBoxAdapter(child: SizedBox(height: 20.w)),

                // month tabs
                actMonthNum.when(
                  data: (data){
                    if(_tabController == null && data.isNotEmpty){
                      final newTabs = _buildTabs(context, data);
                      _tabController = TabController(length: newTabs.length, vsync: this);
                      WidgetsBinding.instance.addPostFrameCallback((_){
                        if(_tabs.isEmpty){
                          ref.read(activeMonthProvider.notifier).state = newTabs.first;
                          setState(() {
                            _tabs = newTabs;
                          });
                        }
                      });
                    }
                    if(_tabController != null && _tabs.isNotEmpty){
                      return SliverPersistentHeader(
                        pinned: true,
                        delegate: _TabsHeaderDelegate(
                          tabs: _tabs,
                          controller: _tabController!,
                          ref: ref,
                        ),
                      );
                    }
                    return SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                  error: (_, __) => _MonthTabsSection(monthList: [], controller: _scrollController),
                  loading: () => _MonthTabsSection(monthList: [], controller: _scrollController),
                ),
              ],
            ),
        ),


      ],
      body: (_tabController == null || _tabs.isEmpty)
          ? const SizedBox.shrink()
          : TabBarView(
        controller: _tabController,
        // ✅ 禁止左右滑动，避免 NestedScroll 冲突 avoid NestedScroll conflict
        physics: const NeverScrollableScrollPhysics(),
        children: _tabs.map((t) {
          return Builder(builder: (context) {
            return CustomScrollView(
              key: PageStorageKey(t.value),
              // ✅ 重点 1：要让内部自己处理滚动
              physics: const ClampingScrollPhysics(),
              // ✅ 重点 2：不要共享 controller
              controller: ScrollController(),
              // ✅ 重点 3：确保不参与 NestedScrollView 的 primary 滚动
              primary: false,
              // ✅ 重点 4：添加顶部 overlap 修复
              slivers: [
                SliverOverlapInjector(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                ),
                _WinnerList(
                  listController: _listController,
                  controller: ScrollController(),
                )
              ],
            );
          });
        }).toList(),
      ),
    ),
    );
  }
}

/// Banner section
class _Banner extends StatelessWidget {
  final List<Banners>? list;

  const _Banner({required this.list});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      child: SwiperBanner<Banners>(banners: list ?? []),
    );
  }
}

/// Total Winners section

class _TotalWinners extends StatelessWidget {
  final int totalWinners;

  const _TotalWinners({required this.totalWinners});

  @override
  Widget build(BuildContext context) {
    // error or loading state
    if (totalWinners == 0) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        child: Skeleton.react(width: double.infinity, height: 100.w),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: context.textWhite, width: 6.w),
        boxShadow: [
          BoxShadow(
            color: Color(0x140A0D12),
            offset: Offset(0, 20.w),
            blurRadius: 24.w,
            spreadRadius: -4.w,
          ),
          BoxShadow(
            color: Color(0x0A0A0D12),
            offset: Offset(0, 8.w),
            blurRadius: 8.w,
            spreadRadius: -4.w,
          ),
          BoxShadow(
            color: Color(0x0A0A0D12),
            offset: Offset(0, 3.w),
            blurRadius: 3.w,
            spreadRadius: -1.5.w,
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.w),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF181D27), Color(0xFF414651)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimeCount(
              value: totalWinners,
              render: (value) => Text(
                'winner.number'.tr(
                  namedArgs: {
                    'number': FormatHelper.formatCompactDecimal(value),
                  },
                ),
                style: TextStyle(
                  fontSize: context.textXl,
                  color: context.fgBrandPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(height: 8.w),
            Text(
              'winner.next'.tr(),
              style: TextStyle(
                fontSize: context.textMd,
                fontWeight: FontWeight.w800,
                color: context.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Latest Winners section
class LatestWinners extends StatefulWidget {
  final List<WinnersLastsItem> list;

  const LatestWinners({super.key, required this.list});

  @override
  State<LatestWinners> createState() => _LatestWinnersState();
}

/// latest winners list section
class _LatestWinnersState extends State<LatestWinners> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    /// Loading state with skeletons
    if (widget.list.isNullOrEmpty) {
      return SizedBox(
        height: 200.w,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemBuilder: (_, index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Skeleton.react(width: 216.w, height: 200.w),
            );
          },
          separatorBuilder: (_, __) => SizedBox.shrink(),
          itemCount: 6,
        ),
      );
    }

    /// Build swiper when data is available
    /// with dots indicator
    /// if more than 1 item
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              width: 20.w,
              height: 20.w,
              colorFilter: ColorFilter.mode(
                context.fgPrimary900,
                BlendMode.srcIn,
              ),
              fit: BoxFit.contain,
              'assets/images/award.svg',
            ),
            SizedBox(width: 8.w),
            Text(
              'winner.latest'.tr(),
              style: TextStyle(
                color: context.textPrimary900,
                fontSize: 16.w,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 300.w,
              child: Swiper(
                itemWidth: 216.w,
                itemHeight: 300.w,
                viewportFraction: 0.6,
                // two side item visible
                scale: 0.86,
                loop: false,
                // disable infinite loop to void first item cut off
                itemCount: widget.list.length,
                onIndexChanged: (i) {
                  if (mounted) {
                    setState(() {
                      currentIndex = i;
                    });
                  }
                },
                itemBuilder: (context, index) {
                  final item = widget.list[index];

                  /// winner item
                  return _LatestWinnerSwiperItem(item: item);
                },
              ),
            ),
            // dots indicator
            if (widget.list.length > 1)
              _PositionedDot(
                length: widget.list.length,
                currentIndex: currentIndex,
              ),
          ],
        ),
      ],
    );
  }
}

/// latest winner swiper item
class _LatestWinnerSwiperItem extends StatelessWidget {
  final WinnersLastsItem item;

  const _LatestWinnerSwiperItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 20.w),
      child: Material(
        color: context.bgPrimary,
        elevation: 8.w,
        shadowColor: Colors.black.withValues(alpha: 120),
        borderRadius: BorderRadius.circular(12.w),
        clipBehavior: Clip.antiAlias,

        surfaceTintColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.w),
            border: Border.all(color: context.borderSecondary, width: 1.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ClipRRect(
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(8.w),
                  child: CachedNetworkImage(
                    imageUrl: proxied(item.mainImageList![0]),
                    width: 180.w,
                    height: 120.w,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Skeleton.react(
                      width: 180.w,
                      height: 120.w,
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    errorWidget: (_, __, ___) => Skeleton.react(
                      width: 180.w,
                      height: 120.w,
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.w),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Text(
                  item.winnerName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.textMd,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary900,
                    height: context.leadingMd,
                  ),
                ),
              ),
              SizedBox(height: 8.w),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Text(
                  item.treasureName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimary900,
                    fontSize: context.textXs,
                    fontWeight: FontWeight.w800,
                    height: context.leadingXs,
                  ),
                ),
              ),
              SizedBox(height: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.buttonOutlineBorder,
                    width: 2.w,
                  ),
                  borderRadius: BorderRadius.circular(8.w),
                ),
                child: Text('common.award.details'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<ActMonthTab> _buildTabs(BuildContext context, List<int> monthList) {
  final names = [
    'common.month.jan'.tr(),
    'common.month.feb'.tr(),
    'common.month.mar'.tr(),
    'common.month.apr'.tr(),
    'common.month.may'.tr(),
    'common.month.jun'.tr(),
    'common.month.jul'.tr(),
    'common.month.aug'.tr(),
    'common.month.sep'.tr(),
    'common.month.oct'.tr(),
    'common.month.nov'.tr(),
    'common.month.dec'.tr(),
  ];

  final now = DateTime.now();
  return monthList.map((v) {
    final back = v - 1;
    final d = DateTime(now.year, now.month - back, 1);
    final title = names[d.month - 1];
    final monthTitle = DateFormat(
      'MMM yyyy',
      context.locale.toLanguageTag(),
    ).format(d).toUpperCase();
    return ActMonthTab(value: v, title: title, monthTitle: monthTitle);
  }).toList();
}

/// Title for the winners list section
class _ListTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              width: 24.w,
              height: 24.w,
              colorFilter: ColorFilter.mode(
                context.textPrimary900,
                BlendMode.srcIn,
              ),
              'assets/images/list.svg',
            ),
            SizedBox(width: 16.w),
            Text(
              'winner.list'.tr(),
              style: TextStyle(
                fontSize: 16.w,
                fontWeight: FontWeight.w800,
                color: context.textPrimary900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Month model for tabs
/// Used to represent each month in the tabs section
/// with its value, title, and display title.
/// E.g., value: 1, title: "January", monthTitle: "Jan"

class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List <ActMonthTab> tabs;
  final TabController controller;
  final WidgetRef ref;
  _TabsHeaderDelegate({required this.tabs,required this.controller,required this.ref});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context,double shrinkOffset, bool overlapsContent) {
    return Material(
      color: context.bgPrimary,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        height: maxExtent,
        child: TabBar(
          tabs: tabs.map((e) => Tab(text: e.title)).toList(),
          controller: controller,
          isScrollable: true,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          indicatorColor: context.fgBrandPrimary,
          onTap: (i){
            final next = tabs[i];
            ref.read(activeMonthProvider.notifier).state = next;
          },
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsHeaderDelegate oldDelegate) {
    return oldDelegate.tabs != tabs || oldDelegate.controller != controller;
  }
}

class _MonthTabsSection extends StatelessWidget {
  final List<int> monthList;
  final ScrollController controller;

  const _MonthTabsSection({required this.monthList,required this.controller});

  /// Build month tabs based on the provided month list
  /// Generates a list of _MonthModel with localized month names


  @override
  Widget build(BuildContext context) {
    /// Loading state with skeletons
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 44.h,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (_) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 12.h),
                child: Skeleton.react(
                  width: 60.w,
                  height: 44.h,
                  borderRadius: BorderRadius.circular(context.radiusSm),
                ),
              );
            }),
          ),
        ),
      ),
    );

  }
}

/// Winners list section
class _WinnerList extends ConsumerWidget {

  final PageListController<ActWinnersMonth> listController;
  final ScrollController controller;
  const _WinnerList({required this.listController,required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(activeMonthProvider);
    print("🧩 currentMonth: ${currentMonth!.value}");

    if(currentMonth == null){
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return MultiSliver(
      children: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                currentMonth.monthTitle,
                style: TextStyle(
                  fontSize: context.textMd,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900,
                  height: context.leadingMd,
                ),
              ),
            ),
          ),
        ),
        PageListViewPro<ActWinnersMonth>(
          controller: listController,
          sliverMode: true,
          itemBuilder:
              (
              BuildContext context,
              ActWinnersMonth item,
              int index,
              bool isLast,
              ) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WinnerListItem(item: item),
                ],
              ),
            );
          },
        )

      ],
    );
  }
}

/// Single winner list item
class _WinnerListItem extends StatelessWidget{
  final ActWinnersMonth item;
  const _WinnerListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item.firstOfDay!)
          Padding(
            padding: EdgeInsets.only(
              left: 12.w,
              bottom: 12.w,
              top: 12.w,
            ),
            child: Text(
              item.dateTitle ?? '',
              style: TextStyle(
                fontSize: context.textXs,
                fontWeight: FontWeight.w600,
                color: context.textSecondary700,
              ),
            ),
          ),
          Container(
          padding: EdgeInsets.only(
            left: 8.w,
            right: 8.w,
            top: item.firstOfDay == true ? 16.w : 12.w,
            bottom: item.lastOfDay == true ? 16.w : 0,
          ),
          decoration: BoxDecoration(
            color: context.bgPrimary,
            borderRadius: BorderRadius.vertical(
              top: item.firstOfDay == true
                  ? Radius.circular(8.w)
                  : Radius.zero,
              bottom: item.lastOfDay == true
                  ? Radius.circular(8.w)
                  : Radius.zero,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ClipRRect(
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(8.w),
                child: CachedNetworkImage(
                  imageUrl: proxied(item.mainImageList!.first),
                  width: 72.w,
                  height: 72.w,
                  fit: BoxFit.cover,
                  placeholder: (_, __) {
                    return Skeleton.react(
                      width: 72.w,
                      height: 72.w,
                      borderRadius: BorderRadius.circular(8.w),
                    );
                  },
                  errorWidget: (_, __, ___) {
                    return Skeleton.react(
                      width: 72.w,
                      height: 72.w,
                      borderRadius: BorderRadius.circular(8.w),
                    );
                  },
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.treasureName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.textSm,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary900,
                        height: context.leadingSm,
                      ),
                    ),
                    SizedBox(height: 4.w),
                    Text(
                      item.winnerName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.textXs,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary700,
                        height: context.leadingXs,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
            ],
          ),
        ),
      ],
    );
  }

}

/// Dots indicator for the swiper
/// Indicates the current index in the swiper with animated dots
/// - length: Total number of items in the swiper
/// - currentIndex: Currently active index in the swiper
class _PositionedDot extends StatelessWidget {
  final int length;
  final int currentIndex;

  const _PositionedDot({required this.length, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: -20.w,
      left: 0,
      right: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(length, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: currentIndex == i ? 18.w : 8.w,
            height: 8.w,
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              color: currentIndex == i
                  ? context.fgBrandPrimary
                  : Colors.black.withAlpha(30),
              borderRadius: BorderRadius.circular(3.w),
            ),
          );
        }),
      ),
    );
  }
}

List<ActWinnersMonth> preProcessWinnersData(List<ActWinnersMonth> data) {
  // sort by lottery_time desc
  final Map<String, List<ActWinnersMonth>> grouped = {};

  for (final item in data) {
    final date = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.fromMillisecondsSinceEpoch(item.lotteryTime));
    grouped.putIfAbsent(date, () => []);
    grouped[date]!.add(item);
  }

  // connect title and tag
  final List<ActWinnersMonth> result = [];

  grouped.forEach((date, group) {
    /// Add a title item for the date
    final dateTitle = DateFormat('EEEE d MMM').format(DateTime.parse(date));

    for (int i = 0; i < group.length; i++) {
      final isFirst = i == 0;
      final isLast = i == group.length - 1;
      final item = group[i].copyWith(
        firstOfDay: isFirst,
        lastOfDay: isLast,
        dateTitle: isFirst ? dateTitle : null,
      );
      result.add(item);
    }
  });
  // preprocess data if needed
  // return result;
  return result;
}
