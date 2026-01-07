// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

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
    this.onPopInvokedWithResult,
  }) : super(key: key);

  final Widget child;

  final WithdrawFormModelForm form;

  final bool Function(FormGroup formGroup)? canPop;

  final ReactiveFormPopInvokedWithResultCallback<dynamic>?
      onPopInvokedWithResult;

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
        onPopInvokedWithResult: onPopInvokedWithResult,
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
    this.onPopInvokedWithResult,
    required this.builder,
    this.initState,
  }) : super(key: key);

  final WithdrawFormModel? model;

  final Widget? child;

  final bool Function(FormGroup formGroup)? canPop;

  final ReactiveFormPopInvokedWithResultCallback<dynamic>?
      onPopInvokedWithResult;

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

  StreamSubscription<LogRecord>? _logSubscription;

  @override
  void initState() {
    _formModel = WithdrawFormModelForm(
        WithdrawFormModelForm.formElements(widget.model), null);

    if (_formModel.form.disabled) {
      _formModel.form.markAsDisabled();
    }

    widget.initState?.call(context, _formModel);

    _logSubscription = _logWithdrawFormModelForm.onRecord.listen((LogRecord e) {
      // use `dumpErrorToConsole` for severe messages to ensure that severe
      // exceptions are formatted consistently with other Flutter examples and
      // avoids printing duplicate exceptions
      if (e.level >= Level.SEVERE) {
        final Object? error = e.error;
        FlutterError.dumpErrorToConsole(
          FlutterErrorDetails(
            exception: error is Exception ? error : Exception(error),
            stack: e.stackTrace,
            library: e.loggerName,
            context: ErrorDescription(e.message),
          ),
        );
      } else {
        log(
          e.message,
          time: e.time,
          sequenceNumber: e.sequenceNumber,
          level: e.level.value,
          name: e.loggerName,
          zone: e.zone,
          error: e.error,
          stackTrace: e.stackTrace,
        );
      }
    });

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
    _logSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveWithdrawFormModelForm(
      key: ObjectKey(_formModel),
      form: _formModel,
      // canPop: widget.canPop,
      // onPopInvoked: widget.onPopInvoked,
      child: ReactiveFormBuilder(
        form: () => _formModel.form,
        canPop: widget.canPop,
        onPopInvokedWithResult: widget.onPopInvokedWithResult,
        builder: (context, formGroup, child) =>
            widget.builder(context, _formModel, widget.child),
        child: widget.child,
      ),
    );
  }
}

final _logWithdrawFormModelForm = Logger.detached('WithdrawFormModelForm');

class WithdrawFormModelForm
    implements FormModel<WithdrawFormModel, WithdrawFormModel> {
  WithdrawFormModelForm(
    this.form,
    this.path,
  );

  static const String amountControlName = "amount";

  final FormGroup form;

  final String? path;

  final Map<String, bool> _disabled = {};

  String amountControlPath() => pathBuilder(amountControlName);

  String get _amountValue => amountControl.value ?? '';

  String get _amountRawValue => amountControl.value ?? '';

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsAmount {
    try {
      form.control(amountControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, Object> get amountErrors => amountControl.errors;

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
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

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
  WithdrawFormModel get model {
    final isValid = !currentForm.hasErrors && currentForm.errors.isEmpty;

    if (!isValid) {
      _logWithdrawFormModelForm.warning(
        'Avoid calling `model` on invalid form.Possible exceptions for non-nullable fields which should be guarded by `required` validator.',
        null,
        StackTrace.current,
      );
    }
    return WithdrawFormModel(amount: _amountValue);
  }

  @override
  WithdrawFormModel get rawModel {
    return WithdrawFormModel(amount: _amountRawValue);
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
  bool equalsTo(WithdrawFormModel? other) {
    final currentForm = this.currentForm;

    return const DeepCollectionEquality().equals(
      currentForm is FormControlCollection<dynamic>
          ? currentForm.rawValue
          : currentForm.value,
      WithdrawFormModelForm.formElements(other).rawValue,
    );
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
      _logWithdrawFormModelForm.info('Errors');
      _logWithdrawFormModelForm.info('┗━━ ${form.errors}');
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
    this.emptyBuilder,
    this.controlFilter,
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
      FormControl<ReactiveWithdrawFormModelFormArrayBuilderT> control,
      ReactiveWithdrawFormModelFormArrayBuilderT? item,
      WithdrawFormModelForm formModel) itemBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  final bool Function(
          FormControl<ReactiveWithdrawFormModelFormArrayBuilderT> control)?
      controlFilter;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveWithdrawFormModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final builder = this.builder;
    final itemBuilder = this.itemBuilder;

    return ReactiveFormArrayItemBuilder<
        ReactiveWithdrawFormModelFormArrayBuilderT>(
      formControl: formControl ?? control?.call(formModel),
      builder: builder != null
          ? (context, itemList) => builder(
                context,
                itemList,
                formModel,
              )
          : null,
      itemBuilder: (
        context,
        i,
        control,
        item,
      ) =>
          itemBuilder(context, i, control, item, formModel),
      emptyBuilder: emptyBuilder,
      controlFilter: controlFilter,
    );
  }
}

class ReactiveWithdrawFormModelFormArrayBuilder2<
    ReactiveWithdrawFormModelFormArrayBuilderT> extends StatelessWidget {
  const ReactiveWithdrawFormModelFormArrayBuilder2({
    Key? key,
    this.control,
    this.formControl,
    this.builder,
    required this.itemBuilder,
    this.emptyBuilder,
    this.controlFilter,
  })  : assert(control != null || formControl != null,
            "You have to specify `control` or `formControl`!"),
        super(key: key);

  final FormArray<ReactiveWithdrawFormModelFormArrayBuilderT>? formControl;

  final FormArray<ReactiveWithdrawFormModelFormArrayBuilderT>? Function(
      WithdrawFormModelForm formModel)? control;

  final Widget Function(
      ({
        BuildContext context,
        List<Widget> itemList,
        WithdrawFormModelForm formModel
      }) params)? builder;

  final Widget Function(
      ({
        BuildContext context,
        int i,
        FormControl<ReactiveWithdrawFormModelFormArrayBuilderT> control,
        ReactiveWithdrawFormModelFormArrayBuilderT? item,
        WithdrawFormModelForm formModel
      }) params) itemBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  final bool Function(
          FormControl<ReactiveWithdrawFormModelFormArrayBuilderT> control)?
      controlFilter;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveWithdrawFormModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final builder = this.builder;
    final itemBuilder = this.itemBuilder;

    return ReactiveFormArrayItemBuilder<
        ReactiveWithdrawFormModelFormArrayBuilderT>(
      formControl: formControl ?? control?.call(formModel),
      builder: builder != null
          ? (context, itemList) => builder((
                context: context,
                itemList: itemList,
                formModel: formModel,
              ))
          : null,
      itemBuilder: (
        context,
        i,
        control,
        item,
      ) =>
          itemBuilder((
        context: context,
        i: i,
        control: control,
        item: item,
        formModel: formModel
      )),
      emptyBuilder: emptyBuilder,
      controlFilter: controlFilter,
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
