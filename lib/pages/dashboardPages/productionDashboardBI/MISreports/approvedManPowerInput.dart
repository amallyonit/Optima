// ignore_for_file: file_names, use_build_context_synchronously
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:optima/api_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../notificationService.dart';
import '../../ReportService.dart';

class AttendanceRow {
  final String plant;
  final DateTime date;
  final bool isSunday;
  final TextEditingController targetController;
  final TextEditingController onrollController;
  final TextEditingController presentController;

  AttendanceRow({
    required this.plant,
    required this.date,
    required this.isSunday,
    String? initialTarget,
  }) : targetController = TextEditingController(text: initialTarget ?? ''),
       onrollController = TextEditingController(),
       presentController = TextEditingController();

  String get formattedDate {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d-$m-$y';
  }

  /// compute absent percent string, or empty if not applicable
  String computeAbsentPercent() {
    if (isSunday) return 'Sunday';
    final onroll = double.tryParse(onrollController.text) ?? 0.0;
    final present = double.tryParse(presentController.text) ?? 0.0;
    if (onroll <= 0) return '';
    final absentPercent = ((onroll - present) / onroll) * 100.0;
    return '${absentPercent.toStringAsFixed(2)}%';
  }

  void dispose() {
    targetController.dispose();
    onrollController.dispose();
    presentController.dispose();
  }
}

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  static const double _tableColumnWidth = 100;
  static const double _tableFieldHeight = 38;
  static const double _tableRowHeight = _tableFieldHeight;
  static const double _tableVerticalGap = 4;

  DateTime? _from;
  DateTime? _to;
  final List<AttendanceRow> _rows = [];
  final int _warnRowThreshold = 400;
  bool isSaving = false;
  bool isLoading = false;

  // Scroll controllers
  final ScrollController _verticalController = ScrollController();
  final ScrollController _headerHorizontal = ScrollController();
  final ScrollController _bodyHorizontal = ScrollController();

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

  Future<void> _saveAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    const apiUrl = '${ApiHelper.baseUrl}insertorupdateattendance';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};

    List<Map<String, dynamic>> attendanceData = _rows
        .where((r) => !r.isSunday)
        .map(
          (r) => {
            'AttendancePlant': r.plant,
            'AttendanceDate': r.date.toIso8601String(),
            'AttendanceTarget': double.tryParse(r.targetController.text) ?? 0,
            'AttendanceOnroll': double.tryParse(r.onrollController.text) ?? 0,
            'AttendancePresent': double.tryParse(r.presentController.text) ?? 0,
            'AttendanceAbsentPercent':
                double.tryParse(r.computeAbsentPercent().replaceAll('%', '')) ??
                0,
          },
        )
        .toList();

    final payload = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      "attendanceData": attendanceData,
    };
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

  Future<void> selectAttendance(
    String fromDt,
    String toDate,
    String plant,
  ) async {
    if (_selectedPlant!.isEmpty) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "Please select one plant and continue.",
      );
      return;
    }
    if (fromDt.isEmpty || toDate.isEmpty) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "Please select from & to date and continue.",
      );
      return;
    }
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    final payload = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      "AttendancePlant": _selectedPlant,
      "FromDate": fromDt,
      "ToDate": toDate,
    };

    const apiUrl = '${ApiHelper.baseUrl}selectmonthlyattendance';
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

          if (result.isEmpty) {
            setState(() {
              for (var row in _rows) {
                row.targetController.clear();
                row.onrollController.clear();
                row.presentController.clear();
              }
            });

            if (!mounted) return;
            NotificationService.info(
              title: "Info",
              message: "No data found for the selected range.",
            );

            setState(() => isLoading = false);
            return;
          }

          setState(() {
            for (var row in _rows) {
              row.targetController.clear();
              row.onrollController.clear();
              row.presentController.clear();
            }

            for (var item in result) {
              final dateString = item['AttendanceDate'];
              final apiDate = DateTime.tryParse(dateString);
              if (apiDate == null) continue;

              final index = _rows.indexWhere(
                (r) =>
                    r.date.year == apiDate.year &&
                    r.date.month == apiDate.month &&
                    r.date.day == apiDate.day,
              );
              if (index != -1) {
                final row = _rows[index];
                row.targetController.text =
                    item['AttendanceTarget']?.toString() ?? '';
                row.onrollController.text =
                    item['AttendanceOnroll']?.toString() ?? '';
                row.presentController.text =
                    item['AttendancePresent']?.toString() ?? '';
              }
            }
          });
          setState(() => isLoading = false);
        } else {
          setState(() {
            for (var row in _rows) {
              row.targetController.clear();
              row.onrollController.clear();
              row.presentController.clear();
            }
          });

          if (!mounted) return;
          NotificationService.info(
            title: "Info",
            message: "No data found for the selected range.",
          );
        }
      } else {
        if (!mounted) return;
        NotificationService.error(
          title: "Error",
          message: "Error occured while fetching attendance data.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while fetching attendance data.",
      );
    }
    setState(() => isLoading = false);
  }

  void _generateTable({String? defaultTarget}) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    if (_from == null || _to == null) {
      if (!mounted) return;
      setState(() => isLoading = false);

      NotificationService.info(
        title: "Info",
        message: "Please select both From and To dates.",
      );
      return;
    }
    if (_from!.isAfter(_to!)) {
      if (!mounted) return;
      setState(() => isLoading = false);

      NotificationService.info(
        title: "Info",
        message: "From date must be before or equal to To date.",
      );
      return;
    }

    final days = _to!.difference(_from!).inDays + 1;
    if (days > _warnRowThreshold) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Large row count'),
          content: Text(
            'You are generating $days rows. Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await _createRows(defaultTarget: defaultTarget);
      }
    } else {
      await _createRows(defaultTarget: defaultTarget);
    }
    setState(() => isLoading = false);
  }

  Future<void> _createRows({String? defaultTarget}) async {
    for (final r in _rows) {
      r.dispose();
    }
    _rows.clear();

    DateTime cur = DateTime(_from!.year, _from!.month, _from!.day);
    final end = DateTime(_to!.year, _to!.month, _to!.day);
    while (!cur.isAfter(end)) {
      final isSunday = false;
      final row = AttendanceRow(
        plant: _selectedPlant!,
        date: cur,
        isSunday: isSunday,
        initialTarget: defaultTarget,
      );
      if (!isSunday) {
        row.onrollController.addListener(() => setState(() {}));
        row.presentController.addListener(() => setState(() {}));
      }
      _rows.add(row);
      cur = cur.add(const Duration(days: 1));
    }
    await selectAttendance(
      _from!.toIso8601String(),
      _to!.toIso8601String(),
      _selectedPlant!,
    );
  }

  void _clear() {
    for (final r in _rows) {
      r.dispose();
    }
    _rows.clear();
    setState(() {});
  }

  Future<void> _downloadExcel() async {
    if (_rows.isEmpty) {
      if (!mounted) return;
      NotificationService.info(
        title: "Info",
        message: "No data available to export.",
      );
      return;
    }

    final reportService = ReportService();

    await reportService.generateExcel(
      sheetName: 'Attendance',
      headers: ['Date', 'Target', 'Onroll', 'Present', 'Absent %'],
      rows: _rows
          .map(
            (r) => [
              r.formattedDate,
              r.targetController.text,
              r.onrollController.text,
              r.presentController.text,
              r.computeAbsentPercent(),
            ],
          )
          .toList(),
      fileName: 'attendance_report.xlsx',
      amountColumns: [],
      addTotalRow: false,
      reportTitle:
          'Production[MIS] - Attendance of "${_selectedPlant ?? ''} (${_format(_from!)} to ${_format(_to!)})"',
    );
  }

  @override
  void initState() {
    super.initState();

    _bodyHorizontal.addListener(() {
      if (_headerHorizontal.hasClients &&
          _headerHorizontal.offset != _bodyHorizontal.offset) {
        _headerHorizontal.jumpTo(_bodyHorizontal.offset);
      }
    });

    _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _to = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectAttendance(
        _from!.toIso8601String(),
        _to!.toIso8601String(),
        _selectedPlant!,
      );
    });
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _verticalController.dispose();
    _headerHorizontal.dispose();
    _bodyHorizontal.dispose();
    super.dispose();
  }

  String _format(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd-$mm-$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    final hasRows = _rows.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Attendance Input')),
      body: SafeArea(
        child: Column(
          children: [
            // Filter area (kept outside expanded so it doesn't shrink)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [const SizedBox(height: 10), _buildDatePickers()],
                  ),
                ),
              ),
            ),

            // Main content - Expanded to take remaining space and allow keyboard to resize it
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
      bottomNavigationBar: hasRows
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                                  await _saveAttendance();
                                  setState(() => isSaving = false);
                                },
                          child: isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
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

                      /// DOWNLOAD BUTTON
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
            )
          : null,
    );
  }

  Widget _buildStickyTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        return Column(
          children: [
            /// STICKY HEADER
            SingleChildScrollView(
              controller: _headerHorizontal,
              physics: const NeverScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: _buildHeaderRow(),
            ),
            const SizedBox(height: _tableVerticalGap),

            /// BODY (this must be height-bounded)
            SizedBox(
              height:
                  availableHeight -
                  _tableRowHeight -
                  _tableVerticalGap, // header + spacing
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: SingleChildScrollView(
                    controller: _bodyHorizontal,
                    scrollDirection: Axis.horizontal,
                    child: _buildRowsList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderRow() {
    TextStyle th = const TextStyle(fontWeight: FontWeight.bold);
    return Row(
      children: [
        _headerCell('Date', th),
        _headerCell('Target', th),
        _headerCell('Onroll', th),
        _headerCell('Present', th),
        _headerCell('Absent', th),
      ],
    );
  }

  Widget _headerCell(String title, TextStyle style) {
    return Container(
      width: _tableColumnWidth,
      height: _tableRowHeight,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      alignment: Alignment.center,
      color: Colors.blueGrey.shade50,
      child: Text(title, style: style),
    );
  }

  Widget _dataCell(Widget child, {bool isDate = false}) {
    if (isDate) {
      return SizedBox(
        width: _tableColumnWidth,
        height: _tableFieldHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            height: _tableFieldHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      );
    }

    return SizedBox(
      width: _tableColumnWidth,
      height: _tableRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildRowsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: _rows.map((r) {
            final isSun = r.isSunday;
            final bg = isSun ? Colors.orange.shade50 : null;
            final textStyle = isSun
                ? TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w700,
                  )
                : null;

            return Container(
              color: bg,
              margin: const EdgeInsets.only(bottom: _tableVerticalGap),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _dataCell(
                    Text(
                      r.formattedDate,
                      style: textStyle,
                      textAlign: TextAlign.center,
                    ),
                    isDate: true,
                  ),

                  _dataCell(
                    isSun
                        ? Text('Sunday', style: textStyle)
                        : _buildTextField(r.targetController),
                  ),

                  _dataCell(
                    isSun
                        ? Text('Sunday', style: textStyle)
                        : _buildTextField(r.onrollController),
                  ),

                  _dataCell(
                    isSun
                        ? Text('Sunday', style: textStyle)
                        : _buildTextField(r.presentController),
                  ),

                  _dataCell(
                    isSun
                        ? Container(
                            alignment: Alignment.center,
                            height: _tableFieldHeight,
                            child: Text('Sunday', style: textStyle),
                          )
                        : SizedBox(
                            height: _tableFieldHeight,
                            width: double.infinity,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                r.computeAbsentPercent(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return SizedBox(
      height: _tableFieldHeight,
      width: double.infinity,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        scrollPadding: const EdgeInsets.only(bottom: 200),
        keyboardAppearance: Brightness.light,
        textAlignVertical: TextAlignVertical.center,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          border: OutlineInputBorder(),
          isDense: true,
          hintText: '0',
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
          if (value == null) return;
          setState(() {
            _selectedPlant = value;
            if (_from != null && _to != null) {
              _generateTable();
              selectAttendance(
                _from!.toIso8601String(),
                _to!.toIso8601String(),
                value,
              );
            }
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
        onPressed: _generateTable,
        style: buttonStyle,
        child: const Text('Generate Table'),
      ),
      ElevatedButton(
        style: buttonStyle.copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.grey[700]),
        ),
        onPressed: _clear,
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
}
