// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_forms.dart';

// **************************************************************************
// ReactiveFormsGenerator
// **************************************************************************

class ReactiveLoginOtpModelFormConsumer extends StatelessWidget {
  const ReactiveLoginOtpModelFormConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final Widget? child;

  final Widget Function(
      BuildContext context, LoginOtpModelForm formModel, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveLoginOtpModelForm.of(context);

    if (formModel is! LoginOtpModelForm) {
      throw FormControlParentNotFoundException(this);
    }
    return builder(context, formModel, child);
  }
}

class LoginOtpModelFormInheritedStreamer extends InheritedStreamer<dynamic> {
  const LoginOtpModelFormInheritedStreamer({
    Key? key,
    required this.form,
    required Stream<dynamic> stream,
    required Widget child,
  }) : super(
          stream,
          child,
          key: key,
        );

  final LoginOtpModelForm form;
}

class ReactiveLoginOtpModelForm extends StatelessWidget {
  const ReactiveLoginOtpModelForm({
    Key? key,
    required this.form,
    required this.child,
    this.canPop,
    this.onPopInvokedWithResult,
  }) : super(key: key);

  final Widget child;

  final LoginOtpModelForm form;

  final bool Function(FormGroup formGroup)? canPop;

  final ReactiveFormPopInvokedWithResultCallback<dynamic>?
      onPopInvokedWithResult;

  static LoginOtpModelForm? of(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<
              LoginOtpModelFormInheritedStreamer>()
          ?.form;
    }

