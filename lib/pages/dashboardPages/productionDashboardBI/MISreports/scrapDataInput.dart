// ignore_for_file: file_names, use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';

class ScrapInputPage extends StatefulWidget {
  @override
  _ScrapInputPageState createState() => _ScrapInputPageState();
}

class _ScrapInputPageState extends State<ScrapInputPage> {
  final String plant = "";
  DateTime? date;
  final bool isSunday = false;

  final List<String> headers = [
    "DATE",
    "FABRIC WASTE CUTTING (IN KGS)",
    "POLY COVER WASTE (IN KGS)",
    "WASTE CORRUGATED BOX (IN KGS)",
    "QUALITY TUBE ( ROLLS)",
    "NORMAL TUBE ( ROLLS)",
    "LINEN WASTE FABRIC (IN KGS)",
    "WASTE IRON (IN KGS)",
    "WASTE WOOD",
    "PLASTIC WASTE MT Can (IN KGS)",
    "MASK TIE WASTAGE",
    "MASK LOOP WASTAGE",
    "BOUFFANT CAP WASTAGE",
    "SURGICAL CAP",
    "VEHICLE NO",
  ];
  final List<String> dates = [];
  bool isSaving = false;
  String get formattedDate {
    final d = date?.day.toString().padLeft(2, '0');
    final m = date?.month.toString().padLeft(2, '0');
    final y = date?.year.toString();
    return '$d-$m-$y';
  }

  DateTime? _from;
  DateTime? _to;

  late List<List<TextEditingController>> controllers;
  late List<List<FocusNode>> focusNodes;
  final _verticalController = ScrollController();
  final _headerHorizontalController = ScrollController();
  final _bodyHorizontalController = ScrollController();
  late List<double> totals = [];
  int remainingCells = 0;
  String userID = "";

  final DateFormat displayFormat = DateFormat('MMM/yyyy');
  bool isLoading = false;

  String? _selectedPlant = 'Rajapalayam Plant';

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
    loadData();
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

  String formatDate(String isoDate) {
    final dt = DateTime.parse(isoDate);
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return "$d-$m-$y";
  }

