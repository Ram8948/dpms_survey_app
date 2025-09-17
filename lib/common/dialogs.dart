import 'package:flutter/material.dart';

Future<void> showAlertDialog(
  BuildContext context,
  String message, {
  String title = 'Alert',
  bool showOK = false,
}) {
  return showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          content: Text(message),
          actions:
              showOK
                  ? [
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'OK'),
                      child: const Text('OK'),
                    ),
                  ]
                  : null,
        ),
  );
}
