// ignore_for_file: file_names, use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';

import 'package:path_provider/path_provider.dart';
import '../../ReportService.dart';

class SterilizationExpensesPage extends StatefulWidget {
  @override
  _SterilizationExpensesPageState createState() =>
      _SterilizationExpensesPageState();
}

class _SterilizationExpensesPageState extends State<SterilizationExpensesPage> {
  final String plant = "";
  DateTime? date;
  final bool isSunday = false;

  final List<String> headers = [
    "DATE",
    "NO. OF CTN BOX M1",
    "NO. OF CTN BOX M2",
    "EO CONSUMED M1 (Kg)",
    "EO CONSUMED M2 (Kg)",
    "CO2 GAS CONSUMED (M1&M2)",
    "GAS WASTAGE",
    "BIOLOGICAL INDICATOR (M1&M2)",
    "CHEMICAL INDICATOR (M1&M2)",
    "MAN POWER",
    "MICROTROL",
    "REMARK",
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

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;

    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> exportSterilizationExcel() async {
    if (dates.isEmpty || controllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data available to export.")),
      );
      return;
    }

    List<List<dynamic>> rows = [];

    String caption =
        "Sterilization Expenses - ${_selectedPlant ?? ''} - ${_selectedShift ?? ''} "
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

    // print("Rows count: ${rows.length}"); // debug

    reportService.generateExcel(
      sheetName: 'Sterilization Expenses',
      headers: headers,
      rows: rows,
      fileName: 'Sterilization_Expenses.xlsx',
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

  Future<void> _saveSterilizationDetails() async {
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date first.")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    List<Map<String, dynamic>> sterilizeData = [];

    for (int i = 0; i < dates.length; i++) {
      double m1 = double.tryParse(controllers[i][0].text) ?? 0.0;
      double m2 = double.tryParse(controllers[i][1].text) ?? 0.0;
      double eo1 = double.tryParse(controllers[i][2].text) ?? 0.0;
      double eo2 = double.tryParse(controllers[i][3].text) ?? 0.0;
      double co2 = double.tryParse(controllers[i][4].text) ?? 0.0;
      double co2Wastage = double.tryParse(controllers[i][5].text) ?? 0.0;
      double bio = double.tryParse(controllers[i][6].text) ?? 0.0;
      double chem = double.tryParse(controllers[i][7].text) ?? 0.0;
      double man = double.tryParse(controllers[i][8].text) ?? 0.0;
      double micro = double.tryParse(controllers[i][9].text) ?? 0.0;
      String remark = controllers[i][10].text.trim();

      // Skip fully empty rows
      bool isRowEmpty =
          m1 == 0 &&
          m2 == 0 &&
          eo1 == 0 &&
          eo2 == 0 &&
          co2 == 0 &&
          co2Wastage == 0 &&
          bio == 0 &&
          chem == 0 &&
          man == 0 &&
          micro == 0 &&
          remark.isEmpty;

      bool existedInDb = existingDbDates.contains(dates[i]);

      // Skip only if:
      // - Row is empty
      // - AND it never existed before
      if (isRowEmpty && !existedInDb) continue;

      sterilizeData.add({
        "UserId": userID,
        "SterilizePlant": _selectedPlant,
        "SterilizeShift": _selectedShift,
        "SterilizeDate": convertToIso(dates[i]),
        "NoOfCtnBoxM1": m1,
        "NoOfCtnBoxM2": m2,
        "EOConsumedM1": eo1,
        "EOConsumedM2": eo2,
        "CO2ConsumedM1M2": co2,
        "CO2Wastage": co2Wastage,
        "BiologicalIndicator": bio,
        "ChemicalIndicator": chem,
        "ManPower": man,
        "Microtrol": micro,
        "Remark": remark,
      });
    }

    // If nothing to save
    if (sterilizeData.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No data entered to save.")));
      return;
    }

    final payload = {
      'UserID': userID,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      "SterilizeData": sterilizeData,
    };

    const apiUrl = '${ApiHelper.baseUrl}insertorupdatesterilizeexpenses';
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

        await fetchSterilizationDetails(_selectedPlant!, _selectedShift!);
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

  Future<void> fetchSterilizationDetails(String plant, String shift) async {
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a month first.")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    final payload = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      "SterilizePlant": plant,
      "SterilizeShift": shift,
      "FromDate": _from?.toIso8601String(),
      "ToDate": _to?.toIso8601String(),
    };
    //print(payload);
    const apiUrl = '${ApiHelper.baseUrl}selectsterilizeexpenses';
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
            String formatted = formatDate(row['SterilizeDate']);
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
              TextEditingController(
                text: existingRow?['NoOfCtnBoxM1']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['NoOfCtnBoxM2']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['EOConsumedM1']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['EOConsumedM2']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['CO2ConsumedM1M2']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['CO2Wastage']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['BiologicalIndicator']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['ChemicalIndicator']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['ManPower']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['Microtrol']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['Remark']?.toString() ?? '',
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

    await fetchSterilizationDetails(_selectedPlant!, _selectedShift!);

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
          "STERILIZATION EXPENSES ENTRY",
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
        11: FixedColumnWidth(180),
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
        11: FixedColumnWidth(180),
      },
      children: [
        for (int i = 0; i < dates.length; i++) buildRow(i),

        /// TOTAL (always 9 columns)
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

            // Column 10 → REMARK → no total
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
                // value.toStringAsFixed(2),
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
                          await _saveSterilizationDetails();
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
                  onPressed: exportSterilizationExcel,
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
          await fetchSterilizationDetails(value!, _selectedShift!);
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
          await fetchSterilizationDetails(_selectedPlant!, value!);
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
