import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/anime_count.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/list.dart';
import 'package:flutter_app/components/lucky_nested_tabs.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/providers/winners_provider.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_app/utils/format_helper.dart';


/// Winners Page
/// Displays banners, total winners, latest winners, and categorized winners list.
/// Uses Riverpod for state management and data fetching.

class WinnersPage extends ConsumerStatefulWidget {
  const WinnersPage({super.key});

  @override
  ConsumerState<WinnersPage> createState() => _WinnersPageState();
}

class _WinnersPageState extends ConsumerState<WinnersPage> with SingleTickerProviderStateMixin {

  final Map<int, GlobalKey<_WinnerListState>> _listKeys = {};

  List<ActMonthTab> _tabs = const [];
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<List<int>>>(
      actMonthNumProvider,
        (prev,next){
         next.whenData((months){
           if(months.isNotEmpty){
             final tabs = _buildTabs(context, months);
             ref.read(activeMonthProvider.notifier).state = tabs.first;
             setState(() {
               _tabs = tabs;
             });
           }
         });
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    Future<void> onRefresh() async {
      ref.invalidate(winnersBannerProvider);
      ref.invalidate(winnersQuantityProvider);
      ref.invalidate(winnersLastsProvider);
      ref.invalidate(actMonthNumProvider);
      final cur = ref.read(activeMonthProvider)?.value;
      if (cur != null) {
        await _listKeys[cur]?.currentState?.refresh();
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final activeItem = ref.watch(activeMonthProvider);


    return BaseScaffold(
      showBack: false,
      body: LuckyNestedTabs<ActMonthTab>(
          tabs: _tabs,
          activeItem: activeItem,
          renderItem: (item) => Text(item.title),
          onChange: (tab) {
            ref.read(activeMonthProvider.notifier).state = tab;
          },
          renderBeforeTabs: [RenderBeforeTabs()],
          onRefresh: onRefresh,
          children: _tabs.map((e){
            _listKeys[e.value] ??= GlobalKey<_WinnerListState>();
            return _WinnerList(key: _listKeys[e.value], monthValue: e.value);
          }).toList(),
      ),
    );
  }
}

/// Section before the tabs: banners, total winners, latest winners, and list title
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
        // Banner section
        banners.when(
          data: (data) => _Banner(list: data),
          loading: () => _Banner(list: null),
          error: (_, __) => _Banner(list: null),
        ),
        SizedBox(height: 32.w),
        // Total winners section
        quantity.when(
          data: (data) => _TotalWinners(totalWinners: data.awardTotalQuantity),
          loading: () => _TotalWinners(totalWinners: 0),
          error: (_, __) => _TotalWinners(totalWinners: 0),
        ),
        SizedBox(height: 32.w),
        // Latest winners section
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


class _WinnerList extends ConsumerStatefulWidget {
  final int monthValue;
  const _WinnerList({super.key, required this.monthValue});

  @override
  ConsumerState<_WinnerList> createState() => _WinnerListState();
}

/// Winners list section
class _WinnerListState extends ConsumerState<_WinnerList> {
  late PageListController<ActWinnersMonth> _ctl;
  late final ScrollController _inner;                 // ← 每个 tab 独立
  Future<void> refresh() async {
    _ctl.refresh();
  }

  @override
  void initState() {
    super.initState();
     _inner = ScrollController();
    _ctl = PageListController<ActWinnersMonth>(
      request: ({required int pageSize, required int current}) {
        final req = ref.read(actWinnersMonthsProvider(widget.monthValue));
        return req(pageSize: pageSize, current: current);
      },
      preprocess: preProcessWinnersData,
      requestKey: widget.monthValue, // 首次进来自动加载
    );
  }

  @override
  void didUpdateWidget(covariant _WinnerList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.monthValue != widget.monthValue){
      _ctl.setRequestKey(widget.monthValue);
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    _inner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = ref.watch(activeMonthProvider);

    if(currentMonth?.title == ''){
      return SizedBox.shrink();
    }

    return CustomScrollView(
      key: PageStorageKey('winner-list-${widget.monthValue}'),
      slivers: [
        SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                currentMonth!.monthTitle,
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
          controller: _ctl,
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
