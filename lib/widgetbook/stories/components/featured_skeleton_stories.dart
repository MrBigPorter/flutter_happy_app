import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:flutter_app/components/skeleton.dart';

/// FeaturedSkeleton 组件的 Widgetbook story
WidgetbookComponent buildFeaturedSkeletonStories() {
  return WidgetbookComponent(
    name: 'FeaturedSkeleton',
    useCases: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Skeleton.react(
              width: double.infinity,
              height: 200,
            ),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Dark Mode',
        builder: (context) {
          final width = context.knobs.double.slider(label: 'width',initialValue: 300,min: 50,max: 600);
          final height = context.knobs.double.slider(label: 'height',initialValue: 200,min: 50,max: 600);
          final shimer = context.knobs.boolean(label: 'shimer',initialValue: true);
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: Skeleton.circle(width: width.w, height: height.w,shimmer: shimer,),
            ),
          );
        },
      ),
    ],
  );
}