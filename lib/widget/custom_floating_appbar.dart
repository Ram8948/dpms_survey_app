import 'package:flutter/material.dart';

class CustomFloatingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final IconData? rightIcon;
  final VoidCallback? onRightIconPressed;

  const CustomFloatingAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBackPressed,
    this.rightIcon,
    this.onRightIconPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 24);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: kToolbarHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xFFE8F7FF),
              Colors.white,
            ],
            stops: [0.1025, 0.845],
          ),
          border: Border.all(color: const Color(0xFF8DCAFF), width: 1),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
              )
            else
              const SizedBox(width: 48), // Keep space if no back button to center title
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ),
            if (rightIcon != null && onRightIconPressed != null)
              IconButton(
                icon: Icon(rightIcon, color: Colors.black),
                onPressed: onRightIconPressed,
              )
            else
              const SizedBox(width: 48), // Keep space to balance layout
          ],
        ),
      ),
    );
  }
}
