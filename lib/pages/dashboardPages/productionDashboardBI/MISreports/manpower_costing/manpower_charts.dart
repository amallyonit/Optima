// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../dashboard_card_ui.dart';
import 'manpower_controller.dart';

double niceDivVal(double maxValue, {int targetSteps = 5}) {
  if (maxValue <= 0) return 1;

  final rawStep = maxValue / targetSteps;
  final exponent = (log(rawStep) / ln10).floor();
  final base = pow(10, exponent).toDouble();

  final fraction = rawStep / base;

  double niceFraction;
  if (fraction <= 1) {
    niceFraction = 1;
  } else if (fraction <= 2) {
    niceFraction = 2;
  } else if (fraction <= 5) {
    niceFraction = 5;
  } else {
    niceFraction = 10;
  }

  return niceFraction * base;
}

double getNiceMaxY(double maxValue, {int targetSteps = 5}) {
  final step = niceDivVal(maxValue, targetSteps: targetSteps);
  return (maxValue / step).ceil() * step;
}

SideTitles _bottomTitles(List<MonthlyProductionData> data) => SideTitles(
  showTitles: true,
  getTitlesWidget: (val, meta) {
    if (val.toInt() >= data.length) return const Text("");

    final mthData = data[val.toInt()];
    final text = mthData.monthName;

    return Text(text.length > 3 ? text.substring(0, 3) : text);
  },
);

SideTitles get _leftTitles => SideTitles(
  reservedSize: 50,
  showTitles: true,
  getTitlesWidget: (value, meta) {
    String leftDouble = "";
    leftDouble = formatAmount(value);
    return Text(leftDouble, style: const TextStyle(fontSize: 12));
  },
);

SideTitles get _emptyTitlesTop =>
    SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

Widget getEmptyTopTitle(double val, TitleMeta meta) {
  return const Text("");
}

