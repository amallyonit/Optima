// ignore_for_file: file_names, use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:open_file/open_file.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/excel_helper.dart';

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:excel/excel.dart' as xl;

import '../../../../notificationService.dart';

class DepartmentOvertimeData {
  final String departmentName;
  final double otHours;
  final double otAmount;

  DepartmentOvertimeData({
    required this.departmentName,
    required this.otHours,
    required this.otAmount,
  });
}

class DepartmentOvertimeList {
  final List<DepartmentOvertimeData> data;

  DepartmentOvertimeList({required this.data});
}

DepartmentOvertimeList overtimeGraphData = DepartmentOvertimeList(data: []);

class OvertimeReportPage extends StatefulWidget {
  @override
  _OvertimeReportPageState createState() => _OvertimeReportPageState();
}

class _OvertimeReportPageState extends State<OvertimeReportPage> {
  final List<String> headers = ["Division", "OT Hours", "OT Amount", "Remarks"];

  final List<String> departments = [
    "Production 1",
    "Production 2",
    "Production 3",
    "Production 4",
    "Sterile",
    "Quality",
    "Sample",
    "Maintenance",
    "Medical Device",
    "Inventory",
    "SCM",
    "Admin & HR",
  ];

  late List<List<TextEditingController>> controllers;
  late List<List<FocusNode>> focusNodes;

  final FocusNode targetFocusNode = FocusNode();

  late List<double> totals;
  int remainingCells = 0;
  String userID = "";
  String? _selectedPlant = 'Rajapalayam Plant';
  double target = 0;

  final TextEditingController targetController = TextEditingController();

