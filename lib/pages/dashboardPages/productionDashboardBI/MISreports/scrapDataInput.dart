// ignore_for_file: file_names, use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import '../../../../classes/dashBoard.dart';
import '../../../../classes/dataManager.dart';
import '../../../../notificationService.dart';
import '../../ReportService.dart';

class WasteType {
  final String name;
  final String uom;
  double? rate;
  double? quantity;
  double? amount;

  WasteType({required this.name, required this.uom, this.rate});
}

class ScrapInputPage extends StatefulWidget {
  @override
  _ScrapInputPageState createState() => _ScrapInputPageState();
}

class _ScrapInputPageState extends State<ScrapInputPage> {
  List<SalesTargetList> salesTarget = [];
  final reportService = ReportService();

  final String plant = "";
  DateTime? date;
  final bool isSunday = false;

  final List<String> headers = [
    "DATE",
    "FABRIC WASTE CUTTING (KGS)",
    "POLY COVER WASTE (KGS)",
    "WASTE CORRUGATED BOX (KGS)",
    "QUALITY TUBE (NOS)",
    "NORMAL TUBE (NOS)",
    "LINEN WASTE FABRIC (KGS)",
    "IRON WASTAGE (KGS)",
    "WASTAGE WOOD (KGS)",
    "PLASTIC WASTE MT Can (KGS)",
    "MASK TIE WASTAGE (KGS)",
    "MASK LOOP WASTAGE (KGS)",
    "BOUFFANT CAP WASTAGE (KGS)",
    "SURGICAL CAP (KGS)",
    "WASTE OIL (LTR)",
    "P.P. COVER WASTAGGE (KGS)",
    "SAC BAG WASTE (NOS)",
    "CLOTH WASTAGE (KGS)",
    "VEHICLE NO",
  ];

  final List<WasteType> wasteTypes = [
    WasteType(name: "WASTE CUTTING", uom: "KGS"),
    WasteType(name: "POLY COVER WASTE", uom: "KGS"),
    WasteType(name: "WASTE CORRUGATED BOX", uom: "KGS"),
    WasteType(name: "QUALITY TUBE", uom: "NOS"),
    WasteType(name: "NORMAL TUBE", uom: "NOS"),
    WasteType(name: "LINEN WASTE FABRIC", uom: "KGS"),
    WasteType(name: "IRON WASTAGE", uom: "KGS"),
    WasteType(name: "WASTAGE WOOD", uom: "KGS"),
    WasteType(name: "PLASTIC WASTE MT Can", uom: "KGS"),
    WasteType(name: "MASK TIE WASTAGE", uom: "KGS"),
    WasteType(name: "MASK LOOP WASTAGE", uom: "KGS"),
    WasteType(name: "BOUFFANT CAP WASTAGE", uom: "KGS"),
    WasteType(name: "SURGICAL CAP", uom: "KGS"),
    WasteType(name: "WASTE OIL", uom: "LTR"),
    WasteType(name: "P.P. COVER WASTAGGE", uom: "KGS"),
    WasteType(name: "SAC BAG WASTE", uom: "NOS"),
    WasteType(name: "CLOTH WASTAGE", uom: "KGS"),
  ];

  final List<String> dates = [];
  bool isSaving = false;
  bool isGeneratingExcel = false;
  String get formattedDate {
    final d = date?.day.toString().padLeft(2, '0');
    final m = date?.month.toString().padLeft(2, '0');
    final y = date?.year.toString();
    return '$d-$m-$y';
  }

  DateTime? _from;
  DateTime? _to;
  Set<String> existingDbDates = {};
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

  List<String> buildWeekHeaders(List<String> dates) {
    List<String> weekHeaders = [];

    for (int i = 0; i < dates.length; i += 7) {
      final start = dates[i];
      final end = dates[(i + 6 < dates.length) ? i + 6 : dates.length - 1];

      weekHeaders.add("$start TO $end");
    }

    return weekHeaders;
  }

