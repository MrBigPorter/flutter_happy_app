import 'package:flutter_app/utils/form/validators.dart';
import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';

part 'address_form.gform.dart';

@Rf()
class AddressFormModel {
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String contactName;
  final String fullAddress;
  final int? provinceId;
  final int? cityId;
  final int? barangayId;
  final String? postalCode;
  final String phone;
  final bool isDefault;
  final String? label;

  const AddressFormModel({
    @RfControl() this.firstName,
    @RfControl() this.middleName,
    @RfControl() this.lastName,
    @RfControl(validators: [NonEmpty(), RealName()]) this.contactName = '',
    @RfControl(validators: [NonEmpty()]) this.fullAddress = '',
    @RfControl(validators: [Required()]) this.provinceId,
    @RfControl(validators: [Required()]) this.cityId,
    @RfControl(validators: [Required()]) this.barangayId,
    @RfControl(validators: [PostalCode()]) this.postalCode,
    @RfControl(validators: [NonEmpty(), Phone10()]) this.phone = '',
    @RfControl(validators: [Required()]) this.isDefault = false,
    @RfControl() this.label,
  });


}