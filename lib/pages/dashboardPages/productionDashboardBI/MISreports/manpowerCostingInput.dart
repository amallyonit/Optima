// ignore_for_file: file_names, use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:excel/excel.dart' as xl;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:optima/excel_helper.dart';
import 'package:optima/pages/dashboardPages/excel_helper_web.dart';

class ManpowerCostingInputTable extends StatefulWidget {
  @override
  _ManpowerCostingInputTableState createState() =>
      _ManpowerCostingInputTableState();
}

class _ManpowerCostingInputTableState extends State<ManpowerCostingInputTable> {
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
    // Auto-select text when focused
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

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;

    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> _downloadExcel() async {
    if (controllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data available to export.")),
      );
      return;
    }

    final excel = xl.Excel.createExcel();
    final sheet = excel['Overtime'];

    String caption =
        "${_selectedPlant ?? ''} (${DateFormat('MMMM yyyy').format(selectedDate!)})";

    /// Caption
    sheet.appendRow(toCellRow([caption]));

    /// Empty Row
    sheet.appendRow([]);

    /// Header Row
    sheet.appendRow(toCellRow(headers));

    /// Data Rows
    for (int i = 0; i < departments.length; i++) {
      List<dynamic> row = [departments[i]];

      for (int j = 0; j < headers.length - 1; j++) {
        row.add(controllers[i][j].text);
      }

      sheet.appendRow(toCellRow(row));
    }

    /// Total Row
    List<dynamic> totalRow = ["Total"];
    totalRow.addAll(totals.map((e) => e.toStringAsFixed(2)));

    sheet.appendRow(toCellRow(totalRow));

    /// Target row
    sheet.appendRow([]);
    sheet.appendRow(toCellRow(["Target", target]));

    /// Save / Download
    if (kIsWeb) {
      final excelBytes = excel.encode()!;
      saveAndOpenExcel('monthly_overtime_report.xlsx', excelBytes);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/monthly_overtime_report.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<void> _saveOvertimeData() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a month first.")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final selectedMonth = DateFormat('yyyy-MM').format(selectedDate!);

    List<Map<String, dynamic>> overtimeData = [];
    for (int i = 0; i < departments.length; i++) {
      Map<String, dynamic> row = {
        "Department": departments[i],
        "OTHours": double.tryParse(controllers[i][0].text) ?? 0.0,
        "OTAmount": double.tryParse(controllers[i][1].text) ?? 0.0,
        "Remarks": double.tryParse(controllers[i][2].text) ?? "",
      };
      overtimeData.add(row);
    }

    final payload = {
      'UserID': userID,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      "OtPlant": _selectedPlant,
      "MonthYear": selectedMonth,
      "Target": target,
      "OvertimeData": overtimeData,
    };

    const apiUrl = '${ApiHelper.baseUrl}insertorupdatemonthlyovertimedetails';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(payload),
        headers: headerss,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data saved successfully")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    }
  }

  Future<void> selectOvertimeDetails(String plant) async {
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
      "OtPlant": plant,
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

          departments.clear();
          controllers.clear();

          for (int i = 0; i < result.length; i++) {
            final row = result[i];
            if (i == 0) {
              final val = row['Target'];
              double? target;

              if (val != null) {
                // Convert safely from int, double, or string
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

            setState(() {
              controllers.add(rowControllers);
            });
          }
        } else {
          setState(() {
            controllers.clear();
          });
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

    if (selectedDate != null) {
      await selectOvertimeDetails(_selectedPlant!);
    }
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
          "Manpower Costing Input",
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
                mainAxisAlignment: MainAxisAlignment.center,
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
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_salaryInputTable(), _summaryInputTable()],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  /// SAVE BUTTON
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2ca9df),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      onPressed: () async {
                        await _saveOvertimeData();
                      },
                      child: const Text(
                        "Save",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// DOWNLOAD EXCEL
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2ca9df),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      onPressed: _downloadExcel,
                      child: const Text(
                        "Download Excel",
                        style: TextStyle(fontSize: 14, color: Colors.white),
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
        onChanged: (value) async {
          setState(() {
            _selectedPlant = value!;
          });
          await selectOvertimeDetails(value!);
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

  Widget _salaryInputTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Table(
            border: TableBorder.all(color: Colors.black),
            columnWidths: const {
              0: FixedColumnWidth(243),
              1: FixedColumnWidth(135),
              2: FixedColumnWidth(135),
              3: FixedColumnWidth(135),
              4: FixedColumnWidth(135),
              5: FixedColumnWidth(135),
              6: FixedColumnWidth(135),
              7: FixedColumnWidth(135),
              8: FixedColumnWidth(135),
              9: FixedColumnWidth(135),
              10: FixedColumnWidth(135),
              11: FixedColumnWidth(135),
            },
            children: [
              // Header row
              TableRow(
                decoration: const BoxDecoration(color: Color(0xffc0e4f3)),
                children: headers.map((text) {
                  return Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8.0),
                    height: 80,
                    child: Text(
                      text,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),

              // Data rows
              for (int i = 0; i < departments.length; i++) buildRow(i),

              // Total row
              TableRow(
                decoration: BoxDecoration(color: Colors.green.shade200),
                children: [
                  Container(
                    alignment: Alignment.center,
                    height: 55,
                    padding: const EdgeInsets.all(8.0),
                    child: const Text(
                      "Total",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...totals.map((val) {
                    return Container(
                      alignment: Alignment.center,
                      height: 55,
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          val.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryInputTable() {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: const TableBorder(
        left: BorderSide(color: Colors.black),
        right: BorderSide(color: Colors.black),
        bottom: BorderSide(color: Colors.black),
        horizontalInside: BorderSide(color: Colors.black),
        verticalInside: BorderSide(color: Colors.black),
      ),
      columnWidths: const {0: FixedColumnWidth(243), 1: FixedColumnWidth(135)},
      children: [
        _buildInputRow("Target", targetController, targetFocusNode, (value) {
          final parsed = double.tryParse(value);
          if (parsed != null) {
            setState(() {
              target = parsed;
            });
          }
        }),
      ],
    );
  }

  TableRow _buildInputRow(
    String label,
    TextEditingController controller,
    FocusNode focusNode,
    Function(String) onChanged,
  ) {
    return TableRow(
      children: [
        // 1st cell
        Container(
          alignment: Alignment.center,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
          ),
          padding: const EdgeInsets.all(0.0),
          child: Text(label),
        ),

        // 2nd cell - editable text field
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
          ),
          padding: const EdgeInsets.all(3.0),
          child: SizedBox(
            width: 60,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
