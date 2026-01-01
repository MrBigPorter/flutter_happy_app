// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'address_form.dart';

// **************************************************************************
// ReactiveFormsGenerator
// **************************************************************************

class ReactiveAddressFormModelFormConsumer extends StatelessWidget {
  const ReactiveAddressFormModelFormConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final Widget? child;

  final Widget Function(
          BuildContext context, AddressFormModelForm formModel, Widget? child)
      builder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveAddressFormModelForm.of(context);

    if (formModel is! AddressFormModelForm) {
      throw FormControlParentNotFoundException(this);
    }
    return builder(context, formModel, child);
  }
}

class AddressFormModelFormInheritedStreamer extends InheritedStreamer<dynamic> {
  const AddressFormModelFormInheritedStreamer({
    Key? key,
    required this.form,
    required Stream<dynamic> stream,
    required Widget child,
  }) : super(
          stream,
          child,
          key: key,
        );

  final AddressFormModelForm form;
}

class ReactiveAddressFormModelForm extends StatelessWidget {
  const ReactiveAddressFormModelForm({
    Key? key,
    required this.form,
    required this.child,
    this.canPop,
    this.onPopInvokedWithResult,
  }) : super(key: key);

  final Widget child;

  final AddressFormModelForm form;

  final bool Function(FormGroup formGroup)? canPop;

  final ReactiveFormPopInvokedWithResultCallback<dynamic>?
      onPopInvokedWithResult;

  static AddressFormModelForm? of(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<
              AddressFormModelFormInheritedStreamer>()
          ?.form;
    }

