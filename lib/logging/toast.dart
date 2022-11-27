import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:priobike/common/layout/ci.dart';

class ToastMessage {
  static showError(String message) {
    HapticFeedback.heavyImpact();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: CI.red,
      textColor: Colors.white,
      fontSize: 20.0,
    );
  }

  static showSuccess(String message) {
    HapticFeedback.heavyImpact();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: CI.green,
      textColor: Colors.white,
      fontSize: 20.0,
    );
  }
}
