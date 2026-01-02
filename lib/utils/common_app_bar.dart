
import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  const CommonAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF00509D),

      // 🔥 REDUCE BACK BUTTON WIDTH
      leadingWidth: 36,

      leading: showBack
          ? IconButton(
        padding: EdgeInsets.zero, // 🔥 remove extra padding
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        onPressed: onBack ?? () => Navigator.pop(context),
      )
          : null,

      // 🔥 REDUCE SPACE BETWEEN ARROW & TITLE
      titleSpacing: 8,

      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20, // optional: slightly smaller
        ),
      ),
      elevation: 1,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
