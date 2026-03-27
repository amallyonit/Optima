import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/externalComplaintPage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:optima/pages/dashboardPages/customerDashboard/customerSalesPerformance.dart';
import 'package:optima/pages/dashboardPages/financesDashboard/cashConversionFinance.dart';
import 'package:optima/pages/dashboardPages/financesDashboard/cashFlowFinance.dart';
import 'package:optima/pages/dashboardPages/financesDashboard/expensesFinance.dart';
import 'package:optima/pages/dashboardPages/financesDashboard/monthlyPLFinance.dart';
import 'package:optima/pages/dashboardPages/financesDashboard/payableFinance.dart';
import 'package:optima/pages/dashboardPages/financesDashboard/receivablesFinance.dart';
import 'package:optima/pages/dashboardPages/inventoryDashboardBI/inventoryAgeingAnalysis.dart';
import 'package:optima/pages/dashboardPages/inventoryDashboardBI/inventoryMovementAnalysis.dart';
import 'package:optima/pages/dashboardPages/inventoryDashboardBI/inventorySlowDeadAnalysis.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/agingReport.dart';
// import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/manpowerCostingReport.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/minimumStockVsActualStock.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/salesVsProduction.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/stockStatement.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/summaryOfRawMaterials.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/dayWiseProductionDetails.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/dayWiseProductionReportwrtMPPresent.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/jobCardEntryForAlternateMaterials.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/openProductionOrderAnalysis.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/productAnalysis.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/productionOrderAnalysis.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/produtionOrdersPendingReport.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/salesOrderVsProductionCompletedReport.dart';
import 'package:optima/pages/dashboardPages/purchaseDashboard/procurementLeadTimeAnalysis.dart';
import 'package:optima/pages/dashboardPages/purchaseDashboard/purchasePriceAnalysis.dart';
import 'package:optima/pages/dashboardPages/salesDashboardBI/deliveryAnalysis.dart';
import 'package:optima/pages/dashboardPages/salesDashboardBI/salesAnalysis.dart';
import 'package:optima/pages/dashboardPages/salesDashboardBI/soAnalysisBI.dart';
import 'package:optima/pages/notificationpage.dart';
import '../leadstages/finalstage.dart';
import '../leadstages/stagefiveentry.dart';
import '../leadstages/stagefourentry.dart';
import '../leadstages/stageoneentry.dart';
import '../leadstages/stagethreeentry.dart';
import '../leadstages/stagetwoentry.dart';
import '../pages/customerdatapage.dart';
import '../pages/dashboardPages/financesDashboard/customerCollectionAnalysis.dart';
import '../pages/dashboardPages/financesDashboard/dailyCostingReport.dart';
import '../pages/dashboardPages/financesDashboard/monthlyCollectionReport.dart';
import '../pages/dashboardPages/financesDashboard/productMarginReport.dart';
import '../pages/dashboardPages/financesDashboard/vendorPayment.dart';
import '../pages/dashboardPages/inventoryDashboardBI/inventoryAnalysis.dart';
import '../pages/dashboardPages/productionDashboardBI/MISreports/carriageInwardReport.dart';
import '../pages/dashboardPages/productionDashboardBI/MISreports/carriageOutwardReport.dart';
import '../pages/dashboardPages/productionDashboardBI/MISreports/cmsCostingReport.dart';
import '../pages/dashboardPages/productionDashboardBI/MISreports/monthlyProductionSummary.dart';
import '../pages/dashboardPages/productionDashboardBI/MISreports/purchasePrice.dart';
import '../pages/dashboardPages/productionDashboardBI/MISreports/salesVsDelivery.dart';
import '../pages/dashboardPages/productionDashboardBI/MISreports/sampleDataDetailsPage.dart';
import '../pages/dashboardPages/productionDashboardBI/MISreports/scrapReport.dart';
import '../pages/dashboardPages/productionDashboardBI/MISreports/topProducts.dart';
import '../pages/dashboardPages/purchaseDashboard/paymentAnalysis.dart';
import '../pages/dashboardPages/purchaseDashboard/poAnalysis.dart';
import '../pages/dashboardPages/purchaseDashboard/procurementAnalysis.dart';
import '../pages/dashboardPages/salesDashboardBI/collectionAnalysisBI.dart';
import '../pages/homepage.dart';
import '../pages/followupeditpage.dart';
import '../pages/leadpagelist.dart';
import '../pages/header.dart';
import '../pages/footer.dart';
import '../pages/monthlyScheduler/approvalPage.dart';
import '../pages/monthlyScheduler/monthlyScheduler.dart';

