import 'package:flutter/material.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildSkeletonStories() {
  return WidgetbookComponent(
    name: 'Skeleton',
    useCases: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (context) {
          final width = context.knobs
              .double.slider(label: 'width', initialValue: 300, min: 50, max: 600);
          final height = context.knobs
              .double.slider(label: 'height', initialValue: 200, min: 50, max: 600);
          final shimer =
              context.knobs.boolean(label: 'shimer', initialValue: true);
          final darkMode =
              context.knobs.boolean(label: 'Dark Mode', initialValue: false);

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: darkMode ? ThemeData.dark() : ThemeData.light(),
            home:Scaffold(
              backgroundColor:  darkMode ? Colors.black : Colors.white,
              body: Center(
                child: Skeleton.react(
                    width: width,
                    height: height,
                    shimmer: shimer
                ),
              ),
            )
          );
        },
      ),
    ],
  );
}