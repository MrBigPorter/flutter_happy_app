import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/anime_count.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/models/winners_lasts_item.dart';
import 'package:flutter_app/core/providers/winners_provider.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../utils/format_helper.dart';

class WinnersPage extends ConsumerWidget {
  const WinnersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(winnersBannerProvider);
    final quantity = ref.watch(winnersQuantityProvider);
    final winnersLasts = ref.watch(winnersLastsProvider);

    Future<void> onRefresh() async {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return BaseScaffold(
      showBack: false,
      body: RefreshIndicator(
        child: ListView(
          children: [
            // banner
            banners.when(
              data: (list) => _Banner(list: list),
              error: (_, __) => _Banner(list: []),
              loading: () => _Banner(list: []),
            ),
            SizedBox(height: 32.w),
            //total winners
            quantity.when(
              data: (data) =>
                  _TotalWinners(totalWinners: data.awardTotalQuantity),
              error: (_, __) => _TotalWinners(totalWinners: 0),
              loading: () => _TotalWinners(totalWinners: 0),
            ),
            //latest winners list
            SizedBox(height: 32.w),
            winnersLasts.when(
              data: (data) => LatestWinners(list: data),
              error: (_, __) => LatestWinners(list: []),
              loading: () => LatestWinners(list: []),
            ),
            SizedBox(height: 40.w,),
            // tabs section
            _TabsSection(),
            // winners list
            _WinnerList(),
          ],
        ),
        onRefresh: () => onRefresh(),
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
    if (widget.list.isNullOrEmpty) {
      return SizedBox(
        height: 200.w,
        child:  ListView.separated(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemBuilder: (_,index){
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Skeleton.react(width: 216.w, height: 200.w),
            );
          },
          separatorBuilder: (_,__)=> SizedBox.shrink(),
          itemCount: 6,
        ),
      );
    }

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
             child:  Swiper(
               itemWidth: 216.w,
               itemHeight: 300.w,
               viewportFraction: 0.6, // two side item visible
               scale: 0.86,
               loop: false,
               // disable infinite loop to void first item cut off
               itemCount: widget.list.length,
               onIndexChanged: (i){
                 if(mounted){
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
        padding: EdgeInsets.symmetric(horizontal: 8.w,vertical: 20.w),
        child: Material(
          color: context.bgPrimary,
          elevation: 8.w,
          shadowColor: Colors.black.withValues(alpha: 120),
          borderRadius: BorderRadius.circular(12.w),
          clipBehavior: Clip.antiAlias,

          surfaceTintColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal:16.w,vertical: 16.w),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: context.borderSecondary, width: 1.w)
            ),
            child:  Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child:  ClipRRect(
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.w,
                  ),
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
/// Tabs section
class _TabsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Winners by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Tabs
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'Daily'),
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Winners list section
class _WinnerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 20,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                'U$index',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text('User $index'),
            subtitle: const Text('Won \$100'),
          );
        },
      ),
    );
  }
}

class _PositionedDot extends StatelessWidget {
  final int length;
  final int currentIndex;

  const _PositionedDot({
    required this.length,
    required this.currentIndex,
});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: -20.w,
      left: 0,
      right: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(length, (i){
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: currentIndex == i ? 18.w : 8.w,
            height: 8.w,
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              color: currentIndex == i ? context.fgBrandPrimary : Colors.black.withAlpha(30),
              borderRadius: BorderRadius.circular(3.w),
            ),
          );
        }),
      ),
    );
  }
}
