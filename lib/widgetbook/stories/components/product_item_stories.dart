import 'package:flutter/material.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildProductItemStories() {
  return WidgetbookComponent(
    name: 'ProductItem',
    useCases: [
      WidgetbookUseCase(
        name: 'Interactive Demo',
        builder: (context) {
          final rate = context.knobs.double.slider(
            label: 'Buy Rate (%)',
            initialValue: 45,
            min: 0,
            max: 100,
          );

          final price = context.knobs.double.slider(
            label: 'Unit Amount (₱)',
            initialValue: 199,
            min: 1,
            max: 999,
          );


          final darkMode = context.knobs.boolean(
            label: 'Dark Mode',
            initialValue: false,
          );


          final costAmount = context.knobs.int.slider(
            label: 'Cost Amount (₱)',
            initialValue: 20,
            min: 1,
            max: 100,
          );

          final showCountDown = context.knobs.boolean(
            label: 'Show Countdown',
            initialValue: true,
          );

          final countdownHours = context.knobs.int.slider(
            label: 'Countdown Hours',
            initialValue: 2,
            min: 0,
            max: 24,
          );

          final int lotteryTime = showCountDown
              ? DateTime.now()
              .add(Duration(hours: countdownHours))
              .millisecondsSinceEpoch
              .toInt()
              : 0;

          final mockData = ProductListItem(
            treasureId: '12345',
            treasureName: 'Wireless Bluetooth Headset',
            treasureCoverImg:
            'https://picsum.photos/id/1011/400/400', // mock 图
            unitAmount: price,
            costAmount: costAmount,
            buyQuantityRate: rate,
            imgStyleType: 1,
            lotteryMode: 1,
            minBuyQuantity: 1,
            productName: 'Wireless Bluetooth Headset',
            seqBuyQuantity: 1,
            seqShelvesQuantity: 101,
            lotteryTime: lotteryTime,
          );

          return MaterialApp(
             debugShowCheckedModeBanner: false,
            theme: darkMode ? ThemeData.dark() : ThemeData.light(),
            home: Scaffold(
              backgroundColor: darkMode ? Colors.black : Colors.white,
              body: SafeArea(
                child: SingleChildScrollView(
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.all(20),
                  child: SizedBox(
                    child: ProductItem(data: mockData),
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