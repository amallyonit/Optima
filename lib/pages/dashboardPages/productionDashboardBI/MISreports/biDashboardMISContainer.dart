// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:optima/pages/comingsoon.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/carriageInwardReport.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/carriageOutwardReport.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/manpower_costing/manpower_dashboard_page.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/monthlyProductionSummary.dart';
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

class ReportTile extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;

  const ReportTile({
    super.key,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

String deviceOrientationMISContainer = "";

class ProductionReportsMIS extends StatefulWidget {
  const ProductionReportsMIS({super.key});

  @override
  State<ProductionReportsMIS> createState() => _ProductionReportsMISState();
}

class _ProductionReportsMISState extends State<ProductionReportsMIS> {
  final GlobalKey<NavigatorState> _nestedNavKey = GlobalKey<NavigatorState>();

  static final List<ReportItem> _items = [
    ReportItem(
      title: 'Manpower Costing Report',
      pageBuilder: () => const ManpowerDashboardPage(),
    ),
    ReportItem(
      title: 'Overtime Report',
      pageBuilder: () => OvertimeReportPage(),
    ),
    ReportItem(
      title: 'FG - Minimum Stock Vs Actual Stock',
      pageBuilder: () => const MinimumStockVsActualStockPage(),
    ),
    ReportItem(
      title: 'Stock Statement',
      pageBuilder: () => const StockStatementPage(),
    ),
    ReportItem(
      title: 'RM Day Inventory Vs Current Stock',
      pageBuilder: () => const SummaryOfRawMaterials(),
    ),
    ReportItem(
      title: 'FG & RM Aging Report',
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
      title: 'Carriage Outward Bangalore To Branch & Direct Customers NEW',
      pageBuilder: () => const CarriageOutwardPage(),
    ),
    ReportItem(
      title: 'Carriage Inward Cost Report',
      pageBuilder: () => const CarriageInwardPage(),
      isUnderDevelopment: true,
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
      title: 'CMS Costing Report',
      pageBuilder: () => const CMSCostingReportPage(),
    ),
    ReportItem(
      title: 'Scrap Report',
      pageBuilder: () => const ScrapReportPage(),
    ),
    ReportItem(
      title: 'Monthly Production Summary',
      pageBuilder: () => const MonthlyProductionSummaryPage(),
      isUnderDevelopment: true,
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
      title: 'Kerala Freight',
      pageBuilder: () => const ComingSoonPage(),
      isUnderDevelopment: true,
    ),
    ReportItem(
      title: 'Monthly Workforce Summary',
      pageBuilder: () => const MonthlyWorkforceSummaryPage(),
    ),
  ];

  Widget _buildReportsList(BuildContext navContext) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _items[index];

              final tileColor = (index % 2 == 0)
                  ? Colors.lightBlue.shade100
                  : Colors.grey.shade300;

              return ReportTile(
                title: item.title,
                color: tileColor,
                onTap: () {
                  if (item.isUnderDevelopment) {
                    _showUnderDevelopmentPopup(context);
                    return;
                  }
                  if (_nestedNavKey.currentState != null) {
                    _nestedNavKey.currentState!.push(
                      MaterialPageRoute(builder: (_) => item.pageBuilder()),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => item.pageBuilder()),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUnderDevelopmentPopup(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 This report is under development'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_nestedNavKey.currentState?.canPop() ?? false) {
      _nestedNavKey.currentState!.pop();
      return false; // consumed
    }
    return true; // allow root to pop
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.width;
    if (screenHeight > 600) {
      deviceOrientationMISContainer = "Landscape";
    } else {
      deviceOrientationMISContainer = "Portrait";
    }
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: deviceOrientationMISContainer == "Landscape" ? 1300 : 600,
              child: Navigator(
                key: _nestedNavKey,
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (navContext) => Scaffold(
                      appBar: AppBar(
                        title: const Text('Production Reports (MIS)'),
                        automaticallyImplyLeading: false,
                      ),
                      body: _buildReportsList(navContext),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
