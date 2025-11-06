import 'package:flutter/cupertino.dart';
import 'package:flutter_app/ui/form/lucky_item_scope.dart';
import 'package:reactive_forms/reactive_forms.dart';


typedef ItemBuilder<T> = Widget Function(BuildContext context, FormControl<T> control);

class LuckyFormItem<T>  extends StatelessWidget {
  final String name;
  final ItemBuilder<T> builder;
  const LuckyFormItem({
    super.key,
    required this.name,
    required this.builder,
  });

  String? _firsError(AbstractControl<dynamic> c){
    if(!c.invalid) return null;
    if(c.errors.isEmpty) return 'Invalid';
    final k = c.errors.keys.first;
    final v = c.errors.values.first;
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveValueListenableBuilder<T>(
      formControlName: name,
      builder: (ctx, ctr, child){
        final err = (ctr.invalid && (ctr.touched || ctr.dirty)) ? _firsError(ctr) : null;
        final fc = ctr as FormControl<T>;
        return LuckyItemScope(
            name: name,
            errorText: err,
            hasError: err != null,
            touchedOrDirty: ctr.touched || ctr.dirty,
            child: builder(ctx,fc)
        );
      },
    );
  }
}