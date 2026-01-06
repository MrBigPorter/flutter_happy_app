import 'package:flutter_app/utils/form/validators.dart';
import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';


part 'withdraw_form.gform.dart';

@Rf()
class WithdrawFormModel {
  const WithdrawFormModel({
    @RfControl(validators: [NonEmpty(), WithdrawAmount()]) this.amount = '',
  });

  final String amount;
}