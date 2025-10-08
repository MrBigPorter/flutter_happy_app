import 'package:flutter/material.dart';
import 'package:flutter_app/components/render_countdown.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildRenderCountdownStories() {
  return WidgetbookComponent(
    name: 'RenderCountdown',
    useCases: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (context) {
          final showCountdown = context.knobs.boolean(
            label: 'Show Countdown',
            initialValue: true,
          );

          final countdownHours = context.knobs.double.slider(
            label: 'Countdown Hours',
            initialValue: 1,
            min: 0.1,
            max: 48,
            divisions: 95
          );

          final darkMode = context.knobs.boolean(
            label: 'Dark Mode',
            initialValue: false,
          );

          final targetTime = showCountdown ? DateTime.now().add(Duration(hours: countdownHours.toInt())) : 0;

          Widget builderSoldOut() {
            return const Text(
              'Sold Out',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            );
          }

          Widget builderEnd(String days2) {
            return Text(
              'Ended $days2 days ago',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            );
          }
          Widget builderCountdown(String hhmmss) {
            return Text(
              'Time Left: $hhmmss',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            );
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: darkMode ? ThemeData.dark() : ThemeData.light(),
            home: Scaffold(
              backgroundColor: darkMode ? Colors.black : Colors.white,
              body: Center(
                child: Container(
                  width: 260,
                  padding:  EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: darkMode ? Colors.grey[900] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: darkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1,
                    )
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'RenderCountdown Demo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )
                      ),
                      const SizedBox(height: 20),
                      RenderCountdown(
                          lotteryTime: targetTime,
                          renderSoldOut: builderSoldOut,
                          renderEnd: builderEnd,
                          renderCountdown: builderCountdown
                      )
                    ],
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