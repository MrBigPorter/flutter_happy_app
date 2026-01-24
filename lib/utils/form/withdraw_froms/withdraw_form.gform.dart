// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file:

part of 'withdraw_form.dart';

// **************************************************************************
// ReactiveFormsGenerator
// **************************************************************************

class ReactiveWithdrawFormModelFormConsumer extends StatelessWidget {
  const ReactiveWithdrawFormModelFormConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final Widget? child;

  final Widget Function(
          BuildContext context, WithdrawFormModelForm formModel, Widget? child)
      builder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveWithdrawFormModelForm.of(context);

    if (formModel is! WithdrawFormModelForm) {
      throw FormControlParentNotFoundException(this);
    }
    return builder(context, formModel, child);
  }
}

class WithdrawFormModelFormInheritedStreamer
    extends InheritedStreamer<dynamic> {
  const WithdrawFormModelFormInheritedStreamer({
    Key? key,
    required this.form,
    required Stream<dynamic> stream,
    required Widget child,
  }) : super(
          stream,
          child,
          key: key,
        );

  final WithdrawFormModelForm form;
}

class ReactiveWithdrawFormModelForm extends StatelessWidget {
  const ReactiveWithdrawFormModelForm({
    Key? key,
    required this.form,
    required this.child,
    this.canPop,
    this.onPopInvoked,
  }) : super(key: key);

  final Widget child;

  final WithdrawFormModelForm form;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

  static WithdrawFormModelForm? of(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<
              WithdrawFormModelFormInheritedStreamer>()
          ?.form;
    }

