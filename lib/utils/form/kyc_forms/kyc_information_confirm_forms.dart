import 'package:flutter_app/utils/form/validators.dart';
import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';

part 'kyc_information_confirm_forms.gform.dart';

@Rf()
class KycInformationConfirmModel {
  const KycInformationConfirmModel({
    @RfControl() this.type = 0,
    @RfControl() this.typeText = 'UNKNOWN',

    @RfControl(validators: [NonEmpty(), IdNumberValidator()])
    this.idNumber = '',

    @RfControl(validators: [NonEmpty(), RealName()])
    this.firstName = '',

    @RfControl(validators: [RealName()])
    this.middleName,

    @RfControl(validators: [NonEmpty(), RealName()])
    this.lastName = '',

    @RfControl() this.realName = '',

    @RfControl(validators: [NonEmpty()]) this.gender = 'MALE',
    @RfControl(validators: [NonEmpty()]) this.birthday = '',
    @RfControl() this.expiryDate,
    @RfControl() this.countryCode = 63,

    @RfControl(validators: [Required()]) this.province,
    @RfControl(validators: [Required()]) this.city,
    @RfControl(validators: [Required()]) this.barangay,
    @RfControl(validators: [Required(), PostalCode()]) this.postalCode,
    @RfControl(validators: [NonEmpty()]) this.address = '',
  });

  final int type;
  final String typeText;

  final String idNumber;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String realName;

  final String gender;
  final String birthday;
  final String? expiryDate;
  final int countryCode;

  final int? province;
  final int? city;
  final int? barangay;
  final int? postalCode;
  final String address;
}