class AppProviders {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(create: (_) => LeadMasterHomePageProvider()),
    ChangeNotifierProvider(create: (_) => LeadContactHomePageProvider()),
    ChangeNotifierProvider(create: (_) => LeadActivityHomePageProvider()),
    ChangeNotifierProvider(create: (_) => LeadMasterProvider()),
    ChangeNotifierProvider(create: (_) => LeadMasterFollowUpProvider()),
    ChangeNotifierProvider(create: (_) => LeadMasterHeaderPageProvider()),
    ChangeNotifierProvider(create: (_) => LeadContactProvider()),
    ChangeNotifierProvider(create: (_) => LeadContactFollowUpProvider()),
    ChangeNotifierProvider(create: (_) => LeadContactHeaderPageProvider()),
    ChangeNotifierProvider(create: (_) => LeadMasterStage1Provider()),
    ChangeNotifierProvider(create: (_) => LeadContactStage1Provider()),
    ChangeNotifierProvider(create: (_) => LeadProductsProvider()),
    ChangeNotifierProvider(create: (_) => LeadProductsStage3Provider()),
    ChangeNotifierProvider(create: (_) => LeadProductsStage4Provider()),
    ChangeNotifierProvider(create: (_) => LeadProductsStage5Provider()),
    ChangeNotifierProvider(create: (_) => LeadProductsStage6Provider()),
    ChangeNotifierProvider(create: (_) => LeadProductsFinalStageProvider()),
    ChangeNotifierProvider(create: (_) => LeadMasterFooterPageProvider()),
    ChangeNotifierProvider(create: (_) => LeadActivityCustomerDataProvider()),
    ChangeNotifierProvider(create: (_) => LeadPageListProvider()),
    ChangeNotifierProvider(create: (_) => LeadActivityFollowupProvider()),
    ChangeNotifierProvider(create: (_) => LeadActivityFooterPageProvider()),
    ChangeNotifierProvider(
      create: (_) => SalesTargetListSalesAnalysisProvider(),
    ),
    ChangeNotifierProvider(
      create: (_) => CollectionListCollectionsAnalysisBIProvider(),
    ),
    ChangeNotifierProvider(create: (_) => SalesListSalesAnalysisProvider()),
    ChangeNotifierProvider(
      create: (_) => SalesTargetListCustomerSalesPerformancePageProvider(),
    ),
    ChangeNotifierProvider(
      create: (_) => SalesListCustomerSalesPerformancePageProvider(),
    ),
    ChangeNotifierProvider(
      create: (_) => TargetListCollectionsAnalysisBIProvider(),
    ),
    ChangeNotifierProvider(create: (_) => SalesOrderListSoAnalysisBIProvider()),
    ChangeNotifierProvider(
      create: (_) => FinanceReceivablesCollectionBIProvider(),
    ),
    ChangeNotifierProvider(
      create: (_) => FinanceReceivablesTargetCollectionBIProvider(),
    ),
    ChangeNotifierProvider(
      create: (_) => FinancePayablesCollectionBIProvider(),
    ),
    // ChangeNotifierProvider(create: (_) => FinancePayablesTargetCollectionBIProvider()),
    ChangeNotifierProvider(create: (_) => FinanceCashFlowBIProvider()),
    ChangeNotifierProvider(create: (_) => FinanceExpensesBIProvider()),
    ChangeNotifierProvider(create: (_) => CheckinDetailsHomePageProvider()),
    ChangeNotifierProvider(
      create: (_) => PurchaseProcurementAnalysisProvider(),
    ),
    ChangeNotifierProvider(create: (_) => PaymentAnalysisProvider()),
    ChangeNotifierProvider(create: (_) => PurchasePOAnalysisProvider()),
    ChangeNotifierProvider(
      create: (_) => InventoryListInventoryAnalysisProvider(),
    ),
    ChangeNotifierProvider(
      create: (_) => InventoryListInventoryLevelAnalysisProvider(),
    ),
    ChangeNotifierProvider(create: (_) => ProductionOrderAnalysisProvider()),
    ChangeNotifierProvider(
      create: (_) => OpenProductionOrderAnalysisProvider(),
    ),
    ChangeNotifierProvider(create: (_) => ConsumptionListProvider()),
    ChangeNotifierProvider(create: (_) => ProductionListProvider()),
    ChangeNotifierProvider(
      create: (_) => ProductionOrderSPendingReportProvider(),
    ),
    ChangeNotifierProvider(create: (_) => DayWiseProductionDetailsProvider()),
    ChangeNotifierProvider(create: (_) => SalesOrderVsProductionProvider()),
    ChangeNotifierProvider(create: (_) => DayWiseProductionwrtMPProvider()),
    ChangeNotifierProvider(create: (_) => JobCardEntryProvider()),
    ChangeNotifierProvider(create: (_) => InventoryMovementAnalysisProvider()),
    ChangeNotifierProvider(create: (_) => PurchasePriceAnalysisProvider()),
    ChangeNotifierProvider(create: (_) => ProcurementLeadTimeProvider()),
    ChangeNotifierProvider(create: (_) => DeliveryAnalysisProvider()),
    ChangeNotifierProvider(
      create: (_) => ScheduledLeadActivityHomePageProvider(),
    ),
    ChangeNotifierProvider(create: (_) => InventorySlowDeadAnalysisProvider()),
    ChangeNotifierProvider(create: (_) => InventoryAgeingAnalysisProvider()),
    ChangeNotifierProvider(create: (_) => ProductWiseMarginProvider()),
    ChangeNotifierProvider(create: (_) => ProductWiseMarginItemCostProvider()),
    ChangeNotifierProvider(create: (_) => TrialBalanceProvider()),
    ChangeNotifierProvider(create: (_) => CashConversionReceivablesProvider()),
    ChangeNotifierProvider(create: (_) => CashConversionSalesProvider()),
    ChangeNotifierProvider(create: (_) => CashConversionCollectionProvider()),
    ChangeNotifierProvider(create: (_) => NotificationListProvider()),
    ChangeNotifierProvider(create: (_) => PendingOrderExcelProvider()),
    ChangeNotifierProvider(create: (_) => MonthlyDebtorAgingProvider()),
    ChangeNotifierProvider(create: (_) => MonthlyCollectionListProvider()),
    ChangeNotifierProvider(create: (_) => DailyCostingSalesProvider()),
    ChangeNotifierProvider(create: (_) => DailyCostingSOListProvider()),
    ChangeNotifierProvider(create: (_) => DailyCostingPurchaseProvider()),
    ChangeNotifierProvider(create: (_) => DailyCostingPOProvider()),
    ChangeNotifierProvider(create: (_) => DailyCostingInventoryProvider()),
    ChangeNotifierProvider(create: (_) => ActualPayableProvider()),
    ChangeNotifierProvider(create: (_) => InventoryMonthlyPLProvider()),
    ChangeNotifierProvider(create: (_) => InventoryClosingMonthlyPLProvider()),
    ChangeNotifierProvider(create: (_) => SalesTargetMonthlyPLProvider()),
    ChangeNotifierProvider(create: (_) => PurchaseMonthlyPLProvider()),
    ChangeNotifierProvider(create: (_) => SalesMonthlyPLProvider()),
    ChangeNotifierProvider(create: (_) => CashConversionPayableProvider()),
    ChangeNotifierProvider(
      create: (_) => InventoryClosingCashConversionProvider(),
    ),
    ChangeNotifierProvider(create: (_) => InventoryCashConversionProvider()),
    ChangeNotifierProvider(create: (_) => PurchaseCashConversionProvider()),
    ChangeNotifierProvider(create: (_) => ProductWiseMarginProvider()),
    ChangeNotifierProvider(create: (_) => ProductWiseMarginItemCostProvider()),
    ChangeNotifierProvider(
      create: (_) => CollectionAnalysisCustomerDashboardTargetProvider(),
    ),
    ChangeNotifierProvider(create: (_) => DailyCostingSalesTargetProvider()),
    ChangeNotifierProvider(
      create: (_) => DailyCostingInventoryClosingProvider(),
    ),
    ChangeNotifierProvider(create: (_) => VendorPaymentProvider()),
    ChangeNotifierProvider(create: (_) => VendorPayableProvider()),
    ChangeNotifierProvider(create: (_) => PayableTrialBalanceProvider()),
    ChangeNotifierProvider(create: (_) => DailyCostingGRNProvider()),
    // ChangeNotifierProvider(create: (_) => MSIProductionReportsProvider()),
    ChangeNotifierProvider(
      create: (_) => CashConversionActualPayableProvider(),
    ),
    ChangeNotifierProvider(create: (_) => GRNCashConversionProvider()),
    ChangeNotifierProvider(create: (_) => PayableSalesTargetProvider()),
    ChangeNotifierProvider(create: (_) => MonthlySchedulerProvider()),
    ChangeNotifierProvider(create: (_) => GRNMonthlyPLProvider()),

