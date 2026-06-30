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

class WrapsheetCalculationPage extends StatefulWidget {
  @override
  _WrapsheetCalculationPageState createState() =>
      _WrapsheetCalculationPageState();
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

class _WrapsheetCalculationPageState extends State<WrapsheetCalculationPage> {
  final String plant = "";
  DateTime? date;
  final bool isSunday = false;

  final List<String> headers = [
    "Action",
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

  static const int _frozenColumnCount = 2;
  static const double _headerHeight = 72;
  static const double _rowHeight = 55;
  static const double _actionColumnWidth = 90;
  static const double _dateColumnWidth = 120;
  static const int _dataColumnCount = 30;
  static const Set<int> _formulaColumnIndexes = {18, 24, 25, 26, 27, 28};

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

  bool _isFormulaColumn(int colIndex) {
    return _formulaColumnIndexes.contains(colIndex);
  }

  double _numericValue(List<TextEditingController> row, int index) {
    if (index < 0 || index >= row.length) return 0;
    return double.tryParse(row[index].text.trim()) ?? 0;
  }

  String _formatCalculatedValue(double value) {
    if (!value.isFinite) return '0';
    final rounded = double.parse(value.toStringAsFixed(4));
    if (rounded == 0) return '0';
    return rounded.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _setCalculatedValue(
    List<TextEditingController> row,
    int index,
    double value,
  ) {
    final text = _formatCalculatedValue(value);
    if (row[index].text == text) return;
    row[index].text = text;
  }

  void _recalculateRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= controllers.length) return;

    final row = controllers[rowIndex];

    final qtyProd1 = _numericValue(row, 0);
    final lg1 = _numericValue(row, 1);
    final wd1 = _numericValue(row, 2);
    final qtyProd2 = _numericValue(row, 3);
    final lg2 = _numericValue(row, 4);
    final wd2 = _numericValue(row, 5);
    final qtyProd3 = _numericValue(row, 6);
    final lg3 = _numericValue(row, 7);
    final wd3 = _numericValue(row, 8);
    final gsm = _numericValue(row, 9);
    final openWt = _numericValue(row, 11);
    final newRollWt = _numericValue(row, 12);
    final closingWt = _numericValue(row, 13);
    final noOfLays = _numericValue(row, 15);
    final catcherWasteLg = _numericValue(row, 16);
    final catcherWasteWd = _numericValue(row, 17);
    final addWaste1 = _numericValue(row, 21);
    final addWaste2Lg = _numericValue(row, 22);
    final addWaste2Wd = _numericValue(row, 23);

    final catcherWaste =
        catcherWasteLg * catcherWasteWd * gsm * noOfLays / 10000 / 1000;
    final addWaste2 = addWaste2Lg * addWaste2Wd * noOfLays * gsm / 10000 / 1000;
    final stdCons =
        ((lg1 * wd1 * gsm * qtyProd1) +
                (lg2 * wd2 * gsm * qtyProd2) +
                (qtyProd3 * lg3 * wd3 * gsm)) /
            10000 /
            1000 +
        catcherWaste +
        addWaste2 +
        addWaste1;
    final actCons = openWt + newRollWt - closingWt;
    final consDif = actCons - stdCons;
    final percentWaste = actCons == 0 ? 0.0 : consDif / actCons;

    _setCalculatedValue(row, 18, catcherWaste);
    _setCalculatedValue(row, 24, addWaste2);
    _setCalculatedValue(row, 25, stdCons);
    _setCalculatedValue(row, 26, actCons);
    _setCalculatedValue(row, 27, consDif);
    _setCalculatedValue(row, 28, percentWaste);
  }

  void _recalculateAllRows() {
    for (int i = 0; i < controllers.length; i++) {
      _recalculateRow(i);
    }
  }

  void _refreshCalculatedValuesAndTotals({int? rowIndex}) {
    if (rowIndex == null) {
      _recalculateAllRows();
    } else {
      _recalculateRow(rowIndex);
    }
    initializeCellValues();
    calculateTotals();
  }

  bool _hasRowData(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= controllers.length) return false;

    final row = controllers[rowIndex];
    final remarks = row.last.text.trim();
    final hasNumericValue = row
        .take(row.length - 1)
        .any(
          (controller) => (double.tryParse(controller.text.trim()) ?? 0) != 0,
        );

    return hasNumericValue || remarks.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
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

  Future<void> exportWrapsheetExcel() async {
    if (dates.isEmpty || controllers.isEmpty) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "No data available to export.",
      );
      return;
    }

    _refreshCalculatedValuesAndTotals();

    List<List<dynamic>> rows = [];

