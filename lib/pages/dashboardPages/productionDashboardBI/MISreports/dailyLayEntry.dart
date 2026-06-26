// ignore_for_file: file_names, use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:optima/api_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../notificationService.dart';
import '../../../../widgets/permanent_horizontal_scrollbar.dart';
import '../../ReportService.dart';

class DailyLayEntryPage extends StatefulWidget {
  @override
  _DailyLayEntryState createState() => _DailyLayEntryState();
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
    final text = newValue.text.replaceAll(',', '');

    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
      return oldValue;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _DailyLayEntryState extends State<DailyLayEntryPage> {
  final List<String> headers = [
    'Action',
    'Date',
    'Lay Report-Dom No. of worker',
    'Lay Report-Dom in mtrs.',
    'Lay Report-Dom in Kgs.',
    'Lay Report-Dom Achievement per man power in meters',
    'Lay Report-Clean Room No. of worker',
    'Lay Report-Clean Room in mtrs.',
    'Lay Report-Clean Room in Kgs.',
    'Lay Report-Clean Room Achievement per man power in meters',
    'Gown - Stitching No. of Tailor',
    'Gown - Stitching Nos.',
    'Gown - Stitching Achievement per man power in Nos.',
    'Gown - Folding No. of Folder',
    'Gown - Folding Nos.',
    'Gown - Folding Achievement per man power in Nos.',
  ];

  static const int _dataColumnCount = 14;
  static const Set<int> _formulaColumns = {3, 7, 10, 13};
  static const int _frozenColumnCount = 2;
  static const double _headerHeight = 82;
  static const double _rowHeight = 55;
  static const double _actionColumnWidth = 90;
  static const double _dateColumnWidth = 120;

  final List<String> dates = [];
  final Set<String> existingDbDates = {};
  final List<int> rowIds = [];
  final List<int> deletedRowIds = [];

  List<List<TextEditingController>> controllers = [];
  List<List<FocusNode>> focusNodes = [];
  List<List<double>> cellValues = [];
  late List<double> totals = [];
  late ValueNotifier<List<double>> totalsNotifier;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _bodyHorizontalController = ScrollController();

  DateTime? _from;
  DateTime? _to;
  bool isLoading = false;
  bool isSaving = false;
  bool _isSyncing = false;
  String userID = '';
  String? _selectedPlant = 'Bangalore IPD Plant';
  int? highlightedRowIndex;
  int? _pendingActionRowIndex;
  bool? _pendingActionIsAdd;

  final reportService = ReportService();

  double get _frozenTableWidth => _actionColumnWidth + _dateColumnWidth;

  @override
  void initState() {
    super.initState();
    totalsNotifier = ValueNotifier([]);
    _bodyHorizontalController.addListener(_syncHeaderToBodyScroll);
    _headerHorizontalController.addListener(_syncBodyToHeaderScroll);
    _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _to = DateTime.now();
    _generateDateArray();
  }

  void _syncHeaderToBodyScroll() =>
      _syncHorizontalScroll(_bodyHorizontalController);

  void _syncBodyToHeaderScroll() =>
      _syncHorizontalScroll(_headerHorizontalController);

  void _syncHorizontalScroll(ScrollController source) {
    if (_isSyncing || !source.hasClients) return;
    _isSyncing = true;

    final target = source == _bodyHorizontalController
        ? _headerHorizontalController
        : _bodyHorizontalController;

    if (target.hasClients && target.offset != source.offset) {
      target.jumpTo(source.offset.clamp(0.0, target.position.maxScrollExtent));
    }

    _isSyncing = false;
  }

  bool isFormulaColumn(int colIndex) => _formulaColumns.contains(colIndex);

  String formatDate(String isoDate) {
    final dt = DateTime.parse(isoDate);
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d-$m-$y';
  }

  String _format(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd-$mm-$yyyy';
  }

  String convertToIso(String ddMMyyyy) {
    final parts = ddMMyyyy.split('-');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    final dt = DateTime(year, month, day);
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  double _getColumnWidth(int visibleColumnIndex) {
    if (visibleColumnIndex == 0) return _actionColumnWidth;
    if (visibleColumnIndex == 1) return _dateColumnWidth;
    if ({5, 9, 12, 15}.contains(visibleColumnIndex)) return 190;
    return 145;
  }

  Map<int, TableColumnWidth> _buildColumnWidths(int start, int end) {
    return {
      for (int i = start; i < end; i++)
        i - start: FixedColumnWidth(_getColumnWidth(i)),
    };
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _to = picked);
  }

  Future<void> exportDailyLayExcel() async {
    if (dates.isEmpty || controllers.isEmpty) {
      NotificationService.warning(
        title: 'Warning',
        message: 'No data available to export.',
      );
      return;
    }

    _recalculateSheet();

    final caption =
        'Daily Lay and Production Entry - ${_selectedPlant ?? ''} '
        '(${_format(_from!)} to ${_format(_to!)})';

    final rows = List<List<dynamic>>.generate(
      dates.length,
      (i) => [dates[i], ...controllers[i].map((e) => e.text)],
    );

    reportService.generateExcel(
      sheetName: 'Daily Lay',
      headers: headers.sublist(1),
      rows: rows,
      fileName: 'Daily_Lay_Entry.xlsx',
      amountColumns: List.generate(headers.length - 2, (i) => i + 1),
      addTotalRow: true,
      reportTitle: caption,
    );
  }

  Future<void> _saveDailyLayDetails() async {
    if (_from == null || _to == null) {
      NotificationService.warning(
        title: 'Warning',
        message: 'Please select date first',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    _recalculateSheet();

    final dailyLayData = <Map<String, dynamic>>[];

    for (int i = 0; i < dates.length; i++) {
      final values = List<double>.generate(
        _dataColumnCount,
        (index) => _cellNumber(i, index),
      );

      final isRowEmpty = [
        0,
        1,
        2,
        4,
        5,
        6,
        8,
        9,
        11,
        12,
      ].map((index) => values[index]).every((value) => value == 0);
      final existedInDb = existingDbDates.contains(dates[i]);

      if (isRowEmpty && !existedInDb) continue;

      dailyLayData.add({
        'DailyLayEntryId': rowIds[i],
        'UserId': int.tryParse(userID) ?? 0,
        'DailyLayPlant': _selectedPlant,
        'DailyLayDate': convertToIso(dates[i]),
        'LayReportDomNoOfWorker': values[0],
        'LayReportDomMeters': values[1],
        'LayReportDomKgs': values[2],
        'LayReportDomAchievementPerManpowerMeters': values[3],
        'LayReportCleanRoomNoOfWorker': values[4],
        'LayReportCleanRoomMeters': values[5],
        'LayReportCleanRoomKgs': values[6],
        'LayReportCleanRoomAchievementPerManpowerMeters': values[7],
        'GownStitchingNoOfTailor': values[8],
        'GownStitchingNos': values[9],
        'GownStitchingAchievementPerManpowerNos': values[10],
        'GownFoldingNoOfFolder': values[11],
        'GownFoldingNos': values[12],
        'GownFoldingAchievementPerManpowerNos': values[13],
      });
    }

    if (dailyLayData.isEmpty && deletedRowIds.isEmpty) {
      NotificationService.warning(
        title: 'Warning',
        message: 'No data find to save.',
      );
      return;
    }

    final payload = {
      'UserID': userID,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'DailyLayData': dailyLayData,
      'DeletedIds': deletedRowIds,
    };

    const apiUrl = '${ApiHelper.baseUrl}insertorupdatedailylayentry';
    final headerss = {HttpHeaders.contentTypeHeader: 'application/json'};

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(payload),
        headers: headerss,
      );

      if (response.statusCode == 200) {
        NotificationService.success(
          title: 'Success',
          message: 'Saved successfully.',
        );
        deletedRowIds.clear();
        _displayData();
      } else {
        NotificationService.error(title: 'Error', message: 'Save failed..');
      }
    } catch (e, s) {
      debugPrint('SAVE DAILY LAY ERROR: $e');
      debugPrintStack(stackTrace: s);
      NotificationService.error(title: 'Error', message: e.toString());
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
                'DailyLayEntryId',
                'DailyLayId',
                'Id',
              ])?.toString() ??
              '0',
        ) ??
        0;
  }

  String _rowDate(Map<String, dynamic> row) {
    final value = _firstValue(row, const ['DailyLayDate', 'LayDate', 'Date']);
    return formatDate(value?.toString() ?? DateTime.now().toIso8601String());
  }

  List<TextEditingController> _controllersFromApiRow(Map<String, dynamic> row) {
    return [
      TextEditingController(
        text: _rowText(row, const ['LayReportDomNoOfWorker', 'DomNoOfWorker']),
      ),
      TextEditingController(
        text: _rowText(row, const ['LayReportDomMeters', 'DomMeters']),
      ),
      TextEditingController(
        text: _rowText(row, const ['LayReportDomKgs', 'DomKgs']),
      ),
      TextEditingController(
        text: _rowText(row, const [
          'LayReportDomAchievementPerManpowerMeters',
          'DomAchievement',
        ]),
      ),
      TextEditingController(
        text: _rowText(row, const [
          'LayReportCleanRoomNoOfWorker',
          'CleanRoomNoOfWorker',
        ]),
      ),
      TextEditingController(
        text: _rowText(row, const [
          'LayReportCleanRoomMeters',
          'CleanRoomMeters',
        ]),
      ),
      TextEditingController(
        text: _rowText(row, const ['LayReportCleanRoomKgs', 'CleanRoomKgs']),
      ),
      TextEditingController(
        text: _rowText(row, const [
          'LayReportCleanRoomAchievementPerManpowerMeters',
          'CleanRoomAchievement',
        ]),
      ),
      TextEditingController(
        text: _rowText(row, const ['GownStitchingNoOfTailor']),
      ),
      TextEditingController(text: _rowText(row, const ['GownStitchingNos'])),
      TextEditingController(
        text: _rowText(row, const [
          'GownStitchingAchievementPerManpowerNos',
          'GownStitchingAchievement',
        ]),
      ),
      TextEditingController(
        text: _rowText(row, const ['GownFoldingNoOfFolder']),
      ),
      TextEditingController(text: _rowText(row, const ['GownFoldingNos'])),
      TextEditingController(
        text: _rowText(row, const [
          'GownFoldingAchievementPerManpowerNos',
          'GownFoldingAchievement',
        ]),
      ),
    ];
  }

  Future<void> fetchDailyLayDetails(String plant) async {
    if (_from == null || _to == null) {
      NotificationService.warning(
        title: 'Warning',
        message: 'Please select a month first.',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    final payload = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'DailyLayPlant': plant,
      'FromDate': _from?.toIso8601String(),
      'ToDate': _to?.toIso8601String(),
    };

    const apiUrl = '${ApiHelper.baseUrl}selectdailylayentry';
    final headerss = {HttpHeaders.contentTypeHeader: 'application/json'};

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(payload),
        headers: headerss,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;

        if (decoded['Status'] == true && decoded['Data'] != null) {
          final result = decoded['Data'] as List<dynamic>;
          final apiDataByDate = <String, List<Map<String, dynamic>>>{};
          existingDbDates.clear();

          for (final row in result) {
            final typedRow = Map<String, dynamic>.from(row as Map);
            final formatted = _rowDate(typedRow);
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
          if (mounted) setState(() {});
        } else {
          emptyTableCreation();
        }
      } else {
        emptyTableCreation();
        NotificationService.info(
          title: 'Info',
          message: 'Error occured while selecting the daily lay details',
        );
      }
    } catch (e) {
      emptyTableCreation();
      NotificationService.error(
        title: 'Error',
        message: 'Error occured while selecting the daily lay details',
      );
    }
  }

  void emptyTableCreation() {
    existingDbDates.clear();
    _disposeRows();
    controllers.clear();
    rowIds.clear();

    for (int i = 0; i < dates.length; i++) {
      rowIds.add(0);
      controllers.add(_createEmptyRowControllers());
    }

    _buildFocusNodes();
    _recalculateSheet();
    if (mounted) setState(() {});
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
      final rowFocusNodes = <FocusNode>[];

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
    await fetchDailyLayDetails(_selectedPlant!);
    setState(() => isLoading = false);
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

    final safeStart = startRow.clamp(0, controllers.length - 1).toInt();

    for (int row = safeStart; row < controllers.length; row++) {
      final domWorker = _cellNumber(row, 0);
      final domMeters = _cellNumber(row, 1);
      final cleanWorker = _cellNumber(row, 4);
      final cleanMeters = _cellNumber(row, 5);
      final tailor = _cellNumber(row, 8);
      final stitchingNos = _cellNumber(row, 9);
      final folder = _cellNumber(row, 11);
      final foldingNos = _cellNumber(row, 12);

      _setCalculatedCell(row, 3, domWorker == 0 ? 0 : domMeters / domWorker);
      _setCalculatedCell(
        row,
        7,
        cleanWorker == 0 ? 0 : cleanMeters / cleanWorker,
      );
      _setCalculatedCell(row, 10, tailor == 0 ? 0 : stitchingNos / tailor);
      _setCalculatedCell(row, 13, folder == 0 ? 0 : foldingNos / folder);
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

    final numericColumnCount = controllers[0].length;
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
      rowIds
        ..clear()
        ..addAll(List.filled(dates.length, 0));
      deletedRowIds.clear();
      _buildFocusNodes();
      _recalculateSheet();
    });
  }

  void _generateDateArray() async {
    if (_from == null || _to == null) return;
    setState(() => isLoading = true);
    _disposeRows();
    dates.clear();
    controllers.clear();
    focusNodes.clear();
    rowIds.clear();
    existingDbDates.clear();

    DateTime current = _from!;
    while (current.isBefore(_to!) || current.isAtSameMomentAs(_to!)) {
      dates.add(_format(current));
      current = current.add(const Duration(days: 1));
    }

    await loadData();
    setState(() => isLoading = false);
  }

  void _displayData() async {
    if (_from == null || _to == null) return;

    _disposeRows();
    dates.clear();
    controllers.clear();
    focusNodes.clear();
    rowIds.clear();
    existingDbDates.clear();

    DateTime current = _from!;
    while (current.isBefore(_to!) || current.isAtSameMomentAs(_to!)) {
      dates.add(_format(current));
      current = current.add(const Duration(days: 1));
    }

    totals = List.filled(_dataColumnCount, 0.0);
    await fetchDailyLayDetails(_selectedPlant!);
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
      setState(() => highlightedRowIndex = null);
    });
  }

  void _deleteRow(int rowIndex) {
    if (dates.length <= 1) return;

    final rowId = rowIds[rowIndex];
    final deletedValues = List<double>.from(cellValues[rowIndex]);

    if (rowId > 0) deletedRowIds.add(rowId);

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
          'DAILY LAY AND PRODUCTION ENTRY',
          style: TextStyle(
            color: Colors.blue,
            fontFamily: 'Poppins',
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
            if (!(keyboardVisible && isLandscape))
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _buildDatePickers(),
                ),
              ),
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

    _selectedPlant ??= 'Bangalore IPD Plant';

    final dropdownPlant = SizedBox(
      width: 194,
      height: 40,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
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
            child: Text(
              'Rajapalayam IPD Plant',
              overflow: TextOverflow.ellipsis,
            ),
          ),

          DropdownMenuItem(
            value: 'Bangalore IPD Plant',
            child: Text('Bangalore IPD Plant', overflow: TextOverflow.ellipsis),
          ),
        ],
        selectedItemBuilder: (context) => const [
          Text('Rajapalayam IPD Plant', overflow: TextOverflow.ellipsis),
          Text('Bangalore IPD Plant', overflow: TextOverflow.ellipsis),
        ],
        onChanged: (value) {
          setState(() => _selectedPlant = value!);
          if (_from != null && _to != null) _generateDateArray();
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

    if (isLandscape) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            dropdownPlant,
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
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [dropdownPlant],
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
        maxLines: 4,
        overflow: TextOverflow.visible,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                'Total',
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
            return Container(
              alignment: Alignment.centerRight,
              height: _rowHeight,
              padding: const EdgeInsets.all(8),
              child: ValueListenableBuilder<List<double>>(
                valueListenable: totalsNotifier,
                builder: (context, totals, child) {
                  final text = index < totals.length
                      ? _formatNumber(totals[index])
                      : '0';
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [DecimalInputFormatter()],
              textInputAction: TextInputAction.next,
              textAlign: TextAlign.right,
              onChanged: (_) => updateColumnTotal(rowIndex, colIndex),
              onSubmitted: (_) => _moveFocus(rowIndex, colIndex, rowOffset: 1),
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
          icon: isBusy
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              : Icon(icon, size: 20, color: effectiveColor),
          onPressed: isEnabled ? onTap : null,
          tooltip: tooltip,
        ),
      ),
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
                          await _saveDailyLayDetails();
                          setState(() => isSaving = false);
                        },
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2ca9df),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  onPressed: exportDailyLayExcel,
                  child: Text(
                    'Download Excel',
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

  @override
  void dispose() {
    _disposeRows();
    _verticalController.dispose();
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();
    totalsNotifier.dispose();
    super.dispose();
  }
}
