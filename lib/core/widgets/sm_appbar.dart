import 'package:flutter/material.dart';

class SMAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SMAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
