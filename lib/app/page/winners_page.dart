import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/anime_count.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/list.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/providers/winners_provider.dart';
import 'package:flutter_app/ui/lucky_refresh_header_pro.dart';
import 'package:flutter_app/ui/lucky_tab_bar_delegate.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';

/// Winners Page
/// 1. 上半部分 header 包含 banner、total winners、latest winners
/// 2. 下半部分 tab 列表 winners list with tabs
/// 3. 支持下拉刷新 pull to refresh
/// 4. 支持 tab 吸顶 pinned tab bar
/// 5. 支持分页加载分页加载 page list view
/// 6. 支持国际化 i18n
class WinnersPage extends ConsumerStatefulWidget {
  const WinnersPage({super.key});

  @override
  ConsumerState<WinnersPage> createState() => _WinnersPageState();
}

class _WinnersPageState extends ConsumerState<WinnersPage>
    with SingleTickerProviderStateMixin {
  final Map<int, GlobalKey<_WinnerListState>> _listKeys = {};
  late TabController _tabController;
  List<ActMonthTab> _tabs = const [];
  DateTime _lastRefreshTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<List<int>>>(actMonthNumProvider, (prev, next) {
      next.whenData((months) {
        if (months.isNotEmpty) {
          final tabs = _buildTabs(context, months);
          ref.read(activeMonthProvider.notifier).state = tabs.first;
          setState(() {
            _tabs = tabs;
            _listKeys
            ..clear()
            ..addEntries(tabs.map((t) => MapEntry(t.value, GlobalKey<_WinnerListState>())));
          });
          _tabController = TabController(length: tabs.length, vsync: this);
        }
      });
    });

  }

  Future<void> _onRefresh() async {

    /// 暂存当前激活 tab  avoid losing current active tab
    final cur = ref.read(activeMonthProvider)?.value;
    if (cur == null) return;

    ///  刷新月份列表 refresh month list
    await Future.wait([
      ref.refresh(winnersBannerProvider.future),
      ref.refresh(winnersQuantityProvider.future),
      ref.refresh(winnersLastsProvider.future),
    ]);

    final req = ref.refresh(actWinnersMonthsProvider(cur));
    await req(pageSize: 10, current: 1); // 刷新当前 tab 列表 refresh current tab list
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _lastRefreshTime = DateTime.now());
  }

  Future<bool> _onRefreshWrapper() async {
    await _onRefresh(); // 调用你原本的刷新逻辑
    return true; // 告诉 PullToRefresh 已完成
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BaseScaffold(
      showBack: false,
      body: PullToRefreshNotification(
        onRefresh: _onRefreshWrapper,
        maxDragOffset: 100,
        child: ExtendedNestedScrollView(
          onlyOneScrollInBody: true,
          pinnedHeaderSliverHeightBuilder: () =>
          kToolbarHeight - 8,
          headerSliverBuilder: (context, _) => [
            /// ✅ 下拉刷新头 pull to refresh header
            SliverToBoxAdapter(
              child: PullToRefreshContainer(
                    (info) => LuckyRefreshHeaderPro(
                        info:info,
                        lastRefreshTime: _lastRefreshTime,
                    ),
              ),
            ),

            /// ✅ 全部上半部分内容都放这里 header before tabs
            SliverToBoxAdapter(child: RenderBeforeTabs()),

            /// ✅ Tab 吸顶区域 pinned tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: LuckySliverTabBarDelegate(
                  controller: _tabController,
                  tabs: _tabs,
                  renderItem: (t) => Tab(text: t.title),
                  onTap: (item) {
                    ref.read(activeMonthProvider.notifier).state = item;
                  }
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: _tabs.map((t) {
              return ExtendedVisibilityDetector(
                uniqueKey: Key('Tab${t.value}'),
                child: _WinnerList(key:_listKeys[t.value],monthValue: t.value),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}


/// ========== 下面是 header（上半部分） ==========
class RenderBeforeTabs extends ConsumerWidget {
  const RenderBeforeTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(winnersBannerProvider);
    final quantity = ref.watch(winnersQuantityProvider);
    final winnersLasts = ref.watch(winnersLastsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        banners.when(
          data: (data) => _Banner(list: data),
          loading: () => _Banner(list: null),
          error: (_, __) => _Banner(list: null),
        ),
        SizedBox(height: 32.w),
        quantity.when(
          data: (data) => _TotalWinners(totalWinners: data.awardTotalQuantity),
          loading: () => _TotalWinners(totalWinners: 0),
          error: (_, __) => _TotalWinners(totalWinners: 0),
        ),
        SizedBox(height: 32.w),
        winnersLasts.when(
          data: (data) => LatestWinners(list: data),
          loading: () => LatestWinners(list: []),
          error: (_, __) => LatestWinners(list: []),
        ),
        SizedBox(height: 80.w),
        // List title section
        _ListTitle(),
        SizedBox(height: 16.w),
      ],
    );
  }
}

/// banner
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

/// total winners
class _TotalWinners extends StatelessWidget {
  final int totalWinners;
  const _TotalWinners({required this.totalWinners});

  @override
  Widget build(BuildContext context) {
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
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.w),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF181D27), Color(0xFF414651)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimeCount(
              value: totalWinners,
              render: (value) => Text(
                'winner.number'.tr(namedArgs: {
                  'number': FormatHelper.formatCompactDecimal(value),
                }),
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

/// latest winners
class LatestWinners extends StatefulWidget {
  final List<WinnersLastsItem> list;
  const LatestWinners({super.key, required this.list});
  @override
  State<LatestWinners> createState() => _LatestWinnersState();
}

class _LatestWinnersState extends State<LatestWinners> {
  int currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    if (widget.list.isEmpty) {
      return SizedBox(
        height: 200.w,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, __) =>
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Skeleton.react(width: 216.w, height: 200.w)),
          separatorBuilder: (_, __) => const SizedBox.shrink(),
          itemCount: 6,
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/award.svg',
              width: 20.w,
              height: 20.w,
              colorFilter:
              ColorFilter.mode(context.fgPrimary900, BlendMode.srcIn),
            ),
            SizedBox(width: 8.w),
            Text('winner.latest'.tr(),
                style: TextStyle(
                    color: context.textPrimary900,
                    fontSize: 16.w,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 300.w,
              child: Swiper(
                itemWidth: 216.w,
                viewportFraction: 0.6,
                scale: 0.86,
                loop: false,
                itemCount: widget.list.length,
                onIndexChanged: (i) => setState(() => currentIndex = i),
                itemBuilder: (context, index) =>
                    _LatestWinnerSwiperItem(item: widget.list[index]),
              ),
            ),
            if (widget.list.length > 1)
              _PositionedDot(length: widget.list.length, currentIndex: currentIndex),
          ],
        ),
      ],
    );
  }
}

/// swiper item
class _LatestWinnerSwiperItem extends StatelessWidget {
  final WinnersLastsItem item;
  const _LatestWinnerSwiperItem({required this.item});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 20.w),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.w),
          color: context.bgPrimary,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8.w,
              offset: Offset(0, 4.w),
            ),

          ]
        ),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.w),
            border: Border.all(color: context.borderSecondary, width: 1.w),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.w),
                /// images
                child: CachedNetworkImage(
                  imageUrl: proxied(item.mainImageList!.first),
                  width: 180.w,
                  height: 120.w,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Skeleton.react(width: 180.w, height: 120.w),
                  errorWidget: (_, __, ___) =>
                      Skeleton.react(width: 180.w, height: 120.w),
                ),
              ),
              SizedBox(height: 8.w),
              /// winner name
              Text(item.winnerName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.textMd,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary900)),
              SizedBox(height: 8.w),
              /// treasure name
              Text(item.treasureName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.textXs,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary900)),
            ],
          ),
        ),
      ),
    );
  }
}

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

