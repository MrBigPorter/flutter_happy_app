import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/components/base_scaffold.dart';

WidgetbookComponent buildBaseScaffoldStories() {
  return WidgetbookComponent(
    name: 'BaseScaffold',
    useCases: [
      WidgetbookUseCase(
        name: 'Interactive Demo',
        builder: (context) {
          // 🎛️ 可调参数
          final title = context.knobs.string(
            label: 'Title',
            initialValue: 'Lucky Page',
          );

          final showAppBar = context.knobs.boolean(
            label: 'Show AppBar',
            initialValue: true,
          );

          final showBack = context.knobs.boolean(
            label: 'Show Back Button',
            initialValue: true,
          );

          final darkMode = context.knobs.boolean(
            label: 'Dark Mode',
            initialValue: false,
          );

          final bodyText = context.knobs.string(
            label: 'Body Text',
            initialValue: 'This is a demo body area 👇',
          );

          final actionCount = context.knobs.double.slider(
            label: 'Action Buttons',
            initialValue: 1,
            min: 0,
            max: 3,
          ).toInt();

          // 生成 actions
          final actions = List.generate(
            actionCount,
                (i) => IconButton(
              icon: Icon(Icons.favorite, color: Colors.red[(i + 1) * 200]),
              onPressed: () {},
            ),
          );

          return MaterialApp(
            theme: darkMode ? ThemeData.dark() : ThemeData.light(),
            home: BaseScaffold(
              title: title,
              showAppBar: showAppBar,
              showBack: showBack,
              actions: actions,
              body: Center(
                child: Container(
                  width: 300.w,
                  height: 400.w,
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: darkMode ? Colors.grey[900] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      bodyText,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: darkMode ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}