    ChangeNotifierProvider(
      create: (_) => SchedulerApprovalProviderForApproval(),
    ),
    ChangeNotifierProvider(create: (_) => SchedulerApprovalProviderForHome()),
    ChangeNotifierProvider(
      create: (_) => SchedulerApprovalProviderForHomePending(),
    ),
    // ChangeNotifierProvider(create: (_) => ManpowerCostingProductionProvider()),
    // ChangeNotifierProvider(create: (_) => ManpowerCostingRCPProvider()),
    // ChangeNotifierProvider(create: (_) => ManpowerCostingCTCProvider()),
    // ChangeNotifierProvider(create: (_) => ManpowerCostingTargetProvider()),
    ChangeNotifierProvider(create: (_) => StockStatusListMISProvider()),
    ChangeNotifierProvider(create: (_) => StockStatementMISProvider()),
    ChangeNotifierProvider(create: (_) => SummOfRawMaterialMISProvider()),
    ChangeNotifierProvider(create: (_) => AgingReportMISProvider()),
    ChangeNotifierProvider(
      create: (_) => SalesVsProductionDeliveryDetailsMISProvider(),
    ),
    ChangeNotifierProvider(create: (_) => SalesVsDeliveryDetailsMISProvider()),
    ChangeNotifierProvider(create: (_) => PurchasePriceMISProvider()),
    ChangeNotifierProvider(create: (_) => BOMCostMISProvider()),
    ChangeNotifierProvider(create: (_) => TopProductsMISProvider()),
    ChangeNotifierProvider(create: (_) => CMSDetailsMISProvider()),
    ChangeNotifierProvider(create: (_) => ScrapDetailProvider()),
    ChangeNotifierProvider(create: (_) => ComplaintDetailsMISProvider()),
    ChangeNotifierProvider(create: (_) => SampleDetailsMISProvider()),
    ChangeNotifierProvider(create: (_) => MonthlyProductionMISProvider()),
    ChangeNotifierProvider(create: (_) => CarriageInwardMISProvider()),
    ChangeNotifierProvider(create: (_) => CarriageOutwardMISProvider()),
    ChangeNotifierProvider(create: (_) => SalesOrderListHomePageProvider()),
  ];
}
