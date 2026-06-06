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
import '../../../notificationService.dart';
import '../ReportService.dart';

final reportService = ReportService();

class SalaryInputTable extends StatefulWidget {
  @override
  _SalaryInputTableState createState() => _SalaryInputTableState();
}

class _SalaryInputTableState extends State<SalaryInputTable> {
  bool _isBusy = false;
  String _loadingText = "Loading...";
  final List<String> headers = [
    "Department in Factory",
    "Salary including Production Incentive + OT",
    "Total Present Staff/Labour for current month",
    "Avg Monthly Gross Salary Per head",
    "Employer Contribution for PF @13%",
    "Annual Bonus",
    "Employer Contribution for ESI @3.25%",
    "Total Avg Monthly CTC Per Head",
    "Total Monthly Gross Salary incl OT",
    "Production Incentive",
    "Over Time",
    "Increment Arrears",
  ];

  final List<String> departments = [
    "Production Dept (incl Overtime)",
    "Production Dept (Contract)",
    "HR & Admin Dept+Maintainance",
    "Purchase, Store & Supply Chain Dept",
    "QA&QC Dept",
    "Design & Development Dept",
    "Production Dept (incl Prod Head, Floor-Incharge & Supervisors)",
    "Production Dept (Temporary Basis)",
  ];

  late List<List<TextEditingController>> controllers;
  late List<List<FocusNode>> focusNodes;

  final FocusNode noOfDaysFocusNode = FocusNode();
  final FocusNode totalManPowerFocusNode = FocusNode();
  final FocusNode averageWorkForceFocusNode = FocusNode();

  late List<double> totals;
  int remainingCells = 0;
  String userID = "";
  String? _selectedPlant = 'Rajapalayam Plant';
  int noOfDays = 0;
  double totalManPower = 0;
  double averageWorkForce = 0;

  final TextEditingController noOfDaysController = TextEditingController();
  final TextEditingController totalManPowerController = TextEditingController();
  final TextEditingController averageWorkForceController =
      TextEditingController();

