// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file:

part of 'kyc_information_confirm_forms.dart';

// **************************************************************************
// ReactiveFormsGenerator
// **************************************************************************

class ReactiveKycInformationConfirmModelFormConsumer extends StatelessWidget {
  const ReactiveKycInformationConfirmModelFormConsumer({
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final Widget? child;

  final Widget Function(BuildContext context,
      KycInformationConfirmModelForm formModel, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveKycInformationConfirmModelForm.of(context);

    if (formModel is! KycInformationConfirmModelForm) {
      throw FormControlParentNotFoundException(this);
    }
    return builder(context, formModel, child);
  }
}

class KycInformationConfirmModelFormInheritedStreamer
    extends InheritedStreamer<dynamic> {
  const KycInformationConfirmModelFormInheritedStreamer({
    Key? key,
    required this.form,
    required Stream<dynamic> stream,
    required Widget child,
  }) : super(
          stream,
          child,
          key: key,
        );

  final KycInformationConfirmModelForm form;
}

class ReactiveKycInformationConfirmModelForm extends StatelessWidget {
  const ReactiveKycInformationConfirmModelForm({
    Key? key,
    required this.form,
    required this.child,
    this.canPop,
    this.onPopInvoked,
  }) : super(key: key);

  final Widget child;

  final KycInformationConfirmModelForm form;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

  static KycInformationConfirmModelForm? of(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<
              KycInformationConfirmModelFormInheritedStreamer>()
          ?.form;
    }

    final element = context.getElementForInheritedWidgetOfExactType<
        KycInformationConfirmModelFormInheritedStreamer>();
    return element == null
        ? null
        : (element.widget as KycInformationConfirmModelFormInheritedStreamer)
            .form;
  }

  @override
  Widget build(BuildContext context) {
    return KycInformationConfirmModelFormInheritedStreamer(
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

extension ReactiveReactiveKycInformationConfirmModelFormExt on BuildContext {
  KycInformationConfirmModelForm? kycInformationConfirmModelFormWatch() =>
      ReactiveKycInformationConfirmModelForm.of(this);

  KycInformationConfirmModelForm? kycInformationConfirmModelFormRead() =>
      ReactiveKycInformationConfirmModelForm.of(this, listen: false);
}

class KycInformationConfirmModelFormBuilder extends StatefulWidget {
  const KycInformationConfirmModelFormBuilder({
    Key? key,
    this.model,
    this.child,
    this.canPop,
    this.onPopInvoked,
    required this.builder,
    this.initState,
  }) : super(key: key);

  final KycInformationConfirmModel? model;

  final Widget? child;

  final bool Function(FormGroup formGroup)? canPop;

  final void Function(FormGroup formGroup, bool didPop)? onPopInvoked;

  final Widget Function(BuildContext context,
      KycInformationConfirmModelForm formModel, Widget? child) builder;

  final void Function(
          BuildContext context, KycInformationConfirmModelForm formModel)?
      initState;

  @override
  _KycInformationConfirmModelFormBuilderState createState() =>
      _KycInformationConfirmModelFormBuilderState();
}

class _KycInformationConfirmModelFormBuilderState
    extends State<KycInformationConfirmModelFormBuilder> {
  late KycInformationConfirmModelForm _formModel;

  @override
  void initState() {
    _formModel = KycInformationConfirmModelForm(
        KycInformationConfirmModelForm.formElements(widget.model), null);

    if (_formModel.form.disabled) {
      _formModel.form.markAsDisabled();
    }

    widget.initState?.call(context, _formModel);

    super.initState();
  }

  @override
  void didUpdateWidget(
      covariant KycInformationConfirmModelFormBuilder oldWidget) {
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
    return ReactiveKycInformationConfirmModelForm(
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

class KycInformationConfirmModelForm
    implements FormModel<KycInformationConfirmModel> {
  KycInformationConfirmModelForm(
    this.form,
    this.path,
  );

  static const String typeControlName = "type";

  static const String typeTextControlName = "typeText";

  static const String idNumberControlName = "idNumber";

  static const String firstNameControlName = "firstName";

  static const String middleNameControlName = "middleName";

  static const String lastNameControlName = "lastName";

  static const String realNameControlName = "realName";

  static const String genderControlName = "gender";

  static const String birthdayControlName = "birthday";

  static const String expiryDateControlName = "expiryDate";

  static const String countryCodeControlName = "countryCode";

  static const String provinceControlName = "province";

  static const String cityControlName = "city";

  static const String barangayControlName = "barangay";

  static const String postalCodeControlName = "postalCode";

  static const String addressControlName = "address";

  final FormGroup form;

  final String? path;

  final Map<String, bool> _disabled = {};

  String typeControlPath() => pathBuilder(typeControlName);

  String typeTextControlPath() => pathBuilder(typeTextControlName);

  String idNumberControlPath() => pathBuilder(idNumberControlName);

  String firstNameControlPath() => pathBuilder(firstNameControlName);

  String middleNameControlPath() => pathBuilder(middleNameControlName);

  String lastNameControlPath() => pathBuilder(lastNameControlName);

  String realNameControlPath() => pathBuilder(realNameControlName);

  String genderControlPath() => pathBuilder(genderControlName);

  String birthdayControlPath() => pathBuilder(birthdayControlName);

  String expiryDateControlPath() => pathBuilder(expiryDateControlName);

  String countryCodeControlPath() => pathBuilder(countryCodeControlName);

  String provinceControlPath() => pathBuilder(provinceControlName);

  String cityControlPath() => pathBuilder(cityControlName);

  String barangayControlPath() => pathBuilder(barangayControlName);

  String postalCodeControlPath() => pathBuilder(postalCodeControlName);

  String addressControlPath() => pathBuilder(addressControlName);

  int get _typeValue => typeControl.value as int;

  String get _typeTextValue => typeTextControl.value ?? "UNKNOWN";

  String get _idNumberValue => idNumberControl.value ?? "";

  String get _firstNameValue => firstNameControl.value ?? "";

  String? get _middleNameValue => middleNameControl?.value;

  String get _lastNameValue => lastNameControl.value ?? "";

  String get _realNameValue => realNameControl.value ?? "";

  String get _genderValue => genderControl.value ?? "MALE";

  String get _birthdayValue => birthdayControl.value ?? "";

  String? get _expiryDateValue => expiryDateControl?.value;

  int get _countryCodeValue => countryCodeControl.value as int;

  int? get _provinceValue => provinceControl?.value;

  int? get _cityValue => cityControl?.value;

  int? get _barangayValue => barangayControl?.value;

  int? get _postalCodeValue => postalCodeControl?.value;

  String get _addressValue => addressControl.value ?? "";

  bool get containsType {
    try {
      form.control(typeControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsTypeText {
    try {
      form.control(typeTextControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsIdNumber {
    try {
      form.control(idNumberControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

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

  bool get containsRealName {
    try {
      form.control(realNameControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsGender {
    try {
      form.control(genderControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsBirthday {
    try {
      form.control(birthdayControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsExpiryDate {
    try {
      form.control(expiryDateControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsCountryCode {
    try {
      form.control(countryCodeControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsProvince {
    try {
      form.control(provinceControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsCity {
    try {
      form.control(cityControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get containsBarangay {
    try {
      form.control(barangayControlPath());
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

  bool get containsAddress {
    try {
      form.control(addressControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  Object? get typeErrors => typeControl.errors;

  Object? get typeTextErrors => typeTextControl.errors;

  Object? get idNumberErrors => idNumberControl.errors;

  Object? get firstNameErrors => firstNameControl.errors;

  Object? get middleNameErrors => middleNameControl?.errors;

  Object? get lastNameErrors => lastNameControl.errors;

  Object? get realNameErrors => realNameControl.errors;

  Object? get genderErrors => genderControl.errors;

  Object? get birthdayErrors => birthdayControl.errors;

  Object? get expiryDateErrors => expiryDateControl?.errors;

  Object? get countryCodeErrors => countryCodeControl.errors;

  Object? get provinceErrors => provinceControl?.errors;

  Object? get cityErrors => cityControl?.errors;

  Object? get barangayErrors => barangayControl?.errors;

  Object? get postalCodeErrors => postalCodeControl?.errors;

  Object? get addressErrors => addressControl.errors;

  void get typeFocus => form.focus(typeControlPath());

  void get typeTextFocus => form.focus(typeTextControlPath());

  void get idNumberFocus => form.focus(idNumberControlPath());

  void get firstNameFocus => form.focus(firstNameControlPath());

  void get middleNameFocus => form.focus(middleNameControlPath());

  void get lastNameFocus => form.focus(lastNameControlPath());

  void get realNameFocus => form.focus(realNameControlPath());

  void get genderFocus => form.focus(genderControlPath());

  void get birthdayFocus => form.focus(birthdayControlPath());

  void get expiryDateFocus => form.focus(expiryDateControlPath());

  void get countryCodeFocus => form.focus(countryCodeControlPath());

  void get provinceFocus => form.focus(provinceControlPath());

  void get cityFocus => form.focus(cityControlPath());

  void get barangayFocus => form.focus(barangayControlPath());

  void get postalCodeFocus => form.focus(postalCodeControlPath());

  void get addressFocus => form.focus(addressControlPath());

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

  void expiryDateRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsExpiryDate) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          expiryDateControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            expiryDateControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  void provinceRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsProvince) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          provinceControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            provinceControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  void cityRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsCity) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          cityControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            cityControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  void barangayRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsBarangay) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          barangayControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            barangayControlName,
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

  void typeValueUpdate(
    int value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    typeControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void typeTextValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    typeTextControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void idNumberValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    idNumberControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void firstNameValueUpdate(
    String value, {
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
    middleNameControl?.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void lastNameValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    lastNameControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void realNameValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    realNameControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void genderValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    genderControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void birthdayValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    birthdayControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void expiryDateValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    expiryDateControl?.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void countryCodeValueUpdate(
    int value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    countryCodeControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void provinceValueUpdate(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    provinceControl?.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void cityValueUpdate(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    cityControl?.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void barangayValueUpdate(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    barangayControl?.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void postalCodeValueUpdate(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    postalCodeControl?.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void addressValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    addressControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void typeValuePatch(
    int value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    typeControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void typeTextValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    typeTextControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void idNumberValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    idNumberControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void firstNameValuePatch(
    String value, {
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
    middleNameControl?.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void lastNameValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    lastNameControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void realNameValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    realNameControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void genderValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    genderControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void birthdayValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    birthdayControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void expiryDateValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    expiryDateControl?.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void countryCodeValuePatch(
    int value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    countryCodeControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void provinceValuePatch(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    provinceControl?.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void cityValuePatch(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    cityControl?.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void barangayValuePatch(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    barangayControl?.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void postalCodeValuePatch(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    postalCodeControl?.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void addressValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    addressControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void typeValueReset(
    int value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      typeControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void typeTextValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      typeTextControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void idNumberValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      idNumberControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void firstNameValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      firstNameControl.reset(
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
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      lastNameControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void realNameValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      realNameControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void genderValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      genderControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void birthdayValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      birthdayControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void expiryDateValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      expiryDateControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void countryCodeValueReset(
    int value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      countryCodeControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void provinceValueReset(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      provinceControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void cityValueReset(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      cityControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void barangayValueReset(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      barangayControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void postalCodeValueReset(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      postalCodeControl?.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  void addressValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      addressControl.reset(
          value: value, updateParent: updateParent, emitEvent: emitEvent);

  FormControl<int> get typeControl =>
      form.control(typeControlPath()) as FormControl<int>;

  FormControl<String> get typeTextControl =>
      form.control(typeTextControlPath()) as FormControl<String>;

  FormControl<String> get idNumberControl =>
      form.control(idNumberControlPath()) as FormControl<String>;

  FormControl<String> get firstNameControl =>
      form.control(firstNameControlPath()) as FormControl<String>;

  FormControl<String>? get middleNameControl => containsMiddleName
      ? form.control(middleNameControlPath()) as FormControl<String>?
      : null;

  FormControl<String> get lastNameControl =>
      form.control(lastNameControlPath()) as FormControl<String>;

  FormControl<String> get realNameControl =>
      form.control(realNameControlPath()) as FormControl<String>;

  FormControl<String> get genderControl =>
      form.control(genderControlPath()) as FormControl<String>;

  FormControl<String> get birthdayControl =>
      form.control(birthdayControlPath()) as FormControl<String>;

  FormControl<String>? get expiryDateControl => containsExpiryDate
      ? form.control(expiryDateControlPath()) as FormControl<String>?
      : null;

  FormControl<int> get countryCodeControl =>
      form.control(countryCodeControlPath()) as FormControl<int>;

  FormControl<int>? get provinceControl => containsProvince
      ? form.control(provinceControlPath()) as FormControl<int>?
      : null;

  FormControl<int>? get cityControl => containsCity
      ? form.control(cityControlPath()) as FormControl<int>?
      : null;

  FormControl<int>? get barangayControl => containsBarangay
      ? form.control(barangayControlPath()) as FormControl<int>?
      : null;

  FormControl<int>? get postalCodeControl => containsPostalCode
      ? form.control(postalCodeControlPath()) as FormControl<int>?
      : null;

  FormControl<String> get addressControl =>
      form.control(addressControlPath()) as FormControl<String>;

  void typeSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      typeControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      typeControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void typeTextSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      typeTextControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      typeTextControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void idNumberSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      idNumberControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      idNumberControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

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

  void realNameSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      realNameControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      realNameControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void genderSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      genderControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      genderControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void birthdaySetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      birthdayControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      birthdayControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void expiryDateSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      expiryDateControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      expiryDateControl?.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void countryCodeSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      countryCodeControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      countryCodeControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void provinceSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      provinceControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      provinceControl?.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void citySetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      cityControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      cityControl?.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void barangaySetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      barangayControl?.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      barangayControl?.markAsEnabled(
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

  void addressSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      addressControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      addressControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  @override
  KycInformationConfirmModel get model {
    final isValid = !currentForm.hasErrors && currentForm.errors.isEmpty;

    if (!isValid) {
      debugPrintStack(
          label:
              '[${path ?? 'KycInformationConfirmModelForm'}]\n┗━ Avoid calling `model` on invalid form. Possible exceptions for non-nullable fields which should be guarded by `required` validator.');
    }
    return KycInformationConfirmModel(
        type: _typeValue,
        typeText: _typeTextValue,
        idNumber: _idNumberValue,
        firstName: _firstNameValue,
        middleName: _middleNameValue,
        lastName: _lastNameValue,
        realName: _realNameValue,
        gender: _genderValue,
        birthday: _birthdayValue,
        expiryDate: _expiryDateValue,
        countryCode: _countryCodeValue,
        province: _provinceValue,
        city: _cityValue,
        barangay: _barangayValue,
        postalCode: _postalCodeValue,
        address: _addressValue);
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
    required void Function(KycInformationConfirmModel model) onValid,
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
    KycInformationConfirmModel? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.updateValue(
          KycInformationConfirmModelForm.formElements(value).rawValue,
          updateParent: updateParent,
          emitEvent: emitEvent);

  @override
  void reset({
    KycInformationConfirmModel? value,
    bool updateParent = true,
    bool emitEvent = true,
  }) =>
      form.reset(
          value: value != null ? formElements(value).rawValue : null,
          updateParent: updateParent,
          emitEvent: emitEvent);

  String pathBuilder(String? pathItem) =>
      [path, pathItem].whereType<String>().join(".");

  static FormGroup formElements(
          KycInformationConfirmModel? kycInformationConfirmModel) =>
      FormGroup({
        typeControlName: FormControl<int>(
            value: kycInformationConfirmModel?.type,
            validators: [],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        typeTextControlName: FormControl<String>(
            value: kycInformationConfirmModel?.typeText,
            validators: [],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        idNumberControlName: FormControl<String>(
            value: kycInformationConfirmModel?.idNumber,
            validators: [NonEmpty(), IdNumberValidator()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        firstNameControlName: FormControl<String>(
            value: kycInformationConfirmModel?.firstName,
            validators: [NonEmpty(), RealName()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        middleNameControlName: FormControl<String>(
            value: kycInformationConfirmModel?.middleName,
            validators: [RealName()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        lastNameControlName: FormControl<String>(
            value: kycInformationConfirmModel?.lastName,
            validators: [NonEmpty(), RealName()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        realNameControlName: FormControl<String>(
            value: kycInformationConfirmModel?.realName,
            validators: [],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        genderControlName: FormControl<String>(
            value: kycInformationConfirmModel?.gender,
            validators: [NonEmpty()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        birthdayControlName: FormControl<String>(
            value: kycInformationConfirmModel?.birthday,
            validators: [NonEmpty()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        expiryDateControlName: FormControl<String>(
            value: kycInformationConfirmModel?.expiryDate,
            validators: [],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        countryCodeControlName: FormControl<int>(
            value: kycInformationConfirmModel?.countryCode,
            validators: [],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        provinceControlName: FormControl<int>(
            value: kycInformationConfirmModel?.province,
            validators: [Required()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        cityControlName: FormControl<int>(
            value: kycInformationConfirmModel?.city,
            validators: [Required()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        barangayControlName: FormControl<int>(
            value: kycInformationConfirmModel?.barangay,
            validators: [Required()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        postalCodeControlName: FormControl<int>(
            value: kycInformationConfirmModel?.postalCode,
            validators: [Required(), PostalCode()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        addressControlName: FormControl<String>(
            value: kycInformationConfirmModel?.address,
            validators: [NonEmpty()],
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

class ReactiveKycInformationConfirmModelFormArrayBuilder<
        ReactiveKycInformationConfirmModelFormArrayBuilderT>
    extends StatelessWidget {
  const ReactiveKycInformationConfirmModelFormArrayBuilder({
    Key? key,
    this.control,
    this.formControl,
    this.builder,
    required this.itemBuilder,
  })  : assert(control != null || formControl != null,
            "You have to specify `control` or `formControl`!"),
        super(key: key);

  final FormArray<ReactiveKycInformationConfirmModelFormArrayBuilderT>?
      formControl;

  final FormArray<ReactiveKycInformationConfirmModelFormArrayBuilderT>?
      Function(KycInformationConfirmModelForm formModel)? control;

  final Widget Function(BuildContext context, List<Widget> itemList,
      KycInformationConfirmModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      ReactiveKycInformationConfirmModelFormArrayBuilderT? item,
      KycInformationConfirmModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveKycInformationConfirmModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    return ReactiveFormArray<
        ReactiveKycInformationConfirmModelFormArrayBuilderT>(
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

class ReactiveKycInformationConfirmModelFormFormGroupArrayBuilder<
        ReactiveKycInformationConfirmModelFormFormGroupArrayBuilderT>
    extends StatelessWidget {
  const ReactiveKycInformationConfirmModelFormFormGroupArrayBuilder({
    Key? key,
    this.extended,
    this.getExtended,
    this.builder,
    required this.itemBuilder,
  })  : assert(extended != null || getExtended != null,
            "You have to specify `control` or `formControl`!"),
        super(key: key);

  final ExtendedControl<List<Map<String, Object?>?>,
          List<ReactiveKycInformationConfirmModelFormFormGroupArrayBuilderT>>?
      extended;

  final ExtendedControl<List<Map<String, Object?>?>,
          List<ReactiveKycInformationConfirmModelFormFormGroupArrayBuilderT>>
      Function(KycInformationConfirmModelForm formModel)? getExtended;

  final Widget Function(BuildContext context, List<Widget> itemList,
      KycInformationConfirmModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      ReactiveKycInformationConfirmModelFormFormGroupArrayBuilderT? item,
      KycInformationConfirmModelForm formModel) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveKycInformationConfirmModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final value = (extended ?? getExtended?.call(formModel))!;

    return StreamBuilder<List<Map<String, Object?>?>?>(
      stream: value.control.valueChanges,
      builder: (context, snapshot) {
        final itemList = (value.value() ??
                <ReactiveKycInformationConfirmModelFormFormGroupArrayBuilderT>[])
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
