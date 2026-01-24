// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file:

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
    this.onPopInvoked,
  }) : super(key: key);

  final Widget child;

  final AddressFormModelForm form;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

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
        onPopInvoked: onPopInvoked,
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
    this.onPopInvoked,
    required this.builder,
    this.initState,
  }) : super(key: key);

  final AddressFormModel? model;

  final Widget? child;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

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

  @override
  void initState() {
    _formModel = AddressFormModelForm(
        AddressFormModelForm.formElements(widget.model), null);

    if (_formModel.form.disabled) {
      _formModel.form.markAsDisabled();
    }

    widget.initState?.call(context, _formModel);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveAddressFormModelForm(
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

class AddressFormModelForm implements FormModel<AddressFormModel> {
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

  String? get _firstNameValue => firstNameControl?.value;

  String? get _middleNameValue => middleNameControl?.value;

  String? get _lastNameValue => lastNameControl?.value;

  String get _contactNameValue => contactNameControl.value ?? "";

  String get _fullAddressValue => fullAddressControl.value ?? "";

  int? get _provinceIdValue => provinceIdControl?.value;

  int? get _cityIdValue => cityIdControl?.value;

  int? get _barangayIdValue => barangayIdControl?.value;

  String? get _postalCodeValue => postalCodeControl?.value;

  String get _phoneValue => phoneControl.value ?? "";

  bool get _isDefaultValue => isDefaultControl.value as bool;

  String? get _labelValue => labelControl?.value;

  bool get containsFirstName {
    try {
      form.control(firstNameControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsMiddleName {
    try {
      form.control(middleNameControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsLastName {
    try {
      form.control(lastNameControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsContactName {
    try {
      form.control(contactNameControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsFullAddress {
    try {
      form.control(fullAddressControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsProvinceId {
    try {
      form.control(provinceIdControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsCityId {
    try {
      form.control(cityIdControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsBarangayId {
    try {
      form.control(barangayIdControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsPostalCode {
    try {
      form.control(postalCodeControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsPhone {
    try {
      form.control(phoneControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsIsDefault {
    try {
      form.control(isDefaultControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsLabel {
    try {
      form.control(labelControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  Object? get firstNameErrors => firstNameControl?.errors;

  Object? get middleNameErrors => middleNameControl?.errors;

  Object? get lastNameErrors => lastNameControl?.errors;

  Object? get contactNameErrors => contactNameControl.errors;

  Object? get fullAddressErrors => fullAddressControl.errors;

  Object? get provinceIdErrors => provinceIdControl?.errors;

  Object? get cityIdErrors => cityIdControl?.errors;

  Object? get barangayIdErrors => barangayIdControl?.errors;

  Object? get postalCodeErrors => postalCodeControl?.errors;

  Object? get phoneErrors => phoneControl.errors;

  Object? get isDefaultErrors => isDefaultControl.errors;

  Object? get labelErrors => labelControl?.errors;

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
    firstNameControl?.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void middleNameValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    middleNameControl?.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void lastNameValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    lastNameControl?.updateValue(value,
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
    provinceIdControl?.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void cityIdValueUpdate(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    cityIdControl?.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void barangayIdValueUpdate(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    barangayIdControl?.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void postalCodeValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    postalCodeControl?.updateValue(value,
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
    bool value, {
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
    labelControl?.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void firstNameValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    firstNameControl?.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void middleNameValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    middleNameControl?.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void lastNameValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    lastNameControl?.patchValue(value,
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
    provinceIdControl?.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void cityIdValuePatch(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    cityIdControl?.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void barangayIdValuePatch(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    barangayIdControl?.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void postalCodeValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    postalCodeControl?.patchValue(value,
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
    bool value, {
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
    labelControl?.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void firstNameValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      firstNameControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void middleNameValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      middleNameControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void lastNameValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      lastNameControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void contactNameValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      contactNameControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void fullAddressValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      fullAddressControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void provinceIdValueReset(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      provinceIdControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void cityIdValueReset(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      cityIdControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void barangayIdValueReset(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      barangayIdControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void postalCodeValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      postalCodeControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void phoneValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      phoneControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void isDefaultValueReset(
    bool value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      isDefaultControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void labelValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      labelControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  FormControl<String>? get firstNameControl => containsFirstName
      ? form.control(firstNameControlPath()) as FormControl<String>?
      : null;

  FormControl<String>? get middleNameControl => containsMiddleName
      ? form.control(middleNameControlPath()) as FormControl<String>?
      : null;

  FormControl<String>? get lastNameControl => containsLastName
      ? form.control(lastNameControlPath()) as FormControl<String>?
      : null;

  FormControl<String> get contactNameControl =>
      form.control(contactNameControlPath()) as FormControl<String>;

  FormControl<String> get fullAddressControl =>
      form.control(fullAddressControlPath()) as FormControl<String>;

  FormControl<int>? get provinceIdControl => containsProvinceId
      ? form.control(provinceIdControlPath()) as FormControl<int>?
      : null;

  FormControl<int>? get cityIdControl => containsCityId
      ? form.control(cityIdControlPath()) as FormControl<int>?
      : null;

  FormControl<int>? get barangayIdControl => containsBarangayId
      ? form.control(barangayIdControlPath()) as FormControl<int>?
      : null;

  FormControl<String>? get postalCodeControl => containsPostalCode
      ? form.control(postalCodeControlPath()) as FormControl<String>?
      : null;

  FormControl<String> get phoneControl =>
      form.control(phoneControlPath()) as FormControl<String>;

  FormControl<bool> get isDefaultControl =>
      form.control(isDefaultControlPath()) as FormControl<bool>;

  FormControl<String>? get labelControl => containsLabel
      ? form.control(labelControlPath()) as FormControl<String>?
      : null;

  void firstNameSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      firstNameControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      firstNameControl?.markAsEnabled(
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
      middleNameControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      middleNameControl?.markAsEnabled(
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
      lastNameControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      lastNameControl?.markAsEnabled(
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
      provinceIdControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      provinceIdControl?.markAsEnabled(
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
      cityIdControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      cityIdControl?.markAsEnabled(
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
      barangayIdControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      barangayIdControl?.markAsEnabled(
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
      postalCodeControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      postalCodeControl?.markAsEnabled(
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
      labelControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      labelControl?.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  @override
  AddressFormModel get model {
    final isValid = !currentForm.hasErrors && currentForm.errors.isEmpty;

    if (!isValid) {
      debugPrintStack(
          label:
              '[${path ?? 'AddressFormModelForm'}]\n┗━ Avoid calling `model` on invalid form. Possible exceptions for non-nullable fields which should be guarded by `required` validator.');
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
    required void Function(AddressFormModel model) onValid,
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
        isDefaultControlName: FormControl<bool>(
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
      ReactiveAddressFormModelFormArrayBuilderT? item,
      AddressFormModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveAddressFormModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    return ReactiveFormArray<ReactiveAddressFormModelFormArrayBuilderT>(
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
