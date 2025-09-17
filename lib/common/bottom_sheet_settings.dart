import 'dart:math';
import 'package:flutter/material.dart';

class BottomSheetSettings extends StatelessWidget {
  const BottomSheetSettings({
    required this.onCloseIconPressed,
    required this.settingsWidgets,
    super.key,
  });
  final VoidCallback onCloseIconPressed;
  final List<Widget> Function(BuildContext) settingsWidgets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        max(
          20,
          View.of(context).viewPadding.bottom /
              View.of(context).devicePixelRatio,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('Settings', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onCloseIconPressed,
              ),
            ],
          ),
          // Display the setting widgets.
          ...settingsWidgets(context),
        ],
      ),
    );
  }
}
