import 'package:flutter/material.dart';
import 'chart_card_header.dart';
import 'chart_card_body.dart';

export 'chart_card_header.dart';
export 'chart_card_body.dart';
export 'finance_kpi.dart';

class SparklinePainter extends CustomPainter {
  final Color color;

  SparklinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 16)
      ..lineTo(size.width * .15, 15)
      ..lineTo(size.width * .30, 4)
      ..lineTo(size.width * .45, 15)
      ..lineTo(size.width * .60, 6)
      ..lineTo(size.width * .75, 14)
      ..lineTo(size.width * .90, 5)
      ..lineTo(size.width, 4);

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

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
