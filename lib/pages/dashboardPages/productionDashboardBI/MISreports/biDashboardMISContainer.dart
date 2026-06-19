// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:optima/pages/comingsoon.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/carriageInwardReport.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/carriageOutwardReport.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/dailyRawMaterialReport.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/manpower_costing/manpower_dashboard_page.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/monthlyProductionSummary.dart';
import '../../../../notificationService.dart';
import 'sampleDataDetailsPage.dart';
import 'agingReport.dart';
import 'cmsCostingReport.dart';
import 'externalComplaintPage.dart';
import 'minimumStockVsActualStock.dart';
import 'monthlyWorkforceSummary.dart';
import 'overtimeReport.dart';
import 'purchasePrice.dart';
import 'salesVsDelivery.dart';
import 'salesVsProduction.dart';
import 'scrapReport.dart';
import 'stockStatement.dart';
import 'summaryOfRawMaterials.dart';
import 'topProducts.dart';

class ReportItem {
  final String title;
  final Widget Function() pageBuilder;
  final bool isUnderDevelopment;
  ReportItem({
    required this.title,
    required this.pageBuilder,
    this.isUnderDevelopment = false,
  });
}

final GlobalKey<_ProductionReportsMISState> productionReportsMISKey =
    GlobalKey<_ProductionReportsMISState>();

class ProductionReportsMIS extends StatefulWidget {
  const ProductionReportsMIS({super.key});

  @override
  State<ProductionReportsMIS> createState() => _ProductionReportsMISState();
}

class _ProductionReportsMISState extends State<ProductionReportsMIS> {
  final GlobalKey<NavigatorState> _nestedNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchText = "";

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Map<String, List<ReportItem>> get _groupedReports {
    return {
      "Costing Reports": [
        _items[0], // Manpower
        _items[1], // Overtime
        _items[10], // Purchase Price
        _items[12], // CMS Costing
      ],

      "Inventory Reports": [
        _items[2],
        _items[3],
        _items[4],
        _items[5],
        _items[19],
      ],

      "Sales Reports": [_items[6], _items[7], _items[11]],

      "Production Reports": [
        _items[8],
        _items[9],
        _items[13],
        _items[14],
        _items[18],
        _items[17],
      ],

      "Quality Reports": [_items[15], _items[16]],
    };
  }

  static final List<ReportItem> _items = [
    ReportItem(
      title: 'Manpower Costing',
      pageBuilder: () => const ManpowerDashboardPage(),
    ),
    ReportItem(title: 'Overtime', pageBuilder: () => OvertimeReportPage()),
    ReportItem(
      title: 'FG - Minimum Stock Vs Actual Stock',
      pageBuilder: () => const MinimumStockVsActualStockPage(),
    ),
    ReportItem(
      title: 'Stock Statement',
      pageBuilder: () => const StockStatementPage(),
    ),
    ReportItem(
      title: 'RM - Day Inventory Vs Current Stock',
      pageBuilder: () => const SummaryOfRawMaterials(),
    ),
    ReportItem(
      title: 'FG & RM Ageing',
      pageBuilder: () => const AgingReportPage(),
    ),
    ReportItem(
      title: 'Sales Vs Production',
      pageBuilder: () => const SalesVsProductionPage(),
    ),
    ReportItem(
      title: 'Sales Vs Delivery',
      pageBuilder: () => const SalesVsDeliveryPage(),
    ),
    ReportItem(
      title: 'Carriage Outward Cost',
      pageBuilder: () => const CarriageOutwardPage(),
    ),
    ReportItem(
      title: 'Carriage Inward Cost',
      pageBuilder: () => const CarriageInwardPage(),
    ),
    ReportItem(
      title: 'Purchase Price Analysis',
      pageBuilder: () => const PurchasePriceMIS(),
    ),
    ReportItem(
      title: 'Top Products',
      pageBuilder: () => const TopProductsPage(),
    ),
    ReportItem(
      title: 'CMS Costing',
      pageBuilder: () => const CMSCostingReportPage(),
    ),
    ReportItem(
      title: 'Scrap Details',
      pageBuilder: () => const ScrapReportPage(),
    ),
    ReportItem(
      title: 'Monthly Production',
      pageBuilder: () => const MonthlyProductionSummaryPage(),
    ),
    ReportItem(
      title: 'Sample Data Details',
      pageBuilder: () => const SampleDataPage(),
    ),
    ReportItem(
      title: 'External Complaint',
      pageBuilder: () => const ExternalComplaintPage(),
      isUnderDevelopment: false,
    ),
    ReportItem(
      title: 'Freight Charges',
      pageBuilder: () => const ComingSoonPage(),
      isUnderDevelopment: true,
    ),
    ReportItem(
      title: 'Monthly Workforce',
      pageBuilder: () => const MonthlyWorkforceSummaryPage(),
    ),
    ReportItem(
      title: 'Daily Raw Material',
      pageBuilder: () => const DailyRawMaterialReport(),
    ),
  ];

  void _openReport(ReportItem item) {
    if (item.isUnderDevelopment) {
      _showUnderDevelopmentPopup(context);
      return;
    }

    if (item.title == 'Scrap Details') {
      if (!mounted) return;

      NotificationService.info(
        title: "Info",
        message:
            "This report available in Dashboard Data Inputs -> Scrap Details Input.",
      );
      return;
    }

    _nestedNavKey.currentState
        ?.push(MaterialPageRoute(builder: (_) => item.pageBuilder()))
        .then((_) {
          if (mounted) {
            Future.delayed(
              const Duration(milliseconds: 200),
              () => _scaffoldKey.currentState?.openDrawer(),
            );
          }
        });
  }

  Widget _buildDrawer() {
    IconData getCategoryIcon(String category) {
      switch (category) {
        case "Costing Reports":
          return Icons.account_balance_wallet_outlined;

        case "Inventory Reports":
          return Icons.inventory_2_outlined;

        case "Sales Reports":
          return Icons.bar_chart_outlined;

        case "Production Reports":
          return Icons.precision_manufacturing_outlined;

        case "Quality Reports":
          return Icons.verified_outlined;

        default:
          return Icons.folder_outlined;
      }
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchText = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search Reports",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  ..._groupedReports.entries
                      .where((group) {
                        return group.value.any(
                          (item) =>
                              item.title.toLowerCase().contains(_searchText),
                        );
                      })
                      .map(
                        (group) => Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              leading: Icon(
                                getCategoryIcon(group.key),
                                color: Theme.of(context).primaryColor,
                              ),
                              title: Text(
                                group.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text("${group.value.length} Reports"),
                              children: group.value
                                  .where(
                                    (item) => item.title.toLowerCase().contains(
                                      _searchText,
                                    ),
                                  )
                                  .map((item) {
                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.only(
                                        left: 50,
                                        right: 16,
                                      ),
                                      title: Text(
                                        item.title,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right,
                                        size: 18,
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);

                                        Future.delayed(
                                          const Duration(milliseconds: 200),
                                          () => _openReport(item),
                                        );
                                      },
                                    );
                                  })
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnderDevelopmentPopup(BuildContext context) {
    if (!mounted) return;
    NotificationService.info(
      title: "Info",
      message: "🚧 This report is under development.",
    );
  }

  Future<bool> _onWillPop() async {
    if (_nestedNavKey.currentState?.canPop() ?? false) {
      _nestedNavKey.currentState!.pop();

      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _scaffoldKey.currentState?.openDrawer();
        }
      });

      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scaffoldKey.currentState?.openDrawer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        body: Navigator(
          key: _nestedNavKey,
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (_) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
