import 'package:flutter_app/widgetbook/stories/components/base_scaffold_stories.dart';
import 'package:flutter_app/widgetbook/stories/components/home_banner_stories.dart';
import 'package:flutter_app/widgetbook/stories/components/product_item_stories.dart';
import 'package:flutter_app/widgetbook/stories/components/render_countdown_stories.dart';
import 'package:flutter_app/widgetbook/stories/components/skeleton_stories.dart';
import 'package:flutter_app/widgetbook/stories/components/tabs_stories.dart';
import 'package:flutter_app/widgetbook/stories/ui/bubble_progress_stories.dart';
import 'package:flutter_app/widgetbook/stories/ui/enter_button_stories.dart';
import 'package:widgetbook/widgetbook.dart';

import 'components/featured_skeleton_stories.dart';

/// Combine all component stories into a list of WidgetbookNode

List<WidgetbookNode> buildAllComponentStories (){
  return [
    WidgetbookFolder(
        name: 'UI Components',
        children: [
          buildBubbleProgressStories(),
          buildEnterButtonStories(),
          buildBaseScaffoldStories(),
          buildHomeBannerStories(),
          buildProductItemStories(),
          buildRenderCountdownStories(),
          buildSkeletonStories(),
          buildTabsStories(),
          // Add other component stories here
        ]
    ),
    WidgetbookFolder(
        name: 'Components',
        children: [
          buildFeaturedSkeletonStories()
          // Add other component stories here
        ]
    )
  ];
}