  Future<void> _saveScrapDetails() async {
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select datefirss t.")),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    List<Map<String, dynamic>> scrapData = [];
    for (int i = 0; i < dates.length; i++) {
      Map<String, dynamic> row = {
        "UserId": userID,
        "ScrapPlant": _selectedPlant,
        "ScrapDate": convertToIso(dates[i]),
        "FabricWasteCutting": double.tryParse(controllers[i][0].text) ?? 0.0,
        "PolyCoverWaste": double.tryParse(controllers[i][1].text) ?? 0.0,
        "WasteCorrugatedBox": double.tryParse(controllers[i][2].text) ?? 0.0,
        "QualityTubeRolls": double.tryParse(controllers[i][3].text) ?? 0.0,
        "NormalTubeRolls": double.tryParse(controllers[i][4].text) ?? 0.0,
        "LinenWasteFabric": double.tryParse(controllers[i][5].text) ?? 0.0,
        "WasteIron": double.tryParse(controllers[i][6].text) ?? 0.0,
        "WasteWood": double.tryParse(controllers[i][7].text) ?? 0.0,
        "PlasticWasteMTCan": double.tryParse(controllers[i][8].text) ?? 0.0,
        "MaskTiewastage": double.tryParse(controllers[i][9].text) ?? 0.0,
        "MaskLoopWastage": double.tryParse(controllers[i][10].text) ?? 0.0,
        "BouffantCapWastage": double.tryParse(controllers[i][11].text) ?? 0.0,
        "SurgicalCap": double.tryParse(controllers[i][12].text) ?? 0.0,
        "VehicleNo": controllers[i][13].text,
      };
      scrapData.add(row);
    }

    final payload = {
      'UserID': userID,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      "ScrapData": scrapData,
    };

    const apiUrl = '${ApiHelper.baseUrl}insertorupdatescrapdatainput';
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

  Future<void> fetchScrapDetails(String plant) async {
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
      "ScrapPlant": _selectedPlant,
      "FromDate": _from?.toIso8601String(),
      "ToDate": _to?.toIso8601String(),
    };
    //print(payload);
    const apiUrl = '${ApiHelper.baseUrl}selectscrapdatainput';
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

          dates.clear();
          controllers.clear();

          for (int i = 0; i < result.length; i++) {
            final row = result[i];
            //dates.add(row['ScrapDate'] ?? '');
            dates.add(formatDate(row['ScrapDate']));
            final rowControllers = <TextEditingController>[
              TextEditingController(
                text: row['FabricWasteCutting']?.toString() ?? '0',
              ),
              TextEditingController(
                text: row['PolyCoverWaste']?.toString() ?? '0',
              ),
              TextEditingController(
                text: row['WasteCorrugatedBox']?.toString() ?? '0',
              ),
              TextEditingController(
                text: row['QualityTubeRolls']?.toString() ?? '0',
              ),
              TextEditingController(
                text: row['NormalTubeRolls']?.toString() ?? '0',
              ),
              TextEditingController(
                text: row['LinenWasteFabric']?.toString() ?? '0',
              ),
              TextEditingController(text: row['WasteIron']?.toString() ?? '0'),
              TextEditingController(text: row['WasteWood']?.toString() ?? '0'),
              TextEditingController(
                text: row['PlasticWasteMTCan']?.toString() ?? '0',
              ),
              TextEditingController(
                text: row['MaskTiewastage']?.toString() ?? '0',
              ),
              TextEditingController(
                text: row['MaskLoopWastage']?.toString() ?? '0',
              ),
              TextEditingController(
                text: row['BouffantCapWastage']?.toString() ?? '0',
              ),
              TextEditingController(
                text: row['SurgicalCap']?.toString() ?? '0',
              ),
              TextEditingController(text: row['VehicleNo']?.toString() ?? ''),
            ];

            for (var controller in rowControllers) {
              controller.addListener(() {
                calculateTotals();
              });
            }
            setState(() {
              controllers.add(rowControllers);
            });
          }
          focusNodes = List.generate(
            controllers.length,
            (i) => List.generate(controllers[i].length, (j) {
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
          setState(() {
            calculateTotals();
          });
        } else {
          setState(() {
            controllers.clear();
          });
          clearValues();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("No data found.")));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
      }
    } catch (e) {
      //print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch: $e")));
    }
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    controllers = List.generate(
      dates.length,
      (_) => List.generate(
        headers.length - 1,
        (index) =>
            TextEditingController(text: index == headers.length - 2 ? "" : "0"),
      ),
    );

    focusNodes = List.generate(
      dates.length,
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
    await fetchScrapDetails(_selectedPlant!);
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
    List<double> newTotals = List.filled(headers.length - 2, 0.0);

    for (int row = 0; row < controllers.length; row++) {
      for (int col = 1; col < headers.length - 1; col++) {
        final txt = controllers[row][col - 1].text.trim();
        final val = double.tryParse(txt) ?? 0.0;

        newTotals[col - 1] += val;
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
    dates.clear(); // clear old dates
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
          "SCRAP DATA INPUT",
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
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xffc0e4f3)),
          children: headers
              .map(
                (text) => Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8.0),
                  height: 60,
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
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
      },
      children: [
        for (int i = 0; i < dates.length; i++) buildRow(i),

        /// TOTAL (always 10 columns)
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

            // Column 9 → REMARK → no total
            if (colIndex == 9) {
              return Container(
                alignment: Alignment.center,
                height: 55,
                padding: const EdgeInsets.all(8.0),
                child: const Text(""),
              );
            }

            // Total index MUST match columnIndex - 1
            final totalIndex = colIndex - 1;

            // Safely fetch total
            final value = (totalIndex >= 0 && totalIndex < totals.length)
                ? totals[totalIndex]
                : 0.0;

            return Container(
              alignment: Alignment.centerRight,
              height: 55,
              padding: const EdgeInsets.all(8.0),
              child: Text(
                value.toStringAsFixed(2),
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
          width: double.infinity,
          height: 50,
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
                    await _saveScrapDetails();
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
      ),
    );
  }

  Widget _buildDatePickers() {
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
            if (_from!.toIso8601String().isNotEmpty &&
                _to!.toIso8601String().isNotEmpty) {
              _generateDateArray();
            }
            fetchScrapDetails(value);
          });
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
            dropdown,
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
          dropdown,
          const SizedBox(height: 12),
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
              // keyboardType: TextInputType.number,
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
    super.dispose();
  }
}
