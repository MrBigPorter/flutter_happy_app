// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

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
    this.onPopInvokedWithResult,
  }) : super(key: key);

  final Widget child;

  final KycInformationConfirmModelForm form;

  final bool Function(FormGroup formGroup)? canPop;

  final ReactiveFormPopInvokedWithResultCallback<dynamic>?
      onPopInvokedWithResult;

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
        onPopInvokedWithResult: onPopInvokedWithResult,
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
    this.onPopInvokedWithResult,
    required this.builder,
    this.initState,
  }) : super(key: key);

  final KycInformationConfirmModel? model;

  final Widget? child;

  final bool Function(FormGroup formGroup)? canPop;

  final ReactiveFormPopInvokedWithResultCallback<dynamic>?
      onPopInvokedWithResult;

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

  StreamSubscription<LogRecord>? _logSubscription;

  @override
  void initState() {
    _formModel = KycInformationConfirmModelForm(
        KycInformationConfirmModelForm.formElements(widget.model), null);

    if (_formModel.form.disabled) {
      _formModel.form.markAsDisabled();
    }

    widget.initState?.call(context, _formModel);

    _logSubscription =
        _logKycInformationConfirmModelForm.onRecord.listen((LogRecord e) {
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
    _logSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveKycInformationConfirmModelForm(
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

final _logKycInformationConfirmModelForm =
    Logger.detached('KycInformationConfirmModelForm');

class KycInformationConfirmModelForm
    implements
        FormModel<KycInformationConfirmModel, KycInformationConfirmModel> {
  KycInformationConfirmModelForm(
    this.form,
    this.path,
  );

  static const String idTypeControlName = "idType";

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

  static const String idCardFrontControlName = "idCardFront";

  static const String idCardBackControlName = "idCardBack";

  static const String faceImageControlName = "faceImage";

  static const String livenessScoreControlName = "livenessScore";

  final FormGroup form;

  final String? path;

  final Map<String, bool> _disabled = {};

  String idTypeControlPath() => pathBuilder(idTypeControlName);

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

  String idCardFrontControlPath() => pathBuilder(idCardFrontControlName);

  String idCardBackControlPath() => pathBuilder(idCardBackControlName);

  String faceImageControlPath() => pathBuilder(faceImageControlName);

  String livenessScoreControlPath() => pathBuilder(livenessScoreControlName);

  int get _idTypeValue => idTypeControl.value ?? 1;

  String get _idNumberValue => idNumberControl.value ?? '';

  String get _firstNameValue => firstNameControl.value ?? '';

  String? get _middleNameValue => middleNameControl.value;

  String get _lastNameValue => lastNameControl.value ?? '';

  String? get _realNameValue => realNameControl.value;

  String get _genderValue => genderControl.value ?? 'MALE';

  String get _birthdayValue => birthdayControl.value ?? '';

  String? get _expiryDateValue => expiryDateControl.value;

  int? get _countryCodeValue => countryCodeControl.value;

  String get _provinceValue => provinceControl.value ?? '';

  String get _cityValue => cityControl.value ?? '';

  String get _barangayValue => barangayControl.value ?? '';

  String get _postalCodeValue => postalCodeControl.value ?? '';

  String get _addressValue => addressControl.value ?? '';

  String get _idCardFrontValue => idCardFrontControl.value ?? '';

  String? get _idCardBackValue => idCardBackControl.value;

  String? get _faceImageValue => faceImageControl.value;

  double? get _livenessScoreValue => livenessScoreControl.value;

  int get _idTypeRawValue => idTypeControl.value ?? 1;

  String get _idNumberRawValue => idNumberControl.value ?? '';

  String get _firstNameRawValue => firstNameControl.value ?? '';

  String? get _middleNameRawValue => middleNameControl.value;

  String get _lastNameRawValue => lastNameControl.value ?? '';

  String? get _realNameRawValue => realNameControl.value;

  String get _genderRawValue => genderControl.value ?? 'MALE';

  String get _birthdayRawValue => birthdayControl.value ?? '';

  String? get _expiryDateRawValue => expiryDateControl.value;

  int? get _countryCodeRawValue => countryCodeControl.value;

  String get _provinceRawValue => provinceControl.value ?? '';

  String get _cityRawValue => cityControl.value ?? '';

  String get _barangayRawValue => barangayControl.value ?? '';

  String get _postalCodeRawValue => postalCodeControl.value ?? '';

  String get _addressRawValue => addressControl.value ?? '';

  String get _idCardFrontRawValue => idCardFrontControl.value ?? '';

  String? get _idCardBackRawValue => idCardBackControl.value;

  String? get _faceImageRawValue => faceImageControl.value;

  double? get _livenessScoreRawValue => livenessScoreControl.value;

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsIdType {
    try {
      form.control(idTypeControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsIdNumber {
    try {
      form.control(idNumberControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

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
  bool get containsRealName {
    try {
      form.control(realNameControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsGender {
    try {
      form.control(genderControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsBirthday {
    try {
      form.control(birthdayControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsExpiryDate {
    try {
      form.control(expiryDateControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsCountryCode {
    try {
      form.control(countryCodeControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsProvince {
    try {
      form.control(provinceControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsCity {
    try {
      form.control(cityControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsBarangay {
    try {
      form.control(barangayControlPath());
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
  bool get containsAddress {
    try {
      form.control(addressControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsIdCardFront {
    try {
      form.control(idCardFrontControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsIdCardBack {
    try {
      form.control(idCardBackControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsFaceImage {
    try {
      form.control(faceImageControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  @Deprecated(
      'Generator completely wraps the form and ensures at startup that all controls are present inside the form so we do not need this additional step')
  bool get containsLivenessScore {
    try {
      form.control(livenessScoreControlPath());
      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, Object> get idTypeErrors => idTypeControl.errors;

  Map<String, Object> get idNumberErrors => idNumberControl.errors;

  Map<String, Object> get firstNameErrors => firstNameControl.errors;

  Map<String, Object>? get middleNameErrors => middleNameControl.errors;

  Map<String, Object> get lastNameErrors => lastNameControl.errors;

  Map<String, Object>? get realNameErrors => realNameControl.errors;

  Map<String, Object> get genderErrors => genderControl.errors;

  Map<String, Object> get birthdayErrors => birthdayControl.errors;

  Map<String, Object>? get expiryDateErrors => expiryDateControl.errors;

  Map<String, Object>? get countryCodeErrors => countryCodeControl.errors;

  Map<String, Object> get provinceErrors => provinceControl.errors;

  Map<String, Object> get cityErrors => cityControl.errors;

  Map<String, Object> get barangayErrors => barangayControl.errors;

  Map<String, Object> get postalCodeErrors => postalCodeControl.errors;

  Map<String, Object> get addressErrors => addressControl.errors;

  Map<String, Object> get idCardFrontErrors => idCardFrontControl.errors;

  Map<String, Object>? get idCardBackErrors => idCardBackControl.errors;

  Map<String, Object>? get faceImageErrors => faceImageControl.errors;

  Map<String, Object>? get livenessScoreErrors => livenessScoreControl.errors;

  void get idTypeFocus => form.focus(idTypeControlPath());

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

  void get idCardFrontFocus => form.focus(idCardFrontControlPath());

  void get idCardBackFocus => form.focus(idCardBackControlPath());

  void get faceImageFocus => form.focus(faceImageControlPath());

  void get livenessScoreFocus => form.focus(livenessScoreControlPath());

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
  void realNameRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsRealName) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          realNameControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            realNameControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
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

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void countryCodeRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsCountryCode) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          countryCodeControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            countryCodeControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void idCardBackRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsIdCardBack) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          idCardBackControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            idCardBackControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void faceImageRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsFaceImage) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          faceImageControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            faceImageControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  @Deprecated(
      'Generator completely wraps the form so manual fields removal could lead to unexpected crashes')
  void livenessScoreRemove({
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (containsLivenessScore) {
      final controlPath = path;
      if (controlPath == null) {
        form.removeControl(
          livenessScoreControlName,
          updateParent: updateParent,
          emitEvent: emitEvent,
        );
      } else {
        final formGroup = form.control(controlPath);

        if (formGroup is FormGroup) {
          formGroup.removeControl(
            livenessScoreControlName,
            updateParent: updateParent,
            emitEvent: emitEvent,
          );
        }
      }
    }
  }

  void idTypeValueUpdate(
    int value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    idTypeControl.updateValue(value,
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
    middleNameControl.updateValue(value,
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
    String? value, {
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
    expiryDateControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void countryCodeValueUpdate(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    countryCodeControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void provinceValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    provinceControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void cityValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    cityControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void barangayValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    barangayControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void postalCodeValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    postalCodeControl.updateValue(value,
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

  void idCardFrontValueUpdate(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    idCardFrontControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void idCardBackValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    idCardBackControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void faceImageValueUpdate(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    faceImageControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void livenessScoreValueUpdate(
    double? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    livenessScoreControl.updateValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void idTypeValuePatch(
    int value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    idTypeControl.patchValue(value,
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
    middleNameControl.patchValue(value,
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
    String? value, {
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
    expiryDateControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void countryCodeValuePatch(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    countryCodeControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void provinceValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    provinceControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void cityValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    cityControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void barangayValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    barangayControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void postalCodeValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    postalCodeControl.patchValue(value,
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

  void idCardFrontValuePatch(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    idCardFrontControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void idCardBackValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    idCardBackControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void faceImageValuePatch(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    faceImageControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void livenessScoreValuePatch(
    double? value, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    livenessScoreControl.patchValue(value,
        updateParent: updateParent, emitEvent: emitEvent);
  }

  void idTypeValueReset(
    int value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      idTypeControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void idNumberValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      idNumberControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void firstNameValueReset(
    String value, {
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
    String value, {
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

  void realNameValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      realNameControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void genderValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      genderControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void birthdayValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      birthdayControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void expiryDateValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      expiryDateControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void countryCodeValueReset(
    int? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      countryCodeControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void provinceValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      provinceControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void cityValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      cityControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void barangayValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      barangayControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void postalCodeValueReset(
    String value, {
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

  void addressValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      addressControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void idCardFrontValueReset(
    String value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      idCardFrontControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void idCardBackValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      idCardBackControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void faceImageValueReset(
    String? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      faceImageControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  void livenessScoreValueReset(
    double? value, {
    bool updateParent = true,
    bool emitEvent = true,
    bool removeFocus = false,
    bool? disabled,
  }) =>
      livenessScoreControl.reset(
        value: value,
        updateParent: updateParent,
        emitEvent: emitEvent,
        removeFocus: removeFocus,
        disabled: disabled,
      );

  FormControl<int> get idTypeControl =>
      form.control(idTypeControlPath()) as FormControl<int>;

  FormControl<String> get idNumberControl =>
      form.control(idNumberControlPath()) as FormControl<String>;

  FormControl<String> get firstNameControl =>
      form.control(firstNameControlPath()) as FormControl<String>;

  FormControl<String> get middleNameControl =>
      form.control(middleNameControlPath()) as FormControl<String>;

  FormControl<String> get lastNameControl =>
      form.control(lastNameControlPath()) as FormControl<String>;

  FormControl<String> get realNameControl =>
      form.control(realNameControlPath()) as FormControl<String>;

  FormControl<String> get genderControl =>
      form.control(genderControlPath()) as FormControl<String>;

  FormControl<String> get birthdayControl =>
      form.control(birthdayControlPath()) as FormControl<String>;

  FormControl<String> get expiryDateControl =>
      form.control(expiryDateControlPath()) as FormControl<String>;

  FormControl<int> get countryCodeControl =>
      form.control(countryCodeControlPath()) as FormControl<int>;

  FormControl<String> get provinceControl =>
      form.control(provinceControlPath()) as FormControl<String>;

  FormControl<String> get cityControl =>
      form.control(cityControlPath()) as FormControl<String>;

  FormControl<String> get barangayControl =>
      form.control(barangayControlPath()) as FormControl<String>;

  FormControl<String> get postalCodeControl =>
      form.control(postalCodeControlPath()) as FormControl<String>;

  FormControl<String> get addressControl =>
      form.control(addressControlPath()) as FormControl<String>;

  FormControl<String> get idCardFrontControl =>
      form.control(idCardFrontControlPath()) as FormControl<String>;

  FormControl<String> get idCardBackControl =>
      form.control(idCardBackControlPath()) as FormControl<String>;

  FormControl<String> get faceImageControl =>
      form.control(faceImageControlPath()) as FormControl<String>;

  FormControl<double> get livenessScoreControl =>
      form.control(livenessScoreControlPath()) as FormControl<double>;

  void idTypeSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      idTypeControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      idTypeControl.markAsEnabled(
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
      expiryDateControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      expiryDateControl.markAsEnabled(
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
      provinceControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      provinceControl.markAsEnabled(
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
      cityControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      cityControl.markAsEnabled(
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
      barangayControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      barangayControl.markAsEnabled(
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

  void idCardFrontSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      idCardFrontControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      idCardFrontControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void idCardBackSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      idCardBackControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      idCardBackControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void faceImageSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      faceImageControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      faceImageControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  void livenessScoreSetDisabled(
    bool disabled, {
    bool updateParent = true,
    bool emitEvent = true,
  }) {
    if (disabled) {
      livenessScoreControl.markAsDisabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    } else {
      livenessScoreControl.markAsEnabled(
        updateParent: updateParent,
        emitEvent: emitEvent,
      );
    }
  }

  @override
  KycInformationConfirmModel get model {
    final isValid = !currentForm.hasErrors && currentForm.errors.isEmpty;

    if (!isValid) {
      _logKycInformationConfirmModelForm.warning(
        'Avoid calling `model` on invalid form.Possible exceptions for non-nullable fields which should be guarded by `required` validator.',
        null,
        StackTrace.current,
      );
    }
    return KycInformationConfirmModel(
        idType: _idTypeValue,
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
        address: _addressValue,
        idCardFront: _idCardFrontValue,
        idCardBack: _idCardBackValue,
        faceImage: _faceImageValue,
        livenessScore: _livenessScoreValue);
  }

  @override
  KycInformationConfirmModel get rawModel {
    return KycInformationConfirmModel(
        idType: _idTypeRawValue,
        idNumber: _idNumberRawValue,
        firstName: _firstNameRawValue,
        middleName: _middleNameRawValue,
        lastName: _lastNameRawValue,
        realName: _realNameRawValue,
        gender: _genderRawValue,
        birthday: _birthdayRawValue,
        expiryDate: _expiryDateRawValue,
        countryCode: _countryCodeRawValue,
        province: _provinceRawValue,
        city: _cityRawValue,
        barangay: _barangayRawValue,
        postalCode: _postalCodeRawValue,
        address: _addressRawValue,
        idCardFront: _idCardFrontRawValue,
        idCardBack: _idCardBackRawValue,
        faceImage: _faceImageRawValue,
        livenessScore: _livenessScoreRawValue);
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
  bool equalsTo(KycInformationConfirmModel? other) {
    final currentForm = this.currentForm;

    return const DeepCollectionEquality().equals(
      currentForm is FormControlCollection<dynamic>
          ? currentForm.rawValue
          : currentForm.value,
      KycInformationConfirmModelForm.formElements(other).rawValue,
    );
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
      _logKycInformationConfirmModelForm.info('Errors');
      _logKycInformationConfirmModelForm.info('┗━━ ${form.errors}');
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
        idTypeControlName: FormControl<int>(
            value: kycInformationConfirmModel?.idType,
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
        provinceControlName: FormControl<String>(
            value: kycInformationConfirmModel?.province,
            validators: [NonEmpty()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        cityControlName: FormControl<String>(
            value: kycInformationConfirmModel?.city,
            validators: [NonEmpty()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        barangayControlName: FormControl<String>(
            value: kycInformationConfirmModel?.barangay,
            validators: [NonEmpty()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        postalCodeControlName: FormControl<String>(
            value: kycInformationConfirmModel?.postalCode,
            validators: [NonEmpty()],
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
            touched: false),
        idCardFrontControlName: FormControl<String>(
            value: kycInformationConfirmModel?.idCardFront,
            validators: [NonEmpty()],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        idCardBackControlName: FormControl<String>(
            value: kycInformationConfirmModel?.idCardBack,
            validators: [],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        faceImageControlName: FormControl<String>(
            value: kycInformationConfirmModel?.faceImage,
            validators: [],
            asyncValidators: [],
            asyncValidatorsDebounceTime: 250,
            disabled: false,
            touched: false),
        livenessScoreControlName: FormControl<double>(
            value: kycInformationConfirmModel?.livenessScore,
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

class ReactiveKycInformationConfirmModelFormArrayBuilder<
        ReactiveKycInformationConfirmModelFormArrayBuilderT>
    extends StatelessWidget {
  const ReactiveKycInformationConfirmModelFormArrayBuilder({
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

  final FormArray<ReactiveKycInformationConfirmModelFormArrayBuilderT>?
      formControl;

  final FormArray<ReactiveKycInformationConfirmModelFormArrayBuilderT>?
      Function(KycInformationConfirmModelForm formModel)? control;

  final Widget Function(BuildContext context, List<Widget> itemList,
      KycInformationConfirmModelForm formModel)? builder;

  final Widget Function(
      BuildContext context,
      int i,
      FormControl<ReactiveKycInformationConfirmModelFormArrayBuilderT> control,
      ReactiveKycInformationConfirmModelFormArrayBuilderT? item,
      KycInformationConfirmModelForm formModel) itemBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  final bool Function(
      FormControl<ReactiveKycInformationConfirmModelFormArrayBuilderT>
          control)? controlFilter;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveKycInformationConfirmModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final builder = this.builder;
    final itemBuilder = this.itemBuilder;

    return ReactiveFormArrayItemBuilder<
        ReactiveKycInformationConfirmModelFormArrayBuilderT>(
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

class ReactiveKycInformationConfirmModelFormArrayBuilder2<
        ReactiveKycInformationConfirmModelFormArrayBuilderT>
    extends StatelessWidget {
  const ReactiveKycInformationConfirmModelFormArrayBuilder2({
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

  final FormArray<ReactiveKycInformationConfirmModelFormArrayBuilderT>?
      formControl;

  final FormArray<ReactiveKycInformationConfirmModelFormArrayBuilderT>?
      Function(KycInformationConfirmModelForm formModel)? control;

  final Widget Function(
      ({
        BuildContext context,
        List<Widget> itemList,
        KycInformationConfirmModelForm formModel
      }) params)? builder;

  final Widget Function(
      ({
        BuildContext context,
        int i,
        FormControl<
            ReactiveKycInformationConfirmModelFormArrayBuilderT> control,
        ReactiveKycInformationConfirmModelFormArrayBuilderT? item,
        KycInformationConfirmModelForm formModel
      }) params) itemBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  final bool Function(
      FormControl<ReactiveKycInformationConfirmModelFormArrayBuilderT>
          control)? controlFilter;

  @override
  Widget build(BuildContext context) {
    final formModel = ReactiveKycInformationConfirmModelForm.of(context);

    if (formModel == null) {
      throw FormControlParentNotFoundException(this);
    }

    final builder = this.builder;
    final itemBuilder = this.itemBuilder;

    return ReactiveFormArrayItemBuilder<
        ReactiveKycInformationConfirmModelFormArrayBuilderT>(
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
