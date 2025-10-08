import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookComponent buildBubbleProgressStories (){
  return WidgetbookComponent(
    name: 'BubbleProgress',
    useCases: [
      WidgetbookUseCase(
          name: 'default',
          builder: (context) => Center(
            child: SizedBox(
              width: 300,
              child: BubbleProgress(
                  value: context.knobs.double.slider(label: 'Value', initialValue: 50, min: 0, max: 100),
              ),
            ),
          )
      ),
      WidgetbookUseCase(
          name: 'Custom Tip Content',
          builder: (context) => Center(
            child: SizedBox(
              width: 300,
              child: BubbleProgress(
                  value: context.knobs.double.slider(label: 'Value', initialValue: 50, min: 0, max: 100),
                  tipBuilder: (v) => Text('${v.toStringAsFixed(1)}%', style: TextStyle(color: context.bgSecondary, fontSize: 12),),
                  topPadding: 10,
              ),
            ),
          )
      ),
      WidgetbookUseCase(
          name: 'No Tip Background',
          builder: (context)=> Center(
            child: SizedBox(
              width: 300,
              child: BubbleProgress(
                  value: context.knobs.double.slider(label: 'Value', initialValue: 50, min: 0, max: 100),
                  showTipBg: false,
                  topPadding: 20,
                  textColor: context.textPrimary900,
              ),
            ),
          )
      ),
      WidgetbookUseCase(
          name: 'others',
          builder: (context)=> Center(
            child: SizedBox(
              width: 300,
              child: BubbleProgress(
                  value: context.knobs.double.slider(label: 'Value', initialValue: 50, min: 0, max: 100),
                  color: Colors.green,
                  trackHeight: 8,
                  thumbSize: 12,
                  duration: Duration(milliseconds: context.knobs.int.slider(label: 'Duration (ms)', initialValue: 220, min: 100, max: 2000)),
                  showTipBg: context.knobs.boolean(label: 'Show Tip Background', initialValue: true),
                  topPadding: context.knobs.int.slider(label: 'Top Padding', initialValue: 4, min: 0, max: 20).toDouble(),
              ),
            ),
          )
      )
    ],
  );
}