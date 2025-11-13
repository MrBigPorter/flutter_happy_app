import 'package:flutter/painting.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// RadixToast - A utility class for displaying toast messages with different styles
/// Methods:
/// - success(String message): Show a success toast
/// - error(String message): Show an error toast
/// - info(String message): Show an info toast
/// Usage:
/// ```dart
/// RadixToast.success('Operation successful!');
/// RadixToast.error('An error occurred.');
/// RadixToast.info('Here is some information.');
/// ```
class RadixToast {
  // Show a success toast message, for inner use
  static void _show(
    String message, {
    required Color backgroundColor,
    required Color textColor,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    // Cancel any existing toasts before showing a new one, avoids stacking
    Fluttertoast.cancel();

    // Show the toast with specified parameters
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      timeInSecForIosWeb: 2,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 16.w,
    );
  }

  // Success toast
  static void success(String message) {
    _show(
      message,
      backgroundColor: const Color(0xFF4CAF50), // Green background
      textColor: const Color(0xFFFFFFFF), // White text
    );
  }

  // Error toast
  static void error(String message) {
    _show(
      message,
      backgroundColor: const Color(0xFFF44336), // Red background
      textColor: const Color(0xFFFFFFFF), // White text
    );
  }

  // Info toast
  static void info(String message) {
    _show(
      message,
      backgroundColor: const Color(0xFF2196F3), // Blue background
      textColor: const Color(0xFFFFFFFF), // White text
    );
  }
}
