import 'package:flutter/material.dart';

mixin LoadingMixin<T extends StatefulWidget> on State<T> {
  void showLoading([String? message]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );
  }

  void hideLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
