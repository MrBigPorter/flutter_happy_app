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
        builder: (context) => Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Skeleton.circle(width: 100.w, height: 100.w),
          ),
        ),
      ),
    ],
  );
}