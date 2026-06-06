import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackBar {
  static show(String text) {
    if (Get.context == null) {
      Get.snackbar('错误', text);
      return;
    }
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(duration: const Duration(seconds: 3), content: Text(text)),
    );
  }
}
