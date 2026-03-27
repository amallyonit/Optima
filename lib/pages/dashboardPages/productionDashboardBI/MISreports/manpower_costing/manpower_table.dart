import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String getMonthName(int month) {
  final formatter = DateFormat('MMMM');
  return formatter.format(DateTime(2000, month));
}

class ProductionDataTable extends StatelessWidget {
  final List<String> particulars;
  final List<List<String>> data;

  const ProductionDataTable({
    super.key,
    required this.particulars,
    required this.data,
  });

  List<String> get _headers => [
    'Particulars',
    'Total',
    'Increase/Decrease with Target',
    '${getMonthName(DateTime.now().month)} ${DateTime.now().year}\nTotal',
    '${getMonthName(DateTime.now().month)} ${DateTime.now().year}\n% w.r.t Current Month',
    'Last 3 months\nTotal',
    'Last 3 months\n% w.r.t Current Month',
    'Last 12 Months\nTotal',
    'Last 12 Months\n% w.r.t Current Month',
  ];

  Widget _cell(
    String text, {
    bool bold = false,
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int valueCols = _headers.length - 1;
    final monthYear = DateFormat('MMMM yyyy').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          color: Colors.yellow[700],
          child: Text(
            'Working for the Month of $monthYear',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width,
            ),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: {
                0: const FixedColumnWidth(260),
                for (int i = 1; i < _headers.length; i++)
                  i: const FixedColumnWidth(140),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: _headers.map((h) => _cell(h, bold: true)).toList(),
                ),
                for (int r = 0; r < particulars.length; r++)
                  TableRow(
                    children: [
                      _cell(particulars[r]),
                      for (int c = 0; c < valueCols; c++)
                        _cell(
                          (r < data.length && c < data[r].length)
                              ? data[r][c]
                              : '',
                          align: TextAlign.right,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
