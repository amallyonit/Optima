import 'package:flutter/material.dart';
import 'chart_card_header.dart';
import 'chart_card_body.dart';

export 'chart_card_header.dart';
export 'chart_card_body.dart';
export 'finance_kpi.dart';

class DashboardCardUI extends StatelessWidget {
  final String title;
  final List<PopupMenuEntry> menuItems;
  final Widget child;
  final double spacing;
  final Widget? trailing;

  const DashboardCardUI({
    super.key,
    required this.title,
    required this.menuItems,
    required this.child,
    this.spacing = 12,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCardBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            DashboardCardHeader(
              title: title,
              menuItems: menuItems,
              trailing: trailing,
            ),

          if (title.isNotEmpty) SizedBox(height: spacing),

          child,
        ],
      ),
    );
  }
}
