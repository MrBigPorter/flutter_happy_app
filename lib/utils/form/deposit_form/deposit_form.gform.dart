// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file:

part of 'deposit_form.dart';

// **************************************************************************
// ReactiveFormsGenerator
// **************************************************************************

class ReactiveDepositFormModelFormConsumer extends StatelessWidget {
  const ReactiveDepositFormModelFormConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final Widget? child;

  final Widget Function(
          BuildContext context, DepositFormModelForm formModel, Widget? child)
      builder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveDepositFormModelForm.of(context);

    if (formModel is! DepositFormModelForm) {
      throw FormControlParentNotFoundException(this);
    }
    return builder(context, formModel, child);
  }
}

class DepositFormModelFormInheritedStreamer extends InheritedStreamer<dynamic> {
  const DepositFormModelFormInheritedStreamer({
    Key? key,
    required this.form,
    required Stream<dynamic> stream,
    required Widget child,
  }) : super(
          stream,
          child,
          key: key,
        );

  final DepositFormModelForm form;
}

class ReactiveDepositFormModelForm extends StatelessWidget {
  const ReactiveDepositFormModelForm({
    Key? key,
    required this.form,
    required this.child,
    this.canPop,
    this.onPopInvoked,
  }) : super(key: key);

  final Widget child;

  final DepositFormModelForm form;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

  static DepositFormModelForm? of(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<
              DepositFormModelFormInheritedStreamer>()
          ?.form;
    }

    final element = context.getElementForInheritedWidgetOfExactType<
        DepositFormModelFormInheritedStreamer>();
    return element == null
        ? null
        : (element.widget as DepositFormModelFormInheritedStreamer).form;
  }

  @override
  Widget build(BuildContext context) {
    return DepositFormModelFormInheritedStreamer(
      form: form,
      stream: form.form.statusChanged,
      child: ReactiveFormPopScope(
        canPop: canPop,
        onPopInvoked: onPopInvoked,
        child: child,
      ),
    );
  }
}

extension ReactiveReactiveDepositFormModelFormExt on BuildContext {
  DepositFormModelForm? depositFormModelFormWatch() =>
      ReactiveDepositFormModelForm.of(this);

  DepositFormModelForm? depositFormModelFormRead() =>
      ReactiveDepositFormModelForm.of(this, listen: false);
}

class DepositFormModelFormBuilder extends StatefulWidget {
  const DepositFormModelFormBuilder({
    Key? key,
    this.model,
    this.child,
    this.canPop,
    this.onPopInvoked,
    required this.builder,
    this.initState,
  }) : super(key: key);

  final DepositFormModel? model;

  final Widget? child;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

  final Widget Function(
          BuildContext context, DepositFormModelForm formModel, Widget? child)
      builder;

  final void Function(BuildContext context, DepositFormModelForm formModel)?
      initState;

  @override
  _DepositFormModelFormBuilderState createState() =>
      _DepositFormModelFormBuilderState();
}

