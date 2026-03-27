// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optima/classes/dashBoard.dart';
import 'manpower_charts.dart';
import 'manpower_controller.dart';
import 'manpower_table.dart';
import 'production_summary_cards.dart';
import 'manpower_excel.dart';

class ManpowerDashboardPage extends StatefulWidget {
  const ManpowerDashboardPage({super.key});

  @override
  State<ManpowerDashboardPage> createState() => _ManpowerDashboardPageState();
}

List<String> particulars = [
  'Produced Qty',
  'No.of Boxes Produced',
  'Total Present Workforce',
  'Total Present Labour',
  'Avg no of workforce/ Box /month',
  'Avg no of Labour/ Box /month',
  'Avg Monthly CTC of Total Workforce',
  'Avg Monthly CTC of Total Labour',
  'Avg. Boxes/Day',
  'No. of Working Days',
  'Avg Workforce',
  'Avg Labour',
  'Total Manpower Cost/box /day',
  'Total Labour Cost/box /day',
];
String selectedMonthlySubGroup = "All";
String selectedDailySubGroup = "All";

class ItemSubGroupDropdown extends StatefulWidget {
  final List production; // List<ProductionOrderList> or List<Map>
  final ValueChanged<String?> onChanged;
  final String placeholder; // shown when no items available

  const ItemSubGroupDropdown({
    super.key,
    required this.production,
    required this.onChanged,
    this.placeholder = 'Kits/Gowns',
  });

  @override
  State<ItemSubGroupDropdown> createState() => _ItemSubGroupDropdownState();
}

class _ItemSubGroupDropdownState extends State<ItemSubGroupDropdown> {
  late final List<String> _items;
  String? _selected;

  // These are the subgroups that should be shown as "Kits/Gowns"
  static const _grouped = {'packs', 'gowns', 'safety packs', 'drapes'};

  @override
  void initState() {
    super.initState();
    _items = _extractItemSubGroups(widget.production);
    _selected = _items.isNotEmpty ? _items.first : null;
  }

  String _displayNameFor(String raw) {
    final low = raw.trim().toLowerCase();
    if (_grouped.contains(low)) return 'Kits/Gowns';
    return raw.trim();
  }

  List<String> _extractItemSubGroups(List list) {
    final seen = <String>{};
    final out = <String>[];
    out.add("All");
    for (var e in list) {
      String val = '';
      try {
        val = (e.itemSubGroup ?? '').toString().trim();
      } catch (_) {
        if (e is Map && e.containsKey('itemSubGroup')) {
          val = (e['itemSubGroup'] ?? '').toString().trim();
        }
      }
      if (val.isEmpty) continue;

      final display = _displayNameFor(val);
      // Use display value for uniqueness so grouped items collapse into one entry.
      if (!seen.contains(display)) {
        seen.add(display);
        out.add(display);
      }
    }

    // If nothing found, optionally return the placeholder as a single disabled item
    if (out.isEmpty) {
      out.add(widget.placeholder);
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selected,
              hint: const SizedBox.shrink(),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: _items.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selected = val;
                });
                widget.onChanged(val);
              },
              isDense: true,
              isExpanded: false,
            ),
          ),
        ],
      ),
      onTap: () {},
    );
  }
}

class BranchPicker extends StatefulWidget {
  final List<ProductionOrderList> production;
  final ValueChanged<String?>? onChanged;
  final VoidCallback? onClear; // called when the cross is pressed
  final VoidCallback? onSearchPressed; // optional override for search button
  final String title;

  const BranchPicker({
    super.key,
    required this.production,
    this.onChanged,
    this.onClear,
    this.onSearchPressed,
    this.title = 'Manpower Costing Report',
  });

  @override
  State<BranchPicker> createState() => _BranchPickerState();
}

class _BranchPickerState extends State<BranchPicker> {
  late final List<String> _branches;
  String? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _branches = _extractBranches(widget.production);
    _selectedBranch = null; // show "Select Branch" hint initially
  }

  List<String> _extractBranches(List<ProductionOrderList> list) {
    final s = list
        .map((p) => (p.branch).toString())
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList();
    s.sort((a, b) => a.compareTo(b));
    return s;
  }

  // Default search behavior: open a simple dialog to pick branch
  Future<void> _defaultOpenSearchDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String filter = '';
        return StatefulBuilder(
          builder: (c, setStateDialog) {
            final filtered = _branches
                .where((b) => b.toLowerCase().contains(filter.toLowerCase()))
                .toList();
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 320,
                height: 420,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search branches',
                          isDense: true,
                        ),
                        onChanged: (v) => setStateDialog(() => filter = v),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No branches found'))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final b = filtered[i];
                                return ListTile(
                                  title: Text(b),
                                  onTap: () => Navigator.of(context).pop(b),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _selectedBranch = result);
      widget.onChanged?.call(result);
    }
  }

  void _onSearchPressed() {
    if (widget.onSearchPressed != null) {
      widget.onSearchPressed!();
    } else {
      _defaultOpenSearchDialog();
    }
  }

  void _onClearPressed() {
    setState(() => _selectedBranch = null);
    // call both onChanged (with null) and onClear if provided
    widget.onChanged?.call(null);
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(6.0);
    final borderSide = BorderSide(color: Colors.grey.shade300, width: 1.0);

    // Build the circular icon widget (search or clear) shown inside the field
    Widget _buildCircularAction() {
      final bool hasSelection = _selectedBranch != null;
      final icon = hasSelection ? Icons.close : Icons.search;
      final onPressed = hasSelection ? _onClearPressed : _onSearchPressed;
      final iconColor = hasSelection ? Colors.black54 : Colors.blueAccent;
      final borderColor = hasSelection
          ? Colors.grey.shade300
          : Colors.blueAccent;

      return Container(
        margin: const EdgeInsets.only(right: 8),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          splashRadius: 18,
          icon: Icon(icon, size: 18, color: iconColor),
          onPressed: _branches.isEmpty ? null : onPressed,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Wrap field and circular icon in a row so the icon appears inside-right visually.
        // We use Expanded for the Dropdown so it fills available space.
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBranch,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                decoration: InputDecoration(
                  hintText: null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(borderRadius: borderRadius),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: borderSide,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  // Put a small right padding to avoid overlap with our manual circular icon
                  // (suffixIcon could be used but this approach gives consistent circular look)
                ),
                hint: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Branch',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
                items: _branches
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedBranch = val);
                  widget.onChanged?.call(val);
                },
              ),
            ),

            // small spacing between field and circular icon
            const SizedBox(width: 8),

            // the circular search/clear icon
            _buildCircularAction(),
          ],
        ),
      ],
    );
  }
}

