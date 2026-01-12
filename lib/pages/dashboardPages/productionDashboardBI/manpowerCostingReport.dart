// ignore_for_file: unused_local_variable, file_names, avoid_web_libraries_in_flutter
import 'package:optima/excel_helper.dart';
import 'dart:convert';
import 'dart:typed_data';
// import 'dart:html' as html;
import 'package:universal_html/html.dart' as html;
import 'package:excel/excel.dart' hide Border, BorderStyle, TextSpan;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pluto_grid/pluto_grid.dart';

class ManpowerApiTable extends StatefulWidget {
  const ManpowerApiTable({super.key});

  @override
  State<ManpowerApiTable> createState() => _ManpowerApiTableState();
}

class _ManpowerApiTableState extends State<ManpowerApiTable> {
  List<PlutoColumn> columns = [];
  List<PlutoRow> rows = [];
  List<PlutoColumnGroup> columnGroups = [];

  @override
  void initState() {
    super.initState();
    _setupColumns();
    _fetchData();
  }

  void _setupColumns() {
    columns = <PlutoColumn>[
      PlutoColumn(
        title: 'Particulars',
        field: 'particulars',
        type: PlutoColumnType.text(),
        width: 200,
        frozen: PlutoColumnFrozen.start,
      ),
      PlutoColumn(
        title: 'Total',
        field: 'total',
        type: PlutoColumnType.text(),
        textAlign: PlutoColumnTextAlign.right,
        width: 90,
      ),
      PlutoColumn(
        title: 'Increase/Decrease w.r.t Target',
        field: 'incDec',
        type: PlutoColumnType.text(),
        textAlign: PlutoColumnTextAlign.right,
        width: 170,
      ),
      PlutoColumn(
        title: 'Total',
        field: 'dec_total',
        type: PlutoColumnType.text(),
        textAlign: PlutoColumnTextAlign.right,
        width: 90,
      ),
      PlutoColumn(
        title: '% w.r.t Current Month',
        field: 'dec_pct',
        type: PlutoColumnType.text(),
        textAlign: PlutoColumnTextAlign.right,
        width: 150,
      ),
      PlutoColumn(
        title: 'Total',
        field: 'last5_total',
        type: PlutoColumnType.text(),
        textAlign: PlutoColumnTextAlign.right,
        width: 90,
      ),
      PlutoColumn(
        title: '% w.r.t Current Month',
        field: 'last5_pct',
        type: PlutoColumnType.text(),
        textAlign: PlutoColumnTextAlign.right,
        width: 150,
      ),
      PlutoColumn(
        title: 'Total',
        field: 'last12_total',
        type: PlutoColumnType.text(),
        textAlign: PlutoColumnTextAlign.right,
        width: 90,
      ),
      PlutoColumn(
        title: '% w.r.t Current Month',
        field: 'last12_pct',
        type: PlutoColumnType.text(),
        textAlign: PlutoColumnTextAlign.right,
        width: 150,
      ),
    ];

    columnGroups = <PlutoColumnGroup>[
      PlutoColumnGroup(title: 'Particulars', fields: ['particulars']),
      PlutoColumnGroup(
        title: 'Working for the Month of January 2025',
        children: [
          PlutoColumnGroup(title: 'Total', fields: ['total']),
          PlutoColumnGroup(
            title: 'Increase/Decrease with Target',
            fields: ['incDec'],
          ),
          PlutoColumnGroup(
            title: 'Dec-24',
            children: [
              PlutoColumnGroup(title: 'Total', fields: ['dec_total']),
              PlutoColumnGroup(
                title: '% w.r.t. Current Month',
                fields: ['dec_pct'],
              ),
            ],
          ),
          PlutoColumnGroup(
            title: 'Last 5 months',
            children: [
              PlutoColumnGroup(title: 'Total', fields: ['last5_total']),
              PlutoColumnGroup(
                title: '% w.r.t. Current Month',
                fields: ['last5_pct'],
              ),
            ],
          ),
          PlutoColumnGroup(
            title: 'Last 12 months',
            children: [
              PlutoColumnGroup(title: 'Total', fields: ['last12_total']),
              PlutoColumnGroup(
                title: '% w.r.t. Current Month',
                fields: ['last12_pct'],
              ),
            ],
          ),
        ],
      ),
    ];
  }

  Future<void> _fetchData() async {
    // Replace with your API endpoint
    final url = Uri.parse("https://yourapi.com/manpower");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);

      setState(() {
        rows = jsonData.map((item) {
          return PlutoRow(
            cells: {
              'particulars': PlutoCell(value: item['particulars']),
              'total': PlutoCell(value: item['total']),
              'incDec': PlutoCell(value: item['incDec']),
              'dec_total': PlutoCell(value: item['dec_total']),
              'dec_pct': PlutoCell(value: item['dec_pct']),
              'last5_total': PlutoCell(value: item['last5_total']),
              'last5_pct': PlutoCell(value: item['last5_pct']),
              'last12_total': PlutoCell(value: item['last12_total']),
              'last12_pct': PlutoCell(value: item['last12_pct']),
            },
          );
        }).toList();
      });
    } else {
      debugPrint("Failed to load data: ${response.statusCode}");
    }
  }

  void _exportToExcel() {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // Header row
    sheetObject.appendRow(
      toCellRow([
        'Particulars',
        'Total',
        'Inc/Dec',
        'Dec Total',
        'Dec %',
        'Last5 Total',
        'Last5 %',
        'Last12 Total',
        'Last12 %',
      ]),
    );

    // Data rows
    for (var row in rows) {
      sheetObject.appendRow(
        toCellRow([
          row.cells['particulars']?.value,
          row.cells['total']?.value,
          row.cells['incDec']?.value,
          row.cells['dec_total']?.value,
          row.cells['dec_pct']?.value,
          row.cells['last5_total']?.value,
          row.cells['last5_pct']?.value,
          row.cells['last12_total']?.value,
          row.cells['last12_pct']?.value,
        ]),
      );
    }

    var fileBytes = excel.encode()!;
    final blob = html.Blob([Uint8List.fromList(fileBytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "manpower.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Working for the Month of January 2025"),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_present),
            tooltip: "Export to Excel",
            onPressed: _exportToExcel,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export to PDF",
            onPressed: _exportToExcel,
          ),
        ],
      ),
      body: rows.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PlutoGrid(
              columns: columns,
              rows: rows,
              columnGroups: columnGroups,
              configuration: const PlutoGridConfiguration(
                style: PlutoGridStyleConfig(
                  columnHeight: 44,
                  rowHeight: 40,
                  gridBorderColor: Colors.black54,
                ),
              ),
            ),
    );
  }
}