    final element = context.getElementForInheritedWidgetOfExactType<
        WithdrawFormModelFormInheritedStreamer>();
    return element == null
        ? null
        : (element.widget as WithdrawFormModelFormInheritedStreamer).form;
  }

  @override
  Widget build(BuildContext context) {
    return WithdrawFormModelFormInheritedStreamer(
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

extension ReactiveReactiveWithdrawFormModelFormExt on BuildContext {
  WithdrawFormModelForm? withdrawFormModelFormWatch() =>
      ReactiveWithdrawFormModelForm.of(this);

  WithdrawFormModelForm? withdrawFormModelFormRead() =>
      ReactiveWithdrawFormModelForm.of(this, listen: false);
}

class WithdrawFormModelFormBuilder extends StatefulWidget {
  const WithdrawFormModelFormBuilder({
    Key? key,
    this.model,
    this.child,
    this.canPop,
    this.onPopInvoked,
    required this.builder,
    this.initState,
  }) : super(key: key);

  final WithdrawFormModel? model;

  final Widget? child;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

  final Widget Function(
          BuildContext context, WithdrawFormModelForm formModel, Widget? child)
      builder;

  final void Function(BuildContext context, WithdrawFormModelForm formModel)?
      initState;

  @override
  _WithdrawFormModelFormBuilderState createState() =>
      _WithdrawFormModelFormBuilderState();
}

class _WithdrawFormModelFormBuilderState
    extends State<WithdrawFormModelFormBuilder> {
  late WithdrawFormModelForm _formModel;

  @override
  void initState() {
    _formModel = WithdrawFormModelForm(
        WithdrawFormModelForm.formElements(widget.model), null);

    if (_formModel.form.disabled) {
      _formModel.form.markAsDisabled();
    }

    widget.initState?.call(context, _formModel);

    super.initState();
  }

  @override
  void didUpdateWidget(covariant WithdrawFormModelFormBuilder oldWidget) {
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
    return ReactiveWithdrawFormModelForm(
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

class WithdrawFormModelForm implements FormModel<WithdrawFormModel> {
  WithdrawFormModelForm(
    this.form,
    this.path,
  );

  static const String amountControlName = "amount";

  static const String accountNameControlName = "accountName";

  static const String accountNumberControlName = "accountNumber";

  final FormGroup form;

  final String? path;

  final Map<String, bool> _disabled = {};

  String amountControlPath() => pathBuilder(amountControlName);

  String accountNameControlPath() => pathBuilder(accountNameControlName);

  String accountNumberControlPath() => pathBuilder(accountNumberControlName);

  String get _amountValue => amountControl.value ?? "";

  String get _accountNameValue => accountNameControl.value ?? "";

  String get _accountNumberValue => accountNumberControl.value ?? "";

  bool get containsAmount {
    try {
      form.control(amountControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsAccountName {
    try {
      form.control(accountNameControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsAccountNumber {
    try {
      form.control(accountNumberControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  Object? get amountErrors => amountControl.errors;

  Object? get accountNameErrors => accountNameControl.errors;

  Object? get accountNumberErrors => accountNumberControl.errors;

  void get amountFocus => form.focus(amountControlPath());

  void get accountNameFocus => form.focus(accountNameControlPath());

  void get accountNumberFocus => form.focus(accountNumberControlPath());

  void amountValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    amountControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void accountNameValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    accountNameControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void accountNumberValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    accountNumberControl.updateValue(value,
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

  void accountNameValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    accountNameControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void accountNumberValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    accountNumberControl.patchValue(value,
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

  void accountNameValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      accountNameControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void accountNumberValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      accountNumberControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  FormControl<String> get amountControl =>
      form.control(amountControlPath()) as FormControl<String>;

  FormControl<String> get accountNameControl =>
      form.control(accountNameControlPath()) as FormControl<String>;

  FormControl<String> get accountNumberControl =>
      form.control(accountNumberControlPath()) as FormControl<String>;

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

  void accountNameSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      accountNameControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      accountNameControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void accountNumberSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      accountNumberControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      accountNumberControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  @override
  WithdrawFormModel get model {
    final isValid = !currentForm.hasErrors && currentForm.errors.isEmpty;

    if (!isValid) {
      debugPrintStack(
          label:
              '[${path ?? 'WithdrawFormModelForm'}]\n┗━ Avoid calling `model` on invalid form. Possible exceptions for non-nullable fields which should be guarded by `required` validator.');
    }
    return WithdrawFormModel(
        amount: _amountValue,
        accountName: _accountNameValue,
        accountNumber: _accountNumberValue);
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
    required void Function(WithdrawFormModel model) onValid,
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
    WithdrawFormModel? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.updateValue(WithdrawFormModelForm.formElements(value).rawValue,
          updateParent: updateParent, emitEvent: emitEvent);

  @override
  void reset({
    WithdrawFormModel? value,
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.reset(
          value: value != null ? formElements(value).rawValue : null,
          updateParent: updateParent,
          emitEvent: emitEvent);

  String pathBuilder(String? pathItem) =>
      [path, pathItem].whereType<String>().join(".");

  static FormGroup formElements(WithdrawFormModel? withdrawFormModel) =>
      FormGroup({
        amountControlName: FormControl<String>(
            value: withdrawFormModel?.amount,
            validators: [NonEmpty(), WithdrawAmount()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        accountNameControlName: FormControl<String>(
            value: withdrawFormModel?.accountName,
            validators: [NonEmpty(), MinLengthValidator(2)],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        accountNumberControlName: FormControl<String>(
            value: withdrawFormModel?.accountNumber,
            validators: [NonEmpty(), MinLengthValidator(5)],
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

class ReactiveWithdrawFormModelFormArrayBuilder<
    ReactiveWithdrawFormModelFormArrayBuilderT> extends StatelessWidget {
  const ReactiveWithdrawFormModelFormArrayBuilder({
    Key? key,
    this.control,
    this.formControl,
    this.builder,
    required this.itemBuilder,
  })  : assert(control != null || formControl != null,
            "You have to specify `control` or `formControl`!"),
        super(key: key);

  final FormArray<ReactiveWithdrawFormModelFormArrayBuilderT>? formControl;

  final FormArray<ReactiveWithdrawFormModelFormArrayBuilderT>? Function(
      WithdrawFormModelForm formModel)? control;

  final Widget Function(BuildContext context, List<Widget> itemList,
      WithdrawFormModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      ReactiveWithdrawFormModelFormArrayBuilderT? item,
      WithdrawFormModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveWithdrawFormModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    return ReactiveFormArray<ReactiveWithdrawFormModelFormArrayBuilderT>(
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

class ReactiveWithdrawFormModelFormFormGroupArrayBuilder<
        ReactiveWithdrawFormModelFormFormGroupArrayBuilderT>
    extends StatelessWidget {
  const ReactiveWithdrawFormModelFormFormGroupArrayBuilder({
    Key? key,
    this.extended,
    this.getExtended,
    this.builder,
    required this.itemBuilder,
  })  : assert(extended != null || getExtended != null,
            "You have to specify `control` or `formControl`!"),
        super(key: key);

  final ExtendedControl<List<Map<String, Object?>?>,
      List<ReactiveWithdrawFormModelFormFormGroupArrayBuilderT>>? extended;

  final ExtendedControl<List<Map<String, Object?>?>,
          List<ReactiveWithdrawFormModelFormFormGroupArrayBuilderT>>
      Function(WithdrawFormModelForm formModel)? getExtended;

  final Widget Function(BuildContext context, List<Widget> itemList,
      WithdrawFormModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      ReactiveWithdrawFormModelFormFormGroupArrayBuilderT? item,
      WithdrawFormModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveWithdrawFormModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final value = (extended ?? getExtended?.call(formModel))!;

    return StreamBuilder<List<Map<String, Object?>?>?>(
      stream: value.control.valueChanges,
      builder: (context, snapshot) {
        final itemList = (value.value() ??
                <ReactiveWithdrawFormModelFormFormGroupArrayBuilderT>[])
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
