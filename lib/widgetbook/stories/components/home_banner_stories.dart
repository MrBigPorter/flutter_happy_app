import 'package:flutter/material.dart';
import 'package:flutter_app/components/home_banner.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../core/models/banners.dart';

WidgetbookComponent buildHomeBannerStories() {
  return WidgetbookComponent(
    name: 'HomeBanner',
    useCases: [
      WidgetbookUseCase(
        name: 'Interactive Demo',
        builder: (context) {
          final count = context.knobs.double.slider(label: 'Banner count',initialValue: 3,min: 1,max: 5).toInt();
          final height = context.knobs.double.slider(label: 'Banner height',initialValue: 120,min: 80,max: 200);
          final autoPlay = context.knobs.boolean(label: 'Auto Play',initialValue: true);
          final intervalSeconds = context.knobs.durationOrNull(label: 'Interval Seconds',initialValue: const Duration(seconds: 3)) ?? const Duration(seconds: 3);
          final showIndicator = context.knobs.boolean(label: 'Show Indicator',initialValue: true);
          final darkMode = context.knobs.boolean(label: 'Dark Mode',initialValue: false);
          final sampleImages = List.generate(count, (index) => 'https://picsum.photos/800/400?random=$index');
          final banners = List.generate(sampleImages.length, (i)=> Banners(
             id: i,
             bannerImgUrl: sampleImages[i],
             jumpCate: 0,
             relatedTitleId: 0,
             state: 1,
             sortOrder: i,
             jumpUrl: '',
          ));

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: darkMode ? ThemeData.dark() : ThemeData.light(),
            home: Scaffold(
              backgroundColor: darkMode ? Colors.black : Colors.white,
              appBar: AppBar(title: Text('Home Banner Demo')),
              body: SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 20.w),
                    Center(
                      child: Text(
                        'This is a demo banner area 👇',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                    SizedBox(height: 20.w,),
                    HomeBanner(
                      banners: banners,
                      height: height.w,
                      autoPlay: autoPlay,
                      interval: intervalSeconds,
                        showIndicator:showIndicator
                    )
                  ],
                ),
              )
            ),
          );
        },
      ),
    ],
  );
}