  List<List<dynamic>> buildWeeklyRows() {
    final int weekCount = (dates.length / 7).ceil();

    List<List<dynamic>> rows = [];

    // Skip DATE column and VEHICLE NO column
    for (int col = 0; col < headers.length - 2; col++) {
      List<dynamic> row = [];

      row.add(headers[col + 1]); // description

      List<double> weeklyTotals = List.filled(weekCount, 0);

      for (int day = 0; day < dates.length; day++) {
        final weekIndex = day ~/ 7;

        final value = double.tryParse(controllers[day][col].text) ?? 0;

        weeklyTotals[weekIndex] += value;
      }

      row.addAll(weeklyTotals);
      row.add(weeklyTotals.fold(0.0, (a, b) => a + b));

      rows.add(row);
    }

    return rows;
  }

  Future<List<List<dynamic>>> buildMonthlyRows() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? '';
    final userLevel = prefs.getString('userLevel') ?? '';
    await _loadSalesTarget(userName, userLevel);
    int i = 0;
    for (final waste in wasteTypes) {
      waste.rate = await getWasteRate(waste.name);
      final qty = controllers.fold<double>(
        0,
        (sum, row) => sum + (double.tryParse(row[i].text) ?? 0),
      );
      waste.quantity = qty;
      waste.amount = waste.rate! * qty;
      i++;
    }

