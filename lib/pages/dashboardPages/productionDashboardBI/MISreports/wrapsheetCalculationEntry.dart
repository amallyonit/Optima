// ignore_for_file: file_names, use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import '../../../../notificationService.dart';
import '../../ReportService.dart';

class WrapsheetCalculationPage extends StatefulWidget {
  @override
  _WrapsheetCalculationPageState createState() =>
      _WrapsheetCalculationPageState();
}

class _WrapsheetCalculationPageState extends State<WrapsheetCalculationPage> {
  final String plant = "";
  DateTime? date;
  final bool isSunday = false;

  final List<String> headers = [
    "Date",

    "Qty. Prod. 1",
    "Lg 1",
    "Wd 1",

    "Qty. Prod. 2",
    "Lg 2",
    "Wd 2",

    "Qty. Prod. 3",
    "Lg 3",
    "Wd 3",

    "GSM",
    "Roll Width",
    "Open Wt.",
    "New Roll Wt.",
    "Closing Wt.",
    "Lay Lg",
    "No. of Lays",

    "Catcher Waste Lg",
    "Catcher Waste Wd",
    "Catcher Waste Wastage",

    "Add. Waste 1 Lg",
    "Add. Waste 1 Wd",
    "Add. Waste 1 Wastage",

    "Add. Waste 2 Lg",
    "Add. Waste 2 Wd",
    "Add. Waste 2 Wastage",

    "Std. Cons.",
    "Act. Cons.",
    "Cons. Dif.",
    "% Waste",

    "Remarks",
  ];

  final List<String> dates = [];
  Set<String> existingDbDates = {};

  bool isSaving = false;
  String formatDate(String isoDate) {
    final dt = DateTime.parse(isoDate);
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return "$d-$m-$y";
  }

  DateTime? _from;
  DateTime? _to;

  List<List<TextEditingController>> controllers = [];
  List<List<FocusNode>> focusNodes = [];

  final _verticalController = ScrollController();
  final _headerHorizontalController = ScrollController();
  final _bodyHorizontalController = ScrollController();
  late List<double> totals = [];
  int remainingCells = 0;
  String userID = "";

  final DateFormat displayFormat = DateFormat('MMM/yyyy');
  bool isLoading = false;

  String? _selectedPlant = 'Rajapalayam Plant';
  String? _selectedShift = 'DAY';

  final reportService = ReportService();