    final element = context.getElementForInheritedWidgetOfExactType<
        LoginOtpModelFormInheritedStreamer>();
    return element == null
        ? null
        : (element.widget as LoginOtpModelFormInheritedStreamer).form;
  }

  @override
  Widget build(BuildContext context) {
    return LoginOtpModelFormInheritedStreamer(
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

extension ReactiveReactiveLoginOtpModelFormExt on BuildContext {
  LoginOtpModelForm? loginOtpModelFormWatch() =>
      ReactiveLoginOtpModelForm.of(this);

  LoginOtpModelForm? loginOtpModelFormRead() =>
      ReactiveLoginOtpModelForm.of(this, listen: false);
}

class LoginOtpModelFormBuilder extends StatefulWidget {
  const LoginOtpModelFormBuilder({
    Key? key,
    this.model,
    this.child,
    this.canPop,
    this.onPopInvokedWithResult,
    required this.builder,
    this.initState,
  }) : super(key: key);

  final LoginOtpModel? model;

  final Widget? child;

  final bool Function(FormGroup formGroup)? canPop;

  final ReactiveFormPopInvokedWithResultCallback<dynamic>?
      onPopInvokedWithResult;

  final Widget Function(
      BuildContext context, LoginOtpModelForm formModel, Widget? child) builder;

  final void Function(BuildContext context, LoginOtpModelForm formModel)?
      initState;

  @override
  _LoginOtpModelFormBuilderState createState() =>
      _LoginOtpModelFormBuilderState();
}

class _LoginOtpModelFormBuilderState extends State<LoginOtpModelFormBuilder> {
  late LoginOtpModelForm _formModel;

  StreamSubscription<LogRecord>? _logSubscription;

  @override
  void initState() {
    _formModel =
        LoginOtpModelForm(LoginOtpModelForm.formElements(widget.model), null);

    if (_formModel.form.disabled) {
      _formModel.form.markAsDisabled();
    }

    widget.initState?.call(context, _formModel);

    _logSubscription = _logLoginOtpModelForm.onRecord.listen((LogRecord e) {
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
  void didUpdateWidget(covariant LoginOtpModelFormBuilder oldWidget) {
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
    return ReactiveLoginOtpModelForm(
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

final _logLoginOtpModelForm = Logger.detached('LoginOtpModelForm');

class LoginOtpModelForm implements FormModel<LoginOtpModel, LoginOtpModel> {
  LoginOtpModelForm(
    this.form,
    this.path,
  );

  static const String phoneControlName = "phone";

  static const String otpControlName = "otp";

  static const String inviteCodeControlName = "inviteCode";

  final FormGroup form;

  final String? path;

  final Map<String, bool> _disabled = {};

  String phoneControlPath() => pathBuilder(phoneControlName);

  String otpControlPath() => pathBuilder(otpControlName);

  String inviteCodeControlPath() => pathBuilder(inviteCodeControlName);

  String get _phoneValue => phoneControl.value ?? '';

  String get _otpValue => otpControl.value ?? '';

  String? get _inviteCodeValue => inviteCodeControl.value;

  String get _phoneRawValue => phoneControl.value ?? '';

  String get _otpRawValue => otpControl.value ?? '';

  String? get _inviteCodeRawValue => inviteCodeControl.value;

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsPhone {
    try {
      form.control(phoneControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsOtp {
    try {
      form.control(otpControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsInviteCode {
    try {
      form.control(inviteCodeControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, Object> get phoneErrors => phoneControl.errors;

  Map<String, Object> get otpErrors => otpControl.errors;

  Map<String, Object>? get inviteCodeErrors => inviteCodeControl.errors;

  void get phoneFocus => form.focus(phoneControlPath());

  void get otpFocus => form.focus(otpControlPath());

  void get inviteCodeFocus => form.focus(inviteCodeControlPath());

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void inviteCodeRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsInviteCode) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          inviteCodeControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            inviteCodeControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  void phoneValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    phoneControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void otpValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    otpControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void inviteCodeValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    inviteCodeControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void phoneValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    phoneControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void otpValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    otpControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void inviteCodeValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    inviteCodeControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void phoneValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      phoneControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void otpValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      otpControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void inviteCodeValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      inviteCodeControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  FormControl<String> get phoneControl =>
      form.control(phoneControlPath()) as FormControl<String>;

  FormControl<String> get otpControl =>
      form.control(otpControlPath()) as FormControl<String>;

  FormControl<String> get inviteCodeControl =>
      form.control(inviteCodeControlPath()) as FormControl<String>;

  void phoneSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      phoneControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      phoneControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void otpSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      otpControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      otpControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void inviteCodeSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      inviteCodeControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      inviteCodeControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  @override
  LoginOtpModel get model {
    final isValid = !currentForm.hasErrors && currentForm.errors.isEmpty;

    if (!isValid) {
      _logLoginOtpModelForm.warning(
        'Avoid calling `model` on invalid form.Possible exceptions for non-nullable fields which should be guarded by `required` validator.',
        null,
        StackTrace.current,
      );
    }
    return LoginOtpModel(
        phone: _phoneValue, otp: _otpValue, inviteCode: _inviteCodeValue);
  }

  @override
  LoginOtpModel get rawModel {
    return LoginOtpModel(
        phone: _phoneRawValue,
        otp: _otpRawValue,
        inviteCode: _inviteCodeRawValue);
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
  bool equalsTo(LoginOtpModel? other) {
    final currentForm = this.currentForm;

    return const DeepCollectionEquality().equals(
      currentForm is FormControlCollection<dynamic>
          ? currentForm.rawValue
          : currentForm.value,
      LoginOtpModelForm.formElements(other).rawValue,
    );
  }

  @override
  void submit({
    required void Function(LoginOtpModel model) onValid,
    void Function()? onNotValid,
  }) {
    currentForm.markAllAsTouched();
    if (currentForm.valid) {
      onValid(model);
    } else {
      _logLoginOtpModelForm.info('Errors');
      _logLoginOtpModelForm.info('┗━━ ${form.errors}');
      onNotValid?.call();
    }
  }

  AbstractControl<dynamic> get currentForm {
    return path == null ? form : form.control(path!);
  }

  @override
  void updateValue(
    LoginOtpModel? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.updateValue(LoginOtpModelForm.formElements(value).rawValue,
          updateParent: updateParent, emitEvent: emitEvent);

  @override
  void reset({
    LoginOtpModel? value,
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.reset(
          value: value != null ? formElements(value).rawValue : null,
          updateParent: updateParent,
          emitEvent: emitEvent);

  String pathBuilder(String? pathItem) =>
      [path, pathItem].whereType<String>().join(".");

  static FormGroup formElements(LoginOtpModel? loginOtpModel) => FormGroup({
        phoneControlName: FormControl<String>(
            value: loginOtpModel?.phone,
            validators: [NonEmpty(), Phone10()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        otpControlName: FormControl<String>(
            value: loginOtpModel?.otp,
            validators: [OtpLen(4)],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        inviteCodeControlName: FormControl<String>(
            value: loginOtpModel?.inviteCode,
            validators: [InviteCode()],
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

class ReactiveLoginOtpModelFormArrayBuilder<
    ReactiveLoginOtpModelFormArrayBuilderT> extends StatelessWidget {
  const ReactiveLoginOtpModelFormArrayBuilder({
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

  final FormArray<ReactiveLoginOtpModelFormArrayBuilderT>? formControl;

  final FormArray<ReactiveLoginOtpModelFormArrayBuilderT>? Function(
      LoginOtpModelForm formModel)? control;

  final Widget Function(BuildContext context, List<Widget> itemList,
      LoginOtpModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      FormControl<ReactiveLoginOtpModelFormArrayBuilderT> control,
      ReactiveLoginOtpModelFormArrayBuilderT? item,
      LoginOtpModelForm formModel) itemBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  final bool Function(
          FormControl<ReactiveLoginOtpModelFormArrayBuilderT> control)?
      controlFilter;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveLoginOtpModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final builder = this.builder;
    final itemBuilder = this.itemBuilder;

    return ReactiveFormArrayItemBuilder<ReactiveLoginOtpModelFormArrayBuilderT>(
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

class ReactiveLoginOtpModelFormArrayBuilder2<
    ReactiveLoginOtpModelFormArrayBuilderT> extends StatelessWidget {
  const ReactiveLoginOtpModelFormArrayBuilder2({
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

  final FormArray<ReactiveLoginOtpModelFormArrayBuilderT>? formControl;

  final FormArray<ReactiveLoginOtpModelFormArrayBuilderT>? Function(
      LoginOtpModelForm formModel)? control;

  final Widget Function(
      ({
        BuildContext context,
        List<Widget> itemList,
        LoginOtpModelForm formModel
      }) params)? builder;

  final Widget Function(
      ({
        BuildContext context,
        int i,
        FormControl<ReactiveLoginOtpModelFormArrayBuilderT> control,
        ReactiveLoginOtpModelFormArrayBuilderT? item,
        LoginOtpModelForm formModel
      }) params) itemBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  final bool Function(
          FormControl<ReactiveLoginOtpModelFormArrayBuilderT> control)?
      controlFilter;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveLoginOtpModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final builder = this.builder;
    final itemBuilder = this.itemBuilder;

    return ReactiveFormArrayItemBuilder<ReactiveLoginOtpModelFormArrayBuilderT>(
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

class ReactiveLoginOtpModelFormFormGroupArrayBuilder<
    ReactiveLoginOtpModelFormFormGroupArrayBuilderT> extends StatelessWidget {
  const ReactiveLoginOtpModelFormFormGroupArrayBuilder({
    Key? key,
    this.extended,
    this.getExtended,
    this.builder,
    required this.itemBuilder,
  })  : assert(extended != null || getExtended != null,
            "You have to specify `control` or `formControl`!"),
        super(key: key);

  final ExtendedControl<List<Map<String, Object?>?>,
      List<ReactiveLoginOtpModelFormFormGroupArrayBuilderT>>? extended;

  final ExtendedControl<List<Map<String, Object?>?>,
          List<ReactiveLoginOtpModelFormFormGroupArrayBuilderT>>
      Function(LoginOtpModelForm formModel)? getExtended;

  final Widget Function(BuildContext context, List<Widget> itemList,
      LoginOtpModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      ReactiveLoginOtpModelFormFormGroupArrayBuilderT? item,
      LoginOtpModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveLoginOtpModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final value = (extended ?? getExtended?.call(formModel))!;

    return StreamBuilder<List<Map<String, Object?>?>?>(
      stream: value.control.valueChanges,
      builder: (context, snapshot) {
        final itemList = (value.value() ??
                <ReactiveLoginOtpModelFormFormGroupArrayBuilderT>[])
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

class ReactiveLoginPasswordModelFormConsumer extends StatelessWidget {
  const ReactiveLoginPasswordModelFormConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final Widget? child;

  final Widget Function(
          BuildContext context, LoginPasswordModelForm formModel, Widget? child)
      builder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveLoginPasswordModelForm.of(context);

    if (formModel is! LoginPasswordModelForm) {
      throw FormControlParentNotFoundException(this);
    }
    return builder(context, formModel, child);
  }
}

class LoginPasswordModelFormInheritedStreamer
    extends InheritedStreamer<dynamic> {
  const LoginPasswordModelFormInheritedStreamer({
    Key? key,
    required this.form,
    required Stream<dynamic> stream,
    required Widget child,
  }) : super(
          stream,
          child,
          key: key,
        );

  final LoginPasswordModelForm form;
}

class ReactiveLoginPasswordModelForm extends StatelessWidget {
  const ReactiveLoginPasswordModelForm({
    Key? key,
    required this.form,
    required this.child,
    this.canPop,
    this.onPopInvokedWithResult,
  }) : super(key: key);

  final Widget child;

  final LoginPasswordModelForm form;

  final bool Function(FormGroup formGroup)? canPop;

  final ReactiveFormPopInvokedWithResultCallback<dynamic>?
      onPopInvokedWithResult;

  static LoginPasswordModelForm? of(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<
              LoginPasswordModelFormInheritedStreamer>()
          ?.form;
    }

    final element = context.getElementForInheritedWidgetOfExactType<
        LoginPasswordModelFormInheritedStreamer>();
    return element == null
        ? null
        : (element.widget as LoginPasswordModelFormInheritedStreamer).form;
  }

  @override
  Widget build(BuildContext context) {
    return LoginPasswordModelFormInheritedStreamer(
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

extension ReactiveReactiveLoginPasswordModelFormExt on BuildContext {
  LoginPasswordModelForm? loginPasswordModelFormWatch() =>
      ReactiveLoginPasswordModelForm.of(this);

  LoginPasswordModelForm? loginPasswordModelFormRead() =>
      ReactiveLoginPasswordModelForm.of(this, listen: false);
}

class LoginPasswordModelFormBuilder extends StatefulWidget {
  const LoginPasswordModelFormBuilder({
    Key? key,
    this.model,
    this.child,
    this.canPop,
    this.onPopInvokedWithResult,
    required this.builder,
    this.initState,
  }) : super(key: key);

  final LoginPasswordModel? model;

  final Widget? child;

  final bool Function(FormGroup formGroup)? canPop;

  final ReactiveFormPopInvokedWithResultCallback<dynamic>?
      onPopInvokedWithResult;

  final Widget Function(
          BuildContext context, LoginPasswordModelForm formModel, Widget? child)
      builder;

  final void Function(BuildContext context, LoginPasswordModelForm formModel)?
      initState;

  @override
  _LoginPasswordModelFormBuilderState createState() =>
      _LoginPasswordModelFormBuilderState();
}

class _LoginPasswordModelFormBuilderState
    extends State<LoginPasswordModelFormBuilder> {
  late LoginPasswordModelForm _formModel;

  StreamSubscription<LogRecord>? _logSubscription;

  @override
  void initState() {
    _formModel = LoginPasswordModelForm(
        LoginPasswordModelForm.formElements(widget.model), null);

    if (_formModel.form.disabled) {
      _formModel.form.markAsDisabled();
    }

    widget.initState?.call(context, _formModel);

    _logSubscription =
        _logLoginPasswordModelForm.onRecord.listen((LogRecord e) {
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
  void didUpdateWidget(covariant LoginPasswordModelFormBuilder oldWidget) {
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
    return ReactiveLoginPasswordModelForm(
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

final _logLoginPasswordModelForm = Logger.detached('LoginPasswordModelForm');

class LoginPasswordModelForm
    implements FormModel<LoginPasswordModel, LoginPasswordModel> {
  LoginPasswordModelForm(
    this.form,
    this.path,
  );

  static const String phoneControlName = "phone";

  static const String passwordControlName = "password";

  static const String inviteCodeControlName = "inviteCode";

  final FormGroup form;

  final String? path;

  final Map<String, bool> _disabled = {};

  String phoneControlPath() => pathBuilder(phoneControlName);

  String passwordControlPath() => pathBuilder(passwordControlName);

  String inviteCodeControlPath() => pathBuilder(inviteCodeControlName);

  String get _phoneValue => phoneControl.value ?? '';

  String get _passwordValue => passwordControl.value ?? '';

  String? get _inviteCodeValue => inviteCodeControl.value;

  String get _phoneRawValue => phoneControl.value ?? '';

  String get _passwordRawValue => passwordControl.value ?? '';

  String? get _inviteCodeRawValue => inviteCodeControl.value;

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsPhone {
    try {
      form.control(phoneControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsPassword {
    try {
      form.control(passwordControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsInviteCode {
    try {
      form.control(inviteCodeControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, Object> get phoneErrors => phoneControl.errors;

  Map<String, Object> get passwordErrors => passwordControl.errors;

  Map<String, Object>? get inviteCodeErrors => inviteCodeControl.errors;

  void get phoneFocus => form.focus(phoneControlPath());

  void get passwordFocus => form.focus(passwordControlPath());

  void get inviteCodeFocus => form.focus(inviteCodeControlPath());

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void inviteCodeRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsInviteCode) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          inviteCodeControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            inviteCodeControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  void phoneValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    phoneControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void passwordValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    passwordControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void inviteCodeValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    inviteCodeControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void phoneValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    phoneControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void passwordValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    passwordControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void inviteCodeValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    inviteCodeControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void phoneValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      phoneControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void passwordValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      passwordControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void inviteCodeValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      inviteCodeControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  FormControl<String> get phoneControl =>
      form.control(phoneControlPath()) as FormControl<String>;

  FormControl<String> get passwordControl =>
      form.control(passwordControlPath()) as FormControl<String>;

  FormControl<String> get inviteCodeControl =>
      form.control(inviteCodeControlPath()) as FormControl<String>;

  void phoneSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      phoneControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      phoneControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void passwordSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      passwordControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      passwordControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void inviteCodeSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      inviteCodeControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      inviteCodeControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  @override
  LoginPasswordModel get model {
    final isValid = !currentForm.hasErrors && currentForm.errors.isEmpty;

    if (!isValid) {
      _logLoginPasswordModelForm.warning(
        'Avoid calling `model` on invalid form.Possible exceptions for non-nullable fields which should be guarded by `required` validator.',
        null,
        StackTrace.current,
      );
    }
    return LoginPasswordModel(
        phone: _phoneValue,
        password: _passwordValue,
        inviteCode: _inviteCodeValue);
  }

  @override
  LoginPasswordModel get rawModel {
    return LoginPasswordModel(
        phone: _phoneRawValue,
        password: _passwordRawValue,
        inviteCode: _inviteCodeRawValue);
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
  bool equalsTo(LoginPasswordModel? other) {
    final currentForm = this.currentForm;

    return const DeepCollectionEquality().equals(
      currentForm is FormControlCollection<dynamic>
          ? currentForm.rawValue
          : currentForm.value,
      LoginPasswordModelForm.formElements(other).rawValue,
    );
  }

  @override
  void submit({
    required void Function(LoginPasswordModel model) onValid,
    void Function()? onNotValid,
  }) {
    currentForm.markAllAsTouched();
    if (currentForm.valid) {
      onValid(model);
    } else {
      _logLoginPasswordModelForm.info('Errors');
      _logLoginPasswordModelForm.info('┗━━ ${form.errors}');
      onNotValid?.call();
    }
  }

  AbstractControl<dynamic> get currentForm {
    return path == null ? form : form.control(path!);
  }

  @override
  void updateValue(
    LoginPasswordModel? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.updateValue(LoginPasswordModelForm.formElements(value).rawValue,
          updateParent: updateParent, emitEvent: emitEvent);

  @override
  void reset({
    LoginPasswordModel? value,
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.reset(
          value: value != null ? formElements(value).rawValue : null,
          updateParent: updateParent,
          emitEvent: emitEvent);

  String pathBuilder(String? pathItem) =>
      [path, pathItem].whereType<String>().join(".");

  static FormGroup formElements(LoginPasswordModel? loginPasswordModel) =>
      FormGroup({
        phoneControlName: FormControl<String>(
            value: loginPasswordModel?.phone,
            validators: [NonEmpty(), Phone10()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        passwordControlName: FormControl<String>(
            value: loginPasswordModel?.password,
            validators: [StrongPassword()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        inviteCodeControlName: FormControl<String>(
            value: loginPasswordModel?.inviteCode,
            validators: [InviteCode()],
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

class ReactiveLoginPasswordModelFormArrayBuilder<
    ReactiveLoginPasswordModelFormArrayBuilderT> extends StatelessWidget {
  const ReactiveLoginPasswordModelFormArrayBuilder({
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

  final FormArray<ReactiveLoginPasswordModelFormArrayBuilderT>? formControl;

  final FormArray<ReactiveLoginPasswordModelFormArrayBuilderT>? Function(
      LoginPasswordModelForm formModel)? control;

  final Widget Function(BuildContext context, List<Widget> itemList,
      LoginPasswordModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      FormControl<ReactiveLoginPasswordModelFormArrayBuilderT> control,
      ReactiveLoginPasswordModelFormArrayBuilderT? item,
      LoginPasswordModelForm formModel) itemBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  final bool Function(
          FormControl<ReactiveLoginPasswordModelFormArrayBuilderT> control)?
      controlFilter;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveLoginPasswordModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final builder = this.builder;
    final itemBuilder = this.itemBuilder;

    return ReactiveFormArrayItemBuilder<
        ReactiveLoginPasswordModelFormArrayBuilderT>(
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

class ReactiveLoginPasswordModelFormArrayBuilder2<
    ReactiveLoginPasswordModelFormArrayBuilderT> extends StatelessWidget {
  const ReactiveLoginPasswordModelFormArrayBuilder2({
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

  final FormArray<ReactiveLoginPasswordModelFormArrayBuilderT>? formControl;

  final FormArray<ReactiveLoginPasswordModelFormArrayBuilderT>? Function(
      LoginPasswordModelForm formModel)? control;

  final Widget Function(
      ({
        BuildContext context,
        List<Widget> itemList,
        LoginPasswordModelForm formModel
      }) params)? builder;

  final Widget Function(
      ({
        BuildContext context,
        int i,
        FormControl<ReactiveLoginPasswordModelFormArrayBuilderT> control,
        ReactiveLoginPasswordModelFormArrayBuilderT? item,
        LoginPasswordModelForm formModel
      }) params) itemBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  final bool Function(
          FormControl<ReactiveLoginPasswordModelFormArrayBuilderT> control)?
      controlFilter;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveLoginPasswordModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final builder = this.builder;
    final itemBuilder = this.itemBuilder;

    return ReactiveFormArrayItemBuilder<
        ReactiveLoginPasswordModelFormArrayBuilderT>(
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

class ReactiveLoginPasswordModelFormFormGroupArrayBuilder<
        ReactiveLoginPasswordModelFormFormGroupArrayBuilderT>
    extends StatelessWidget {
  const ReactiveLoginPasswordModelFormFormGroupArrayBuilder({
    Key? key,
    this.extended,
    this.getExtended,
    this.builder,
    required this.itemBuilder,
  })  : assert(extended != null || getExtended != null,
            "You have to specify `control` or `formControl`!"),
        super(key: key);

  final ExtendedControl<List<Map<String, Object?>?>,
      List<ReactiveLoginPasswordModelFormFormGroupArrayBuilderT>>? extended;

  final ExtendedControl<List<Map<String, Object?>?>,
          List<ReactiveLoginPasswordModelFormFormGroupArrayBuilderT>>
      Function(LoginPasswordModelForm formModel)? getExtended;

  final Widget Function(BuildContext context, List<Widget> itemList,
      LoginPasswordModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      ReactiveLoginPasswordModelFormFormGroupArrayBuilderT? item,
      LoginPasswordModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveLoginPasswordModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final value = (extended ?? getExtended?.call(formModel))!;

    return StreamBuilder<List<Map<String, Object?>?>?>(
      stream: value.control.valueChanges,
      builder: (context, snapshot) {
        final itemList = (value.value() ??
                <ReactiveLoginPasswordModelFormFormGroupArrayBuilderT>[])
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
