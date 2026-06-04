// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void _show({
    required String title,
    required String message,
    required ContentType contentType,
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      duration: duration,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: contentType,
      ),
    );

    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void success({required String title, required String message}) {
    _show(
      title: title,
      message: message,
      contentType: ContentType.success,
      duration: const Duration(seconds: 2),
    );
  }

  static void error({required String title, required String message}) {
    _show(
      title: title,
      message: message,
      contentType: ContentType.failure,
      duration: const Duration(seconds: 4),
    );
  }

  static void warning({required String title, required String message}) {
    _show(
      title: title,
      message: message,
      contentType: ContentType.warning,
      duration: const Duration(seconds: 3),
    );
  }

  static void info({required String title, required String message}) {
    _show(
      title: title,
      message: message,
      contentType: ContentType.help,
      duration: const Duration(seconds: 3),
    );
  }
}