  bool isNumericColumn(int colIndex) {
    return colIndex < controllers[0].length - 1;
  }

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _from = picked);
    }
  }

  Future<void> _pickTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _to = picked);
    }
  }

  String _format(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd-$mm-$yyyy';
  }

  @override
  void initState() {
    super.initState();
    _bodyHorizontalController.addListener(() {
      if (_headerHorizontalController.hasClients) {
        _headerHorizontalController.jumpTo(_bodyHorizontalController.offset);
      }
    });
    _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _to = DateTime.now();
    _generateDateArray();
  }

  Future<void> exportWrapsheetExcel() async {
    if (dates.isEmpty || controllers.isEmpty) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "No data available to export.",
      );
      return;
    }

    List<List<dynamic>> rows = [];

    String caption =
        "Wrapsheet Calculation - ${_selectedPlant ?? ''} - ${_selectedShift ?? ''} "
        "(${_format(_from!)} to ${_format(_to!)})";

    for (int i = 0; i < dates.length; i++) {
      List<dynamic> row = [];

      // First column → DATE
      row.add(dates[i]);

      // Remaining columns
      for (int j = 0; j < controllers[i].length; j++) {
        row.add(controllers[i][j].text);
      }

      rows.add(row);
    }

    reportService.generateExcel(
      sheetName: 'Wrapsheet Calculation',
      headers: headers,
      rows: rows,
      fileName: 'Wrapsheet_Calculation.xlsx',
      amountColumns: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11], // FIXED indexing
      addTotalRow: true,
      reportTitle: caption,
    );
  }

  final inputFormat = DateFormat('dd-MM-yyyy');
  String convertToIso(String ddMMyyyy) {
    final parts = ddMMyyyy.split('-');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    final dt = DateTime(year, month, day);
    return "${dt.year.toString().padLeft(4, '0')}-"
        "${dt.month.toString().padLeft(2, '0')}-"
        "${dt.day.toString().padLeft(2, '0')}";
  }

  Future<void> _saveWrapsheetCalculationDetails() async {
    if (_from == null || _to == null) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "Please select date first",
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    List<Map<String, dynamic>> wrapsheetData = [];

    for (int i = 0; i < dates.length; i++) {
      final row = controllers[i];

      double qtyProd1 = double.tryParse(row[0].text) ?? 0;
      double lg1 = double.tryParse(row[1].text) ?? 0;
      double wd1 = double.tryParse(row[2].text) ?? 0;

      double qtyProd2 = double.tryParse(row[3].text) ?? 0;
      double lg2 = double.tryParse(row[4].text) ?? 0;
      double wd2 = double.tryParse(row[5].text) ?? 0;

      double qtyProd3 = double.tryParse(row[6].text) ?? 0;
      double lg3 = double.tryParse(row[7].text) ?? 0;
      double wd3 = double.tryParse(row[8].text) ?? 0;

      double gsm = double.tryParse(row[9].text) ?? 0;
      double rollWidth = double.tryParse(row[10].text) ?? 0;

      double openWt = double.tryParse(row[11].text) ?? 0;
      double newRollWt = double.tryParse(row[12].text) ?? 0;
      double closingWt = double.tryParse(row[13].text) ?? 0;

      double layLg = double.tryParse(row[14].text) ?? 0;
      double noOfLays = double.tryParse(row[15].text) ?? 0;

      double catcherWasteLg = double.tryParse(row[16].text) ?? 0;
      double catcherWasteWd = double.tryParse(row[17].text) ?? 0;
      double catcherWaste = double.tryParse(row[18].text) ?? 0;

      double addWaste1Lg = double.tryParse(row[19].text) ?? 0;
      double addWaste1Wd = double.tryParse(row[20].text) ?? 0;
      double addWaste1 = double.tryParse(row[21].text) ?? 0;

      double addWaste2Lg = double.tryParse(row[22].text) ?? 0;
      double addWaste2Wd = double.tryParse(row[23].text) ?? 0;
      double addWaste2 = double.tryParse(row[24].text) ?? 0;

      double stdCons = double.tryParse(row[25].text) ?? 0;
      double actCons = double.tryParse(row[26].text) ?? 0;
      double consDif = double.tryParse(row[27].text) ?? 0;
      double percentWaste = double.tryParse(row[28].text) ?? 0;

      String remarks = row[29].text.trim();

      bool isRowEmpty =
          [
            qtyProd1,
            lg1,
            wd1,
            qtyProd2,
            lg2,
            wd2,
            qtyProd3,
            lg3,
            wd3,
            gsm,
            rollWidth,
            openWt,
            newRollWt,
            closingWt,
            layLg,
            noOfLays,
            catcherWasteLg,
            catcherWasteWd,
            catcherWaste,
            addWaste1Lg,
            addWaste1Wd,
            addWaste1,
            addWaste2Lg,
            addWaste2Wd,
            addWaste2,
            stdCons,
            actCons,
            consDif,
            percentWaste,
          ].every((e) => e == 0) &&
          remarks.isEmpty;

      bool existedInDb = existingDbDates.contains(dates[i]);

      if (isRowEmpty && !existedInDb) continue;

      wrapsheetData.add({
        "UserId": int.tryParse(userID) ?? 0,
        "WrapsheetPlant": _selectedPlant,
        "WrapsheetShift": _selectedShift,
        "WrapsheetDate": convertToIso(dates[i]),

        "QtyProd1": qtyProd1,
        "Lg1": lg1,
        "Wd1": wd1,

        "QtyProd2": qtyProd2,
        "Lg2": lg2,
        "Wd2": wd2,

        "QtyProd3": qtyProd3,
        "Lg3": lg3,
        "Wd3": wd3,

        "GSM": gsm,
        "RollWidth": rollWidth,

        "OpenWt": openWt,
        "NewRollWt": newRollWt,
        "ClosingWt": closingWt,

        "LayLg": layLg,
        "NoOfLays": noOfLays,

        "CatcherWasteLg": catcherWasteLg,
        "CatcherWasteWd": catcherWasteWd,
        "CatcherWaste": catcherWaste,

        "AddWaste1Lg": addWaste1Lg,
        "AddWaste1Wd": addWaste1Wd,
        "AddWaste1": addWaste1,

        "AddWaste2Lg": addWaste2Lg,
        "AddWaste2Wd": addWaste2Wd,
        "AddWaste2": addWaste2,

        "StdCons": stdCons,
        "ActCons": actCons,
        "ConsDif": consDif,
        "PercentWaste": percentWaste,

        "Remarks": remarks,
      });
    }

    // If nothing to save
    if (wrapsheetData.isEmpty) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "No data find to save.",
      );
      return;
    }

    final payload = {
      'UserID': userID,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      "WrapsheetData": wrapsheetData,
    };

    const apiUrl = '${ApiHelper.baseUrl}insertorupdatewrapsheetcalculation';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};

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
          message: "Saved successfully.",
        );

        await fetchWrapsheetCalculationDetails(
          _selectedPlant!,
          _selectedShift!,
        );
      } else {
        if (!mounted) return;
        NotificationService.error(title: "Error", message: "Save failed..");
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(title: "Error", message: "Save failed..");
    }
  }

  Future<void> fetchWrapsheetCalculationDetails(
    String plant,
    String shift,
  ) async {
    if (_from == null || _to == null) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "Please select a month first.",
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    final payload = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      "WrapsheetPlant": plant,
      "WrapsheetShift": shift,
      "FromDate": _from?.toIso8601String(),
      "ToDate": _to?.toIso8601String(),
    };

    const apiUrl = '${ApiHelper.baseUrl}selectwrapsheetcalculation';
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

          // Create map of API data by date
          Map<String, dynamic> apiDataByDate = {};
          existingDbDates.clear();

          for (var row in result) {
            String formatted = formatDate(row['WrapsheetDate']);
            apiDataByDate[formatted] = row;

            existingDbDates.add(formatted);
          }

          // Now rebuild controllers for ALL generated dates
          for (final row in controllers) {
            for (final controller in row) {
              controller.dispose();
            }
          }
          controllers.clear();

          for (int i = 0; i < dates.length; i++) {
            final existingRow = apiDataByDate[dates[i]];

            final rowControllers = <TextEditingController>[
              // Qty. Prod. 1
              TextEditingController(
                text: existingRow?['QtyProd1']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['Lg1']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['Wd1']?.toString() ?? '0',
              ),

              // Qty. Prod. 2
              TextEditingController(
                text: existingRow?['QtyProd2']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['Lg2']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['Wd2']?.toString() ?? '0',
              ),

              // Qty. Prod. 3
              TextEditingController(
                text: existingRow?['QtyProd3']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['Lg3']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['Wd3']?.toString() ?? '0',
              ),

              // Roll Details
              TextEditingController(
                text: existingRow?['GSM']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['RollWidth']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['OpenWt']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['NewRollWt']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['ClosingWt']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['LayLg']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['NoOfLays']?.toString() ?? '0',
              ),

              // Catcher Waste
              TextEditingController(
                text: existingRow?['CatcherWasteLg']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['CatcherWasteWd']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['CatcherWaste']?.toString() ?? '0',
              ),

              // Additional Waste 1
              TextEditingController(
                text: existingRow?['AddWaste1Lg']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['AddWaste1Wd']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['AddWaste1']?.toString() ?? '0',
              ),

              // Additional Waste 2
              TextEditingController(
                text: existingRow?['AddWaste2Lg']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['AddWaste2Wd']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['AddWaste2']?.toString() ?? '0',
              ),

              // Consumption
              TextEditingController(
                text: existingRow?['StdCons']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['ActCons']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['ConsDif']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['PercentWaste']?.toString() ?? '0',
              ),

              // Remarks
              TextEditingController(
                text: existingRow?['Remarks']?.toString() ?? '',
              ),
            ];

            for (var controller in rowControllers) {
              controller.addListener(() {
                calculateTotals();
              });
            }

            controllers.add(rowControllers);
          }

          // Rebuild focusNodes with same structure
          for (final row in focusNodes) {
            for (final node in row) {
              node.dispose();
            }
          }
          focusNodes.clear();

          for (int i = 0; i < controllers.length; i++) {
            List<FocusNode> rowFocusNodes = [];

            for (int j = 0; j < controllers[i].length; j++) {
              final node = FocusNode();

              node.addListener(() {
                if (node.hasFocus) {
                  controllers[i][j].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: controllers[i][j].text.length,
                  );
                }
              });

              rowFocusNodes.add(node);
            }

            focusNodes.add(rowFocusNodes);
          }

          setState(() {
            calculateTotals();
          });
        } else {
          emptyTableCreation();
        }
      } else {
        if (!mounted) return;
        NotificationService.error(
          title: "Error",
          message:
              "Error occured while selecting the wrapsheet calculation details",
        );
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message:
            "Error occured while selecting the wrapsheet calculation details",
      );
    }
  }

  void emptyTableCreation() {
    existingDbDates.clear();

    // Create empty controllers for fresh entry
    controllers.clear();

    for (int i = 0; i < dates.length; i++) {
      final rowControllers = <TextEditingController>[
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: '0'),
        TextEditingController(text: ''),
      ];

      for (var controller in rowControllers) {
        controller.addListener(() {
          calculateTotals();
        });
      }

      controllers.add(rowControllers);
    }

    // Build focusNodes
    focusNodes.clear();

    for (int i = 0; i < controllers.length; i++) {
      List<FocusNode> rowFocusNodes = [];

      for (int j = 0; j < controllers[i].length; j++) {
        final node = FocusNode();

        node.addListener(() {
          if (node.hasFocus) {
            controllers[i][j].selection = TextSelection(
              baseOffset: 0,
              extentOffset: controllers[i][j].text.length,
            );
          }
        });

        rowFocusNodes.add(node);
      }

      focusNodes.add(rowFocusNodes);
    }

    setState(() {
      calculateTotals();
    });
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    totals = List.filled(headers.length - 1, 0.0);

    await fetchWrapsheetCalculationDetails(_selectedPlant!, _selectedShift!);

    setState(() => isLoading = false);
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
    if (controllers.isEmpty) return;

    int numericColumnCount = controllers[0].length - 1; // exclude remark

    List<double> newTotals = List.filled(numericColumnCount, 0.0);

    for (int row = 0; row < controllers.length; row++) {
      for (int col = 0; col < numericColumnCount; col++) {
        final txt = controllers[row][col].text.trim();
        final val = double.tryParse(txt) ?? 0.0;
        newTotals[col] += val;
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
      dates.length,
      (_) => List.generate(
        headers.length - 1,
        (index) =>
            TextEditingController(text: index == headers.length - 2 ? "" : "0"),
      ),
    );
  }

  void _generateDateArray() async {
    if (_from == null || _to == null) return;
    setState(() => isLoading = true);
    dates.clear();
    controllers.clear();
    focusNodes.clear();
    existingDbDates.clear();

    DateTime current = _from!;
    while (current.isBefore(_to!) || current.isAtSameMomentAs(_to!)) {
      dates.add(_format(current)); // or use your preferred format
      current = current.add(const Duration(days: 1));
    }
    await loadData();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasRows = dates.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 0.0,
        title: const Text(
          "WRAPSHEET CALCULATION SHEET",
          style: TextStyle(
            color: Colors.blue,
            fontFamily: "Poppins",
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            /// TOP FILTER AREA
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [const SizedBox(height: 10), _buildDatePickers()],
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// MAIN TABLE AREA (sticky header compatible)
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hasRows
                  ? _buildStickyTable()
                  : const Center(
                      child: Text(
                        'No table generated yet. Choose From and To and press Generate.',
                      ),
                    ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: hasRows ? _buildSaveButton() : null,
    );
  }

  Widget _buildStickyTable() {
    return Column(
      children: [
        // STICKY HEADER (not scrollable by user)
        SingleChildScrollView(
          controller: _headerHorizontalController,
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: _buildHeaderTable(),
        ),

        const SizedBox(height: 0),

        // BODY (scrolls vertically + horizontally)
        Expanded(
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                controller: _bodyHorizontalController,
                scrollDirection: Axis.horizontal,
                child: _buildBodyTable(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTable() {
    return Table(
      border: TableBorder.all(color: Colors.black),
      columnWidths: const {
        0: FixedColumnWidth(120),
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
        12: FixedColumnWidth(135),
        13: FixedColumnWidth(135),
        14: FixedColumnWidth(135),
        15: FixedColumnWidth(135),
        16: FixedColumnWidth(135),
        17: FixedColumnWidth(135),
        18: FixedColumnWidth(135),
        19: FixedColumnWidth(135),
        20: FixedColumnWidth(135),
        21: FixedColumnWidth(135),
        22: FixedColumnWidth(135),
        23: FixedColumnWidth(135),
        24: FixedColumnWidth(135),
        25: FixedColumnWidth(135),
        26: FixedColumnWidth(135),
        27: FixedColumnWidth(135),
        28: FixedColumnWidth(135),
        29: FixedColumnWidth(135),
        30: FixedColumnWidth(180),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xffc0e4f3)),
          children: headers
              .map(
                (text) => Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 3,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBodyTable() {
    return Table(
      border: TableBorder.all(color: Colors.black),
      columnWidths: const {
        0: FixedColumnWidth(120),
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
        12: FixedColumnWidth(135),
        13: FixedColumnWidth(135),
        14: FixedColumnWidth(135),
        15: FixedColumnWidth(135),
        16: FixedColumnWidth(135),
        17: FixedColumnWidth(135),
        18: FixedColumnWidth(135),
        19: FixedColumnWidth(135),
        20: FixedColumnWidth(135),
        21: FixedColumnWidth(135),
        22: FixedColumnWidth(135),
        23: FixedColumnWidth(135),
        24: FixedColumnWidth(135),
        25: FixedColumnWidth(135),
        26: FixedColumnWidth(135),
        27: FixedColumnWidth(135),
        28: FixedColumnWidth(135),
        29: FixedColumnWidth(135),
        30: FixedColumnWidth(180),
      },
      children: [
        for (int i = 0; i < dates.length; i++) buildRow(i),

        TableRow(
          decoration: BoxDecoration(color: Colors.green.shade200),
          children: List.generate(headers.length, (colIndex) {
            // Column 0 → DATE → no total
            if (colIndex == 0) {
              return Container(
                alignment: Alignment.center,
                height: 55,
                padding: const EdgeInsets.all(8.0),
                child: const Text(
                  "Total",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }

            // Column 30 → REMARK → no total
            if (colIndex == headers.length - 1) {
              return Container(
                alignment: Alignment.center,
                height: 55,
                padding: const EdgeInsets.all(8.0),
                child: const Text(""),
              );
            }

            // Total index MUST match columnIndex - 1
            final totalIndex = colIndex - 1;

            return Container(
              alignment: Alignment.centerRight,
              height: 55,
              padding: const EdgeInsets.all(8.0),
              child: Text(
                totals[totalIndex].toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              /// SAVE
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2ca9df),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() => isSaving = true);
                          await _saveWrapsheetCalculationDetails();
                          setState(() => isSaving = false);
                        },
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                  onPressed: exportWrapsheetExcel,
                  child: const Text(
                    "Download Excel",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickers() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    _selectedPlant ??= 'Rajapalayam Plant'; // default selection
    _selectedShift ??= 'DAY'; // default selection

    final dropdownPlant = SizedBox(
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
            if (_from!.toIso8601String().isNotEmpty &&
                _to!.toIso8601String().isNotEmpty) {
              _generateDateArray();
            }
          });
          await fetchWrapsheetCalculationDetails(value!, _selectedShift!);
        },
      ),
    );

    final dropdownShift = SizedBox(
      width: 98,
      height: 40,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedShift,
        decoration: InputDecoration(
          labelText: 'Select Shift',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 8,
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'DAY', child: Text('DAY')),
          DropdownMenuItem(value: 'NIGHT', child: Text('NIGHT')),
        ],
        onChanged: (value) async {
          setState(() {
            _selectedShift = value!;
            if (_from!.toIso8601String().isNotEmpty &&
                _to!.toIso8601String().isNotEmpty) {
              _generateDateArray();
            }
          });
          await fetchWrapsheetCalculationDetails(_selectedPlant!, value!);
        },
      ),
    );

    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(110, 40),
      padding: const EdgeInsets.symmetric(horizontal: 5),
    );

    final buttons = [
      const Text('From', style: TextStyle(fontWeight: FontWeight.w600)),
      ElevatedButton(
        onPressed: _pickFrom,
        style: buttonStyle,
        child: Text(_from == null ? 'Select date' : _format(_from!)),
      ),
      const Text('To', style: TextStyle(fontWeight: FontWeight.w600)),
      ElevatedButton(
        onPressed: _pickTo,
        style: buttonStyle,
        child: Text(_to == null ? 'Select date' : _format(_to!)),
      ),
      ElevatedButton(
        onPressed: _generateDateArray,
        style: buttonStyle,
        child: const Text('Generate Table'),
      ),
      ElevatedButton(
        style: buttonStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.grey[700]),
        ),
        onPressed: clearValues,
        child: const Text('Clear', style: TextStyle(color: Colors.white)),
      ),
    ];

    // Layout changes with orientation
    if (isLandscape) {
      // In landscape mode, everything stays in ONE horizontal line with scroll
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            dropdownPlant,
            const SizedBox(width: 12),
            dropdownShift,
            const SizedBox(width: 12),
            ...buttons.map(
              (b) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: b,
              ),
            ),
          ],
        ),
      );
    } else {
      // Portrait → stacked layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                dropdownPlant,
                const SizedBox(width: 12),
                dropdownShift,
              ],
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: buttons,
          ),
        ],
      );
    }
  }

  TableRow buildRow(int rowIndex) {
    if (controllers.length != dates.length ||
        focusNodes.length != dates.length) {
      return TableRow(
        children: List.generate(headers.length, (_) => const SizedBox()),
      );
    }
    return TableRow(
      children: [
        // First cell: Department name
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          height: 55,
          child: Text(dates[rowIndex]),
        ),
        // Other cells: Editable TextFields
        ...List.generate(headers.length - 1, (colIndex) {
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: TextField(
              controller: controllers[rowIndex][colIndex],
              focusNode: focusNodes[rowIndex][colIndex],
              keyboardType: isNumericColumn(colIndex)
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              textAlign: isNumericColumn(colIndex)
                  ? TextAlign.right
                  : TextAlign.left,
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

  @override
  void dispose() {
    // clearValues();
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
    _verticalController.dispose();
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();
    super.dispose();
  }
}