    final element = context.getElementForInheritedWidgetOfExactType<
        AddressFormModelFormInheritedStreamer>();
    return element == null
        ? null
        : (element.widget as AddressFormModelFormInheritedStreamer).form;
  }

  @override
  Widget build(BuildContext context) {
    return AddressFormModelFormInheritedStreamer(
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

extension ReactiveReactiveAddressFormModelFormExt on BuildContext {
  AddressFormModelForm? addressFormModelFormWatch() =>
      ReactiveAddressFormModelForm.of(this);

  AddressFormModelForm? addressFormModelFormRead() =>
      ReactiveAddressFormModelForm.of(this, listen: false);
}

class AddressFormModelFormBuilder extends StatefulWidget {
  const AddressFormModelFormBuilder({
    Key? key,
    this.model,
    this.child,
    this.canPop,
    this.onPopInvokedWithResult,
    required this.builder,
    this.initState,
  }) : super(key: key);

  final AddressFormModel? model;

  final Widget? child;

  final bool Function(FormGroup formGroup)? canPop;

  final ReactiveFormPopInvokedWithResultCallback<dynamic>?
      onPopInvokedWithResult;

  final Widget Function(
          BuildContext context, AddressFormModelForm formModel, Widget? child)
      builder;

  final void Function(BuildContext context, AddressFormModelForm formModel)?
      initState;

  @override
  _AddressFormModelFormBuilderState createState() =>
      _AddressFormModelFormBuilderState();
}

class _AddressFormModelFormBuilderState
    extends State<AddressFormModelFormBuilder> {
  late AddressFormModelForm _formModel;

  StreamSubscription<LogRecord>? _logSubscription;

  @override
  void initState() {
    _formModel = AddressFormModelForm(
        AddressFormModelForm.formElements(widget.model), null);

    if (_formModel.form.disabled) {
      _formModel.form.markAsDisabled();
    }

    widget.initState?.call(context, _formModel);

    _logSubscription = _logAddressFormModelForm.onRecord.listen((LogRecord e) {
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
  void didUpdateWidget(covariant AddressFormModelFormBuilder oldWidget) {
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
    return ReactiveAddressFormModelForm(
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

final _logAddressFormModelForm = Logger.detached('AddressFormModelForm');

class AddressFormModelForm
    implements FormModel<AddressFormModel, AddressFormModel> {
  AddressFormModelForm(
    this.form,
    this.path,
  );

  static const String firstNameControlName = "firstName";

  static const String middleNameControlName = "middleName";

  static const String lastNameControlName = "lastName";

  static const String contactNameControlName = "contactName";

  static const String fullAddressControlName = "fullAddress";

  static const String provinceIdControlName = "provinceId";

  static const String cityIdControlName = "cityId";

  static const String barangayIdControlName = "barangayId";

  static const String postalCodeControlName = "postalCode";

  static const String phoneControlName = "phone";

  static const String isDefaultControlName = "isDefault";

  static const String labelControlName = "label";

  final FormGroup form;

  final String? path;

  final Map<String, bool> _disabled = {};

  String firstNameControlPath() => pathBuilder(firstNameControlName);

  String middleNameControlPath() => pathBuilder(middleNameControlName);

  String lastNameControlPath() => pathBuilder(lastNameControlName);

  String contactNameControlPath() => pathBuilder(contactNameControlName);

  String fullAddressControlPath() => pathBuilder(fullAddressControlName);

  String provinceIdControlPath() => pathBuilder(provinceIdControlName);

  String cityIdControlPath() => pathBuilder(cityIdControlName);

  String barangayIdControlPath() => pathBuilder(barangayIdControlName);

  String postalCodeControlPath() => pathBuilder(postalCodeControlName);

  String phoneControlPath() => pathBuilder(phoneControlName);

  String isDefaultControlPath() => pathBuilder(isDefaultControlName);

  String labelControlPath() => pathBuilder(labelControlName);

  String? get _firstNameValue => firstNameControl.value;

  String? get _middleNameValue => middleNameControl.value;

  String? get _lastNameValue => lastNameControl.value;

  String get _contactNameValue => contactNameControl.value ?? '';

  String get _fullAddressValue => fullAddressControl.value ?? '';

  int? get _provinceIdValue => provinceIdControl.value;

  int? get _cityIdValue => cityIdControl.value;

  int? get _barangayIdValue => barangayIdControl.value;

  String? get _postalCodeValue => postalCodeControl.value;

  String get _phoneValue => phoneControl.value ?? '';

  int get _isDefaultValue => isDefaultControl.value ?? 0;

  String? get _labelValue => labelControl.value;

  String? get _firstNameRawValue => firstNameControl.value;

  String? get _middleNameRawValue => middleNameControl.value;

  String? get _lastNameRawValue => lastNameControl.value;

  String get _contactNameRawValue => contactNameControl.value ?? '';

  String get _fullAddressRawValue => fullAddressControl.value ?? '';

  int? get _provinceIdRawValue => provinceIdControl.value;

  int? get _cityIdRawValue => cityIdControl.value;

  int? get _barangayIdRawValue => barangayIdControl.value;

  String? get _postalCodeRawValue => postalCodeControl.value;

  String get _phoneRawValue => phoneControl.value ?? '';

  int get _isDefaultRawValue => isDefaultControl.value ?? 0;

  String? get _labelRawValue => labelControl.value;

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsFirstName {
    try {
      form.control(firstNameControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsMiddleName {
    try {
      form.control(middleNameControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsLastName {
    try {
      form.control(lastNameControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsContactName {
    try {
      form.control(contactNameControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsFullAddress {
    try {
      form.control(fullAddressControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsProvinceId {
    try {
      form.control(provinceIdControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsCityId {
    try {
      form.control(cityIdControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsBarangayId {
    try {
      form.control(barangayIdControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsPostalCode {
    try {
      form.control(postalCodeControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

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
  bool get containsIsDefault {
    try {
      form.control(isDefaultControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsLabel {
    try {
      form.control(labelControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, Object>? get firstNameErrors => firstNameControl.errors;

  Map<String, Object>? get middleNameErrors => middleNameControl.errors;

  Map<String, Object>? get lastNameErrors => lastNameControl.errors;

  Map<String, Object> get contactNameErrors => contactNameControl.errors;

  Map<String, Object> get fullAddressErrors => fullAddressControl.errors;

  Map<String, Object>? get provinceIdErrors => provinceIdControl.errors;

  Map<String, Object>? get cityIdErrors => cityIdControl.errors;

  Map<String, Object>? get barangayIdErrors => barangayIdControl.errors;

  Map<String, Object>? get postalCodeErrors => postalCodeControl.errors;

  Map<String, Object> get phoneErrors => phoneControl.errors;

  Map<String, Object> get isDefaultErrors => isDefaultControl.errors;

  Map<String, Object>? get labelErrors => labelControl.errors;

  void get firstNameFocus => form.focus(firstNameControlPath());

  void get middleNameFocus => form.focus(middleNameControlPath());

  void get lastNameFocus => form.focus(lastNameControlPath());

  void get contactNameFocus => form.focus(contactNameControlPath());

  void get fullAddressFocus => form.focus(fullAddressControlPath());

  void get provinceIdFocus => form.focus(provinceIdControlPath());

  void get cityIdFocus => form.focus(cityIdControlPath());

  void get barangayIdFocus => form.focus(barangayIdControlPath());

  void get postalCodeFocus => form.focus(postalCodeControlPath());

  void get phoneFocus => form.focus(phoneControlPath());

  void get isDefaultFocus => form.focus(isDefaultControlPath());

  void get labelFocus => form.focus(labelControlPath());

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void firstNameRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsFirstName) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          firstNameControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            firstNameControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void middleNameRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsMiddleName) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          middleNameControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            middleNameControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void lastNameRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsLastName) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          lastNameControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            lastNameControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void provinceIdRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsProvinceId) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          provinceIdControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            provinceIdControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void cityIdRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsCityId) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          cityIdControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            cityIdControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void barangayIdRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsBarangayId) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          barangayIdControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            barangayIdControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void postalCodeRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsPostalCode) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          postalCodeControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            postalCodeControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void labelRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsLabel) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          labelControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            labelControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  void firstNameValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    firstNameControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void middleNameValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    middleNameControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void lastNameValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    lastNameControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void contactNameValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    contactNameControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void fullAddressValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    fullAddressControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void provinceIdValueUpdate(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    provinceIdControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void cityIdValueUpdate(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    cityIdControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void barangayIdValueUpdate(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    barangayIdControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void postalCodeValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    postalCodeControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void phoneValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    phoneControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void isDefaultValueUpdate(
    int value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    isDefaultControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void labelValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    labelControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void firstNameValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    firstNameControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void middleNameValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    middleNameControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void lastNameValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    lastNameControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void contactNameValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    contactNameControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void fullAddressValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    fullAddressControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void provinceIdValuePatch(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    provinceIdControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void cityIdValuePatch(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    cityIdControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void barangayIdValuePatch(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    barangayIdControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void postalCodeValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    postalCodeControl.patchValue(value,
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

  void isDefaultValuePatch(
    int value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    isDefaultControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void labelValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    labelControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void firstNameValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      firstNameControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void middleNameValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      middleNameControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void lastNameValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      lastNameControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void contactNameValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      contactNameControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void fullAddressValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      fullAddressControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void provinceIdValueReset(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      provinceIdControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void cityIdValueReset(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      cityIdControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void barangayIdValueReset(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      barangayIdControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void postalCodeValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      postalCodeControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

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

  void isDefaultValueReset(
    int value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      isDefaultControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void labelValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      labelControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  FormControl<String> get firstNameControl =>
      form.control(firstNameControlPath()) as FormControl<String>;

  FormControl<String> get middleNameControl =>
      form.control(middleNameControlPath()) as FormControl<String>;

  FormControl<String> get lastNameControl =>
      form.control(lastNameControlPath()) as FormControl<String>;

  FormControl<String> get contactNameControl =>
      form.control(contactNameControlPath()) as FormControl<String>;

  FormControl<String> get fullAddressControl =>
      form.control(fullAddressControlPath()) as FormControl<String>;

  FormControl<int> get provinceIdControl =>
      form.control(provinceIdControlPath()) as FormControl<int>;

  FormControl<int> get cityIdControl =>
      form.control(cityIdControlPath()) as FormControl<int>;

  FormControl<int> get barangayIdControl =>
      form.control(barangayIdControlPath()) as FormControl<int>;

  FormControl<String> get postalCodeControl =>
      form.control(postalCodeControlPath()) as FormControl<String>;

  FormControl<String> get phoneControl =>
      form.control(phoneControlPath()) as FormControl<String>;

  FormControl<int> get isDefaultControl =>
      form.control(isDefaultControlPath()) as FormControl<int>;

  FormControl<String> get labelControl =>
      form.control(labelControlPath()) as FormControl<String>;

  void firstNameSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      firstNameControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      firstNameControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void middleNameSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      middleNameControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      middleNameControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void lastNameSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      lastNameControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      lastNameControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void contactNameSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      contactNameControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      contactNameControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void fullAddressSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      fullAddressControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      fullAddressControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void provinceIdSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      provinceIdControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      provinceIdControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void cityIdSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      cityIdControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      cityIdControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void barangayIdSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      barangayIdControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      barangayIdControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void postalCodeSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      postalCodeControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      postalCodeControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

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

  void isDefaultSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      isDefaultControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      isDefaultControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void labelSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      labelControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      labelControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  @override
  AddressFormModel get model {
    final isValid = !currentForm.hasErrors && currentForm.errors.isEmpty;

    if (!isValid) {
      _logAddressFormModelForm.warning(
        'Avoid calling `model` on invalid form.Possible exceptions for non-nullable fields which should be guarded by `required` validator.',
        null,
        StackTrace.current,
      );
    }
    return AddressFormModel(
        firstName: _firstNameValue,
        middleName: _middleNameValue,
        lastName: _lastNameValue,
        contactName: _contactNameValue,
        fullAddress: _fullAddressValue,
        provinceId: _provinceIdValue,
        cityId: _cityIdValue,
        barangayId: _barangayIdValue,
        postalCode: _postalCodeValue,
        phone: _phoneValue,
        isDefault: _isDefaultValue,
        label: _labelValue);
  }

  @override
  AddressFormModel get rawModel {
    return AddressFormModel(
        firstName: _firstNameRawValue,
        middleName: _middleNameRawValue,
        lastName: _lastNameRawValue,
        contactName: _contactNameRawValue,
        fullAddress: _fullAddressRawValue,
        provinceId: _provinceIdRawValue,
        cityId: _cityIdRawValue,
        barangayId: _barangayIdRawValue,
        postalCode: _postalCodeRawValue,
        phone: _phoneRawValue,
        isDefault: _isDefaultRawValue,
        label: _labelRawValue);
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
  bool equalsTo(AddressFormModel? other) {
    final currentForm = this.currentForm;

    return const DeepCollectionEquality().equals(
      currentForm is FormControlCollection<dynamic>
          ? currentForm.rawValue
          : currentForm.value,
      AddressFormModelForm.formElements(other).rawValue,
    );
  }

  @override
  void submit({
    required void Function(AddressFormModel model) onValid,
    void Function()? onNotValid,
  }) {
    currentForm.markAllAsTouched();
    if (currentForm.valid) {
      onValid(model);
    } else {
      _logAddressFormModelForm.info('Errors');
      _logAddressFormModelForm.info('┗━━ ${form.errors}');
      onNotValid?.call();
    }
  }

  AbstractControl<dynamic> get currentForm {
    return path == null ? form : form.control(path!);
  }

  @override
  void updateValue(
    AddressFormModel? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.updateValue(AddressFormModelForm.formElements(value).rawValue,
          updateParent: updateParent, emitEvent: emitEvent);

  @override
  void reset({
    AddressFormModel? value,
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.reset(
          value: value != null ? formElements(value).rawValue : null,
          updateParent: updateParent,
          emitEvent: emitEvent);

  String pathBuilder(String? pathItem) =>
      [path, pathItem].whereType<String>().join(".");

  static FormGroup formElements(AddressFormModel? addressFormModel) =>
      FormGroup({
        firstNameControlName: FormControl<String>(
            value: addressFormModel?.firstName,
            validators: [],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        middleNameControlName: FormControl<String>(
            value: addressFormModel?.middleName,
            validators: [],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        lastNameControlName: FormControl<String>(
            value: addressFormModel?.lastName,
            validators: [],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        contactNameControlName: FormControl<String>(
            value: addressFormModel?.contactName,
            validators: [NonEmpty(), RealName()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        fullAddressControlName: FormControl<String>(
            value: addressFormModel?.fullAddress,
            validators: [NonEmpty()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        provinceIdControlName: FormControl<int>(
            value: addressFormModel?.provinceId,
            validators: [Required()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        cityIdControlName: FormControl<int>(
            value: addressFormModel?.cityId,
            validators: [Required()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        barangayIdControlName: FormControl<int>(
            value: addressFormModel?.barangayId,
            validators: [Required()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        postalCodeControlName: FormControl<String>(
            value: addressFormModel?.postalCode,
            validators: [PostalCode()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        phoneControlName: FormControl<String>(
            value: addressFormModel?.phone,
            validators: [NonEmpty(), Phone10()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        isDefaultControlName: FormControl<int>(
            value: addressFormModel?.isDefault,
            validators: [Required()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        labelControlName: FormControl<String>(
            value: addressFormModel?.label,
            validators: [],
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

class ReactiveAddressFormModelFormArrayBuilder<
    ReactiveAddressFormModelFormArrayBuilderT> extends StatelessWidget {
  const ReactiveAddressFormModelFormArrayBuilder({
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

  final FormArray<ReactiveAddressFormModelFormArrayBuilderT>? formControl;

  final FormArray<ReactiveAddressFormModelFormArrayBuilderT>? Function(
      AddressFormModelForm formModel)? control;

  final Widget Function(BuildContext context, List<Widget> itemList,
      AddressFormModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      FormControl<ReactiveAddressFormModelFormArrayBuilderT> control,
      ReactiveAddressFormModelFormArrayBuilderT? item,
      AddressFormModelForm formModel) itemBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  final bool Function(
          FormControl<ReactiveAddressFormModelFormArrayBuilderT> control)?
      controlFilter;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveAddressFormModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final builder = this.builder;
    final itemBuilder = this.itemBuilder;

    return ReactiveFormArrayItemBuilder<
        ReactiveAddressFormModelFormArrayBuilderT>(
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

class ReactiveAddressFormModelFormArrayBuilder2<
    ReactiveAddressFormModelFormArrayBuilderT> extends StatelessWidget {
  const ReactiveAddressFormModelFormArrayBuilder2({
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

  final FormArray<ReactiveAddressFormModelFormArrayBuilderT>? formControl;

  final FormArray<ReactiveAddressFormModelFormArrayBuilderT>? Function(
      AddressFormModelForm formModel)? control;

  final Widget Function(
      ({
        BuildContext context,
        List<Widget> itemList,
        AddressFormModelForm formModel
      }) params)? builder;

  final Widget Function(
      ({
        BuildContext context,
        int i,
        FormControl<ReactiveAddressFormModelFormArrayBuilderT> control,
        ReactiveAddressFormModelFormArrayBuilderT? item,
        AddressFormModelForm formModel
      }) params) itemBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  final bool Function(
          FormControl<ReactiveAddressFormModelFormArrayBuilderT> control)?
      controlFilter;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveAddressFormModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final builder = this.builder;
    final itemBuilder = this.itemBuilder;

    return ReactiveFormArrayItemBuilder<
        ReactiveAddressFormModelFormArrayBuilderT>(
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

class ReactiveAddressFormModelFormFormGroupArrayBuilder<
        ReactiveAddressFormModelFormFormGroupArrayBuilderT>
    extends StatelessWidget {
  const ReactiveAddressFormModelFormFormGroupArrayBuilder({
    Key? key,
    this.extended,
    this.getExtended,
    this.builder,
    required this.itemBuilder,
  })  : assert(extended != null || getExtended != null,
            "You have to specify `control` or `formControl`!"),
        super(key: key);

  final ExtendedControl<List<Map<String, Object?>?>,
      List<ReactiveAddressFormModelFormFormGroupArrayBuilderT>>? extended;

  final ExtendedControl<List<Map<String, Object?>?>,
          List<ReactiveAddressFormModelFormFormGroupArrayBuilderT>>
      Function(AddressFormModelForm formModel)? getExtended;

  final Widget Function(BuildContext context, List<Widget> itemList,
      AddressFormModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      ReactiveAddressFormModelFormFormGroupArrayBuilderT? item,
      AddressFormModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveAddressFormModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final value = (extended ?? getExtended?.call(formModel))!;

    return StreamBuilder<List<Map<String, Object?>?>?>(
      stream: value.control.valueChanges,
      builder: (context, snapshot) {
        final itemList = (value.value() ??
                <ReactiveAddressFormModelFormFormGroupArrayBuilderT>[])
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