    return wasteTypes.map((waste) {
      return [
        waste.name,
        waste.uom,
        waste.quantity ?? 0,
        waste.rate ?? 0,
        waste.amount ?? 0,
      ];
    }).toList();
  }

  DateTime subtractOneMonth(DateTime date) {
    final previousMonth = DateTime(date.year, date.month - 1, 1);
    final lastDayOfPreviousMonth = DateTime(
      previousMonth.year,
      previousMonth.month + 1,
      0,
    ).day;

    return DateTime(
      previousMonth.year,
      previousMonth.month,
      date.day.clamp(1, lastDayOfPreviousMonth),
    );
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat('yyyyMMdd');
    return formatter.format(date);
  }

  String getMonthName(int month) {
    final formatter = DateFormat('MMMM');
    return formatter.format(DateTime(2000, month));
  }

  String getCurrentFinancialYearSuffix() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    int startYear = (month >= 4) ? year : year - 1;
    int endYear = startYear + 1;

    return "FY${startYear % 100}-${endYear % 100}-T";
  }

  double getTargetForFinancialMonth(
    String salesRep,
    int monthNumber, {
    String? financialYearSuffix,
  }) {
    final monthName = getMonthName(monthNumber);
    double target = 0;
    target = salesTarget
        .where(
          (target) =>
              target.financialYear ==
                  (financialYearSuffix ?? getCurrentFinancialYearSuffix()) &&
              target.salesRep == salesRep,
        )
        .map(
          (target) =>
              double.tryParse(target.getTargetForMonth(monthName)) ?? 0.0,
        )
        .fold(0.0, (sum, value) => sum + value);

    return target;
  }

  Future<void> _loadSalesTarget(String UserName, String UserLevel) async {
    final body = {
      "FromDate": formatDate(subtractOneMonth(_from!)),
      "ToDate": formatDate(_to!),
      "Index": 0,
      "Limit": 0,
      "sapToken": DataManager.readSapToken(),
    };
    const apiUrl = '${ApiHelper.baseUrl}BicxoSalesTargetList';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson["responseData"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['responseData'];
          if (data.isNotEmpty) {
            List<SalesTargetList> newSalesTargetList = (data)
                .map((item) => SalesTargetList.fromJson(item))
                .toList();
            salesTarget = newSalesTargetList;
          }
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            if (!mounted) return;
            NotificationService.warning(
              title: "Security Alert",
              message: "Invalid or Expired Token.",
            );
          } else {
            if (!mounted) return;
            NotificationService.error(
              title: "Error",
              message: responseJson["Error"].toString(),
            );
          }
        }
      } else {
        if (!mounted) return;
        NotificationService.info(
          title: "Info",
          message: "Sales target details not found.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(title: "Error", message: e.toString());
    }
  }

  Future<double> getWasteRate(String wasteType) async {
    double wastageRate = 0;
    wastageRate = getTargetForFinancialMonth(wasteType, _from!.month);
    return wastageRate;
  }

  Future<void> _downloadExcel() async {
    if (dates.isEmpty || controllers.isEmpty) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "No data available to export.",
      );
      return;
    }

    String caption =
        "${_selectedPlant ?? ''} (${_format(_from!)} to ${_format(_to!)})";

    final weekHeaders = buildWeekHeaders(dates);

    final secondSheetHeaders = ['Description', ...weekHeaders, 'Total'];

    final thirdSheetHeaders = [
      'Description',
      'UOM',
      'RATE',
      'Quantity',
      'Amount',
    ];

    await reportService.generateExcel(
      sheetName: 'MonthlyScrapDetails',
      headers: headers,
      rows: List.generate(
        dates.length,
        (i) => [dates[i], ...controllers[i].map((c) => c.text)],
      ),
      amountColumns: [
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
      ],
      addTotalRow: true,

      secondSheetName: 'Weekly Scrap Summary',
      secondSheetHeaders: secondSheetHeaders,
      secondSheetRows: buildWeeklyRows(),
      addSecondSheetTotalRow: true,
      secondSheetAmountColumns: List.generate(
        secondSheetHeaders.length - 1,
        (i) => i + 2,
      ),

      thirdSheetName: "Monthly Scrap Summary $caption",
      thirdSheetHeaders: thirdSheetHeaders,
      thirdSheetRows: await buildMonthlyRows(),
      addThirdSheetTotalRow: true,
      thirdSheetAmountColumns: [3, 4, 5],

      fileName: 'ScrapDetails.xlsx',
      reportTitle: 'Production[MIS] - Scrap Details $caption',
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

  String formatDateString(String isoDate) {
    final dt = DateTime.parse(isoDate);
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return "$d-$m-$y";
  }

  Future<void> _saveScrapDetails() async {
    if (_from == null || _to == null) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "Please select date first.",
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    List<Map<String, dynamic>> scrapData = [];
    for (int i = 0; i < dates.length; i++) {
      bool existedInDb = existingDbDates.contains(dates[i]);
      bool isRowEmpty = true;

      for (int j = 0; j < controllers[i].length; j++) {
        if (controllers[i][j].text.trim().isNotEmpty &&
            controllers[i][j].text != "0") {
          isRowEmpty = false;
          break;
        }
      }

      // Skip only if:
      // empty AND never existed
      if (isRowEmpty && !existedInDb) continue;

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
        "WasteOil": double.tryParse(controllers[i][13].text) ?? 0.0,
        "PpCoverWastage": double.tryParse(controllers[i][14].text) ?? 0.0,
        "SacBagWastage": double.tryParse(controllers[i][15].text) ?? 0.0,
        "ClothWastage": double.tryParse(controllers[i][16].text) ?? 0.0,
        "VehicleNo": controllers[i][17].text,
      };
      scrapData.add(row);
    }

    final payload = {
      'UserID': userID,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      "ScrapData": scrapData,
    };

    if (scrapData.isEmpty) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "No data for save.",
      );
      return;
    }
    const apiUrl = '${ApiHelper.baseUrl}insertorupdatescrapdatainput';
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
      } else {
        if (!mounted) return;
        NotificationService.error(title: "Error", message: "Save failed.");
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(title: "Error", message: "Save failed.");
    }
  }

  void emptyTableCreation() {
    existingDbDates.clear();

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
        TextEditingController(text: ''),
      ];

      for (var c in rowControllers) {
        c.addListener(() => calculateTotals());
      }

      controllers.add(rowControllers);
    }

    focusNodes.clear();

    for (int i = 0; i < controllers.length; i++) {
      List<FocusNode> rowNodes = [];

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

        rowNodes.add(node);
      }

      focusNodes.add(rowNodes);
    }

    calculateTotals();
  }

  Future<void> fetchScrapDetails(String plant) async {
    if (_from == null || _to == null) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "Please select a month first",
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
          existingDbDates.clear();
          final List<dynamic> result = decoded['Data'];

          Map<String, dynamic> apiDataByDate = {};

          for (var row in result) {
            String d = formatDateString(row['ScrapDate']);
            apiDataByDate[d] = row;
            existingDbDates.add(d);
          }

          controllers.clear();

          for (int i = 0; i < dates.length; i++) {
            final existingRow = apiDataByDate[dates[i]];

            final rowControllers = <TextEditingController>[
              TextEditingController(
                text: existingRow?['FabricWasteCutting']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['PolyCoverWaste']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['WasteCorrugatedBox']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['QualityTubeRolls']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['NormalTubeRolls']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['LinenWasteFabric']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['WasteIron']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['WasteWood']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['PlasticWasteMTCan']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['MaskTiewastage']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['MaskLoopWastage']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['BouffantCapWastage']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['SurgicalCap']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['WasteOil']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['PpCoverWastage']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['SacBagWastage']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['ClothWastage']?.toString() ?? '0',
              ),
              TextEditingController(
                text: existingRow?['VehicleNo']?.toString() ?? '',
              ),
            ];

            for (var c in rowControllers) {
              c.addListener(() => calculateTotals());
            }

            controllers.add(rowControllers);
          }

          focusNodes.clear();

          for (int i = 0; i < controllers.length; i++) {
            List<FocusNode> rowNodes = [];

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

              rowNodes.add(node);
            }

            focusNodes.add(rowNodes);
          }

          calculateTotals();
          setState(() {});
        } else {
          emptyTableCreation();
        }
      } else {
        if (!mounted) return;
        NotificationService.error(
          title: "Error",
          message: "Error occured while selecting the scrap details",
        );
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while selecting the scrap details",
      );
    }
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    totals = List.filled(headers.length - 2, 0.0);

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
    if (controllers.isEmpty) return;

    int numericColumns = controllers[0].length - 1;

    List<double> newTotals = List.filled(numericColumns, 0.0);

    for (int row = 0; row < controllers.length; row++) {
      for (int col = 0; col < numericColumns; col++) {
        final val = double.tryParse(controllers[row][col].text) ?? 0;

        newTotals[col] += val;
      }
    }

    setState(() => totals = newTotals);
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

    // Clear previous data
    dates.clear();
    controllers.clear();
    focusNodes.clear();

    DateTime current = _from!;

    while (current.isBefore(_to!) || current.isAtSameMomentAs(_to!)) {
      dates.add(_format(current));
      current = current.add(const Duration(days: 1));
    }

    await loadData();

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasRows = dates.isNotEmpty;
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
    final useKeyboardLayout = isLandscape && isKeyboardOpen;

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

      body: LayoutBuilder(
        builder: (context, constraints) {
          final filterCard = Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [const SizedBox(height: 10), _buildDatePickers()],
              ),
            ),
          );

          final tableArea = isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasRows
              ? _buildStickyTable()
              : const Center(
                  child: Text(
                    'No table generated yet. Choose From and To and press Generate.',
                  ),
                );

          if (useKeyboardLayout) {
            final tableHeight = (constraints.maxHeight - 122).clamp(
              120.0,
              260.0,
            );

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  filterCard,
                  const SizedBox(height: 12),
                  SizedBox(height: tableHeight, child: tableArea),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                /// TOP FILTER AREA
                filterCard,

                const SizedBox(height: 12),

                /// MAIN TABLE AREA (sticky header compatible)
                Expanded(child: tableArea),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: hasRows && !useKeyboardLayout
          ? _buildSaveButton()
          : null,
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
      columnWidths: {
        for (int i = 0; i < headers.length; i++)
          i: FixedColumnWidth(
            i == 0
                ? 120
                : i == headers.length - 1
                ? 160
                : 135,
          ),
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
      columnWidths: {
        for (int i = 0; i < headers.length; i++)
          i: FixedColumnWidth(
            i == 0
                ? 120
                : i == headers.length - 1
                ? 160
                : 135,
          ),
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

            // Column VEHICLE NO → no total
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
          height: 50,
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
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() => isSaving = true);
                          await _saveScrapDetails();
                          setState(() => isSaving = false);
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        )
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
                  onPressed: isGeneratingExcel
                      ? null
                      : () async {
                          setState(() => isGeneratingExcel = true);
                          await _downloadExcel();
                          setState(() => isGeneratingExcel = false);
                        },
                  child: isGeneratingExcel
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        )
                      : const Text(
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