    String caption =
        "Wrapsheet Calculation - ${_selectedPlant ?? ''} - ${_selectedShift ?? ''} "
        "(${_format(_from!)} to ${_format(_to!)})";

    rows = [
      for (int i = 0; i < dates.length; i++)
        if (_hasRowData(i)) [dates[i], ...controllers[i].map((e) => e.text)],
    ];

    if (rows.isEmpty) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "No table data available to export.",
      );
      return;
    }
    reportService.generateExcel(
      sheetName: 'Wrapsheet Calculation',
      headers: headers.sublist(1),
      rows: rows,
      fileName: 'Wrapsheet_Calculation.xlsx',
      amountColumns: List.generate(headers.length - 3, (i) => i + 2),
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

  Future<void> _saveWrapsheetCalculationDetails() async {
    if (_from == null || _to == null) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "Please select date first",
      );
      return;
    }

    _refreshCalculatedValuesAndTotals();

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
        "WrapsheetId": rowIds[i],
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
      'DeletedIds': deletedRowIds,
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

          Map<String, List<dynamic>> apiDataByDate = {};
          existingDbDates.clear();

          for (var row in result) {
            String formatted = formatDate(row['WrapsheetDate']);

            apiDataByDate.putIfAbsent(formatted, () => []);
            apiDataByDate[formatted]!.add(row);

            existingDbDates.add(formatted);
          }

          for (final row in controllers) {
            for (final controller in row) {
              controller.dispose();
            }
          }

          // Rebuild focusNodes with same structure
          for (final row in focusNodes) {
            for (final node in row) {
              node.dispose();
            }
          }
          focusNodes.clear();

          final originalDates = List<String>.from(dates);
          controllers.clear();
          rowIds.clear();
          dates.clear();

          for (final date in originalDates) {
            final rowsForDate = apiDataByDate[date];

            if (rowsForDate == null || rowsForDate.isEmpty) {
              // Empty row for missing date

              dates.add(date);
              rowIds.add(0);

              controllers.add(_createEmptyRowControllers());
            } else {
              // One UI row per DB row

              for (final row in rowsForDate) {
                dates.add(date);

                rowIds.add(
                  int.tryParse(row['WrapsheetId']?.toString() ?? '0') ?? 0,
                );

                final rowControllers = <TextEditingController>[
                  TextEditingController(
                    text: row['QtyProd1']?.toString() ?? '0',
                  ),
                  TextEditingController(text: row['Lg1']?.toString() ?? '0'),
                  TextEditingController(text: row['Wd1']?.toString() ?? '0'),

                  TextEditingController(
                    text: row['QtyProd2']?.toString() ?? '0',
                  ),
                  TextEditingController(text: row['Lg2']?.toString() ?? '0'),
                  TextEditingController(text: row['Wd2']?.toString() ?? '0'),

                  TextEditingController(
                    text: row['QtyProd3']?.toString() ?? '0',
                  ),
                  TextEditingController(text: row['Lg3']?.toString() ?? '0'),
                  TextEditingController(text: row['Wd3']?.toString() ?? '0'),

                  TextEditingController(text: row['GSM']?.toString() ?? '0'),
                  TextEditingController(
                    text: row['RollWidth']?.toString() ?? '0',
                  ),

                  TextEditingController(text: row['OpenWt']?.toString() ?? '0'),
                  TextEditingController(
                    text: row['NewRollWt']?.toString() ?? '0',
                  ),
                  TextEditingController(
                    text: row['ClosingWt']?.toString() ?? '0',
                  ),

                  TextEditingController(text: row['LayLg']?.toString() ?? '0'),
                  TextEditingController(
                    text: row['NoOfLays']?.toString() ?? '0',
                  ),

                  TextEditingController(
                    text: row['CatcherWasteLg']?.toString() ?? '0',
                  ),
                  TextEditingController(
                    text: row['CatcherWasteWd']?.toString() ?? '0',
                  ),
                  TextEditingController(
                    text: row['CatcherWaste']?.toString() ?? '0',
                  ),

                  TextEditingController(
                    text: row['AddWaste1Lg']?.toString() ?? '0',
                  ),
                  TextEditingController(
                    text: row['AddWaste1Wd']?.toString() ?? '0',
                  ),
                  TextEditingController(
                    text: row['AddWaste1']?.toString() ?? '0',
                  ),

                  TextEditingController(
                    text: row['AddWaste2Lg']?.toString() ?? '0',
                  ),
                  TextEditingController(
                    text: row['AddWaste2Wd']?.toString() ?? '0',
                  ),
                  TextEditingController(
                    text: row['AddWaste2']?.toString() ?? '0',
                  ),

                  TextEditingController(
                    text: row['StdCons']?.toString() ?? '0',
                  ),
                  TextEditingController(
                    text: row['ActCons']?.toString() ?? '0',
                  ),
                  TextEditingController(
                    text: row['ConsDif']?.toString() ?? '0',
                  ),
                  TextEditingController(
                    text: row['PercentWaste']?.toString() ?? '0',
                  ),

                  TextEditingController(text: row['Remarks']?.toString() ?? ''),
                ];

                controllers.add(rowControllers);
              }
            }
          }

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

          _refreshCalculatedValuesAndTotals();

          if (mounted) {
            setState(() {});
          }
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

    _disposeRows();
    controllers.clear();
    focusNodes.clear();
    rowIds.clear();

    for (int i = 0; i < dates.length; i++) {
      rowIds.add(0);
      controllers.add(_createEmptyRowControllers());
    }

    // Build focusNodes
    _buildFocusNodes();

    _refreshCalculatedValuesAndTotals();

    if (mounted) {
      setState(() {});
    }
  }

  List<TextEditingController> _createEmptyRowControllers() {
    return List.generate(
      _dataColumnCount,
      (index) =>
          TextEditingController(text: index == _dataColumnCount - 1 ? '' : '0'),
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

  void initializeCellValues() {
    cellValues = List.generate(
      controllers.length,
      (row) => List.generate(controllers[row].length, (col) {
        if (col == controllers[row].length - 1) {
          return 0; // Remarks column
        }

        return double.tryParse(controllers[row][col].text) ?? 0;
      }),
    );
  }

  void updateColumnTotal(int row, int col) {
    // Ignore Remarks column
    if (col == controllers[row].length - 1) return;

    final oldValue = cellValues[row][col];

    // final newValue = double.tryParse(controllers[row][col].text.trim()) ?? 0;
    final text = controllers[row][col].text;
    final newValue = double.tryParse(text) ?? 0;

    if (oldValue == newValue) return;

    cellValues[row][col] = newValue;

    totals[col] = totals[col] - oldValue + newValue;

    // totalsNotifier.value = [...totals];
    totalsNotifier.value = List<double>.from(totals);
  }

  void calculateTotals() {
    if (controllers.isEmpty) return;

    int numericColumnCount = controllers[0].length - 1;

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
      _refreshCalculatedValuesAndTotals();
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
    totals = List.filled(headers.length - 1, 0.0);

    await fetchWrapsheetCalculationDetails(_selectedPlant!, _selectedShift!);
  }

  void _insertRowBelow(int rowIndex) {
    if (rowIndex >= controllers.length) return;

    final newControllers = List.generate(
      controllers[rowIndex].length,
      (index) => TextEditingController(
        text: index == controllers[rowIndex].length - 1 ? '' : '0',
      ),
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

    _refreshCalculatedValuesAndTotals(rowIndex: rowIndex + 1);

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

    for (int i = 0; i < totals.length && i < deletedValues.length - 1; i++) {
      totals[i] -= deletedValues[i];
    }
    totalsNotifier.value = List<double>.from(totals);
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
        padding: const EdgeInsets.all(8.0),

        child: Column(
          children: [
            /// TOP FILTER AREA
            if (!(keyboardVisible && isLandscape))
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
            value: 'Rajapalayam IPD Plant',
            child: Text('Rajapalayam IPD Plant'),
          ),
          DropdownMenuItem(
            value: 'Bangalore IPD Plant',
            child: Text('Bangalore IPD Plant'),
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

            if (colIndex == headers.length - 1) {
              return const SizedBox(height: _rowHeight);
            }

            return Container(
              alignment: Alignment.centerRight,
              height: _rowHeight,
              padding: const EdgeInsets.all(8),
              child: ValueListenableBuilder<List<double>>(
                valueListenable: totalsNotifier,
                builder: (context, totals, child) {
                  return Text(
                    totalIndex < totals.length
                        ? totals[totalIndex].toStringAsFixed(2)
                        : "0.00",
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
                          await _saveWrapsheetCalculationDetails();
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
                  onPressed: exportWrapsheetExcel,
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
    final isFormulaColumn = _isFormulaColumn(colIndex);

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
              readOnly: isFormulaColumn,
              keyboardType: isNumericColumn(colIndex)
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              textInputAction: TextInputAction.next,
              textAlign: isNumericColumn(colIndex)
                  ? TextAlign.right
                  : TextAlign.left,
              onChanged: (_) {
                if (isFormulaColumn) return;
                _refreshCalculatedValuesAndTotals(rowIndex: rowIndex);
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
                filled: isFormulaColumn,
                fillColor: isFormulaColumn ? Colors.grey.shade100 : null,
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
    totalsNotifier.dispose();
    super.dispose();
  }
}
