import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/anime_count.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/ad_res.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/providers/winners_provider.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WinnersPage extends ConsumerWidget {
  const WinnersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(winnersBannerProvider);

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
            _TotalWinners(),
            //latest winners list
            _LatestWinnersList(),
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
  @override
  Widget build(BuildContext context) {
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
              value: 1000000,
              /*render: (value) => Text(
                'winner.number'.tr(namedArgs: {'number': FormatHelper.formatCompactDecimal(value)}),
                style: TextStyle(
                  fontSize: context.textXl,
                  color: context.fgBrandPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),*/
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

/// latest winners list section
class _LatestWinnersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Winners',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
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
        ],
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
