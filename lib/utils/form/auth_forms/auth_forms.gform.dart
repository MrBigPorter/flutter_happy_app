// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file:

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
    this.onPopInvoked,
  }) : super(key: key);

  final Widget child;

  final LoginOtpModelForm form;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

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
        onPopInvoked: onPopInvoked,
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
    this.onPopInvoked,
    required this.builder,
    this.initState,
  }) : super(key: key);

  final LoginOtpModel? model;

  final Widget? child;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

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

  @override
  void initState() {
    _formModel =
        LoginOtpModelForm(LoginOtpModelForm.formElements(widget.model), null);

    if (_formModel.form.disabled) {
      _formModel.form.markAsDisabled();
    }

    widget.initState?.call(context, _formModel);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveLoginOtpModelForm(
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

class LoginOtpModelForm implements FormModel<LoginOtpModel> {
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

  String get _phoneValue => phoneControl.value ?? "";

  String get _otpValue => otpControl.value ?? "";

  String? get _inviteCodeValue => inviteCodeControl?.value;

  bool get containsPhone {
    try {
      form.control(phoneControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsOtp {
    try {
      form.control(otpControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsInviteCode {
    try {
      form.control(inviteCodeControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  Object? get phoneErrors => phoneControl.errors;

  Object? get otpErrors => otpControl.errors;

  Object? get inviteCodeErrors => inviteCodeControl?.errors;

  void get phoneFocus => form.focus(phoneControlPath());

  void get otpFocus => form.focus(otpControlPath());

  void get inviteCodeFocus => form.focus(inviteCodeControlPath());

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
    inviteCodeControl?.updateValue(value,
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
    inviteCodeControl?.patchValue(value,
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
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void otpValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      otpControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void inviteCodeValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      inviteCodeControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  FormControl<String> get phoneControl =>
      form.control(phoneControlPath()) as FormControl<String>;

  FormControl<String> get otpControl =>
      form.control(otpControlPath()) as FormControl<String>;

  FormControl<String>? get inviteCodeControl => containsInviteCode
      ? form.control(inviteCodeControlPath()) as FormControl<String>?
      : null;

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
      inviteCodeControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      inviteCodeControl?.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  @override
  LoginOtpModel get model {
    final isValid = !currentForm.hasErrors && currentForm.errors.isEmpty;

    if (!isValid) {
      debugPrintStack(
          label:
              '[${path ?? 'LoginOtpModelForm'}]\n┗━ Avoid calling `model` on invalid form. Possible exceptions for non-nullable fields which should be guarded by `required` validator.');
    }
    return LoginOtpModel(
        phone: _phoneValue, otp: _otpValue, inviteCode: _inviteCodeValue);
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
    required void Function(LoginOtpModel model) onValid,
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
            validators: [OtpLen(6)],
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
      ReactiveLoginOtpModelFormArrayBuilderT? item,
      LoginOtpModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveLoginOtpModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    return ReactiveFormArray<ReactiveLoginOtpModelFormArrayBuilderT>(
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
    this.onPopInvoked,
  }) : super(key: key);

  final Widget child;

  final LoginPasswordModelForm form;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

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
        onPopInvoked: onPopInvoked,
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
    this.onPopInvoked,
    required this.builder,
    this.initState,
  }) : super(key: key);

  final LoginPasswordModel? model;

  final Widget? child;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

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

  @override
  void initState() {
    _formModel = LoginPasswordModelForm(
        LoginPasswordModelForm.formElements(widget.model), null);

    if (_formModel.form.disabled) {
      _formModel.form.markAsDisabled();
    }

    widget.initState?.call(context, _formModel);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveLoginPasswordModelForm(
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

class LoginPasswordModelForm implements FormModel<LoginPasswordModel> {
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

  String get _phoneValue => phoneControl.value ?? "";

  String get _passwordValue => passwordControl.value ?? "";

  String? get _inviteCodeValue => inviteCodeControl?.value;

  bool get containsPhone {
    try {
      form.control(phoneControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsPassword {
    try {
      form.control(passwordControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsInviteCode {
    try {
      form.control(inviteCodeControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  Object? get phoneErrors => phoneControl.errors;

  Object? get passwordErrors => passwordControl.errors;

  Object? get inviteCodeErrors => inviteCodeControl?.errors;

  void get phoneFocus => form.focus(phoneControlPath());

  void get passwordFocus => form.focus(passwordControlPath());

  void get inviteCodeFocus => form.focus(inviteCodeControlPath());

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
    inviteCodeControl?.updateValue(value,
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
    inviteCodeControl?.patchValue(value,
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
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void passwordValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      passwordControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void inviteCodeValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      inviteCodeControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  FormControl<String> get phoneControl =>
      form.control(phoneControlPath()) as FormControl<String>;

  FormControl<String> get passwordControl =>
      form.control(passwordControlPath()) as FormControl<String>;

  FormControl<String>? get inviteCodeControl => containsInviteCode
      ? form.control(inviteCodeControlPath()) as FormControl<String>?
      : null;

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
      inviteCodeControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      inviteCodeControl?.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  @override
  LoginPasswordModel get model {
    final isValid = !currentForm.hasErrors && currentForm.errors.isEmpty;

    if (!isValid) {
      debugPrintStack(
          label:
              '[${path ?? 'LoginPasswordModelForm'}]\n┗━ Avoid calling `model` on invalid form. Possible exceptions for non-nullable fields which should be guarded by `required` validator.');
    }
    return LoginPasswordModel(
        phone: _phoneValue,
        password: _passwordValue,
        inviteCode: _inviteCodeValue);
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
    required void Function(LoginPasswordModel model) onValid,
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
      ReactiveLoginPasswordModelFormArrayBuilderT? item,
      LoginPasswordModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveLoginPasswordModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    return ReactiveFormArray<ReactiveLoginPasswordModelFormArrayBuilderT>(
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
