import 'package:flutter/material.dart';

class DashboardCardHeader extends StatelessWidget {
  final String title;
  final List<PopupMenuEntry> menuItems;
  final Widget? trailing;

  const DashboardCardHeader({
    super.key,
    required this.title,
    required this.menuItems,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
        PopupMenuButton(
          padding: EdgeInsets.zero,
          itemBuilder: (context) => menuItems,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.more_vert, size: 18),
          ),
        ),
      ],
    );
  }
}
