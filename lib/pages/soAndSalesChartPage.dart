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
  final List<SODetailsList> soDailyList;
  final List<SalesList> salesDailyList;

  const SOAndSalesChartPage({
    super.key,
    required this.soList,
    required this.salesList,
    required this.soDailyList,
    required this.salesDailyList,
  });

  @override
  State<SOAndSalesChartPage> createState() => _SOAndSalesChartPageState();
}

class AxisConfig {
  final double maxY;
  final double interval;

  AxisConfig(this.maxY, this.interval);
}

List<CombinedMonthData> combinedMonthData = [];
List<CombinedCustomerData> combinedData = [];

AxisConfig getAxisConfig(List<CustomerChartData> data) {
  double maxValue = data.fold<double>(
    0,
    (prev, e) => prev > e.value ? prev : e.value,
  );

  if (maxValue == 0) {
    return AxisConfig(10, 2);
  }

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
  double maxValue = data.fold<double>(
    0,
    (prev, e) => prev > getValue(e) ? prev : getValue(e),
  );

  if (maxValue == 0) {
    return AxisConfig(10, 2);
  }

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
  Map<String, bool> expandedCustomers = {};
  late List<CustomerChartData> soChartData = [];
  late List<CustomerChartData> salesChartData = [];
  late List<SODetailsList> filteredSoList = [];
  late List<SalesList> filteredSalesList = [];
  String? filterDate;

  @override
  void initState() {
    super.initState();
    filterDate = DateFormat(
      'dd/MM/yyyy',
    ).format(DataManager.readSelectedDate()!).toString();
    filteredSoList = widget.soDailyList;
    filteredSalesList = widget.salesDailyList;
    combinedMonthData = prepareCombinedMonthData();
    combinedData = prepareCombinedData();
    soChartData = getSOChartData(widget.soDailyList);
    salesChartData = getSalesChartData(widget.salesDailyList);
    expandedCustomers.clear();
  }

  void _filterChartsByDate(String selectedDate) {
    setState(() {
      filteredSoList = widget.soList
          .where((e) => e.soDate == selectedDate)
          .toList();

      filteredSalesList = widget.salesList
          .where(
            (e) =>
                DateFormat('dd/MM/yyyy').format(e.invoiceDate) == selectedDate,
          )
          .toList();

      // rebuild chart data
      combinedData = prepareCombinedData();
      soChartData = getSOChartData(filteredSoList);
      salesChartData = getSalesChartData(filteredSalesList);
    });
  }

  void resetFilters() {
    setState(() {
      filterDate = DateFormat(
        'dd/MM/yyyy',
      ).format(DataManager.readSelectedDate()!).toString();
      filteredSoList = widget.soDailyList;
      filteredSalesList = widget.salesDailyList;
      combinedData = prepareCombinedData();
      soChartData = getSOChartData(filteredSoList);
      salesChartData = getSalesChartData(filteredSalesList);
    });
  }

  List<CustomerChartData> getSOChartData(List<SODetailsList> list) {
    final Map<String, double> soMap = {};
    final Map<String, String> customerNameMap = {};
    final Map<String, List<String>> soNosMap = {};

    // SO aggregation
    for (var item in list) {
      final val = double.tryParse(item.pendingValue) ?? 0;

      soMap[item.customerCode] = (soMap[item.customerCode] ?? 0) + val;

      customerNameMap[item.customerCode] = item.customerName;

      soNosMap.putIfAbsent(item.customerCode, () => []);
      soNosMap[item.customerCode]!.add(item.soNo);
    }

    final allCustomers = {...soMap.keys};

    return allCustomers.map((code) {
      final docs = (soNosMap[code] ?? []).toSet().toList();

      return CustomerChartData(
        customerCode: code,
        customerName: customerNameMap[code] ?? "",
        value: soMap[code] ?? 0,
        count: docs.length,
        docNos: docs,
      );
    }).toList();
  }

  List<CustomerChartData> getSalesChartData(List<SalesList> list) {
    final Map<String, double> salesMap = {};
    final Map<String, String> customerNameMap = {};
    final Map<String, List<String>> invoiceNosMap = {};

    // Sales aggregation
    for (var item in list) {
      final val = double.tryParse(item.rowTotal) ?? 0;

      salesMap[item.customerCode] = (salesMap[item.customerCode] ?? 0) + val;

      customerNameMap[item.customerCode] = item.customerName;

      invoiceNosMap.putIfAbsent(item.customerCode, () => []);
      invoiceNosMap[item.customerCode]!.add(item.invoiceNo);
    }

    final allCustomers = {...salesMap.keys};

    return allCustomers.map((code) {
      final docs = (invoiceNosMap[code] ?? []).toSet().toList();

      return CustomerChartData(
        customerCode: code,
        customerName: customerNameMap[code] ?? "",
        value: salesMap[code] ?? 0,
        count: docs.length,
        docNos: docs,
      );
    }).toList();
  }

  List<CombinedCustomerData> prepareCombinedData() {
    final Map<String, double> soMap = {};
    final Map<String, double> salesMap = {};
    final Map<String, String> customerNameMap = {};
    final Map<String, List<String>> soNosMap = {};
    final Map<String, List<String>> invoiceNosMap = {};

    final parsedFilterDate = DateFormat('dd/MM/yyyy').parse(filterDate!);
    final selectedMonth = parsedFilterDate.month;
    final selectedYear = parsedFilterDate.year;

    // SO aggregation
    for (var item in filteredSoList) {
      final soParsedDate = DateFormat('dd/MM/yyyy').parse(item.soDate);

      if (soParsedDate.month != selectedMonth ||
          soParsedDate.year != selectedYear) {
        continue; // skip other months
      }

      final val = double.tryParse(item.pendingValue) ?? 0;

      soMap[item.customerCode] = (soMap[item.customerCode] ?? 0) + val;

      customerNameMap[item.customerCode] = item.customerName;

      soNosMap.putIfAbsent(item.customerCode, () => []);
      soNosMap[item.customerCode]!.add(item.soNo); // ADD
    }

    // Sales aggregation
    for (var item in filteredSalesList) {
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

  List<CombinedMonthData> prepareCombinedMonthData() {
    final Map<String, double> soMap = {};
    final Map<String, double> salesMap = {};
    final Map<String, String> dateMap = {};
    final Map<String, List<String>> soNosMap = {};
    final Map<String, List<String>> invoiceNosMap = {};

    final parsedFilterDate = DateFormat('dd/MM/yyyy').parse(filterDate!);
    final selectedMonth = parsedFilterDate.month;
    final selectedYear = parsedFilterDate.year;

    // SO aggregation
    for (var item in widget.soList) {
      final soParsedDate = DateFormat('dd/MM/yyyy').parse(item.soDate);

      if (soParsedDate.month != selectedMonth ||
          soParsedDate.year != selectedYear) {
        continue; // skip other months
      }

      final val = double.tryParse(item.pendingValue) ?? 0;

      soMap[item.soDate] = (soMap[item.soDate] ?? 0) + val;

      dateMap[item.soDate] = item.soDate;

      soNosMap.putIfAbsent(item.soDate, () => []);
      soNosMap[item.soDate]!.add(item.soNo); // ADD
    }

    // Sales aggregation
    for (var item in widget.salesList) {
      final val = double.tryParse(item.rowTotal) ?? 0;
      String? invDate = DateFormat(
        'dd/MM/yyyy',
      ).format(item.invoiceDate).toString();
      salesMap[invDate] = (salesMap[invDate] ?? 0) + val;

      dateMap[invDate] = invDate;

      invoiceNosMap.putIfAbsent(invDate, () => []);
      invoiceNosMap[invDate]!.add(item.invoiceNo); // ADD
    }

    final allCustomers = {...soMap.keys, ...salesMap.keys};

    return allCustomers.map((date) {
      return CombinedMonthData(
        docDate: date,
        soValue: soMap[date] ?? 0,
        salesValue: salesMap[date] ?? 0,
        soNos: (soNosMap[date] ?? []).toSet().toList(), // DISTINCT
        invoiceNos: (invoiceNosMap[date] ?? []).toSet().toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    String tmpFilterDate = filterDate!;

    String? selectedMonth = DateFormat('MMM yyyy')
        .format(
          DateTime(
            DateFormat('dd/MM/yyyy').parse(filterDate!).year,
            DateFormat('dd/MM/yyyy').parse(filterDate!).month,
            1,
          ),
        )
        .toString();
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
              tmpFilterDate,
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
          if (filteredSoList.length != widget.soDailyList.length ||
              filteredSalesList.length != widget.salesDailyList.length)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: "Clear Filter",
              onPressed: () {
                resetFilters();
              },
            ),
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
              buildCombinedMonthBarChart(
                context: context,
                data: combinedMonthData,
                title: "SO vs Sales - $selectedMonth",
                color: Colors.green,
              ),
              const SizedBox(height: 30),

              buildCombinedBarChart(
                context: context,
                data: combinedData,
                title: "SO vs Sales - $filterDate (Customer Wise)",
                color: Colors.green,
              ),
              const SizedBox(height: 30),

              buildBarChart(
                data: soChartData,
                title: "Sales Orders - $filterDate (Customer Wise)",
                color: Colors.blue,
              ),
              const SizedBox(height: 30),

              buildBarChart(
                data: salesChartData,
                title: "Invoices - $filterDate (Customer Wise)",
                color: Colors.green,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBarChart({
    required List<CustomerChartData> data,
    required String title,
    required Color color,
  }) {
    data.sort((a, b) => b.value.compareTo(a.value));
    final chartData = data.toList();

    AxisConfig? axis;
    if (chartData.isNotEmpty) {
      axis = getAxisConfig(chartData);
    } else {
      axis = AxisConfig(10, 2);
    }
    final minValue = data.fold<double>(0, (prev, e) {
      final val = e.value;
      return val < prev ? val : prev;
    });
    final minY = minValue < 0 ? minValue * 1.5 : 0;
    final interval = (axis.maxY - minY) / 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        chartData.isEmpty
            ? SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 40,
                        color: Colors.grey.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No data for selected date",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartData.length == 1 ? 160 : chartData.length * 80,
                  height: 300,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: BarChart(
                      duration: const Duration(milliseconds: 250),
                      BarChartData(
                        maxY: axis.maxY,
                        // minY: 0,
                        minY: minValue < 0 ? minValue : 0,
                        baselineY: 0,
                        alignment: chartData.length <= 2
                            ? BarChartAlignment.spaceEvenly
                            : BarChartAlignment.spaceAround,
                        gridData: FlGridData(show: false),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: 0,
                              color: Colors.grey,
                              strokeWidth: 1,
                              dashArray: [5, 5], // optional dashed line
                            ),
                          ],
                        ),
                        barGroups: List.generate(chartData.length, (index) {
                          final item = chartData[index];
                          return BarChartGroupData(
                            x: index,

                            barRods: [
                              BarChartRodData(
                                toY: item.value,
                                width: chartData.length == 1
                                    ? 28
                                    : chartData.length == 2
                                    ? 22
                                    : 18,
                                color: item.value < 0 ? Colors.red : color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            left: BorderSide(color: Colors.black12),
                            bottom: BorderSide.none,
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
                              interval: interval,
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
                                if (value > axis!.maxY) return const SizedBox();
                                final index = value.toInt();
                                if (index >= chartData.length) {
                                  return const SizedBox();
                                }

                                return Transform.rotate(
                                  angle: -0.785, // -45 degrees in radians
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      chartData[index]
                                          .customerCode, // using code now
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
                              final docs = item.docNos.toSet().join(",\n");
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

    final minValue = data.fold<double>(0, (prev, e) {
      final val = e.salesValue;
      return val < prev ? val : prev;
    });

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

        chartData.isEmpty
            ? SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 40,
                        color: Colors.grey.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No data for selected date",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (chartData.length * 80)
                      .clamp(160, double.infinity)
                      .toDouble(),
                  height: 300,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: BarChart(
                      duration: const Duration(milliseconds: 250),
                      BarChartData(
                        maxY: axis.maxY,
                        minY: minValue < 0 ? minValue * 1.2 : 0,
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
                                color: item.salesValue < 0
                                    ? Colors.red
                                    : Colors.green,
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
                                if (value >=
                                    axis.maxY - (axis.interval * 0.1)) {
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
                                if (index >= chartData.length) {
                                  return const SizedBox();
                                }

                                return Transform.rotate(
                                  angle: -0.785, // -45 degrees in radians
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      chartData[index]
                                          .customerCode, // using code now
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
                              return BarTooltipItem(
                                "${item.customerName}\n"
                                "(${item.customerCode})\n\n"
                                "SO Value: ${item.soValue.toStringAsFixed(0)}\n"
                                "Sales Value: ${item.salesValue.toStringAsFixed(0)}\n\n"
                                "SO Count: ${item.soNos.length}\n"
                                "Invoice Count: ${item.invoiceNos.length}\n\n",
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              );
                            },
                          ),
                          touchCallback: (event, response) {
                            if (event is FlTapUpEvent && // IMPORTANT FIX
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

  Widget buildCombinedMonthBarChart({
    required BuildContext context,
    required List<CombinedMonthData> data,
    required String title,
    required Color color,
  }) {
    data.sort((a, b) {
      final dateA = DateFormat('dd/MM/yyyy').parse(a.docDate);
      final dateB = DateFormat('dd/MM/yyyy').parse(b.docDate);
      return dateB.compareTo(dateA); // latest first
    });
    final chartData = data.toList();

    final axis = getCombinedAxisConfig(
      data,
      (e) => e.soValue > e.salesValue ? e.soValue : e.salesValue,
    );

    final minValue = data.fold<double>(0, (prev, e) {
      final val = e.salesValue;
      return val < prev ? val : prev;
    });

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

        chartData.isEmpty
            ? SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 40,
                        color: Colors.grey.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "No data for selected month",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (chartData.length * 80)
                      .clamp(160, double.infinity)
                      .toDouble(),
                  height: 300,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: BarChart(
                      BarChartData(
                        maxY: axis.maxY,
                        minY: minValue < 0 ? minValue * 1.2 : 0,
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
                                width: 25,
                                borderRadius: BorderRadius.circular(4),
                              ),

                              // SALES BAR (Green)
                              BarChartRodData(
                                toY: item.salesValue,
                                color: item.salesValue < 0
                                    ? Colors.red
                                    : Colors.green,
                                width: 25,
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
                                if (value >=
                                    axis.maxY - (axis.interval * 0.1)) {
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
                                if (index >= chartData.length) {
                                  return const SizedBox();
                                }

                                return Transform.rotate(
                                  angle: -0.785, // -45 degrees in radians
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      chartData[index]
                                          .docDate, // using code now
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
                              return BarTooltipItem(
                                "${item.docDate}\n"
                                "SO Value: ${item.soValue.toStringAsFixed(0)}\n"
                                "Sales Value: ${item.salesValue.toStringAsFixed(0)}\n\n"
                                "SO Count: ${item.soNos.length}\n"
                                "Invoice Count: ${item.invoiceNos.length}\n\n",
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              );
                            },
                          ),
                          touchCallback: (event, response) {
                            if (event is FlTapUpEvent &&
                                response != null &&
                                response.spot != null) {
                              final index = response.spot!.touchedBarGroupIndex;
                              final rodIndex =
                                  response.spot!.touchedRodDataIndex;
                              final item = chartData[index];
                              filterDate = item.docDate;
                              final isSO = rodIndex == 0;
                              _filterChartsByDate(item.docDate);
                              _showMonthlyDetails(context, item, isSO);
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

  void _showMonthlyDetails(
    BuildContext context,
    CombinedMonthData item,
    bool isSO,
  ) {
    final selectedDate = item.docDate;
    double dayTotal = 0;
    final parsedSelectedDate = DateFormat('dd/MM/yyyy').parse(selectedDate);
    final soData = widget.soList.where((e) {
      final parsedSoDate = DateFormat('dd/MM/yyyy').parse(e.soDate);
      return parsedSoDate.isBefore(parsedSelectedDate) ||
          parsedSoDate.isAtSameMomentAs(parsedSelectedDate);
    }).toList();

    final salesData = widget.salesList
        .where(
          (e) => DateFormat('dd/MM/yyyy').format(e.invoiceDate) == selectedDate,
        )
        .toList();

    Map<String, Map<String, List<SODetailsList>>> soGrouped = {};

    for (var item in soData) {
      soGrouped.putIfAbsent(item.customerName, () => {});
      soGrouped[item.customerName]!.putIfAbsent(item.soNo, () => []);
      soGrouped[item.customerName]![item.soNo]!.add(item);
    }

    Map<String, Map<String, List<SalesList>>> salesGrouped = {};
    for (var item in salesData) {
      salesGrouped.putIfAbsent(item.customerName, () => {});
      salesGrouped[item.customerName]!.putIfAbsent(item.invoiceNo, () => []);
      salesGrouped[item.customerName]![item.invoiceNo]!.add(item);
    }

    if (isSO) {
      for (var item in soData) {
        dayTotal += double.tryParse(item.pendingValue) ?? 0;
      }
    } else {
      for (var item in salesData) {
        dayTotal += double.tryParse(item.rowTotal) ?? 0;
      }
    }

    final headerTitle = isSO
        ? "Pending Sales Orders Upto - $selectedDate"
        : "Invoices - $selectedDate";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // important
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
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
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSO
                                    ? Colors.blue.withValues(alpha: 0.08)
                                    : Colors.green.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSO
                                      ? Colors.blue.withValues(alpha: 0.3)
                                      : Colors.green.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                headerTitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSO
                                      ? Colors.blue[800]
                                      : Colors.green[800],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
                          Divider(
                            thickness: 1,
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                          ...(isSO
                              ? soGrouped.entries.map((cust) {
                                  double customerTotal = 0;
                                  for (var doc in cust.value.values) {
                                    for (var item in doc) {
                                      customerTotal +=
                                          double.tryParse(item.pendingValue) ??
                                          0;
                                    }
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            onTap: () {
                                              setModalState(() {
                                                expandedCustomers[cust.key] =
                                                    !(expandedCustomers[cust
                                                            .key] ??
                                                        false);
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    (expandedCustomers[cust
                                                            .key] ??
                                                        false)
                                                    ? (isSO
                                                          ? Colors.blue
                                                                .withValues(
                                                                  alpha: 0.08,
                                                                )
                                                          : Colors.green
                                                                .withValues(
                                                                  alpha: 0.08,
                                                                ))
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      cust.key,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSO
                                                            ? Colors.blue[800]
                                                            : Colors.green[800],
                                                      ),
                                                      softWrap: true,
                                                    ),
                                                  ),

                                                  const SizedBox(width: 8),

                                                  AnimatedRotation(
                                                    turns:
                                                        (expandedCustomers[cust
                                                                .key] ??
                                                            false)
                                                        ? 0.5
                                                        : 0.0,
                                                    duration: const Duration(
                                                      milliseconds: 250,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            (isSO
                                                                    ? Colors
                                                                          .blue
                                                                    : Colors
                                                                          .green)
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .keyboard_arrow_down,
                                                        size: 20,
                                                        color: isSO
                                                            ? Colors.blue[700]
                                                            : Colors.green[700],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      AnimatedSize(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        alignment: Alignment.topCenter,
                                        child:
                                            (expandedCustomers[cust.key] ??
                                                false)
                                            ? Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withValues(
                                                    alpha: 0.2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.08,
                                                          ),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ), // elevation feel
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: Colors.grey
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ...cust.value.entries.toList().asMap().entries.map((
                                                      entry,
                                                    ) {
                                                      final index = entry.key;
                                                      final doc = entry.value;

                                                      double docTotal = 0;

                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            "SO: ${doc.key}",
                                                            style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 15,
                                                              color:
                                                                  Color.fromRGBO(
                                                                    120,
                                                                    36,
                                                                    63,
                                                                    1,
                                                                  ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 6,
                                                          ),

                                                          // HEADER ROW
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              border: Border(
                                                                bottom: BorderSide(
                                                                  color: Colors
                                                                      .grey
                                                                      .withValues(
                                                                        alpha:
                                                                            0.5,
                                                                      ),
                                                                ),
                                                              ),
                                                              color:
                                                                  const Color.fromARGB(
                                                                    255,
                                                                    82,
                                                                    82,
                                                                    82,
                                                                  ).withValues(
                                                                    alpha: 0.08,
                                                                  ),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                const Expanded(
                                                                  flex: 5,
                                                                  child: Text(
                                                                    "Item Name",
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                                _vDivider(),
                                                                const Expanded(
                                                                  flex: 2,
                                                                  child: Text(
                                                                    "Qty",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                                _vDivider(),
                                                                const Expanded(
                                                                  flex: 3,
                                                                  child: Text(
                                                                    "Value",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),

                                                          // PRODUCT ROWS
                                                          ...doc.value.map((
                                                            prod,
                                                          ) {
                                                            final qty =
                                                                (double.tryParse(
                                                                          prod.pendingQuantity,
                                                                        ) ??
                                                                        0)
                                                                    .toInt()
                                                                    .toString();

                                                            final val =
                                                                double.tryParse(
                                                                  prod.pendingValue,
                                                                ) ??
                                                                0.0;

                                                            docTotal += val;

                                                            return Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 6,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                border: Border(
                                                                  bottom: BorderSide(
                                                                    color: Colors
                                                                        .grey
                                                                        .withValues(
                                                                          alpha:
                                                                              0.2,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    flex: 5,
                                                                    child: Text(
                                                                      prod.productName,
                                                                      softWrap:
                                                                          true,
                                                                    ),
                                                                  ),
                                                                  _vDivider(),
                                                                  Expanded(
                                                                    flex: 2,
                                                                    child: Text(
                                                                      qty,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .right,
                                                                    ),
                                                                  ),
                                                                  _vDivider(),
                                                                  Expanded(
                                                                    flex: 3,
                                                                    child: Text(
                                                                      val.toStringAsFixed(
                                                                        2,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .right,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }),

                                                          // DOC TOTAL
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 8,
                                                                ),
                                                            child: Row(
                                                              children: [
                                                                const Expanded(
                                                                  flex: 5,
                                                                  child: Text(
                                                                    "SO. Total",
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                                _vDivider(),
                                                                const Expanded(
                                                                  flex: 2,
                                                                  child:
                                                                      SizedBox(),
                                                                ),
                                                                _vDivider(),
                                                                Expanded(
                                                                  flex: 3,
                                                                  child: Text(
                                                                    docTotal
                                                                        .toStringAsFixed(
                                                                          2,
                                                                        ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                    style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (index !=
                                                              cust
                                                                      .value
                                                                      .length -
                                                                  1)
                                                            const Divider(),
                                                        ],
                                                      );
                                                    }),
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          top: BorderSide(
                                                            color: Colors.grey
                                                                .withValues(
                                                                  alpha: 0.4,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 5,
                                                            child: Text(
                                                              "Customer Total",
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),

                                                          _vDivider(),

                                                          const Expanded(
                                                            flex: 2,
                                                            child: SizedBox(),
                                                          ),

                                                          _vDivider(),

                                                          Expanded(
                                                            flex: 3,
                                                            child: Text(
                                                              customerTotal
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox(),
                                      ),

                                      const SizedBox(height: 10),
                                    ],
                                  );
                                })
                              : salesGrouped.entries.map((cust) {
                                  double customerTotal = 0;

                                  for (var doc in cust.value.values) {
                                    for (var item in doc) {
                                      customerTotal +=
                                          double.tryParse(item.rowTotal) ?? 0;
                                    }
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            onTap: () {
                                              setModalState(() {
                                                expandedCustomers[cust.key] =
                                                    !(expandedCustomers[cust
                                                            .key] ??
                                                        false);
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    (expandedCustomers[cust
                                                            .key] ??
                                                        false)
                                                    ? Colors.green.withValues(
                                                        alpha: 0.08,
                                                      )
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      cust.key,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSO
                                                            ? Colors.blue[800]
                                                            : Colors.green[800],
                                                      ),
                                                      softWrap: true,
                                                    ),
                                                  ),

                                                  const SizedBox(width: 8),

                                                  AnimatedRotation(
                                                    turns:
                                                        (expandedCustomers[cust
                                                                .key] ??
                                                            false)
                                                        ? 0.5
                                                        : 0.0,
                                                    duration: const Duration(
                                                      milliseconds: 250,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            (isSO
                                                                    ? Colors
                                                                          .blue
                                                                    : Colors
                                                                          .green)
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .keyboard_arrow_down,
                                                        size: 20,
                                                        color: isSO
                                                            ? Colors.blue[700]
                                                            : Colors.green[700],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // ANIMATED DETAILS
                                      AnimatedSize(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                        alignment: Alignment.topCenter,
                                        child:
                                            (expandedCustomers[cust.key] ??
                                                false)
                                            ? Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.08,
                                                          ),
                                                      blurRadius: 10,
                                                      offset: const Offset(
                                                        0,
                                                        4,
                                                      ), // elevation feel
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: Colors.grey
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    ...cust.value.entries.toList().asMap().entries.map((
                                                      entry,
                                                    ) {
                                                      final index = entry.key;
                                                      final doc = entry.value;
                                                      double docTotal = 0;

                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            "Invoice: ${doc.key}",
                                                            style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                              color:
                                                                  Color.fromRGBO(
                                                                    120,
                                                                    36,
                                                                    63,
                                                                    1,
                                                                  ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 6,
                                                          ),

                                                          // HEADER
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              border: Border(
                                                                bottom: BorderSide(
                                                                  color: Colors
                                                                      .grey
                                                                      .withValues(
                                                                        alpha:
                                                                            0.5,
                                                                      ),
                                                                ),
                                                              ),
                                                              color: Colors
                                                                  .green
                                                                  .withValues(
                                                                    alpha: 0.08,
                                                                  ),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                const Expanded(
                                                                  flex: 5,
                                                                  child: Text(
                                                                    "Item Name",
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                                _vDivider(),
                                                                const Expanded(
                                                                  flex: 2,
                                                                  child: Text(
                                                                    "Qty",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                                _vDivider(),
                                                                const Expanded(
                                                                  flex: 3,
                                                                  child: Text(
                                                                    "Value",
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),

                                                          // ROWS
                                                          ...doc.value.map((
                                                            prod,
                                                          ) {
                                                            final qty =
                                                                (double.tryParse(
                                                                          prod.quantity,
                                                                        ) ??
                                                                        0)
                                                                    .toInt()
                                                                    .toString();

                                                            final val =
                                                                double.tryParse(
                                                                  prod.rowTotal,
                                                                ) ??
                                                                0.0;

                                                            docTotal += val;

                                                            return Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 6,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                border: Border(
                                                                  bottom: BorderSide(
                                                                    color: Colors
                                                                        .grey
                                                                        .withValues(
                                                                          alpha:
                                                                              0.2,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    flex: 5,
                                                                    child: Text(
                                                                      prod.description,
                                                                      softWrap:
                                                                          true,
                                                                    ),
                                                                  ),
                                                                  _vDivider(),
                                                                  Expanded(
                                                                    flex: 2,
                                                                    child: Text(
                                                                      qty,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .right,
                                                                    ),
                                                                  ),
                                                                  _vDivider(),
                                                                  Expanded(
                                                                    flex: 3,
                                                                    child: Text(
                                                                      val.toStringAsFixed(
                                                                        2,
                                                                      ),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .right,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }),

                                                          // DOC TOTAL
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 8,
                                                                ),
                                                            child: Row(
                                                              children: [
                                                                const Expanded(
                                                                  flex: 5,
                                                                  child: Text(
                                                                    "Inv. Total",
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                                _vDivider(),
                                                                const Expanded(
                                                                  flex: 2,
                                                                  child:
                                                                      SizedBox(),
                                                                ),
                                                                _vDivider(),
                                                                Expanded(
                                                                  flex: 3,
                                                                  child: Text(
                                                                    docTotal
                                                                        .toStringAsFixed(
                                                                          2,
                                                                        ),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                    style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (index !=
                                                              cust
                                                                      .value
                                                                      .length -
                                                                  1)
                                                            const Divider(),
                                                        ],
                                                      );
                                                    }),
                                                    const SizedBox(height: 8),
                                                    // CUSTOMER TOTAL
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          top: BorderSide(
                                                            color: Colors.grey
                                                                .withValues(
                                                                  alpha: 0.4,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Expanded(
                                                            flex: 5,
                                                            child: Text(
                                                              "Customer Total",
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          _vDivider(),
                                                          const Expanded(
                                                            flex: 2,
                                                            child: SizedBox(),
                                                          ),
                                                          _vDivider(),
                                                          Expanded(
                                                            flex: 3,
                                                            child: Text(
                                                              customerTotal
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox(),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  );
                                })),
                          const SizedBox(height: 10),
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSO
                                  ? Colors.blue.withValues(alpha: 0.08)
                                  : Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: isSO
                                    ? Colors.blue.withValues(alpha: 0.4)
                                    : Colors.green.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    "Day Grand Total",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isSO
                                          ? Colors.blue[800]
                                          : Colors.green[800],
                                    ),
                                  ),
                                ),

                                _vDivider(),

                                const Expanded(flex: 2, child: SizedBox()),

                                _vDivider(),

                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    dayTotal.toStringAsFixed(2),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isSO
                                          ? Colors.blue[800]
                                          : Colors.green[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      },
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 20,
      color: const Color.fromARGB(255, 116, 118, 131).withValues(alpha: 0.3),
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
          const Text(
            "Documents:",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
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
}
