// ignore_for_file: file_names

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../classes/dashBoard.dart';
import '../classes/dataManager.dart';
import '../sidemenu/sidemenu.dart';

class SOAndSalesChartPage extends StatefulWidget {
  final List<SODetailsList> soList;
  final List<SalesList> salesList;
  const SOAndSalesChartPage({
    super.key,
    required this.soList,
    required this.salesList,
  });

  @override
  State<SOAndSalesChartPage> createState() => _SOAndSalesChartPageState();
}

class AxisConfig {
  final double maxY;
  final double interval;

  AxisConfig(this.maxY, this.interval);
}

List<CombinedCustomerData> combinedData = [];
AxisConfig getAxisConfig(List<CustomerChartData> data) {
  double maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

  double interval;

  if (maxValue <= 1000000) {
    interval = 100000; // 1L
  } else if (maxValue <= 5000000) {
    interval = 500000; // 5L
  } else if (maxValue <= 20000000) {
    interval = 1000000; // 10L
  } else if (maxValue <= 50000000) {
    interval = 2000000; // 20L
  } else if (maxValue <= 100000000) {
    interval = 5000000; // 50L
  } else {
    interval = 10000000; // 1 Cr
  }

  double maxY = ((maxValue / interval).ceil() * interval);
  maxY += interval;

  return AxisConfig(maxY, interval);
}

AxisConfig getCombinedAxisConfig<T>(List<T> data, double Function(T) getValue) {
  double maxValue = data
      .map((e) => getValue(e))
      .reduce((a, b) => a > b ? a : b);

  double interval;

  if (maxValue <= 1000000) {
    interval = 100000;
  } else if (maxValue <= 20000000) {
    interval = 1000000;
  } else if (maxValue <= 5000000) {
    interval = 2500000;
  } else if (maxValue <= 20000000) {
    interval = 1000000;
  } else if (maxValue <= 50000000) {
    interval = 2000000;
  } else if (maxValue <= 100000000) {
    interval = 5000000;
  } else {
    interval = 10000000;
  }

  double maxY = ((maxValue / interval).ceil() * interval);
  maxY = maxY + (interval * 0.2);

  return AxisConfig(maxY, interval);
}

String _formatValue(double value) {
  if (value >= 10000000) {
    double cr = value / 10000000;
    return "${cr % 1 == 0 ? cr.toInt() : cr.toStringAsFixed(1)} Cr";
  } else if (value >= 100000) {
    return "${(value / 100000).toStringAsFixed(0)} L";
  } else {
    return value.toStringAsFixed(0);
  }
}