class _DepositFormModelFormBuilderState
    extends State<DepositFormModelFormBuilder> {
  late DepositFormModelForm _formModel;

  @override
  void initState() {
    _formModel = DepositFormModelForm(
        DepositFormModelForm.formElements(widget.model), null);

    if (_formModel.form.disabled) {
      _formModel.form.markAsDisabled();
    }

    widget.initState?.call(context, _formModel);

    super.initState();
  }

  @override
  void didUpdateWidget(covariant DepositFormModelFormBuilder oldWidget) {
    if (widget.model != oldWidget.model) {
      _formModel.updateValue(widget.model);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _formModel.form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveDepositFormModelForm(
      key: ObjectKey(_formModel),
      form: _formModel,
      canPop: widget.canPop,
      onPopInvoked: widget.onPopInvoked,
      child: ReactiveFormBuilder(
        form: () => _formModel.form,
        canPop: widget.canPop,
        onPopInvoked: widget.onPopInvoked,
        builder: (context, formGroup, child) =>
            widget.builder(context, _formModel, widget.child),
        child: widget.child,
      ),
    );
  }
}

class DepositFormModelForm implements FormModel<DepositFormModel> {
  DepositFormModelForm(
    this.form,
    this.path,
  );

  static const String amountControlName = "amount";

  final FormGroup form;

  final String? path;

  final Map<String, bool> _disabled = {};

  String amountControlPath() => pathBuilder(amountControlName);

  String get _amountValue => amountControl.value ?? "";

  bool get containsAmount {
    try {
      form.control(amountControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  Object? get amountErrors => amountControl.errors;

  void get amountFocus => form.focus(amountControlPath());

  void amountValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    amountControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void amountValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    amountControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void amountValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      amountControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  FormControl<String> get amountControl =>
      form.control(amountControlPath()) as FormControl<String>;

  void amountSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      amountControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      amountControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  @override
  DepositFormModel get model {
    final isValid = !currentForm.hasErrors && currentForm.errors.isEmpty;

    if (!isValid) {
      debugPrintStack(
          label:
              '[${path ?? 'DepositFormModelForm'}]\n┗━ Avoid calling `model` on invalid form. Possible exceptions for non-nullable fields which should be guarded by `required` validator.');
    }
    return DepositFormModel(amount: _amountValue);
  }

  @override
  void toggleDisabled({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    final currentFormInstance = currentForm;

    if (currentFormInstance is! FormGroup) {
      return;
    }

    if (_disabled.isEmpty) {
      currentFormInstance.controls.forEach((key, control) {
        _disabled[key] = control.disabled;
      });

      currentForm.markAsDisabled(
          updateParent: updateParent, emitEvent: emitEvent);
    } else {
      currentFormInstance.controls.forEach((key, control) {
        if (_disabled[key] == false) {
          currentFormInstance.controls[key]?.markAsEnabled(
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }

        _disabled.remove(key);
      });
    }
  }

  @override
  void submit({
    required void Function(DepositFormModel model) onValid,
    void Function()? onNotValid,
  }) {
    currentForm.markAllAsTouched();
    if (currentForm.valid) {
      onValid(model);
    } else {
      onNotValid?.call();
    }
  }

  AbstractControl<dynamic> get currentForm {
    return path == null ? form : form.control(path!);
  }

  @override
  void updateValue(
    DepositFormModel? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.updateValue(DepositFormModelForm.formElements(value).rawValue,
          updateParent: updateParent, emitEvent: emitEvent);

  @override
  void reset({
    DepositFormModel? value,
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.reset(
          value: value != null ? formElements(value).rawValue : null,
          updateParent: updateParent,
          emitEvent: emitEvent);

  String pathBuilder(String? pathItem) =>
      [path, pathItem].whereType<String>().join(".");

  static FormGroup formElements(DepositFormModel? depositFormModel) =>
      FormGroup({
        amountControlName: FormControl<String>(
            value: depositFormModel?.amount,
            validators: [NonEmpty(), DepositAmount()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false)
      },
          validators: [],
          asyncValidators: [],
          asyncValidatorsDebounceTime: 250,
          disabled: false);
}

class ReactiveDepositFormModelFormArrayBuilder<
    ReactiveDepositFormModelFormArrayBuilderT> extends StatelessWidget {
  const ReactiveDepositFormModelFormArrayBuilder({
    Key? key,
    this.control,
    this.formControl,
    this.builder,
    required this.itemBuilder,
  })  : assert(control != null || formControl != null,
            "You have to specify `control` or `formControl`!"),
        super(key: key);

  final FormArray<ReactiveDepositFormModelFormArrayBuilderT>? formControl;

  final FormArray<ReactiveDepositFormModelFormArrayBuilderT>? Function(
      DepositFormModelForm formModel)? control;

  final Widget Function(BuildContext context, List<Widget> itemList,
      DepositFormModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      ReactiveDepositFormModelFormArrayBuilderT? item,
      DepositFormModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveDepositFormModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    return ReactiveFormArray<ReactiveDepositFormModelFormArrayBuilderT>(
      formArray: formControl ?? control?.call(formModel),
      builder: (context, formArray, child) {
        final values = formArray.controls.map((e) => e.value).toList();
        final itemList = values
            .asMap()
            .map((i, item) {
              return MapEntry(
                i,
                itemBuilder(
                  context,
                  i,
                  item,
                  formModel,
                ),
              );
            })
            .values
            .toList();

        return builder?.call(
              context,
              itemList,
              formModel,
            ) ??
            Column(children: itemList);
      },
    );
  }
}

class ReactiveDepositFormModelFormFormGroupArrayBuilder<
        ReactiveDepositFormModelFormFormGroupArrayBuilderT>
    extends StatelessWidget {
  const ReactiveDepositFormModelFormFormGroupArrayBuilder({
    Key? key,
    this.extended,
    this.getExtended,
    this.builder,
    required this.itemBuilder,
  })  : assert(extended != null || getExtended != null,
            "You have to specify `control` or `formControl`!"),
        super(key: key);

  final ExtendedControl<List<Map<String, Object?>?>,
      List<ReactiveDepositFormModelFormFormGroupArrayBuilderT>>? extended;

  final ExtendedControl<List<Map<String, Object?>?>,
          List<ReactiveDepositFormModelFormFormGroupArrayBuilderT>>
      Function(DepositFormModelForm formModel)? getExtended;

  final Widget Function(BuildContext context, List<Widget> itemList,
      DepositFormModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      ReactiveDepositFormModelFormFormGroupArrayBuilderT? item,
      DepositFormModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveDepositFormModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final value = (extended ?? getExtended?.call(formModel))!;

    return StreamBuilder<List<Map<String, Object?>?>?>(
      stream: value.control.valueChanges,
      builder: (context, snapshot) {
        final itemList = (value.value() ??
                <ReactiveDepositFormModelFormFormGroupArrayBuilderT>[])
            .asMap()
            .map((i, item) => MapEntry(
                  i,
                  itemBuilder(
                    context,
                    i,
                    item,
                    formModel,
                  ),
                ))
            .values
            .toList();

        return builder?.call(
              context,
              itemList,
              formModel,
            ) ??
            Column(children: itemList);
      },
    );
  }
}
