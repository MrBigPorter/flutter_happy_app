import 'package:flutter_app/utils/form/validators.dart';
import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';


part 'deposit_form.gform.dart';

@Rf()
class DepositFormModel {
  const DepositFormModel({
    @RfControl(validators: [NonEmpty(),DepositAmount()]) this.amount = '',
  });

  final String amount;
}