  DateTime? selectedDate;
  final DateFormat displayFormat = DateFormat('MMM/yyyy');
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Auto-select text when focused
    noOfDaysFocusNode.addListener(() {
      if (noOfDaysFocusNode.hasFocus) {
        noOfDaysController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: noOfDaysController.text.length,
        );
      }
    });
    totalManPowerFocusNode.addListener(() {
      if (totalManPowerFocusNode.hasFocus) {
        totalManPowerController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: totalManPowerController.text.length,
        );
      }
    });
    averageWorkForceFocusNode.addListener(() {
      if (averageWorkForceFocusNode.hasFocus) {
        averageWorkForceController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: averageWorkForceController.text.length,
        );
      }
    });

    selectedDate = DateTime.now();
    loadData();
  }

  Future<void> _downloadExcel() async {
    if (controllers.isEmpty) {
      if (!mounted) return;
      NotificationService.info(
        title: "Info",
        message: "No data available to export.",
      );
      return;
    }

    setState(() {
      _isBusy = true;
      _loadingText = "Generating Excel...";
    });
    try {
      String caption =
          "${_selectedPlant ?? ''} "
          "(${DateFormat('MMMM yyyy').format(selectedDate!)})";

      List<List<dynamic>> rows = [];

      for (int i = 0; i < departments.length; i++) {
        List<dynamic> row = [departments[i]];

        for (int j = 0; j < headers.length - 1; j++) {
          row.add(double.tryParse(controllers[i][j].text) ?? 0);
        }

        rows.add(row);
      }

      await reportService.generateExcel(
        sheetName: 'CTC',
        headers: headers,
        rows: rows,
        fileName: 'monthly_ctc_report.xlsx',
        reportTitle: caption,

        amountColumns: List.generate(headers.length - 1, (index) => index + 2),

        addTotalRow: true,

        footerRows: [
          ["No. of Days", noOfDays],
          ["Total ManPower", totalManPower],
          ["Average Work Force", averageWorkForce],
        ],

        enableStyling: true,
      );
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while generating the excel.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _saveToApi() async {
    if (selectedDate == null) {
      if (!mounted) return;
      NotificationService.info(
        title: "Info",
        message: "Please select a month first.",
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final selectedMonth = DateFormat('yyyy-MM').format(selectedDate!);

    List<Map<String, dynamic>> cTCData = [];
    for (int i = 0; i < departments.length; i++) {
      Map<String, dynamic> row = {
        "UserId": userID,
        "CtcPlant": _selectedPlant,
        "MonthYear": selectedMonth,
        "Department": departments[i],
        "NoOfDays": noOfDays,
        "TotalManPower": totalManPower,
        "AverageWorkForce": averageWorkForce,
        "TotalAmount": double.tryParse(controllers[i][0].text) ?? 0.0,
        "TotalPresentLabour": double.tryParse(controllers[i][1].text) ?? 0.0,
        "AvgMonthlyGrossSalaryPerHead":
            double.tryParse(controllers[i][2].text) ?? 0.0,
        "EmployerPFContribution":
            double.tryParse(controllers[i][3].text) ?? 0.0,
        "AnnualBonus": double.tryParse(controllers[i][4].text) ?? 0.0,
        "EmployerESIContribution":
            double.tryParse(controllers[i][5].text) ?? 0.0,
        "TotalAvgMonthlyCTCPerHead":
            double.tryParse(controllers[i][6].text) ?? 0.0,
        "TotalMonthlyGrossSalaryInclOT":
            double.tryParse(controllers[i][7].text) ?? 0.0,
        "ProductionIncentive": double.tryParse(controllers[i][8].text) ?? 0.0,
        "OverTime": double.tryParse(controllers[i][9].text) ?? 0.0,
        "IncrementArears": double.tryParse(controllers[i][10].text) ?? 0.0,
      };

      cTCData.add(row);
    }

    final payload = {
      'UserID': userID,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      "MonthYear": selectedMonth,
      "NoOfDays": noOfDays,
      "TotalManPower": totalManPower,
      "AverageWorkForce": averageWorkForce,
      "CtcPlant": _selectedPlant,
      "CTCData": cTCData,
    };

    const apiUrl = '${ApiHelper.baseUrl}insertorupdatemonthlyctcdetails';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};

    setState(() {
      _isBusy = true;
      _loadingText = "Saving data...";
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(payload),
        headers: headerss,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        NotificationService.success(
          title: "Success",
          message: "Data saved successfully.",
        );
      } else {
        if (!mounted) return;
        NotificationService.error(title: "Error", message: "Save failed.");
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "An error occured while saving the CTC details.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> fetchCTCDetails(String plant) async {
    if (selectedDate == null) {
      if (!mounted) return;
      NotificationService.info(
        title: "Info",
        message: "Please select a month first.",
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
      "CtcPlant": _selectedPlant,
      "MonthYear": selectedMonth,
    };

    const apiUrl = '${ApiHelper.baseUrl}selectmonthlyctcdetails';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};

    if (mounted) {
      setState(() {
        _isBusy = true;
        _loadingText = "Fetching data...";
      });
    }

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
              noOfDays = row['NoOfDays'];
              noOfDaysController.text = noOfDays.toString();
              totalManPower =
                  double.tryParse(row['TotalManPower'].toString()) ?? 0;
              totalManPowerController.text = totalManPower.toString();
              averageWorkForce =
                  double.tryParse(row['AverageWorkForce'].toString()) ?? 0;
              averageWorkForceController.text = averageWorkForce.toString();
            }

            departments.add(row['Department'] ?? '');

            final rowControllers = <TextEditingController>[
              TextEditingController(text: row['TotalAmount']?.toString() ?? ''),
              TextEditingController(
                text: row['TotalPresentLabour']?.toString() ?? '',
              ),
              TextEditingController(
                text: row['AvgMonthlyGrossSalaryPerHead']?.toString() ?? '',
              ),
              TextEditingController(
                text: row['EmployerPFContribution']?.toString() ?? '',
              ),
              TextEditingController(text: row['AnnualBonus']?.toString() ?? ''),
              TextEditingController(
                text: row['EmployerESIContribution']?.toString() ?? '',
              ),
              TextEditingController(
                text: row['TotalAvgMonthlyCTCPerHead']?.toString() ?? '',
              ),
              TextEditingController(
                text: row['TotalMonthlyGrossSalaryInclOT']?.toString() ?? '',
              ),
              TextEditingController(
                text: row['ProductionIncentive']?.toString() ?? '',
              ),
              TextEditingController(text: row['OverTime']?.toString() ?? ''),
              TextEditingController(
                text: row['IncrementArears']?.toString() ?? '',
              ),
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
          if (!mounted) return;
          NotificationService.info(
            title: "Info",
            message: "No data found for the selected plant and month.",
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Failed to fetch CTC details.",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> loadData() async {
    controllers = List.generate(
      departments.length,
      (_) => List.generate(
        headers.length - 1,
        (_) => TextEditingController(text: "0"),
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
    selectedDate = DateTime.now();
    await fetchCTCDetails(_selectedPlant!);
    setState(() {
      isLoading = false;
    });
    if (selectedDate != null) {
      setState(() {
        noOfDays = getWorkingDaysInMonthFromDate(selectedDate!);
        noOfDaysController.text = noOfDays.toString();
      });
      await calculateTotals();
    }
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
      averageWorkForce = newTotals[1];
      averageWorkForceController.text = averageWorkForce.toString();
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
        (_) => TextEditingController(text: "0"),
      ),
    );

    noOfDaysController.clear();
    totalManPowerController.clear();
    averageWorkForceController.clear();
    noOfDays = 0;
    totalManPower = 0;
    averageWorkForce = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true,
            backgroundColor: Colors.white,
            elevation: 0.0,
            title: const Text(
              "COMPUTATION OF AVERAGE MONTHLY CTC",
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
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [_salaryInputTable(), _summaryInputTable()],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
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
                            await _saveToApi();
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
        ),
        if (_isBusy) _buildLoader(),
      ],
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
          fetchCTCDetails(value!);
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
        _buildInputRow("No. of Days", noOfDaysController, noOfDaysFocusNode, (
          value,
        ) {
          final parsed = int.tryParse(value);
          if (parsed != null) {
            setState(() {
              noOfDays = parsed;
            });
          }
        }),
        _buildInputRow(
          "Total ManPower",
          totalManPowerController,
          totalManPowerFocusNode,
          (value) {
            final parsed = double.tryParse(value);
            if (parsed != null) {
              setState(() {
                totalManPower = parsed;
              });
            }
          },
        ),
        _buildInputRow(
          "Average Work Force",
          averageWorkForceController,
          averageWorkForceFocusNode,
          (value) {
            final parsed = double.tryParse(value);
            if (parsed != null) {
              setState(() {
                averageWorkForce = parsed;
              });
            }
          },
        ),
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
        noOfDays = getWorkingDaysInMonthFromDate(picked);
        noOfDaysController.text = noOfDays.toString();
      });
      await fetchCTCDetails(_selectedPlant!);
      await calculateTotals();
    }
  }

  Widget _buildLoader() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.25),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 20,
                  color: Colors.black12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 50,
                  width: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: Color(0xff2ca9df),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _loadingText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
    noOfDaysFocusNode.dispose();
    totalManPowerFocusNode.dispose();
    averageWorkForceFocusNode.dispose();
    super.dispose();
  }
}
