// ignore_for_file: file_names, use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import '../../../../notificationService.dart';
import '../../../../widgets/permanent_horizontal_scrollbar.dart';
import '../../ReportService.dart';

class ProductionSummaryWithManpowerCostEntryPage extends StatefulWidget {
  @override
  _ProductionSummaryWithManpowerCostEntryState createState() =>
      _ProductionSummaryWithManpowerCostEntryState();
}

class MoveUpIntent extends Intent {
  const MoveUpIntent();
}

class MoveDownIntent extends Intent {
  const MoveDownIntent();
}

class MoveLeftIntent extends Intent {
  const MoveLeftIntent();
}

class MoveRightIntent extends Intent {
  const MoveRightIntent();
}

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(',', '');

    // Allow only digits and one decimal point
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
      return oldValue;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ProductionSummaryWithManpowerCostEntryState
    extends State<ProductionSummaryWithManpowerCostEntryPage> {
  final String plant = "";
  DateTime? date;
  final bool isSunday = false;

  final List<String> headers = [
    "Action",
    "Date",
    "Gown/Kit/Drape Qty.",
    "Gown/Kit/Drape Box",
    "Gown/Kit/Drape Worker",
    "Wrap Sheet Qty.",
    "Wrap Sheet Box",
    "Wrap Sheet Worker",
    "Total Qty.",
    "Target Box Qty.",
    "Total Box",
    "Man Day Target",
    "Man Day Attended",
    "Labour Cost / Box",
    "Cumulative Qty.",
    "Cumulative Target Box Qty.",
    "Cumulative Box",
    "Cumulative Man Day Target",
    "Cumulative Man Day Attended",
    "Cumulative Labour Cost / Box",
    "Productivity Day",
    "Productivity MTD",
  ];

  final List<String> dates = [];
  Set<String> existingDbDates = {};

  bool isSaving = false;
  bool _isSyncing = false;

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
  late List<double> totals = [];
  List<List<double>> cellValues = [];
  late ValueNotifier<List<double>> totalsNotifier;

  double _monthlyCtc = 27080;
  double _ctcDays = 26;
  double _wrapSheetWorkerDivisor = 6000;

  late final TextEditingController _monthlyCtcController;
  late final TextEditingController _ctcDaysController;
  late final TextEditingController _workerDivisorController;

  static const int _dataColumnCount = 20;
  static const Set<int> _formulaColumns = {
    5,
    6,
    8,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
  };

  final ScrollController _horizontalController = ScrollController();
  final _verticalController = ScrollController();
  final ScrollController _horizontalScrollbarController = ScrollController();
  final _headerHorizontalController = ScrollController();
  final _bodyHorizontalController = ScrollController();

  int remainingCells = 0;
  String userID = "";

  final DateFormat displayFormat = DateFormat('MMM/yyyy');
  bool isLoading = false;

  String? _selectedPlant = 'Rajapalayam IPD Plant';
  String? _selectedShift = 'DAY';

  List<int> rowIds = [];
  List<int> deletedRowIds = [];

  int? highlightedRowIndex;
  int? _pendingActionRowIndex;
  bool? _pendingActionIsAdd;

  final reportService = ReportService();

  bool isNumericColumn(int colIndex) {
    return true;
  }

  bool isFormulaColumn(int colIndex) {
    return _formulaColumns.contains(colIndex);
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

  static const int _frozenColumnCount = 2;
  static const double _headerHeight = 72;
  static const double _rowHeight = 55;
  static const double _actionColumnWidth = 90;
  static const double _dateColumnWidth = 120;

  double get _frozenTableWidth => _actionColumnWidth + _dateColumnWidth;

  double _getColumnWidth(int visibleColumnIndex) {
    if (visibleColumnIndex == 0) return _actionColumnWidth;
    if (visibleColumnIndex == 1) return _dateColumnWidth;
    if (visibleColumnIndex == headers.length - 1) return 180;
    return 135;
  }

  Map<int, TableColumnWidth> _buildColumnWidths(int start, int end) {
    return {
      for (int i = start; i < end; i++)
        i - start: FixedColumnWidth(_getColumnWidth(i)),
    };
  }

  @override
  void initState() {
    super.initState();
    _monthlyCtcController = TextEditingController(text: _monthlyCtc.toString());

    _ctcDaysController = TextEditingController(text: _ctcDays.toString());

    _workerDivisorController = TextEditingController(
      text: _wrapSheetWorkerDivisor.toString(),
    );

    totalsNotifier = ValueNotifier([]);
    _bodyHorizontalController.addListener(() {
      if (_headerHorizontalController.hasClients) {
        _headerHorizontalController.jumpTo(_bodyHorizontalController.offset);
      }
    });
    _horizontalScrollbarController.addListener(_syncHorizontalScroll);
    _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _to = DateTime.now();
    _generateDateArray();
  }

  void _syncHorizontalScroll() {
    if (_isSyncing) return;
    _isSyncing = true;

    final source = [
      _headerHorizontalController,
      _bodyHorizontalController,
      _horizontalScrollbarController,
    ].firstWhere((c) => c.hasClients);

    final offset = source.offset;

    for (final controller in [
      _headerHorizontalController,
      _bodyHorizontalController,
      _horizontalScrollbarController,
    ]) {
      if (controller.hasClients && controller.offset != offset) {
        controller.jumpTo(
          offset.clamp(0.0, controller.position.maxScrollExtent),
        );
      }
    }

    _isSyncing = false;
  }

  Future<void> exportProductionDetailedExcel() async {
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
        "Production Summary With Manpower Cost - ${_selectedPlant ?? ''} - ${_selectedShift ?? ''} "
        "(${_format(_from!)} to ${_format(_to!)})";

    rows = List<List<dynamic>>.generate(
      dates.length,
      (i) => [dates[i], ...controllers[i].map((e) => e.text)],
    );
    reportService.generateExcel(
      sheetName: 'Production Summary',
      headers: headers.sublist(1),
      rows: rows,
      fileName: 'Production_Summary_With_Manpower_Cost.xlsx',
      amountColumns: List.generate(headers.length - 2, (i) => i + 1),
      addTotalRow: true,
      reportTitle: caption,
    );
  }

  Future<void> _showDownloadOptions() async {
    if (dates.isEmpty || controllers.isEmpty) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "No data available to export.",
      );
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Download Excel"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: const Text("Detailed"),
                onTap: () => Navigator.of(context).pop("detailed"),
              ),
              ListTile(
                leading: const Icon(Icons.summarize_outlined),
                title: const Text("Summary"),
                onTap: () => Navigator.of(context).pop("summary"),
              ),
            ],
          ),
        );
      },
    );

    if (selected == "detailed") {
      await exportProductionDetailedExcel();
    } else if (selected == "summary") {
      await exportProductionSummaryExcel();
    }
  }

  Future<void> exportProductionSummaryExcel() async {
    if (dates.isEmpty || controllers.isEmpty) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "No data available to export.",
      );
      return;
    }

    _recalculateSheet();

    final summaryDate = _to ?? DateTime.now();
    final summaryDateText = _format(summaryDate);
    final rowsForDate = <int>[
      for (int i = 0; i < dates.length; i++)
        if (dates[i] == summaryDateText) i,
    ];

    if (rowsForDate.isEmpty) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "No data found for $summaryDateText.",
      );
      return;
    }

    final lastDateRow = rowsForDate.last;

    double sumForDate(int col) {
      return rowsForDate.fold<double>(
        0,
        (sum, row) => sum + _cellNumber(row, col),
      );
    }

    String percentText(double achieved, double target) {
      if (target == 0) return "0.00%";
      return "${(achieved / target * 100).toStringAsFixed(2)}%";
    }

    final dayBoxTarget = sumForDate(7);
    final dayBoxAchieved = sumForDate(8);
    final dayManTarget = sumForDate(9);
    final dayManAchieved = sumForDate(10);
    final perDayCtc = _ctcDays == 0 ? 0.0 : _monthlyCtc / _ctcDays;
    final dayLabourCost = dayBoxAchieved == 0
        ? 0.0
        : perDayCtc * dayManAchieved / dayBoxAchieved;
    final dayProductivity = dayManAchieved == 0
        ? 0.0
        : dayBoxAchieved / dayManAchieved;

    final mtdBoxTarget = _cellNumber(lastDateRow, 13);
    final mtdBoxAchieved = _cellNumber(lastDateRow, 14);
    final mtdManTarget = _cellNumber(lastDateRow, 15);
    final mtdManAchieved = _cellNumber(lastDateRow, 16);
    final mtdLabourCost = _cellNumber(lastDateRow, 17);
    final mtdProductivity = _cellNumber(lastDateRow, 19);

    const labourCostTarget = 375.0;
    const productivityTarget = 2.1;

    final List<List<dynamic>> rows = [
      [
        "Box qty",
        dayBoxTarget,
        dayBoxAchieved,
        percentText(dayBoxAchieved, dayBoxTarget),
        mtdBoxTarget,
        mtdBoxAchieved,
        percentText(mtdBoxAchieved, mtdBoxTarget),
      ],
      [
        "Man days",
        dayManTarget,
        dayManAchieved,
        percentText(dayManAchieved, dayManTarget),
        mtdManTarget,
        mtdManAchieved,
        percentText(mtdManAchieved, mtdManTarget),
      ],
      [
        "Labour cost/box",
        labourCostTarget,
        dayLabourCost,
        percentText(dayLabourCost, labourCostTarget),
        labourCostTarget,
        mtdLabourCost,
        percentText(mtdLabourCost, labourCostTarget),
      ],
      [
        "Productivity (Avg Box per person)",
        productivityTarget,
        dayProductivity,
        percentText(dayProductivity, productivityTarget),
        productivityTarget,
        mtdProductivity,
        percentText(mtdProductivity, productivityTarget),
      ],
    ];

    final monthYear = DateFormat('MMM yyyy').format(summaryDate).toUpperCase();
    final caption =
        "Production With Manpower Cost Per Box For The Month Of $monthYear "
        "- ${_selectedPlant ?? ''} - ${_selectedShift ?? ''} "
        "- As On $summaryDateText";

    await reportService.generateExcel(
      sheetName: 'Summary',
      headers: const [
        'Particular',
        'Date Target',
        'Date Achieved',
        'Date Ach %',
        'MTD Target',
        'MTD Achieved',
        'MTD Ach %',
      ],
      rows: rows,
      fileName: 'Production_Summary_With_Manpower_Cost_Summary.xlsx',
      amountColumns: const [2, 3, 5, 6],
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

  void _moveFocus(int row, int col, {int rowOffset = 0, int colOffset = 0}) {
    final newRow = row + rowOffset;
    final newCol = col + colOffset;

    if (newRow < 0 ||
        newRow >= focusNodes.length ||
        newCol < 0 ||
        newCol >= focusNodes[newRow].length) {
      return;
    }

    FocusScope.of(context).requestFocus(focusNodes[newRow][newCol]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final controller = controllers[newRow][newCol];

      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  Future<void> _saveProductionSummaryWithManpowerCostDetails() async {
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

    _recalculateSheet();

    List<Map<String, dynamic>> productionSummaryData = [];

    for (int i = 0; i < dates.length; i++) {
      final values = List<double>.generate(
        _dataColumnCount,
        (index) => _cellNumber(i, index),
      );

      bool isRowEmpty = [
        values[0],
        values[1],
        values[2],
        values[3],
        values[4],
        values[7],
        values[9],
      ].every((e) => e == 0);

      bool existedInDb = existingDbDates.contains(dates[i]);

      if (isRowEmpty && !existedInDb) continue;
      productionSummaryData.add({
        "ProductionSummaryWithManpowerCostId": rowIds[i],
        "UserId": int.tryParse(userID) ?? 0,
        "ProductionSummaryPlant": _selectedPlant,
        "ProductionSummaryShift": _selectedShift,
        "ProductionSummaryDate": convertToIso(dates[i]),
        "MonthlyCTC": _monthlyCtc,
        "CTCDays": _ctcDays,
        "WrapSheetWorkerDivisor": _wrapSheetWorkerDivisor,
        "GownKitDrapeQuantity": values[0],
        "GownKitDrapeNoOfBox": values[1],
        "GownKitDrapeNoOfWorker": values[2],
        "WrapSheetQuantity": values[3],
        "WrapSheetNoOfBox": values[4],
        "WrapSheetNoOfWorker": values[5],
        "TotalQuantity": values[6],
        "TargetBoxQty": values[7],
        "TotalNoOfBox": values[8],
        "ManDayTarget": values[9],
        "ManDayAttended": values[10],
        "LabourCostPerBox": values[11],
        "CumulativeQuantity": values[12],
        "CumulativeTargetBoxQty": values[13],
        "CumulativeNoOfBox": values[14],
        "CumulativeManDayTarget": values[15],
        "CumulativeManDayAttended": values[16],
        "CumulativeLabourCostPerBox": values[17],
        "ProductivityBoxPerPersonDay": values[18],
        "ProductivityBoxPerPersonMTD": values[19],
      });
    }

    // If nothing to save
    if (productionSummaryData.isEmpty) {
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
      "ProductionSummaryWithManpowerCostData": productionSummaryData,
      'DeletedIds': deletedRowIds,
    };

    const apiUrl =
        '${ApiHelper.baseUrl}insertorupdateproductionsummarywithmanpowercost';
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
        deletedRowIds.clear();
        _displayData();
      } else {
        if (!mounted) return;
        NotificationService.error(title: "Error", message: "Save failed..");
      }
    } catch (e, s) {
      debugPrint("SAVE ERROR: $e");
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      NotificationService.error(title: "Error", message: e.toString());
    }
  }

  dynamic _firstValue(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      if (row.containsKey(key) && row[key] != null) return row[key];
    }
    return null;
  }

  String _rowText(Map<String, dynamic> row, List<String> keys) {
    final value = _firstValue(row, keys);
    return value?.toString() ?? '0';
  }

  int _rowId(Map<String, dynamic> row) {
    return int.tryParse(
          _firstValue(row, const [
                'ProductionSummaryWithManpowerCostId',
                'ProductionSummaryId',
                'Id',
              ])?.toString() ??
              '0',
        ) ??
        0;
  }

  String _rowDate(Map<String, dynamic> row) {
    final value = _firstValue(row, const [
      'ProductionSummaryDate',
      'ProductionDate',
      'Date',
    ]);
    return formatDate(value?.toString() ?? DateTime.now().toIso8601String());
  }

  List<TextEditingController> _controllersFromApiRow(Map<String, dynamic> row) {
    return [
      TextEditingController(
        text: _rowText(row, const ['GownKitDrapeQuantity', 'GownQuantity']),
      ),
      TextEditingController(
        text: _rowText(row, const ['GownKitDrapeNoOfBox', 'GownNoOfBox']),
      ),
      TextEditingController(
        text: _rowText(row, const ['GownKitDrapeNoOfWorker', 'GownNoOfWorker']),
      ),
      TextEditingController(text: _rowText(row, const ['WrapSheetQuantity'])),
      TextEditingController(text: _rowText(row, const ['WrapSheetNoOfBox'])),
      TextEditingController(text: _rowText(row, const ['WrapSheetNoOfWorker'])),
      TextEditingController(text: _rowText(row, const ['TotalQuantity'])),
      TextEditingController(text: _rowText(row, const ['TargetBoxQty'])),
      TextEditingController(text: _rowText(row, const ['TotalNoOfBox'])),
      TextEditingController(text: _rowText(row, const ['ManDayTarget'])),
      TextEditingController(text: _rowText(row, const ['ManDayAttended'])),
      TextEditingController(text: _rowText(row, const ['LabourCostPerBox'])),
      TextEditingController(text: _rowText(row, const ['CumulativeQuantity'])),
      TextEditingController(
        text: _rowText(row, const ['CumulativeTargetBoxQty']),
      ),
      TextEditingController(text: _rowText(row, const ['CumulativeNoOfBox'])),
      TextEditingController(
        text: _rowText(row, const ['CumulativeManDayTarget']),
      ),
      TextEditingController(
        text: _rowText(row, const ['CumulativeManDayAttended']),
      ),
      TextEditingController(
        text: _rowText(row, const ['CumulativeLabourCostPerBox']),
      ),
      TextEditingController(
        text: _rowText(row, const ['ProductivityBoxPerPersonDay']),
      ),
      TextEditingController(
        text: _rowText(row, const ['ProductivityBoxPerPersonMTD']),
      ),
    ];
  }

  Future<void> fetchProductionSummaryWithManpowerCostDetails(
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
      "ProductionSummaryPlant": plant,
      "ProductionSummaryShift": shift,
      "FromDate": _from?.toIso8601String(),
      "ToDate": _to?.toIso8601String(),
    };

    const apiUrl =
        '${ApiHelper.baseUrl}selectproductionsummarywithmanpowercost';
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

          if (result.isNotEmpty) {
            final firstRow = Map<String, dynamic>.from(result.first as Map);

            _monthlyCtc = (firstRow["MonthlyCTC"] as num?)?.toDouble() ?? 27080;

            _ctcDays = (firstRow["CTCDays"] as num?)?.toDouble() ?? 26;

            _wrapSheetWorkerDivisor =
                (firstRow["WrapSheetWorkerDivisor"] as num?)?.toDouble() ??
                6000;

            _monthlyCtcController.text = _monthlyCtc.toString();
            _ctcDaysController.text = _ctcDays.toString();
            _workerDivisorController.text = _wrapSheetWorkerDivisor.toString();
          }

          Map<String, List<Map<String, dynamic>>> apiDataByDate = {};
          existingDbDates.clear();

          for (var row in result) {
            final typedRow = Map<String, dynamic>.from(row as Map);
            String formatted = _rowDate(typedRow);

            apiDataByDate.putIfAbsent(formatted, () => []);
            apiDataByDate[formatted]!.add(typedRow);

            existingDbDates.add(formatted);
          }

          _disposeRows();

          final originalDates = List<String>.from(dates);
          controllers.clear();
          rowIds.clear();
          dates.clear();
          focusNodes.clear();

          for (final date in originalDates) {
            final rowsForDate = apiDataByDate[date];

            if (rowsForDate == null || rowsForDate.isEmpty) {
              dates.add(date);
              rowIds.add(0);
              controllers.add(_createEmptyRowControllers());
            } else {
              for (final row in rowsForDate) {
                dates.add(date);
                rowIds.add(_rowId(row));
                controllers.add(_controllersFromApiRow(row));
              }
            }
          }

          _buildFocusNodes();
          _recalculateSheet();

          if (mounted) {
            setState(() {});
          }
        } else {
          emptyTableCreation();
        }
      } else {
        if (!mounted) return;
        emptyTableCreation();
        NotificationService.info(
          title: "Info",
          message:
              "Error occured while selecting the production summary details",
        );
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while selecting the production summary details",
      );
    }
  }

  void emptyTableCreation() {
    existingDbDates.clear();

    // Create empty controllers for fresh entry
    controllers.clear();
    rowIds.clear();

    for (int i = 0; i < dates.length; i++) {
      rowIds.add(0);
      controllers.add(_createEmptyRowControllers());
    }

    // Build focusNodes
    _buildFocusNodes();

    _recalculateSheet();

    if (mounted) {
      setState(() {});
    }
  }

  List<TextEditingController> _createEmptyRowControllers() {
    return List.generate(
      _dataColumnCount,
      (_) => TextEditingController(text: '0'),
    );
  }

  void _disposeRows() {
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
  }

  void _buildFocusNodes() {
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
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    totals = List.filled(_dataColumnCount, 0.0);

    await fetchProductionSummaryWithManpowerCostDetails(
      _selectedPlant!,
      _selectedShift!,
    );

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

  void initializeCellValues() {
    cellValues = List.generate(
      controllers.length,
      (row) => List.generate(controllers[row].length, (col) {
        return double.tryParse(controllers[row][col].text) ?? 0;
      }),
    );
  }

  double _cellNumber(int row, int col) {
    if (row < 0 ||
        row >= controllers.length ||
        col < 0 ||
        col >= controllers[row].length) {
      return 0;
    }
    return double.tryParse(controllers[row][col].text.trim()) ?? 0;
  }

  void _setCalculatedCell(int row, int col, double value) {
    final controller = controllers[row][col];
    final text = _formatNumber(value);
    if (controller.text == text) return;
    controller.text = text;
  }

  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return '0';
    final rounded = double.parse(value.toStringAsFixed(2));
    if (rounded == rounded.roundToDouble()) {
      return rounded.toStringAsFixed(0);
    }
    return rounded.toStringAsFixed(2);
  }

  void _recalculateSheet({int startRow = 0}) {
    if (controllers.isEmpty) {
      totals = List.filled(_dataColumnCount, 0.0);
      totalsNotifier.value = List<double>.from(totals);
      return;
    }

    final perDayCtc = _monthlyCtc / _ctcDays;
    final safeStart = startRow.clamp(0, controllers.length - 1).toInt();

    for (int row = safeStart; row < controllers.length; row++) {
      final gownQty = _cellNumber(row, 0);
      final gownBox = _cellNumber(row, 1);
      final gownWorker = _cellNumber(row, 2);
      final wrapQty = _cellNumber(row, 3);
      final wrapBox = _cellNumber(row, 4);
      final targetBoxQty = _cellNumber(row, 7);
      final manDayTarget = _cellNumber(row, 9);

      final wrapWorker = (wrapQty / _wrapSheetWorkerDivisor).round().toDouble();
      final totalQty = gownQty + wrapQty;
      final totalBox = gownBox + wrapBox;
      final manDayAttended = gownWorker + wrapWorker;
      final labourCostPerBox = totalBox == 0
          ? 0.0
          : perDayCtc * manDayAttended / totalBox;

      final prevCumulativeQty = row == 0 ? 0.0 : _cellNumber(row - 1, 12);
      final prevCumulativeTargetBox = row == 0 ? 0.0 : _cellNumber(row - 1, 13);
      final prevCumulativeBox = row == 0 ? 0.0 : _cellNumber(row - 1, 14);
      final prevCumulativeManDayTarget = row == 0
          ? 0.0
          : _cellNumber(row - 1, 15);
      final prevCumulativeManDayAttended = row == 0
          ? 0.0
          : _cellNumber(row - 1, 16);

      final cumulativeQty = prevCumulativeQty + totalQty;
      final cumulativeTargetBox = prevCumulativeTargetBox + targetBoxQty;
      final cumulativeBox = prevCumulativeBox + totalBox;
      final cumulativeManDayTarget = prevCumulativeManDayTarget + manDayTarget;
      final cumulativeManDayAttended =
          prevCumulativeManDayAttended + manDayAttended;
      final cumulativeLabourCostPerBox = cumulativeBox == 0
          ? 0.0
          : perDayCtc * cumulativeManDayAttended / cumulativeBox;
      final productivityDay = manDayAttended == 0
          ? 0.0
          : totalBox / manDayAttended;
      final productivityMtd = cumulativeManDayAttended == 0
          ? 0.0
          : cumulativeBox / cumulativeManDayAttended;

      _setCalculatedCell(row, 5, wrapWorker);
      _setCalculatedCell(row, 6, totalQty);
      _setCalculatedCell(row, 8, totalBox);
      _setCalculatedCell(row, 10, manDayAttended);
      _setCalculatedCell(row, 11, labourCostPerBox);
      _setCalculatedCell(row, 12, cumulativeQty);
      _setCalculatedCell(row, 13, cumulativeTargetBox);
      _setCalculatedCell(row, 14, cumulativeBox);
      _setCalculatedCell(row, 15, cumulativeManDayTarget);
      _setCalculatedCell(row, 16, cumulativeManDayAttended);
      _setCalculatedCell(row, 17, cumulativeLabourCostPerBox);
      _setCalculatedCell(row, 18, productivityDay);
      _setCalculatedCell(row, 19, productivityMtd);
    }

    initializeCellValues();
    calculateTotals();
  }

  void updateColumnTotal(int row, int col) {
    if (isFormulaColumn(col)) return;
    _recalculateSheet(startRow: row);
  }

  void calculateTotals() {
    if (controllers.isEmpty) return;

    int numericColumnCount = controllers[0].length;

    totals = List.filled(numericColumnCount, 0.0);

    for (int row = 0; row < controllers.length; row++) {
      for (int col = 0; col < numericColumnCount; col++) {
        totals[col] += cellValues[row][col];
      }
    }

    totalsNotifier.value = [...totals];
  }

  void clearValues() {
    _disposeRows();

    setState(() {
      for (int i = 0; i < totals.length; i++) {
        totals[i] = 0.0;
      }
      controllers = List.generate(
        dates.length,
        (_) => _createEmptyRowControllers(),
      );
      _buildFocusNodes();
      _recalculateSheet();
    });
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

  void _displayData() async {
    if (_from == null || _to == null) return;

    dates.clear();
    controllers.clear();
    focusNodes.clear();
    existingDbDates.clear();

    DateTime current = _from!;
    while (current.isBefore(_to!) || current.isAtSameMomentAs(_to!)) {
      dates.add(_format(current));
      current = current.add(const Duration(days: 1));
    }
    totals = List.filled(_dataColumnCount, 0.0);

    await fetchProductionSummaryWithManpowerCostDetails(
      _selectedPlant!,
      _selectedShift!,
    );
  }

  void _insertRowBelow(int rowIndex) {
    if (rowIndex >= controllers.length) return;

    final newControllers = List.generate(
      controllers[rowIndex].length,
      (_) => TextEditingController(text: '0'),
    );

    final newFocusNodes = List.generate(
      controllers[rowIndex].length,
      (_) => FocusNode(),
    );

    setState(() {
      dates.insert(rowIndex + 1, dates[rowIndex]);
      // 0 = new record
      rowIds.insert(rowIndex + 1, 0);
      controllers.insert(rowIndex + 1, newControllers);
      cellValues.insert(rowIndex + 1, List.filled(newControllers.length, 0));
      focusNodes.insert(rowIndex + 1, newFocusNodes);
      highlightedRowIndex = rowIndex + 1;
    });
    _recalculateSheet(startRow: rowIndex + 1);

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      focusNodes[rowIndex + 1][0].requestFocus();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        highlightedRowIndex = null;
      });
    });
  }

  void _deleteRow(int rowIndex) {
    if (dates.length <= 1) return;

    final rowId = rowIds[rowIndex];
    final deletedValues = List<double>.from(cellValues[rowIndex]);

    if (rowId > 0) {
      deletedRowIds.add(rowId);
    }

    controllers[rowIndex].forEach((e) => e.dispose());
    focusNodes[rowIndex].forEach((e) => e.dispose());

    setState(() {
      dates.removeAt(rowIndex);
      rowIds.removeAt(rowIndex);
      controllers.removeAt(rowIndex);
      cellValues.removeAt(rowIndex);
      focusNodes.removeAt(rowIndex);
    });

    for (int i = 0; i < totals.length && i < deletedValues.length; i++) {
      totals[i] -= deletedValues[i];
    }
    totalsNotifier.value = List<double>.from(totals);
    _recalculateSheet(startRow: rowIndex);
  }

  Future<void> _runRowAction({
    required int rowIndex,
    required bool isAdd,
    required VoidCallback action,
  }) async {
    if (_pendingActionRowIndex != null) return;

    setState(() {
      _pendingActionRowIndex = rowIndex;
      _pendingActionIsAdd = isAdd;
    });

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    try {
      HapticFeedback.selectionClick();
      action();
      await WidgetsBinding.instance.endOfFrame;
    } finally {
      if (!mounted) return;

      setState(() {
        _pendingActionRowIndex = null;
        _pendingActionIsAdd = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRows = dates.isNotEmpty;
    final keyboardVisible =
        !kIsWeb && MediaQuery.of(context).viewInsets.bottom > 0;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 0.0,
        title: const Text(
          "PRODUCTION SUMMARY WITH MANPOWER COST",
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
        padding: const EdgeInsets.all(4),

        child: Column(
          children: [
            /// TOP FILTER AREA
            if (!(keyboardVisible && isLandscape))
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      _buildDatePickers(),
                      const SizedBox(height: 8),
                      _buildCalculationSettings(),
                    ],
                  ),
                ),
              ),

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

      bottomNavigationBar: hasRows && !keyboardVisible
          ? _buildSaveButton()
          : null,
    );
  }

  Widget _buildDatePickers() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    _selectedPlant ??= 'Rajapalayam IPD Plant'; // default selection
    _selectedShift ??= 'DAY'; // default selection

    final dropdownPlant = SizedBox(
      width: 240,
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
            value: 'Rajapalayam IPD Plant',
            child: Text('Rajapalayam IPD Plant'),
          ),
          DropdownMenuItem(
            value: 'Rajapalayam CMS Plant',
            child: Text('Rajapalayam CMS Plant'),
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
          if (_from != null && _to != null) {
            _generateDateArray();
          }
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
          });
          if (_from != null && _to != null) {
            _generateDateArray();
          }
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

  Widget _buildCalculationSettings() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: TextFormField(
              controller: _monthlyCtcController,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [DecimalInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Monthly CTC',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5.8,
                ),
              ),
              onChanged: (value) {
                _monthlyCtc = double.tryParse(value) ?? 0;
                _recalculateSheet();
                setState(() {});
              },
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 100,
            child: TextFormField(
              controller: _ctcDaysController,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [DecimalInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'CTC Days',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5.8,
                ),
              ),
              onChanged: (value) {
                _ctcDays = double.tryParse(value) ?? 0;
                _recalculateSheet();
                setState(() {});
              },
            ),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 140,
            child: TextFormField(
              controller: _workerDivisorController,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [DecimalInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'WS Worker Divisor',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5.8,
                ),
              ),
              onChanged: (value) {
                _wrapSheetWorkerDivisor = double.tryParse(value) ?? 0;
                _recalculateSheet();
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyTable() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(blurRadius: 4, color: Colors.black12, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
            child: Row(
              children: [
                SizedBox(width: _frozenTableWidth, child: _buildFrozenHeader()),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerHorizontalController,
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: _buildScrollableHeader(),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade300),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 6, right: 6),
              child: RawScrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 8,
                radius: const Radius.circular(12),
                interactive: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _frozenTableWidth,
                        child: _buildFrozenBodyTable(),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _bodyHorizontalController,
                          scrollDirection: Axis.horizontal,
                          child: _buildScrollableBodyTable(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                SizedBox(width: _frozenTableWidth + 12),
                Expanded(
                  child: PermanentHorizontalScrollbar(
                    controller: _bodyHorizontalController,
                    height: 16,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrozenHeader() {
    return Table(
      border: TableBorder.all(color: Colors.black),
      columnWidths: _buildColumnWidths(0, _frozenColumnCount),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xffc0e4f3)),
          children: headers
              .take(_frozenColumnCount)
              .map(_buildHeaderCell)
              .toList(),
        ),
      ],
    );
  }

  Widget _buildScrollableHeader() {
    return Table(
      border: TableBorder.all(color: Colors.black),
      columnWidths: _buildColumnWidths(_frozenColumnCount, headers.length),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xffc0e4f3)),
          children: headers
              .skip(_frozenColumnCount)
              .map(_buildHeaderCell)
              .toList(),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      alignment: Alignment.center,
      height: _headerHeight,
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        maxLines: 3,
        overflow: TextOverflow.visible,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFrozenBodyTable() {
    return Table(
      border: TableBorder.all(color: Colors.black),
      columnWidths: _buildColumnWidths(0, _frozenColumnCount),
      children: [
        for (int i = 0; i < dates.length; i++) _buildFrozenRow(i),
        TableRow(
          decoration: BoxDecoration(color: Colors.green.shade200),
          children: [
            const SizedBox(height: _rowHeight),
            Container(
              alignment: Alignment.center,
              height: _rowHeight,
              child: const Text(
                "Total",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScrollableBodyTable() {
    return Table(
      border: TableBorder.all(color: Colors.black),
      columnWidths: _buildColumnWidths(_frozenColumnCount, headers.length),
      children: [
        for (int i = 0; i < dates.length; i++) _buildScrollableRow(i),

        TableRow(
          decoration: BoxDecoration(color: Colors.green.shade200),
          children: List.generate(headers.length - _frozenColumnCount, (index) {
            final colIndex = index + _frozenColumnCount;
            final totalIndex = colIndex - 2;

            if ({11, 17, 18, 19}.contains(totalIndex)) {
              return const SizedBox(height: _rowHeight);
            }

            return Container(
              alignment: Alignment.centerRight,
              height: _rowHeight,
              padding: const EdgeInsets.all(8),
              child: ValueListenableBuilder<List<double>>(
                valueListenable: totalsNotifier,
                builder: (context, totals, child) {
                  final text = totalIndex >= 12 && totalIndex <= 16
                      ? (controllers.isEmpty
                            ? "0.00"
                            : controllers.last[totalIndex].text)
                      : (totalIndex < totals.length
                            ? totals[totalIndex].toStringAsFixed(2)
                            : "0.00");
                  return Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final barPadding = isLandscape
        ? const EdgeInsets.fromLTRB(12, 6, 12, 6)
        : const EdgeInsets.all(16.0);
    final buttonHeight = isLandscape ? 42.0 : 50.0;
    final fontSize = isLandscape ? 14.0 : 16.0;

    return Container(
      color: Colors.white,
      padding: barPadding,
      child: SafeArea(
        child: SizedBox(
          height: buttonHeight,
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
                          await _saveProductionSummaryWithManpowerCostDetails();
                          setState(() => isSaving = false);
                        },
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Save",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
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
                  onPressed: _showDownloadOptions,
                  child: Text(
                    "Download Excel",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
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

  TableRow _buildFrozenRow(int rowIndex) {
    if (controllers.length != dates.length ||
        focusNodes.length != dates.length) {
      return TableRow(
        children: List.generate(_frozenColumnCount, (_) => const SizedBox()),
      );
    }

    return TableRow(
      decoration: BoxDecoration(
        color: highlightedRowIndex == rowIndex ? Colors.yellow.shade100 : null,
      ),
      children: [
        Container(
          height: _rowHeight,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.add,
                color: Colors.green,
                tooltip: 'Add row',
                isBusy:
                    _pendingActionRowIndex == rowIndex &&
                    _pendingActionIsAdd == true,
                onTap: _pendingActionRowIndex == null
                    ? () => _runRowAction(
                        rowIndex: rowIndex,
                        isAdd: true,
                        action: () => _insertRowBelow(rowIndex),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: Icons.remove,
                color: Colors.red,
                tooltip: 'Delete row',
                isBusy:
                    _pendingActionRowIndex == rowIndex &&
                    _pendingActionIsAdd == false,
                onTap: dates.length > 1 && _pendingActionRowIndex == null
                    ? () => _runRowAction(
                        rowIndex: rowIndex,
                        isAdd: false,
                        action: () => _deleteRow(rowIndex),
                      )
                    : null,
              ),
            ],
          ),
        ),

        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          height: _rowHeight,
          child: Text(
            dates[rowIndex],
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required bool isBusy,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null && !isBusy;
    final effectiveColor = isEnabled || isBusy ? color : Colors.grey;

    return Semantics(
      button: true,
      label: tooltip,
      enabled: isEnabled,
      child: Material(
        color: effectiveColor.withAlpha(isEnabled || isBusy ? 34 : 14),
        elevation: isEnabled || isBusy ? 2 : 0,
        shadowColor: effectiveColor.withAlpha(70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          splashRadius: 22,
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (isBusy) return color;
              if (states.contains(WidgetState.disabled)) return Colors.grey;
              if (states.contains(WidgetState.pressed)) {
                return effectiveColor.withAlpha(255);
              }
              return effectiveColor;
            }),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (isBusy) return color.withAlpha(34);
              if (states.contains(WidgetState.disabled)) {
                return Colors.grey.withAlpha(16);
              }
              if (states.contains(WidgetState.pressed)) {
                return effectiveColor.withAlpha(58);
              }
              return effectiveColor.withAlpha(28);
            }),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (isBusy) return Colors.transparent;
              if (states.contains(WidgetState.pressed)) {
                return effectiveColor.withAlpha(70);
              }
              return effectiveColor.withAlpha(26);
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (isBusy) return BorderSide(color: color.withAlpha(110));
              final alpha = states.contains(WidgetState.pressed) ? 130 : 70;
              return BorderSide(color: effectiveColor.withAlpha(alpha));
            }),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          icon: isBusy
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Icon(icon, size: 20),
          onPressed: isEnabled ? onTap : null,
        ),
      ),
    );
  }

  TableRow _buildScrollableRow(int rowIndex) {
    if (controllers.length != dates.length ||
        focusNodes.length != dates.length) {
      return TableRow(
        children: List.generate(
          headers.length - _frozenColumnCount,
          (_) => const SizedBox(),
        ),
      );
    }

    return TableRow(
      decoration: BoxDecoration(
        color: highlightedRowIndex == rowIndex ? Colors.yellow.shade100 : null,
      ),
      children: List.generate(controllers[rowIndex].length, (colIndex) {
        return _buildEditableCell(rowIndex, colIndex);
      }),
    );
  }

  Widget _buildEditableCell(int rowIndex, int colIndex) {
    final isCalculated = isFormulaColumn(colIndex);

    return SizedBox(
      height: _rowHeight,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.arrowDown): MoveDownIntent(),
            SingleActivator(LogicalKeyboardKey.arrowUp): MoveUpIntent(),
            SingleActivator(LogicalKeyboardKey.tab): MoveRightIntent(),
            SingleActivator(LogicalKeyboardKey.tab, shift: true):
                MoveLeftIntent(),
          },
          child: Actions(
            actions: {
              MoveDownIntent: CallbackAction<MoveDownIntent>(
                onInvoke: (_) {
                  _moveFocus(rowIndex, colIndex, rowOffset: 1);
                  return null;
                },
              ),
              MoveUpIntent: CallbackAction<MoveUpIntent>(
                onInvoke: (_) {
                  _moveFocus(rowIndex, colIndex, rowOffset: -1);
                  return null;
                },
              ),
              MoveLeftIntent: CallbackAction<MoveLeftIntent>(
                onInvoke: (_) {
                  _moveFocus(rowIndex, colIndex, colOffset: -1);
                  return null;
                },
              ),
              MoveRightIntent: CallbackAction<MoveRightIntent>(
                onInvoke: (_) {
                  _moveFocus(rowIndex, colIndex, colOffset: 1);
                  return null;
                },
              ),
            },
            child: TextField(
              controller: controllers[rowIndex][colIndex],
              focusNode: focusNodes[rowIndex][colIndex],
              readOnly: isCalculated,
              keyboardType: isNumericColumn(colIndex)
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              inputFormatters: isNumericColumn(colIndex)
                  ? [DecimalInputFormatter()]
                  : [],
              textInputAction: TextInputAction.next,
              textAlign: isNumericColumn(colIndex)
                  ? TextAlign.right
                  : TextAlign.left,
              onChanged: (_) {
                updateColumnTotal(rowIndex, colIndex);
              },
              onSubmitted: (_) {
                _moveFocus(rowIndex, colIndex, rowOffset: 1);
              },
              onTap: () {
                controllers[rowIndex][colIndex].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controllers[rowIndex][colIndex].text.length,
                );
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                filled: isCalculated,
                fillColor: const Color(0xfff3f6f8),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
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
    _horizontalController.dispose();
    _verticalController.dispose();

    _horizontalScrollbarController.dispose();
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();

    _monthlyCtcController.dispose();
    _ctcDaysController.dispose();
    _workerDivisorController.dispose();

    totalsNotifier.dispose();
    super.dispose();
  }
}
