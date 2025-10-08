import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../components/tabs.dart';

WidgetbookComponent buildTabsStories(){
  return WidgetbookComponent(
      name: 'Tabs',
      useCases: [
        WidgetbookUseCase(name: 'default', builder: (context){
          final tabCount = context.knobs.int.slider(
              label: 'tabCount',
              initialValue: 4,
              min: 2,
              max: 10
          );

          final showSkeleton = context.knobs.boolean(
            label: 'Show Skeleton (empty data)',
            initialValue: false,
          );

          final height = context.knobs.double.slider(
              label: 'height',
              initialValue: 44,
              min: 30,
              max: 100
          );
          final autoScrollIntoView = context.knobs.boolean(
              label: 'autoScrollIntoView',
              initialValue: true
          );

          final darkMode = context.knobs.boolean(
              label: 'Dark Mode',
              initialValue: false
          );

          final List<String> mockData = List.generate(tabCount, (index) => 'Tab $index');

          final activeTab = context.knobs.object.dropdown<String>(
            label: 'Active Tab',
            options: mockData,
          );

          final active = showSkeleton ? null : activeTab;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: darkMode ? ThemeData.dark() : ThemeData.light(),
            home: Scaffold(
              backgroundColor:  darkMode ? Colors.black : Colors.white,
              body: Center(
                child: Container(
                  color: darkMode ? Colors.grey[900] : Colors.grey[200],
                  child: active == null && showSkeleton
                      ? Tabs<String>(
                    data: [],
                    activeItem: '',
                    renderItem: (item) => const SizedBox.shrink(),
                    onChangeActive: (item) {},
                    tabCount: tabCount,
                    height: height,
                    autoScrollIntoView: autoScrollIntoView,
                  )
                      : Tabs<String>(
                    data: mockData,
                    activeItem: active!,
                    renderItem: (item) => Center(child: Text(item)),
                    onChangeActive: (item) {
                      // no-op
                    },
                    height: height,
                    autoScrollIntoView: autoScrollIntoView,
                  ),
                ),
              ),
            )
          );
        })
      ]
  );
}