class _SOAndSalesChartPageState extends State<SOAndSalesChartPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<CustomerChartData> soChartData = [];
  late List<CustomerChartData> salesChartData = [];
  @override
  void initState() {
    super.initState();
    combinedData = prepareCombinedData();
    soChartData = getSOChartData(widget.soList);
    salesChartData = getSalesChartData(widget.salesList);
  }

  List<CustomerChartData> getSOChartData(List<SODetailsList> list) {
    final Map<String, CustomerChartData> map = {};

    for (var item in list) {
      final key = item.customerName;
      final value = double.tryParse(item.orderValue) ?? 0;

      if (!map.containsKey(key)) {
        map[key] = CustomerChartData(
          customerName: key,
          customerCode: item.customerCode,
          value: value,
          count: 1,
          docNos: [item.soNo],
        );
      } else {
        final existing = map[key]!;
        map[key] = CustomerChartData(
          customerName: key,
          customerCode: item.customerCode,
          value: existing.value + value,
          count: existing.count + 1,
          docNos: [...existing.docNos, item.soNo],
        );
      }
    }

    return map.values.toList();
  }

  List<CustomerChartData> getSalesChartData(List<SalesList> list) {
    final Map<String, CustomerChartData> map = {};

    for (var item in list) {
      final key = item.customerName;
      final value = double.tryParse(item.rowTotal) ?? 0;

      if (!map.containsKey(key)) {
        map[key] = CustomerChartData(
          customerName: key,
          customerCode: item.customerCode,
          value: value,
          count: 1,
          docNos: [item.invoiceNo],
        );
      } else {
        final existing = map[key]!;
        map[key] = CustomerChartData(
          customerName: key,
          customerCode: item.customerCode,
          value: existing.value + value,
          count: existing.count + 1,
          docNos: [...existing.docNos, item.invoiceNo],
        );
      }
    }

    return map.values.toList();
  }

  List<CombinedCustomerData> prepareCombinedData() {
    final Map<String, double> soMap = {};
    final Map<String, double> salesMap = {};
    final Map<String, String> customerNameMap = {};
    final Map<String, List<String>> soNosMap = {};
    final Map<String, List<String>> invoiceNosMap = {};

    // SO aggregation
    for (var item in widget.soList) {
      final val = double.tryParse(item.orderValue) ?? 0;

      soMap[item.customerCode] = (soMap[item.customerCode] ?? 0) + val;

      customerNameMap[item.customerCode] = item.customerName;

      soNosMap.putIfAbsent(item.customerCode, () => []);
      soNosMap[item.customerCode]!.add(item.soNo); // ADD
    }

    // Sales aggregation
    for (var item in widget.salesList) {
      final val = double.tryParse(item.rowTotal) ?? 0;

      salesMap[item.customerCode] = (salesMap[item.customerCode] ?? 0) + val;

      customerNameMap[item.customerCode] = item.customerName;

      invoiceNosMap.putIfAbsent(item.customerCode, () => []);
      invoiceNosMap[item.customerCode]!.add(item.invoiceNo); // ADD
    }

    final allCustomers = {...soMap.keys, ...salesMap.keys};

    return allCustomers.map((code) {
      return CombinedCustomerData(
        customerCode: code,
        customerName: customerNameMap[code] ?? "",
        soValue: soMap[code] ?? 0,
        salesValue: salesMap[code] ?? 0,
        soNos: (soNosMap[code] ?? []).toSet().toList(), // DISTINCT
        invoiceNos: (invoiceNosMap[code] ?? []).toSet().toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    String? filterDate = DateFormat(
      'dd/MM/yyyy',
    ).format(DataManager.readSelectedDate()!).toString();

    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        elevation: 0.0,
        // title: Text(
        //   "SO Vs Sales Analysis\n$filterDate",
        //   textAlign: TextAlign.center,
        //   style: TextStyle(
        //     color: Colors.blue,
        //     fontFamily: "Poppins",
        //     fontWeight: FontWeight.bold,
        //     fontSize: 18,
        //   ),
        // ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "SO Vs Sales Analysis",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue,
                fontFamily: "Poppins",
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              filterDate,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Back button (right side)
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildCombinedBarChart(
                context: context,
                data: combinedData,
                title: "SO vs Sales (Customer Wise)",
                color: Colors.green,
              ),
              const SizedBox(height: 30),

              buildBarChart(
                data: soChartData,
                title: "Sales Orders (Customer Wise)",
                color: Colors.blue,
              ),
              const SizedBox(height: 30),

              buildBarChart(
                data: salesChartData,
                title: "Invoices (Customer Wise)",
                color: Colors.green,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

Widget buildBarChart({
  required List<CustomerChartData> data,
  required String title,
  required Color color,
}) {
  data.sort((a, b) => b.value.compareTo(a.value));
  final chartData = data.toList();
  final axis = getAxisConfig(chartData);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),

      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartData.length * 80,
          height: 300,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: BarChart(
              BarChartData(
                maxY: axis.maxY,
                minY: 0,
                baselineY: 0,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(show: false),
                barGroups: List.generate(chartData.length, (index) {
                  final item = chartData[index];
                  return BarChartGroupData(
                    x: index,

                    barRods: [
                      BarChartRodData(
                        toY: item.value,
                        width: 18,
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Colors.black12),
                    bottom: BorderSide(color: Colors.black12),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ), // remove top axis
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ), // remove right axis
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: axis.interval,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value >= 10000000) {
                          double cr = value / 10000000;
                          return Text(
                            "${cr % 1 == 0 ? cr.toInt() : cr.toStringAsFixed(1)} Cr",
                            style: const TextStyle(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          );
                        } else {
                          return Text(
                            "${(value / 100000).toStringAsFixed(0)} L",
                            style: const TextStyle(fontSize: 10),
                            maxLines: 1,
                          );
                        }
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60, // important for rotated text
                      getTitlesWidget: (value, meta) {
                        if (value > axis.maxY) return const SizedBox();
                        final index = value.toInt();
                        if (index >= chartData.length) return const SizedBox();

                        return Transform.rotate(
                          angle: -0.785, // -45 degrees in radians
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              chartData[index].customerCode, // using code now
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                //  TOOLTIP (important part)
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    fitInsideVertically: true,
                    fitInsideHorizontally: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = chartData[group.x.toInt()];
                      final docs = item.docNos.toSet().join(", ");

                      return BarTooltipItem(
                        "${item.customerName}\n"
                        "Value: ${item.value.toStringAsFixed(0)}\n"
                        "Count: ${item.count}\n"
                        "${title.contains("Order") ? "Order " : "Invoice "}"
                        "Docs:\n$docs",
                        TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget buildCombinedBarChart({
  required BuildContext context,
  required List<CombinedCustomerData> data,
  required String title,
  required Color color,
}) {
  data.sort((a, b) {
    final aMax = a.soValue > a.salesValue ? a.soValue : a.salesValue;
    final bMax = b.soValue > b.salesValue ? b.soValue : b.salesValue;
    return bMax.compareTo(aMax);
  });
  final chartData = data.toList();
  final axis = getCombinedAxisConfig(
    data,
    (e) => e.soValue > e.salesValue ? e.soValue : e.salesValue,
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.square, color: Colors.blue, size: 12),
          SizedBox(width: 4),
          Text("SO"),
          SizedBox(width: 12),
          Icon(Icons.square, color: Colors.green, size: 12),
          SizedBox(width: 4),
          Text("Sales"),
        ],
      ),
      const SizedBox(height: 10),

      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartData.length * 80,
          height: 300,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: BarChart(
              BarChartData(
                maxY: axis.maxY,
                minY: 0,
                baselineY: 0,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(show: false),
                barGroups: List.generate(chartData.length, (index) {
                  final item = chartData[index];
                  return BarChartGroupData(
                    x: index,

                    barRods: [
                      // SO BAR (Blue)
                      BarChartRodData(
                        toY: item.soValue,
                        color: Colors.blue,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),

                      // SALES BAR (Green)
                      BarChartRodData(
                        toY: item.salesValue,
                        color: Colors.green,
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: Colors.black12),
                    bottom: BorderSide(color: Colors.black12),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ), // remove top axis
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ), // remove right axis
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: axis.interval,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        // Prevent duplicate top label
                        if (value >= axis.maxY - (axis.interval * 0.1)) {
                          return const SizedBox();
                        }
                        if (value >= 10000000) {
                          double cr = value / 10000000;
                          return Text(
                            "${cr % 1 == 0 ? cr.toInt() : cr.toStringAsFixed(1)} Cr",
                            style: const TextStyle(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          );
                        } else {
                          return Text(
                            "${(value / 100000).toStringAsFixed(0)} L",
                            style: const TextStyle(fontSize: 10),
                            maxLines: 1,
                          );
                        }
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60, // important for rotated text
                      getTitlesWidget: (value, meta) {
                        if (value > axis.maxY) return const SizedBox();
                        final index = value.toInt();
                        if (index >= chartData.length) return const SizedBox();

                        return Transform.rotate(
                          angle: -0.785, // -45 degrees in radians
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              chartData[index].customerCode, // using code now
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                //  TOOLTIP (important part)
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.black87,
                    fitInsideVertically: true,
                    fitInsideHorizontally: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = chartData[group.x.toInt()];
                      // final soDocs = item.soNos.toSet().join(", ");
                      // final invDocs = item.invoiceNos.toSet().join(", ");
                      return BarTooltipItem(
                        "${item.customerName}\n"
                        "(${item.customerCode})\n\n"
                        "SO Value: ${item.soValue.toStringAsFixed(0)}\n"
                        "Sales Value: ${item.salesValue.toStringAsFixed(0)}\n\n"
                        "SO Count: ${item.soNos.length}\n"
                        "Invoice Count: ${item.invoiceNos.length}\n\n",
                        // "SO Nos:\n$soDocs\n\n"
                        // "Invoice Nos:\n$invDocs",
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent && // 👈 IMPORTANT FIX
                        response != null &&
                        response.spot != null) {
                      final index = response.spot!.touchedBarGroupIndex;
                      final item = chartData[index];

                      _showDetails(context, item);
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

void _showDetails(BuildContext context, CombinedCustomerData item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // important
    builder: (context) {
      return TweenAnimationBuilder(
        duration: const Duration(milliseconds: 300),
        tween: Tween<double>(begin: 0, end: 1),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, (1 - value) * 50), // slide up
            child: Opacity(
              opacity: value, // fade in
              child: child,
            ),
          );
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(
                      0,
                      -2,
                    ), // makes shadow appear above nicely
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Header
                    Text(
                      item.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.customerCode,
                      style: TextStyle(color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 16),

                    // SO Section
                    _buildSection(
                      title: "Sales Orders",
                      color: Colors.blue,
                      value: _formatValue(item.soValue),
                      count: item.soNos.length,
                      docs: item.soNos,
                    ),

                    const SizedBox(height: 16),

                    // Sales Section
                    _buildSection(
                      title: "Invoices",
                      color: Colors.green,
                      value: _formatValue(item.salesValue),
                      count: item.invoiceNos.length,
                      docs: item.invoiceNos,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

Widget _buildSection({
  required String title,
  required Color color,
  required String value,
  required int count,
  required List<String> docs,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Icon(Icons.square, color: color, size: 12),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Value + Count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Value: $value",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text("Count: $count"),
          ],
        ),

        const SizedBox(height: 10),

        // Docs
        const Text("Documents:", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),

        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: docs.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(e, style: const TextStyle(fontSize: 11)),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

AxisTitles getLeftTitles(AxisConfig axis) {
  return AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      interval: axis.interval,
      reservedSize: 50,
      getTitlesWidget: (value, meta) {
        if (value > axis.maxY) return const SizedBox();

        if (value >= 10000000) {
          double cr = value / 10000000;
          return Text(
            "${cr % 1 == 0 ? cr.toInt() : cr.toStringAsFixed(1)} Cr",
            style: const TextStyle(fontSize: 10),
            maxLines: 1,
          );
        } else {
          return Text(
            "${(value / 100000).toStringAsFixed(0)} L",
            style: const TextStyle(fontSize: 10),
            maxLines: 1,
          );
        }
      },
    ),
  );
}
