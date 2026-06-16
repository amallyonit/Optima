// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/classes/globals.dart';
import '../../../../classes/dataManager.dart';
import '../../../../notificationService.dart';
import '../../ReportService.dart';
import '../../dashboard_card_ui.dart';

class MonthlyComplaintData {
  final String monthName;
  double noOfComplaints;

  MonthlyComplaintData({required this.monthName, required this.noOfComplaints});
}

class MonthlyComplaintList {
  List<MonthlyComplaintData> monthlyData;

  MonthlyComplaintList({required this.monthlyData});
}

class ExternalComplaintPage extends StatefulWidget {
  const ExternalComplaintPage({super.key});

  @override
  State<ExternalComplaintPage> createState() => _ExternalComplaintPageState();
}

class _ExternalComplaintPageState extends State<ExternalComplaintPage> {
  DateTime? selectedDate = DateTime.now();
  final reportService = ReportService();
  DateTime? currentDate;
  DateTime? fiscalYearStartDate;
  DateTime? lastMonthFromDate;
  bool chartDataLoaded = false;
  String? formattedFiscalYearStartDate;
  String? formattedDateNow;
  late Future<void> loadDataFuture;
  List<CustomerComplaint> complaintData = [];
  List<CustomerComplaint> complaintDataTemp = [];
  MonthlyComplaintList monthlyComplaintData = MonthlyComplaintList(
    monthlyData: [],
  );

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  DateTime addMonth(DateTime date, int addMonth) {
    int currentMonth = date.month;
    int currentYear = date.year;
    int nextMonth = currentMonth + addMonth;
    int nextYear = currentYear;
    // Handle the case when the next month is December
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }

    int lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    // Handle the case when the original date is at the end of the month
    int originalDay = date.day;
    if (originalDay > lastDayOfNextMonth) {
      originalDay = lastDayOfNextMonth;
    }
    return DateTime(nextYear, nextMonth, originalDay);
  }

  void LoadDates() {
    currentDate = DateTime.now();
    int fiscalYearStartMonth = 4;
    int fiscalYear = currentDate!.month >= fiscalYearStartMonth
        ? currentDate!.year
        : currentDate!.year - 1;
    fiscalYearStartDate = DateTime(fiscalYear, fiscalYearStartMonth, 1);
    lastMonthFromDate = DateTime(
      fiscalYearStartDate!.year,
      fiscalYearStartDate!.month - 1,
      1,
    );
    formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
  }

  SideTitles get _leftTitles => SideTitles(
    reservedSize: 50,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String leftDouble = "";
      leftDouble = value.toInt().toString();
      return Text(leftDouble, style: const TextStyle(fontSize: 12));
    },
  );

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  SideTitles get _bottomTitlesComplaints => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<MonthlyComplaintData> mData = monthlyComplaintData.monthlyData;
      text = mData.elementAt(value.toInt()).monthName;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RotationTransition(
          turns: const AlwaysStoppedAnimation(-25 / 360),
          child: text.length > 7
              ? Text(
                  '${text.substring(0, 5)}...',
                  style: const TextStyle(fontSize: 12),
                )
              : Text(text, style: const TextStyle(fontSize: 12)),
        ),
      );
    },
  );

  List<BarChartGroupData> _complaintChartData(List<MonthlyComplaintData> data) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.noOfComplaints,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Map<String, DateTime> getMonthStartEndDates(int month) {
    DateTime now = DateTime.now();

    int currentYear = now.year;

    int yearForMonth;
    if (now.month >= 1 && now.month <= 3) {
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear - 1
          : currentYear;
    } else {
      yearForMonth = (month >= 4 && month <= 12)
          ? currentYear
          : currentYear + 1;
    }

    DateTime firstDayOfMonth = DateTime(yearForMonth, month, 1);
    DateTime lastDayOfMonth = DateTime(yearForMonth, month + 1, 0);

    return {'start': firstDayOfMonth, 'end': lastDayOfMonth};
  }

  Future<void> _loadComplaints(String UserName, String UserLevel) async {
    int index = 0;
    int limit = 10000;
    int fetchedCount = 0;
    List<CustomerComplaint> tmpComplaintList = [];
    try {
      do {
        var body = {
          "FromDate": formatDate(fiscalYearStartDate!),
          "ToDate": formatDate(currentDate!),
          "Index": index.toString(),
          "Limit": limit.toString(),
          "sapToken": DataManager.readSapToken(),
        };
        const apiUrl = '${ApiHelper.baseUrl}CRMComplaintList';
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          if (responseJson["responseData"].toString().isNotEmpty) {
            List<CustomerComplaint> newComplaintList =
                (responseJson['responseData'] as List)
                    .map((item) => CustomerComplaint.fromJson(item))
                    .toList();

            tmpComplaintList.addAll(newComplaintList);
            fetchedCount = newComplaintList.length;
            index++;
          } else {
            fetchedCount = 0;
          }
        } else {
          fetchedCount = 0;
        }
      } while (fetchedCount == limit);

      setState(() {
        complaintData = tmpComplaintList;
        complaintDataTemp = tmpComplaintList;
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading complaints.",
      );
    }
  }

  Future<void> _loadMonthlyComplaintData() async {
    var complaintList = complaintData;
    Map<int, double> monthCounts = {for (var i = 1; i <= 12; i++) i: 0.0};
    final dateFormat = DateFormat('M/d/yyyy h:mm:ss a');
    for (var complaint in complaintList) {
      String? dateStr = (complaint).dateReceived;

      if (dateStr.isEmpty) {
        continue;
      }

      try {
        DateTime complaintDate = dateFormat.parse(dateStr);

        int month = complaintDate.month;
        if (monthCounts.containsKey(month)) {
          monthCounts[month] = monthCounts[month]! + 1.0;
        }
      } on FormatException catch (e) {
        if (kDebugMode) {
          print('--- FAILED TO PARSE DATE ---');
          print('String from API: $dateStr');
          print('Expected Format: M/d/yyyy h:mm:ss a');
          print('Error: $e');
          print('-----------------------------');
        }
      }
    }

    List<MonthlyComplaintData> finalMonthlyList = [];

    String getMonthAbbr(int month) {
      return DateFormat('MMM').format(DateTime(currentDate!.year, month, 1));
    }

    List<int> fiscalMonthOrder = [4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3];

    for (int month in fiscalMonthOrder) {
      double count = monthCounts[month] ?? 0.0;

      if (count > 0) {
        finalMonthlyList.add(
          MonthlyComplaintData(
            monthName: getMonthAbbr(month),
            noOfComplaints: count,
          ),
        );
      }
    }

    final monthlyComplaintListLocal = MonthlyComplaintList(
      monthlyData: finalMonthlyList,
    );

    if (mounted) {
      setState(() {
        monthlyComplaintData = monthlyComplaintListLocal;
      });
    } else {
      monthlyComplaintData = monthlyComplaintListLocal;
    }
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = selectedUser == ""
        ? prefs.getString('userName') ?? ''
        : selectedUser;
    selectedUser == "" ? prefs.getString('userName') ?? '' : selectedUser;
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadComplaints(userName, userLevel);
    await _loadMonthlyComplaintData();
    chartDataLoaded = true;
  }

  String formatDateForReport(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';

    try {
      return DateFormat(
        'dd/MM/yyyy',
      ).format(DateFormat('M/d/yyyy h:mm:ss a').parse(dateStr));
    } catch (_) {
      try {
        return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
      } catch (_) {
        return dateStr;
      }
    }
  }

  Future<void> generateComplaintReportExcel(BuildContext context) async {
    final headers = [
      'Sl No.',
      'Data Recv.',
      'Customer Name',
      'Plant',
      'Sales Manager',
      'Complaint Evidence',
      'Nature of Complaint',
      'Product Name',
      'Manf. Lot Number',
      'Complaint Related to',
      'Root Cause',
      'Corrective Action',
      'Preventive Action',
      'Status',
    ];
    int SlNo = 1;
    await reportService.generateExcel(
      sheetName: 'ComplaintsReport',
      headers: headers,
      rows: complaintData
          .map(
            (complaint) => [
              SlNo++,
              formatDateForReport(complaint.dateReceived),
              complaint.customerName,
              complaint.plant,
              complaint.salesManager,
              '', // Complaint Evidence (Placeholder)
              complaint.natureOfComplaint,
              complaint.productName,
              complaint.mfrLotNo,
              complaint.problemType,
              complaint.rootCause,
              complaint.correctiveAction,
              complaint.preventiveAction,
              complaint.status,
            ],
          )
          .toList(),
      fileName: 'customer_complaint_report.xlsx',
      amountColumns: [],
      addTotalRow: false,
      reportTitle: 'Production[MIS] - Customer Complaint Report',
    );
  }

  double getMaxValue(double maxValue, double divVal) {
    return (maxValue / divVal).ceil() * divVal;
  }

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    selectedDate = DateTime.now();
    super.initState();
    LoadDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData("");
    }
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formattedFiscalYearStartDate = DateFormat(
      'dd/MM/yy',
    ).format(fiscalYearStartDate!);
    String formattedDateNow = DateFormat('dd/MM/yy').format(currentDate!);
    return chartDataLoaded == true
        ? FinanceVerticalScroll(
            controller: _verticalScrollController,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 15),
                        Text(
                          "$formattedFiscalYearStartDate - $formattedDateNow",
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.all(8),
                  child: DashboardCardUI(
                    title: 'External Complaint Report.',
                    spacing: 10,
                    menuItems: [
                      PopupMenuItem(
                        onTap: () {
                          generateComplaintReportExcel(context);
                        },
                        child: const Text("Download Excel"),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _customerComplaintGraph(),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  Widget _customerComplaintGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = monthlyComplaintData.monthlyData.length;
    if (monthlyComplaintData.monthlyData.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }
    double maxAmount = len > 0
        ? monthlyComplaintData.monthlyData
              .map((data) => data.noOfComplaints)
              .reduce((a, b) => a > b ? a : b)
        : 0;
    return FinanceHorizontalChartScroll(
      controller: _horizontalController,
      verticalController: _verticalScrollController,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: BarChart(
            BarChartData(
              maxY: getMaxValue(maxAmount, 10),
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
                  sideTitles: _bottomTitlesComplaints,
                  axisNameSize: 20,
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
              barGroups: _complaintChartData(monthlyComplaintData.monthlyData),
              barTouchData: BarTouchData(
                allowTouchBarBackDraw: true,
                touchCallback: (flTouchEvent, barTouchResponse) async {
                  if (barTouchResponse != null &&
                      barTouchResponse.spot != null) {
                    setState(() {
                      if (flTouchEvent is FlTapUpEvent) {
                        // touchedWarehouseLocation = touchedWarehouseLocation == ""
                        //     ? warehouseLocationList
                        //     .warehouseData[
                        // barTouchResponse.spot!.spot.x.toInt()]
                        //     .warehouseName
                        //     : "";
                        // selectedChart = barTouchResponse.spot!.spot.x;
                        // showDrillDownChart = true;
                        // loadDataWithFilter(
                        //   touchedAging,
                        //   touchedWarehouseLocation,
                        //   touchedItemGroup,
                        //   touchedItemSubGroup,
                        // );
                      }
                    });
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  maxContentWidth: 200,
                  tooltipBorder: const BorderSide(
                    width: 2.0,
                    color: Colors.black12,
                    style: BorderStyle.none,
                  ),
                  getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                    return BarTooltipItem(
                      monthlyComplaintData.monthlyData[grpIndex].monthName,
                      const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              "\nTotal Complaints: ${monthlyComplaintData.monthlyData[grpIndex].noOfComplaints}",
                          style: const TextStyle(
                            color: Colors.black, //widget.touchedBarColor,
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

class ItemSubGroupDropdown extends StatefulWidget {
  final List production;
  final ValueChanged<String?> onChanged;
  final String placeholder;

  const ItemSubGroupDropdown({
    super.key,
    required this.production,
    required this.onChanged,
    this.placeholder = 'Kits/Gowns',
  });

  @override
  State<ItemSubGroupDropdown> createState() => _ItemSubGroupDropdownState();
}

class _ItemSubGroupDropdownState extends State<ItemSubGroupDropdown> {
  late final List<String> _items;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _items = _extractItemSubGroups(widget.production);
    _selected = _items.isNotEmpty ? _items.first : null;
  }

  List<String> _extractItemSubGroups(List list) {
    final seen = <String>{};
    final out = <String>[];
    for (var e in list) {
      String val = '';
      try {
        val = (e.branchName ?? '').toString().trim();
      } catch (_) {
        if (e is Map && e.containsKey('branchName')) {
          val = (e['branchName'] ?? '').toString();
        }
      }
      if (val.trim().isEmpty) continue;
      if (!seen.contains(val)) {
        seen.add(val);
        out.add(val);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selected,
              hint: const SizedBox.shrink(),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: _items.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selected = val;
                });
                widget.onChanged(val);
              },
              isDense: true,
              isExpanded: false,
            ),
          ),
        ],
      ),
      onTap: () {},
    );
  }
}