List<BarChartGroupData> dailyProductionBarGroups(
  List<DailyProductionData> data,
) {
  final List<BarChartGroupData> groups = [];

  for (int i = 0; i < data.length; i++) {
    final item = data[i];

    groups.add(
      BarChartGroupData(
        x: i,
        barRods: [
          //   BarChartRodData(
          //     toY: avgBoxes,
          //     width: 14,
          //     color: const Color(0xFFFF9F47),
          //     borderRadius: BorderRadius.circular(3),
          //   ),
          BarChartRodData(
            toY: item.boxNo.toDouble(),
            width: 30,
            color: Colors.blue,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  return groups;
}

SideTitles bottomDailyTitles(List<DailyProductionData> data) {
  return SideTitles(
    showTitles: true,
    getTitlesWidget: (val, meta) {
      if (val.toInt() >= data.length) {
        return const Text('');
      }

      final name = data[val.toInt()].dayLabel;

      return Text(name, style: const TextStyle(fontSize: 11));
    },
  );
}

Widget bottomTitleWidgets(
  double value,
  TitleMeta meta,
  List<DailyProductionData> data,
) {
  final int i = value.toInt();

  if (i < 0 || i >= data.length) {
    return const SizedBox.shrink();
  }

  final name = data[i].dayLabel;

  return SideTitleWidget(
    meta: meta,
    space: 6,
    child: Text(name, style: const TextStyle(fontSize: 11)),
  );
}

class TargetAchievementWidget extends StatelessWidget {
  final double qtyPercent;
  final double boxPercent;
  final double qty;
  final double boxes;

  const TargetAchievementWidget({
    super.key,
    required this.qtyPercent,
    required this.boxPercent,
    required this.qty,
    required this.boxes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _gauge(qtyPercent, qty, "Produced Qty"),
        const SizedBox(width: 30),
        _gauge(boxPercent, boxes, "No. of Boxes Produced"),
      ],
    );
  }

  Widget _gauge(double percent, double value, String title) {
    return CircularPercentIndicator(
      arcType: ArcType.HALF,
      radius: 70,
      lineWidth: 27,
      percent: percent / 100,
      progressColor: const Color(0xFF2CA9DF),
      arcBackgroundColor: const Color(0xFFB8ECFF),
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            percent.toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.0,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.0, color: Colors.black),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.0, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class MonthlyProductionBarChart extends StatelessWidget {
  final ManpowerController controller;
  final List<MonthlyProductionData> data;
  final VoidCallback onFilterApplied;
  final ScrollController _horizontalController = ScrollController();
  MonthlyProductionBarChart({
    super.key,
    required this.controller,
    required this.data,
    required this.onFilterApplied,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double barChartWidth = data.length > 6 ? screenWidth * 1.9 : screenWidth;
    int len = data.length;
    double maxProduction = len > 0
        ? data
              .map((d) => d.production > d.target ? d.production : d.target)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    final step = niceDivVal(maxProduction);
    return FinanceHorizontalChartScroll(
      controller: _horizontalController,
      child: SizedBox(
        height: 350,
        width: barChartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getNiceMaxY(maxProduction),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                bottomTitles: AxisTitles(
                  sideTitles: _bottomTitles(data),
                  axisNameSize: 20,
                ),
              ),

              gridData: FlGridData(
                show: true,
                checkToShowHorizontalLine: (value) => value % step == 0,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.grey.shade300, strokeWidth: 1),
                drawVerticalLine: false,
              ),

              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                  top: BorderSide(color: Colors.grey.shade400, width: 0.7),
                ),
              ),

              barGroups: monthWiseProductionAnalysisChartData(data),

              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchTooltipData: BarTouchTooltipData(
                  maxContentWidth: 200,
                  tooltipBorder: const BorderSide(
                    width: 2,
                    color: Colors.black12,
                    style: BorderStyle.none,
                  ),
                  getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                    final item = data[grpIndex];

                    return BarTooltipItem(
                      '${item.monthName}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text:
                              "Achievement : ${formatAmount(item.production)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Target : ${(rodData.backDrawRodData.toY / 100000).toStringAsFixed(2)} L\n",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                  getTooltipColor: (group) => Colors.white,
                  fitInsideVertically: true,
                  fitInsideHorizontally: true,
                ),
                touchCallback: (flTouchEvent, barTouchResponse) {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    if (flTouchEvent is FlTapUpEvent) {
                      final index = barTouchResponse.spot!.spot.x.toInt();

                      if (index < 0 || index >= data.length) return;

                      final item = data[index];

                      final int month = DateFormat(
                        'MMMM',
                      ).parse(item.monthName).month;
                      controller.selectedMonthIndex == month
                          ? controller.selectedMonthIndex = -1
                          : controller.selectedMonthIndex = month;
                      controller.applyMonthFilter(
                        controller.selectedMonthIndex,
                      );
                      onFilterApplied();
                    }
                  }
                },
                handleBuiltInTouches: true,
                touchExtraThreshold: const EdgeInsets.all(10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DailyProductionBarChart extends StatelessWidget {
  final List<DailyProductionData> data;
  final double avgBoxes;
  final ScrollController _horizontalController = ScrollController();
  DailyProductionBarChart({
    super.key,
    required this.data,
    required this.avgBoxes,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final int len = data.length;
    double chartWidth = len > 5 ? screenWidth + (40 * len) : screenWidth;

    var maxProduction = len > 0
        ? data
              .map((d) => d.boxNo > d.boxNo ? d.boxNo : d.boxNo)
              .reduce((a, b) => a > b ? a : b)
        : 0;

    return FinanceHorizontalChartScroll(
      controller: _horizontalController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getNiceMaxY(maxProduction.toDouble()),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: _leftTitles,
                  axisNameSize: 14,
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: 1,
                    getTitlesWidget: (value, meta) =>
                        bottomTitleWidgets(value, meta, data),
                  ),
                ),
              ),

              gridData: FlGridData(
                show: true,
                checkToShowHorizontalLine: (value) => value % 10 == 0,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.grey.shade300, strokeWidth: 1),
                drawVerticalLine: false,
              ),

              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                  top: BorderSide(color: Colors.grey.shade400, width: 0.7),
                ),
              ),

              barGroups: dailyProductionBarGroups(data),

              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,

                touchTooltipData: BarTouchTooltipData(
                  maxContentWidth: 200,

                  tooltipBorder: const BorderSide(
                    width: 2.0,
                    color: Colors.black12,
                    style: BorderStyle.none,
                  ),

                  getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                    final item = data[grpIndex];

                    return BarTooltipItem(
                      '${item.dayLabel}\n',
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Avg Box : ${formatAmount(avgBoxes)}\n",
                          style: const TextStyle(
                            color: Color(0xFFFF9F47),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text:
                              "Actual Boxes : ${formatAmount(item.boxNo.toDouble())}\n",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      textAlign: TextAlign.start,
                    );
                  },

                  getTooltipColor: (group) => Colors.white,
                  fitInsideVertically: true,
                  fitInsideHorizontally: true,
                ),

                handleBuiltInTouches: true,
                touchExtraThreshold: const EdgeInsets.all(10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MonthlyProductionLineChart extends StatelessWidget {
  final List<MonthlyProductionData> data;
  final ScrollController _horizontalController = ScrollController();
  MonthlyProductionLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final int len = data.length;

    if (len == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    double chartWidth = len > 5 ? screenWidth + (40 * len) : screenWidth;

    final List<FlSpot> productionSpots = [];
    final List<FlSpot> boxNoSpots = [];

    for (int i = 0; i < len; i++) {
      final item = data[i];

      productionSpots.add(FlSpot(i.toDouble(), item.production.toDouble()));

      boxNoSpots.add(FlSpot(i.toDouble(), (item.boxNo ?? 0).toDouble()));
    }

    double? minY;
    double? maxY;

    void consider(double v) {
      if (v.isNaN) return;
      if (minY == null || v < minY!) minY = v;
      if (maxY == null || v > maxY!) maxY = v;
    }

    for (final s in productionSpots) {
      consider(s.y);
    }

    for (final s in boxNoSpots) {
      consider(s.y);
    }

    const productionColor = Colors.orange;
    const boxColor = Colors.blue;

    final List<LineChartBarData> lines = [
      LineChartBarData(
        spots: productionSpots,
        isCurved: true,
        color: productionColor,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 4,
            color: productionColor,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        isStrokeCapRound: true,
      ),
      LineChartBarData(
        spots: boxNoSpots,
        isCurved: true,
        color: boxColor,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 4,
            color: boxColor,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        isStrokeCapRound: true,
      ),
    ];

    Widget bottomTitleWidgets(double value, TitleMeta meta) {
      final int i = value.toInt();

      if (i < 0 || i >= data.length) return const Text('');

      final name = data[i].monthName;

      return SideTitleWidget(
        meta: meta,
        child: SizedBox(
          width: 60,
          child: Text(
            name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
    }

    Widget legend = Row(
      children: [
        legendItem(productionColor, 'Production'),
        const SizedBox(width: 8),
        legendItem(boxColor, 'BoxNo'),
      ],
    );

    return FinanceHorizontalChartScroll(
      controller: _horizontalController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                legend,
                const SizedBox(height: 15),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (len - 1).toDouble(),
                      minY: 0,
                      maxY: getNiceMaxY(maxY ?? 0),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 1,
                            getTitlesWidget: bottomTitleWidgets,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: _leftTitles,
                          axisNameSize: 14,
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black12),
                      ),
                      lineBarsData: lines,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DailyProductionLineChart extends StatelessWidget {
  final List<DailyProductionData> data;
  final ScrollController _horizontalController = ScrollController();
  DailyProductionLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final int len = data.length;

    if (len == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    double chartWidth = len > 5 ? screenWidth + (40 * len) : screenWidth;

    final List<FlSpot> productionSpots = [];
    final List<FlSpot> boxNoSpots = [];

    for (int i = 0; i < len; i++) {
      final item = data[i];

      productionSpots.add(FlSpot(i.toDouble(), item.production.toDouble()));

      boxNoSpots.add(FlSpot(i.toDouble(), item.boxNo.toDouble()));
    }

    double? minY;
    double? maxY;

    void consider(double v) {
      if (v.isNaN) return;
      if (minY == null || v < minY!) minY = v;
      if (maxY == null || v > maxY!) maxY = v;
    }

    for (final s in productionSpots) {
      consider(s.y);
    }

    for (final s in boxNoSpots) {
      consider(s.y);
    }

    const productionColor = Colors.orange;
    const boxColor = Colors.blue;

    final List<LineChartBarData> lines = [
      LineChartBarData(
        spots: productionSpots,
        isCurved: true,
        color: productionColor,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 4,
            color: productionColor,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        isStrokeCapRound: true,
      ),
      LineChartBarData(
        spots: boxNoSpots,
        isCurved: true,
        color: boxColor,
        barWidth: 3,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: 4,
            color: boxColor,
            strokeWidth: 1.5,
            strokeColor: Colors.white,
          ),
        ),
        isStrokeCapRound: true,
      ),
    ];

    Widget bottomTitleWidgets(double value, TitleMeta meta) {
      final int i = value.toInt();

      if (i < 0 || i >= data.length) {
        return const SizedBox.shrink();
      }

      final name = data[i].dayLabel;

      return SideTitleWidget(
        meta: meta,
        child: SizedBox(
          width: 60,
          child: Text(
            name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      );
    }

    Widget legend = Row(
      children: [
        legendItem(productionColor, 'Production'),
        const SizedBox(width: 8),
        legendItem(boxColor, 'BoxNo'),
      ],
    );

    return FinanceHorizontalChartScroll(
      controller: _horizontalController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                legend,
                const SizedBox(height: 15),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (len - 1).toDouble(),
                      minY: 0,
                      maxY: getNiceMaxY(maxY ?? 0),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 1,
                            getTitlesWidget: bottomTitleWidgets,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: _leftTitles,
                          axisNameSize: 14,
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black12),
                      ),
                      lineBarsData: lines,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget legendItem(Color c, String text) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12, color: c),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 12)),
    ],
  );
}

List<BarChartGroupData> monthWiseProductionAnalysisChartData(
  List<MonthlyProductionData> data,
) {
  return data.map((chartData) {
    final index = data.indexOf(chartData);

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: chartData.production.toDouble(),
          width: 15,
          color: const Color(0xFF97D7F3),
          borderRadius: BorderRadius.circular(1),
        ),
        BarChartRodData(
          toY: chartData.target.toDouble(),
          width: 15,
          color: const Color(0xFFFF9F47),
          borderRadius: BorderRadius.circular(1),
        ),
      ],
    );
  }).toList();
}
