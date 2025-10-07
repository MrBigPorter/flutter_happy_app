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