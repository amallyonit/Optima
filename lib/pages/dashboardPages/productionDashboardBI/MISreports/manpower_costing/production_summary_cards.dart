import 'package:flutter/material.dart';

class ProductionSummaryCards extends StatelessWidget {
  final double production;
  final double boxes;
  final bool isAverage;
  final bool isDailyAverage;
  final String title;

  const ProductionSummaryCards({
    super.key,
    required this.production,
    required this.boxes,
    required this.isAverage,
    required this.isDailyAverage,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return isDailyAverage
        ? Row(
            children: [
              _card("Average $title Produced\nper Day:", production),
              _card("Total Boxes Produced\nper Day:", boxes),
            ],
          )
        : !isAverage
        ? Row(
            children: [
              _card("Total $title Produced\nQuantity:", production),
              _card("Total $title Produced\nBox Quantity:", boxes),
            ],
          )
        : Row(
            children: [
              _card("Average Boxes\nper Month:", production),
              _card("Total Boxes Produced\nper Month:", boxes),
            ],
          );
  }

  Widget _card(String title, double value) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF97D7F3),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(12),
        child: Text(
          "$title ${value.toStringAsFixed(2)}",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