  DateTime? selectedDate;
  final DateFormat displayFormat = DateFormat('MMM/yyyy');
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    targetFocusNode.addListener(() {
      if (targetFocusNode.hasFocus) {
        targetController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: targetController.text.length,
        );
      }
    });
    selectedDate = DateTime.now();
    loadData();
  }

  Future<void> selectOvertimeDetails() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a month first.")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final selectedMonth = DateFormat('yyyy-MM').format(selectedDate!);

    final payload = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      "OtPlant": _selectedPlant,
      "MonthYear": selectedMonth,
    };

    const apiUrl = '${ApiHelper.baseUrl}selectmonthlyovertimedetails';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(payload),
        headers: headerss,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);

        if (decoded['Status'] == true && decoded['Data'] != null) {
          final List<dynamic> result = decoded['Data'];

          _loadOvertimeGraphData(result);

          departments.clear();
          controllers.clear();

          for (int i = 0; i < result.length; i++) {
            final row = result[i];
            if (i == 0) {
              final val = row['Target'];
              double? target;

              if (val != null) {
                target = (val is num)
                    ? val.toDouble()
                    : double.tryParse(val.toString());
              }
              targetController.text = target?.toString() ?? '';
            }

            departments.add(row['Department'] ?? '');
            final rowControllers = <TextEditingController>[
              TextEditingController(text: row['OTHours']?.toString() ?? ''),
              TextEditingController(text: row['OTAmount']?.toString() ?? ''),
              TextEditingController(text: row['Remarks']?.toString() ?? ''),
            ];

            // Add onChanged to trigger calculateTotals on every controller
            for (var controller in rowControllers) {
              controller.addListener(() {
                calculateTotals();
              });
            }
            controllers.add(rowControllers);
          }
        } else {
          clearValues();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No data found or status is false.")),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch: $e")));
    }
  }

  void _loadOvertimeGraphData(List<dynamic> apiResult) {
    List<DepartmentOvertimeData> processedList = [];

    for (var item in apiResult) {
      // 1. Extract Department Name
      String deptName = item['Department']?.toString() ?? 'Unknown';

      // 2. Extract and Parse OT Hours (Handle String or Number safely)
      double hours = 0.0;
      if (item['OTHours'] != null) {
        hours = double.tryParse(item['OTHours'].toString()) ?? 0.0;
      }

      // 3. Extract and Parse OT Amount
      double amount = 0.0;
      if (item['OTAmount'] != null) {
        amount = double.tryParse(item['OTAmount'].toString()) ?? 0.0;
      }

      // Only add to graph if there is actual data (optional check)
      if (hours > 0 || amount > 0) {
        processedList.add(
          DepartmentOvertimeData(
            departmentName: deptName,
            otHours: hours,
            otAmount: amount,
          ),
        );
      }
    }

    // Create the final list object
    final finalGraphData = DepartmentOvertimeList(data: processedList);

    // Update State
    if (mounted) {
      setState(() {
        overtimeGraphData = finalGraphData;
      });
    } else {
      overtimeGraphData = finalGraphData;
    }
  }

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

  SideTitles get _bottomTitlesOvertime => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<DepartmentOvertimeData> mData = overtimeGraphData.data;
      text = mData.elementAt(value.toInt()).departmentName;
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

  Future<void> loadData() async {
    controllers = List.generate(
      departments.length,
      (_) => List.generate(
        headers.length - 1,
        (index) =>
            TextEditingController(text: index == headers.length - 2 ? "" : "0"),
      ),
    );

    focusNodes = List.generate(
      departments.length,
      (i) => List.generate(headers.length - 1, (j) {
        final node = FocusNode();
        node.addListener(() {
          if (node.hasFocus) {
            controllers[i][j].selection = TextSelection(
              baseOffset: 0,
              extentOffset: controllers[i][j].text.length,
            );
          }
        });
        return node;
      }),
    );

    totals = List.filled(headers.length - 1, 0.0);
    remainingCells = headers.length - 3;

    // if (selectedDate != null) {
    await selectOvertimeDetails();
    // }
    setState(() {
      isLoading = false;
    });
  }

  int getWorkingDaysInMonthFromDate(DateTime date) {
    int year = date.year;
    int month = date.month;
    int totalDays = DateUtils.getDaysInMonth(year, month);
    int workingDays = 0;

    for (int day = 1; day <= totalDays; day++) {
      DateTime current = DateTime(year, month, day);
      if (current.weekday != DateTime.sunday) {
        workingDays++;
      }
    }

    return workingDays;
  }

  List<BarChartGroupData> monthlyChartData(List<DepartmentOvertimeData> data) {
    return data
        .map(
          (chartData) => BarChartGroupData(
            x: data.indexOf(chartData),
            barRods: [
              BarChartRodData(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.zero,
                toY: chartData.otAmount,
                width: 30,
              ),
              BarChartRodData(
                color: const Color(0xFF97D7F3),
                borderRadius: BorderRadius.zero,
                toY: chartData.otHours,
                width: 30,
              ),
            ],
          ),
        )
        .toList();
  }

  Future<void> calculateTotals() async {
    List<double> newTotals = List.filled(headers.length - 1, 0.0);
    if (controllers.isNotEmpty) {
      for (int col = 1; col < headers.length; col++) {
        for (int row = 0; row < departments.length; row++) {
          double val = double.tryParse(controllers[row][col - 1].text) ?? 0.0;
          newTotals[col - 1] += val;
        }
      }
    }
    setState(() {
      totals = newTotals;
    });
  }

  void clearValues() {
    for (int i = 0; i < totals.length; i++) {
      totals[i] = 0.0;
    }
    controllers = List.generate(
      departments.length,
      (_) => List.generate(
        headers.length - 1,
        (index) =>
            TextEditingController(text: index == headers.length - 2 ? "" : "0"),
      ),
    );

    targetController.clear();
    target = 0;
  }

  Future<void> generateOvertimeExcel(BuildContext context) async {
    // 1. Check if data exists
    if (overtimeGraphData.data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No Overtime data available to export.')),
      );
      return;
    }

    try {
      final excel = xl.Excel.createExcel();

      // 2. Create Sheet
      final sheet = excel['Overtime Report'];
      try {
        if (excel.sheets.containsKey('Sheet1')) {
          excel.delete('Sheet1');
        }
      } catch (_) {}

      // 3. Define Styles
      final headerStyle = xl.CellStyle(
        bold: true,
        verticalAlign: xl.VerticalAlign.Center,
        textWrapping: xl.TextWrapping.WrapText,
      );

      final cellStyle = xl.CellStyle(
        verticalAlign: xl.VerticalAlign.Top,
        textWrapping: xl.TextWrapping.WrapText,
      );

      // Style for the Total row at the bottom (Bold)
      final totalRowStyle = xl.CellStyle(
        bold: true,
        verticalAlign: xl.VerticalAlign.Center,
        backgroundColorHex: xl.ExcelColor.fromHexString(
          "#D3D3D3",
        ), // Optional: Light Grey
      );

      // 4. Add Title
      sheet.appendRow(toCellRow(['Overtime Report', '']));
      sheet.appendRow(toCellRow([])); // Empty spacer row

      int currentRowIndex = 2; // Starting index after title

      // 5. Add Headers
      final headers = ['DIVISION', 'OT HOURS', 'OT AMOUNT'];

      sheet.appendRow(toCellRow(headers));

      // Apply Header Style
      for (int i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(
            columnIndex: i,
            rowIndex: currentRowIndex,
          ),
        );
        cell.cellStyle = headerStyle;
      }
      currentRowIndex++;

      // 6. Variables for Totals
      double totalHours = 0.0;
      double totalAmount = 0.0;

      // 7. Loop Data and Add Rows
      for (final item in overtimeGraphData.data) {
        // Calculate totals
        totalHours += item.otHours;
        totalAmount += item.otAmount;

        final rowData = <Object?>[
          item.departmentName,
          item.otHours,
          item.otAmount,
        ];

        sheet.appendRow(toCellRow(rowData));

        // Apply Data Style
        for (int i = 0; i < rowData.length; i++) {
          var cell = sheet.cell(
            xl.CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: currentRowIndex,
            ),
          );
          cell.cellStyle = cellStyle;
        }
        currentRowIndex++;
      }

      // 8. Add TOTAL Row at the bottom
      final totalRowData = <Object?>[
        'TOTAL', // Division Column
        totalHours, // OT Hours Column
        totalAmount, // OT Amount Column
      ];

      sheet.appendRow(toCellRow(totalRowData));

      // Apply Total Row Style
      for (int i = 0; i < totalRowData.length; i++) {
        var cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(
            columnIndex: i,
            rowIndex: currentRowIndex,
          ),
        );
        cell.cellStyle = totalRowStyle;
      }

      // 9. Save and Open
      if (kIsWeb) {
        final excelBytes = excel.encode()!;
        saveAndOpenExcel('overtime_report.xlsx', excelBytes);
      } else {
        final storageDir = await getStorageDirectory();
        final file = File('$storageDir/overtime_report.xlsx');
        await file.writeAsBytes(excel.encode()!);
        OpenFile.open(file.path);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Overtime Report exported successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating excel.",
      );
    }
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 0.0,
        title: const Text(
          "Overtime Report",
          style: TextStyle(
            color: Colors.blue,
            fontFamily: "Poppins",
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: kIsWeb
            ? ScrollViewKeyboardDismissBehavior.manual
            : ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildHeader(),
                  GestureDetector(
                    onTap: () {
                      selectMonth(context);
                    },
                    child: Text(
                      '🗓 ${DateFormat('MMMM yyyy').format(selectedDate!)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF454545),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 15),
                    Text(
                      "Overtime Report",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton(
                      onSelected: (value) {},
                      itemBuilder: (BuildContext bc) {
                        return [
                          PopupMenuItem(
                            onTap: () {
                              setState(() {
                                generateOvertimeExcel(context);
                              });
                            },
                            child: const Text("Download Excel"),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: _itemSubGroupGraph(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    _selectedPlant ??= 'Rajapalayam Plant'; // default selection

    final dropdown = SizedBox(
      width: 194,
      height: 40,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedPlant,
        decoration: InputDecoration(
          labelText: 'Select Plant',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 8,
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: 'Rajapalayam Plant',
            child: Text('Rajapalayam Plant'),
          ),
          DropdownMenuItem(
            value: 'Bangalore IPD Plant',
            child: Text('Bangalore IPD Plant'),
          ),
          DropdownMenuItem(
            value: 'Bangalore MD Plant',
            child: Text('Bangalore MD Plant'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedPlant = value!;
          });
        },
      ),
    );

    // Layout changes with orientation
    if (isLandscape) {
      // In landscape mode, everything stays in ONE horizontal line with scroll
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [dropdown, const SizedBox(width: 12)],
        ),
      );
    } else {
      // Portrait → stacked layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [dropdown, const SizedBox(height: 12)],
      );
    }
  }

  TableRow buildRow(int rowIndex) {
    return TableRow(
      children: [
        // First cell: Department name
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          height: 55,
          child: Text(departments[rowIndex]),
        ),
        // Other cells: Editable TextFields
        ...List.generate(headers.length - 1, (colIndex) {
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: TextField(
              controller: controllers[rowIndex][colIndex],
              focusNode: focusNodes[rowIndex][colIndex],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              onChanged: (_) => calculateTotals(),
              onTap: () {
                controllers[rowIndex][colIndex].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controllers[rowIndex][colIndex].text.length,
                );
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> selectMonth(BuildContext context) async {
    final DateTime? picked = await showMonthPicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null &&
        (picked.month != selectedDate!.month ||
            picked.year != selectedDate!.year)) {
      setState(() {
        selectedDate = picked;
      });
      await loadData();
      await calculateTotals();
    }
  }

  Widget _itemSubGroupGraph() {
    final screenWidth = MediaQuery.of(context).size.width;
    double chartWidth = 0.0;
    int len = overtimeGraphData.data.length;
    if (overtimeGraphData.data.length > 5) {
      chartWidth = screenWidth + (50 * len);
    } else {
      chartWidth = screenWidth;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: chartWidth,
        child: BarChart(
          BarChartData(
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(sideTitles: _leftTitles, axisNameSize: 14),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesOvertime,
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
            barGroups: monthlyChartData(overtimeGraphData.data),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchCallback: (flTouchEvent, barTouchResponse) async {
                if (barTouchResponse != null && barTouchResponse.spot != null) {
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
                    overtimeGraphData.data[grpIndex].departmentName,
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text:
                            "\nOT Hours: ${overtimeGraphData.data[grpIndex].otHours}",
                        style: const TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            "\nOT Amount: ${overtimeGraphData.data[grpIndex].otAmount}",
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
    );
  }

  @override
  void dispose() {
    clearValues();
    for (final row in controllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    for (final row in focusNodes) {
      for (final node in row) {
        node.dispose();
      }
    }
    targetFocusNode.dispose();
    super.dispose();
  }
}
