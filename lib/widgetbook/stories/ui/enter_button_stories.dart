import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:flutter_app/ui/enter_button.dart';

WidgetbookComponent buildEnterButtonStories() {
  return WidgetbookComponent(
    name: 'EnterButton',
    useCases: [
      WidgetbookUseCase(
        name: 'Normal',
        builder: (context) => Center(
          child: EnterButton(
            child: const Text('Submit'),
            onPressed: () {},
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Error Variant',
        builder: (context) => Center(
          child: EnterButton(
            variant: ButtonVariant.error,
            child: const Text('Delete'),
            onPressed: () {},
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Loading',
        builder: (context) => Center(
          child: EnterButton(
            loading: true,
            child: const Text('Loading'),
            onPressed: () {},
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Disabled',
        builder: (context) => Center(
          child: EnterButton(
            onPressed: null,
            child: const Text('Disabled'),
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'Custom Style',
        builder: (context) => Center(
          child: EnterButton(
            backgroundImage: const AssetImage('assets/images/tab_bar/product.svg'),
            onPressed: () {},
            child: const Text('Custom BG'),
          ),
        ),
      ),
    ],
  );
}