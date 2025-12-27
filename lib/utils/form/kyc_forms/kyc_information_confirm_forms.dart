import 'package:flutter_app/utils/form/validators.dart';
import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';

part 'kyc_information_confirm_forms.gform.dart';

@Rf()
class KycInformationConfirmModel {
  const KycInformationConfirmModel({
    // === 1. 身份信息 ===
    @RfControl() this.idType = 1,

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

    // === 2. 地址信息 (PH Address) ===
    @RfControl(validators: [NonEmpty()]) this.province = '',
    @RfControl(validators: [NonEmpty()]) this.city = '',
    @RfControl(validators: [NonEmpty()]) this.barangay = '',

    @RfControl(validators: [NonEmpty()])
    this.postalCode = '',

    @RfControl(validators: [NonEmpty()]) this.address = '',

    // === 3. 图片凭证 ===
    @RfControl(validators: [NonEmpty()])
    this.idCardFront = '',

    @RfControl()
    this.idCardBack,

    @RfControl()
    this.faceImage,

    @RfControl() this.livenessScore,
  });

  // 变量定义（驼峰）
  final int idType;
  final String idNumber;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? realName;
  final String gender;
  final String birthday;
  final String? expiryDate;
  final int? countryCode;

  final String province;
  final String city;
  final String barangay;
  final String postalCode;
  final String address;

  final String idCardFront;
  final String? idCardBack;
  final String? faceImage;
  final double? livenessScore;

}