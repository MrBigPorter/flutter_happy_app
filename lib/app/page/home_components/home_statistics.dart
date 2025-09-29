import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeStatistics extends StatelessWidget {
  final IndexStatistics statistics;

  const HomeStatistics({super.key, required this.statistics});

  String formatNumber(num? n) {
    if (n == null) return '0';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final config = [
      {
        'label': 'home-statistics-prize',
        'icon': 'assets/images/home_statistics/prize.png', // 建议移除开头的 '/'
        'num': formatNumber(statistics.totalAmount),
        'symbol': '₱',
      },
      {
        'label': 'home-statistics-winner',
        'icon': 'assets/images/home_statistics/winner.png',
        'num': statistics.totalUserAmount.toString(),
        'symbol': '',
      },
      {
        'label': 'home-statistics-donate',
        'icon': 'assets/images/home_statistics/donate.png',
        'num': formatNumber(statistics.charityFundNum),
        'symbol': '₱',
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: config.map((item) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.h),
              padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
              decoration: BoxDecoration(
                color: context.bgPrimary,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 图标
                  Image.asset(item['icon']!, width: 24.w, height: 24.h),
                  SizedBox(height: 4.h),
                  // 数字
                  Text(
                    '${item['symbol']}${item['symbol'] == '' ? '' : ' '}${item['num']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.sp,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary900,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // 标题
                  Text(
                    item['label']!.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.sp,
                      height: 1.0,
                      fontWeight: FontWeight.w600,
                      color: context.textTertiary600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}