/// dot indicator
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(length, (i) {
          final active = i == currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 18.w : 8.w,
            height: 8.w,
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              color: active ? context.fgBrandPrimary : Colors.black26,
              borderRadius: BorderRadius.circular(3.w),
            ),
          );
        }),
      ),
    );
  }
}

/// tab 列表部分
class _WinnerList extends ConsumerStatefulWidget {
  final int monthValue;
  const _WinnerList({super.key,required this.monthValue});
  @override
  ConsumerState<_WinnerList> createState() => _WinnerListState();
}

class _WinnerListState extends ConsumerState<_WinnerList> {
  late PageListController<ActWinnersMonth> _ctl;

 /// 对外暴露刷新方法  expose refresh method
  Future<void> refresh() async => _ctl.refresh();

  @override
  void initState() {
    super.initState();
    _ctl = PageListController<ActWinnersMonth>(
      request: ({required int pageSize, required int current}) {
        final req = ref.read(actWinnersMonthsProvider(widget.monthValue));
        return req(pageSize: pageSize, current: current);
      },
      preprocess: preProcessWinnersData,
      requestKey: widget.monthValue,
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = ref.watch(activeMonthProvider);
    if (currentMonth == null) return const SizedBox.shrink();

    return _ctl.wrapWithNotification(
      child: CustomScrollView(
        key: PageStorageKey('winner-list-${widget.monthValue}'),
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
              child: Text(
                currentMonth.monthTitle,
                style: TextStyle(
                  fontSize: context.textMd,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900,
                ),
              ),
            ),
          ),
          PageListViewPro<ActWinnersMonth>(
            controller: _ctl,
            sliverMode: true,
            itemBuilder: (context, item, index, isLast) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _WinnerListItem(item: item),
              );
            },
          ),
        ],
      )
    );
  }
}

/// 单条中奖 item
class _WinnerListItem extends StatelessWidget {
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


/// tab 名称构建
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
    final d = DateTime(now.year, now.month - (v - 1), 1);
    return ActMonthTab(
      value: v,
      title: names[d.month - 1],
      monthTitle: DateFormat('MMM yyyy', context.locale.toLanguageTag())
          .format(d)
          .toUpperCase(),
    );
  }).toList();
}

/// 数据预处理
List<ActWinnersMonth> preProcessWinnersData(List<ActWinnersMonth> data) {
  final Map<String, List<ActWinnersMonth>> grouped = {};
  for (final item in data) {
    final date = DateFormat('yyyy-MM-dd')
        .format(DateTime.fromMillisecondsSinceEpoch(item.lotteryTime));
    grouped.putIfAbsent(date, () => []);
    grouped[date]!.add(item);
  }

  final List<ActWinnersMonth> result = [];
  grouped.forEach((date, group) {
    final dateTitle = DateFormat('EEEE d MMM').format(DateTime.parse(date));
    for (int i = 0; i < group.length; i++) {
      result.add(group[i].copyWith(
        firstOfDay: i == 0,
        lastOfDay: i == group.length - 1,
        dateTitle: i == 0 ? dateTitle : null,
      ));
    }
  });
  return result;
}