class _ManpowerDashboardPageState extends State<ManpowerDashboardPage> {
  final controller = ManpowerController();

  Widget _buildHeader() {
    final start = DateFormat(
      'dd/MM/yy',
    ).format(controller.fiscalYearStartDate!);
    final end = DateFormat('dd/MM/yy').format(controller.currentDate!);

    return Column(
      children: [
        const SizedBox(height: 10),

        Row(children: [const SizedBox(width: 15), Text("$start - $end")]),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                SizedBox(width: 15),
                Text(
                  "Manpower Costing Report",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text("Download Excel"),
                  onTap: () {
                    ManpowerExcelExporter.exportManpowerExcel(
                      controller.table.particulars,
                      controller.table.rows,
                    );
                  },
                ),
                // const PopupMenuItem(child: Text("Download PDF")),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    controller.loadDashboard().then((_) {
      setState(() {});
    });
  }

  Widget _buildBranchFilter() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: BranchPicker(
        production: controller.production,
        onChanged: (b) {
          if (b != null) {
            setState(() {
              controller.applyBranchFilter(b);
            });
          }
        },
        onClear: () {
          setState(() {
            controller.clearBranchFilter();
          });
        },
      ),
    );
  }

  Widget _buildTargetAchievement() {
    return Column(
      children: [
        const SizedBox(height: 10),

        const Text("Target vs Achievement"),

        const SizedBox(height: 10),

        TargetAchievementWidget(
          qtyPercent: controller.qtyPercent,
          boxPercent: controller.boxPercent,
          qty: controller.qtyProduced,
          boxes: controller.boxProduced,
        ),

        const SizedBox(height: 10),

        _buildTargetLegend(),
      ],
    );
  }

  Widget _buildTargetLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(height: 8, width: 8, color: const Color(0xFFFF9F47)),
        const SizedBox(width: 5),
        const Text("Target"),

        const SizedBox(width: 5),

        Container(height: 8, width: 8, color: const Color(0xFF97D7F3)),
        const SizedBox(width: 5),
        const Text("Achievement"),

        const SizedBox(width: 15),
      ],
    );
  }

  Widget _buildMonthlyCharts() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MonthlyProductionBarChart(
            controller: controller,
            data: controller.charts.monthlyBar,
            onFilterApplied: () {
              setState(() {});
            },
          ),
        ),

        const Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0),
          child: Divider(thickness: 2),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ItemSubGroupDropdown(
                production: controller.production,
                onChanged: (value) async {
                  if (value == null) return;
                  await controller.filterByItemSubGroup(value);
                  setState(() {
                    selectedMonthlySubGroup = value == "All" ? "" : value;
                  });
                },
              ),
              const SizedBox(width: 5),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ProductionSummaryCards(
                production: controller.totals.currentMonthQty,
                boxes: controller.totals.currentMonthBoxes,
                isAverage: false,
                isDailyAverage: false,
                title: selectedMonthlySubGroup == "All"
                    ? ""
                    : selectedMonthlySubGroup,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MonthlyProductionLineChart(
            data: controller.charts.monthlyLine,
          ),
        ),

        const Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0),
          child: Divider(thickness: 2),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ProductionSummaryCards(
                production: controller.totals.currentMonthQty,
                boxes: controller.totals.currentMonthBoxes,
                isAverage: true,
                isDailyAverage: false,
                title: selectedMonthlySubGroup == "All"
                    ? ""
                    : selectedMonthlySubGroup,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyCharts() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DailyProductionBarChart(
            data: controller.charts.dailyBar,
            avgBoxes: controller.currentMonthAverageBoxes,
          ),
        ),

        const Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0),
          child: Divider(thickness: 2),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ItemSubGroupDropdown(
                production: controller.production,
                onChanged: (value) async {
                  if (value == null) return;
                  await controller.filterByItemSubGroup(value);
                  setState(() {
                    selectedDailySubGroup = value == "All" ? "" : value;
                  });
                },
              ),
              const SizedBox(width: 5),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ProductionSummaryCards(
                production: controller.totals.currentMonthQty,
                boxes: controller.totals.currentMonthBoxes,
                isAverage: false,
                isDailyAverage: true,
                title: selectedDailySubGroup == "All"
                    ? ""
                    : selectedDailySubGroup,
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DailyProductionLineChart(data: controller.charts.dailyLine),
        ),
      ],
    );
  }

  Widget _buildTable() {
    return ProductionDataTable(
      particulars: particulars,
      data: controller.table.rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildBranchFilter(),
          _buildTargetAchievement(),
          _buildMonthlyCharts(),
          _buildDailyCharts(),
          _buildTable(),
        ],
      ),
    );
  }
}
