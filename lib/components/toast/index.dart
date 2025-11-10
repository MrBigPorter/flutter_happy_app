import 'package:fluttertoast/fluttertoast.dart';

void showAppToast(String message) {
  // avoid showing multiple toasts at the same time
  Fluttertoast.cancel();

}