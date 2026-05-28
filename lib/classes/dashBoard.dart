// ignore_for_file: file_names, non_constant_identifier_names
import 'package:intl/intl.dart';

class PrevYearMonthList {
  final List<PrevYearMonthData> prevYearMonthData;
  PrevYearMonthList({required this.prevYearMonthData});
}

class PrevYearMonthData {
  final String monthName;
  PrevYearMonthData({required this.monthName});
}

class MonthlySalesList {
  final List<MonthlySalesData> monthlyData;
  MonthlySalesList({required this.monthlyData});
}

class YTDSalesData {
  final String customerName;
  final String salesManager;
  final String salesRep;
  final String itemSubGroup;
  final String itemName;
  final String currency;
  final double currencyRate;
  final double price;
  final double aprQty;
  final double aprValue;
  final double mayQty;
  final double mayValue;
  final double junQty;
  final double junValue;
  final double julQty;
  final double julValue;
  final double augQty;
  final double augValue;
  final double sepQty;
  final double sepValue;
  final double octQty;
  final double octValue;
  final double novQty;
  final double novValue;
  final double decQty;
  final double decValue;
  final double janQty;
  final double janValue;
  final double febQty;
  final double febValue;
  final double marQty;
  final double marValue;
  final double ytdTotalValue;
  final double ytdTotalQty;
  YTDSalesData({
    required this.customerName,
    required this.salesManager,
    required this.salesRep,
    required this.itemName,
    required this.itemSubGroup,
    required this.currency,
    required this.currencyRate,
    required this.price,
    required this.aprQty,
    required this.aprValue,
    required this.mayQty,
    required this.mayValue,
    required this.junQty,
    required this.junValue,
    required this.julQty,
    required this.julValue,
    required this.augQty,
    required this.augValue,
    required this.sepQty,
    required this.sepValue,
    required this.octQty,
    required this.octValue,
    required this.novQty,
    required this.novValue,
    required this.decQty,
    required this.decValue,
    required this.janQty,
    required this.janValue,
    required this.febQty,
    required this.febValue,
    required this.marQty,
    required this.marValue,
    required this.ytdTotalValue,
    required this.ytdTotalQty,
  });
}

class YTDSalesList {
  final List<YTDSalesData> ytdData;
  YTDSalesList({required this.ytdData});
}

class YTDCollectionData {
  final String customerName;
  final String salesManager;
  final String salesRep;
  final double aprValue;
  final double mayValue;
  final double junValue;
  final double julValue;
  final double augValue;
  final double sepValue;
  final double octValue;
  final double novValue;
  final double decValue;
  final double janValue;
  final double febValue;
  final double marValue;
  final double ytdTotalValue;
  YTDCollectionData({
    required this.customerName,
    required this.salesManager,
    required this.salesRep,
    required this.aprValue,
    required this.mayValue,
    required this.junValue,
    required this.julValue,
    required this.augValue,
    required this.sepValue,
    required this.octValue,
    required this.novValue,
    required this.decValue,
    required this.janValue,
    required this.febValue,
    required this.marValue,
    required this.ytdTotalValue,
  });
}

class YTDCollectionList {
  final List<YTDCollectionData> ytdColData;
  YTDCollectionList({required this.ytdColData});
}

class MonthlySalesData {
  final String monthName;
  final double salesAmount;
  final double salesTarget;
  MonthlySalesData({
    required this.monthName,
    required this.salesAmount,
    required this.salesTarget,
  });
}

class MonthlyColectionList {
  final List<MonthlyCollectionData> monthlyData;
  MonthlyColectionList({required this.monthlyData});
}

class MonthlyCollectionData {
  final String monthName;
  final double collectionAmount;
  final double collectionTarget;
  MonthlyCollectionData({
    required this.monthName,
    required this.collectionAmount,
    required this.collectionTarget,
  });
}

class RsmwiseData {
  final String rsmName;
  final double salesAmount;
  final double targetAmount;
  RsmwiseData({
    required this.rsmName,
    required this.salesAmount,
    required this.targetAmount,
  });
}

class RsmwiseSalesList {
  final List<RsmwiseData> rsmwiseData;
  RsmwiseSalesList({required this.rsmwiseData});
}

class AsmwiseData {
  final String asmName;
  final double salesAmount;
  final double targetAmount;
  AsmwiseData({
    required this.asmName,
    required this.salesAmount,
    required this.targetAmount,
  });
}

class AsmwiseSalesList {
  final List<AsmwiseData> asmwiseData;
  AsmwiseSalesList({required this.asmwiseData});
}

class TsmwiseData {
  final String tsmName;
  final double salesAmount;
  final double targetAmount;
  TsmwiseData({
    required this.tsmName,
    required this.salesAmount,
    required this.targetAmount,
  });
}

class TsmwiseSalesList {
  final List<TsmwiseData> tsmwiseData;
  TsmwiseSalesList({required this.tsmwiseData});
}

class RsmwiseCollectionData {
  final String rsmName;
  final double collectionAmount;
  final double targetAmount;
  RsmwiseCollectionData({
    required this.rsmName,
    required this.collectionAmount,
    required this.targetAmount,
  });
}

class RsmwiseCollectionList {
  final List<RsmwiseCollectionData> rsmwiseData;
  RsmwiseCollectionList({required this.rsmwiseData});
}

class AsmwiseCollectionData {
  final String asmName;
  final double collectionAmount;
  final double targetAmount;
  AsmwiseCollectionData({
    required this.asmName,
    required this.collectionAmount,
    required this.targetAmount,
  });
}

class AsmwiseCollectionList {
  final List<AsmwiseCollectionData> asmwiseData;
  AsmwiseCollectionList({required this.asmwiseData});
}

class TsmwiseCollectionData {
  final String tsmName;
  final double collectionAmount;
  final double targetAmount;
  TsmwiseCollectionData({
    required this.tsmName,
    required this.collectionAmount,
    required this.targetAmount,
  });
}

class TsmwiseCollectionList {
  final List<TsmwiseCollectionData> tsmwiseData;
  TsmwiseCollectionList({required this.tsmwiseData});
}

class CustomerStateWiseSalesList {
  final List<CustomerStateWiseData> customerStateData;
  CustomerStateWiseSalesList({required this.customerStateData});
}

class CustomerStateWiseData {
  final String stateName;
  final double saleAmount;
  final double targetAmount;
  CustomerStateWiseData({
    required this.stateName,
    required this.saleAmount,
    required this.targetAmount,
  });
}

class CustomerWiseSalesList {
  final List<CustomerWiseData> customerData;
  CustomerWiseSalesList({required this.customerData});
}

class CustomerWiseData {
  final String customerCode;
  final String customerName;
  final double saleAmount;
  final double targetAmount;
  CustomerWiseData({
    required this.customerCode,
    required this.customerName,
    required this.saleAmount,
    required this.targetAmount,
  });
}

class CustomerWiseCollectionList {
  final List<CustomerWiseCollectionData> customerData;
  CustomerWiseCollectionList({required this.customerData});
}

class CustomerWiseCollectionData {
  final String customerCode;
  final String customerName;
  final double collectionAmount;
  final double targetAmount;
  CustomerWiseCollectionData({
    required this.customerCode,
    required this.customerName,
    required this.collectionAmount,
    required this.targetAmount,
  });
}

class ReceivablesCategoryList {
  final List<ReceivablesCategoryData> categoryData;
  ReceivablesCategoryList({required this.categoryData});
}

class ReceivablesCategoryData {
  final int categoryId;
  final String categoryName;
  double categoryAmount;
  double categoryPercentage;
  ReceivablesCategoryData({
    required this.categoryId,
    required this.categoryName,
    required this.categoryAmount,
    required this.categoryPercentage,
  });
}

class ReceivablesAgingList {
  final List<ReceivablesAgingData> agingData;
  ReceivablesAgingList({required this.agingData});
}

class ReceivablesAgingData {
  final String agingGroup;
  double agingPercentage;
  double agingGroupTotal;
  double agingTotal;
  ReceivablesAgingData({
    required this.agingGroup,
    required this.agingPercentage,
    required this.agingGroupTotal,
    required this.agingTotal,
  });
}

class AgingSummary {
  double a0to30DaysTotal = 0;
  double a31to60DaysTotal = 0;
  double a61to90DaysTotal = 0;
  double a91to180DaysTotal = 0;
  double a181DaysTotal = 0;
  double afutureTotal = 0;
}

class ProductGroupwiseSalesList {
  final List<ProductGroupwiseData> productGroupData;
  ProductGroupwiseSalesList({required this.productGroupData});
}

class ProductGroupwiseData {
  final String productGroupName;
  final double salesAmount;
  final double targetAmount;
  ProductGroupwiseData({
    required this.productGroupName,
    required this.salesAmount,
    required this.targetAmount,
  });
}

class ProductwiseSalesList {
  final List<ProductwiseData> productData;
  ProductwiseSalesList({required this.productData});
}

class ProductwiseData {
  final String productCode;
  final String productName;
  double salesAmount;
  double targetAmount;
  ProductwiseData({
    required this.productCode,
    required this.productName,
    required this.salesAmount,
    required this.targetAmount,
  });
}

class SalesTargetList {
  final String financialYear;
  final String salesRepCode;
  final String salesRep;
  final String salesManager;
  final String regionalManager;
  final String april;
  final String may;
  final String june;
  final String july;
  final String aug;
  final String sep;
  final String oct;
  final String nov;
  final String dec;
  final String jan;
  final String feb;
  final String mar;

  SalesTargetList({
    required this.financialYear,
    required this.salesRepCode,
    required this.salesRep,
    required this.salesManager,
    required this.regionalManager,
    required this.april,
    required this.may,
    required this.june,
    required this.july,
    required this.aug,
    required this.sep,
    required this.oct,
    required this.nov,
    required this.dec,
    required this.jan,
    required this.feb,
    required this.mar,
  });

  factory SalesTargetList.fromJson(Map<String, dynamic> json) {
    return SalesTargetList(
      financialYear: json['financialYear'] ?? '',
      salesRepCode: json['salesRepCode'] ?? '',
      salesRep: json['salesRep'] ?? '',
      salesManager: json['salesManager'] ?? '',
      regionalManager: json['regionalManager'] ?? '',
      april: json.containsKey('april') ? json['april'] : '',
      may: json.containsKey('may') ? json['may'] : '',
      june: json.containsKey('june') ? json['june'] : '',
      july: json.containsKey('july') ? json['july'] : '',
      aug: json.containsKey('aug') ? json['aug'] : '',
      sep: json.containsKey('sep') ? json['sep'] : '',
      oct: json.containsKey('oct') ? json['oct'] : '',
      nov: json.containsKey('nov') ? json['nov'] : '',
      dec: json.containsKey('dec') ? json['dec'] : '',
      jan: json.containsKey('jan') ? json['jan'] : '',
      feb: json.containsKey('feb') ? json['feb'] : '',
      mar: json.containsKey('mar') ? json['mar'] : '',
    );
  }

  String getTargetForMonth(String monthName) {
    switch (monthName.toLowerCase()) {
      case 'january':
        return jan;
      case 'february':
        return feb;
      case 'march':
        return mar;
      case 'april':
        return april;
      case 'may':
        return may;
      case 'june':
        return june;
      case 'july':
        return july;
      case 'august':
        return aug;
      case 'september':
        return sep;
      case 'october':
        return oct;
      case 'november':
        return nov;
      case 'december':
        return dec;
      default:
        return '0';
    }
  }
}

class CollectionList {
  final String documentNo;
  final String postingDate;
  final String invoiceNo;
  final String invoiceDate;
  final String salesRep;
  final String salesManager;
  final String regionalManager;
  final String customerGroup;
  final String bpGroup;
  final String customerSubGroup;
  final String paymentTermsDays;
  final String paymentTerms;
  final String customerCode;
  final String customerName;
  final String modeofPayment;
  final String total;
  final String documentTotal;
  final String remarks;

  CollectionList({
    required this.documentNo,
    required this.postingDate,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.salesRep,
    required this.salesManager,
    required this.regionalManager,
    required this.customerGroup,
    required this.bpGroup,
    required this.customerSubGroup,
    required this.paymentTermsDays,
    required this.paymentTerms,
    required this.customerCode,
    required this.customerName,
    required this.modeofPayment,
    required this.total,
    required this.documentTotal,
    required this.remarks,
  });

  factory CollectionList.fromJson(Map<String, dynamic> json) {
    return CollectionList(
      documentNo: json['documentNo'],
      postingDate: json['postingDate'],
      invoiceNo: json['invoiceNo'],
      invoiceDate: json['invoiceDate'],
      salesRep: json['salesRep'],
      salesManager: json['salesManager'],
      regionalManager: json['regionalManager'],
      customerGroup: json['customerGroup'],
      bpGroup: json['bpGroup'],
      customerSubGroup: json['customerSubGroup'],
      paymentTermsDays: json['paymentTermsDays'],
      paymentTerms: json['paymentTerms'],
      customerCode: json['customerCode'],
      customerName: json['customerName'],
      modeofPayment: json['modeofPayment'],
      total: json['total'],
      documentTotal: json['documentTotal'],
      remarks: json['remarks'],
    );
  }
}

class DebtorsAgingList {
  final String salesManager;
  final String regionalManager;
  final String salesRep;
  final String customerGroup;
  final String bpGroup;
  final String customerCode;
  final String customerName;
  final String creditLimit;
  final String postingDate;
  final String documentNumber;
  final String documentRefNo;
  final String accountBalance;
  final String invoiceIssues;
  final String expectedPayment;
  final String expectedPaymentRemarks;
  final String lastReceiptDate;
  final String documentType;
  final String paymentTermsDays;
  final String paymentTerms;
  final String dueon;
  final String dueDays;
  final String balance;
  final String ageingBrackets;
  final String future;
  final String a0to30Days;
  final String a31to60Days;
  final String a61to90Days;
  final String a91to180Days;
  final String a181Days;
  final String eKartNo;
  late String commitment;
  late DateTime parsedDueDate;
  late DateTime parsedPostingDate;
  DebtorsAgingList({
    required this.salesManager,
    required this.regionalManager,
    required this.salesRep,
    required this.customerGroup,
    required this.bpGroup,
    required this.customerCode,
    required this.customerName,
    required this.creditLimit,
    required this.postingDate,
    required this.documentNumber,
    required this.documentRefNo,
    required this.accountBalance,
    required this.invoiceIssues,
    required this.expectedPayment,
    required this.expectedPaymentRemarks,
    required this.lastReceiptDate,
    required this.documentType,
    required this.paymentTermsDays,
    required this.paymentTerms,
    required this.dueon,
    required this.dueDays,
    required this.balance,
    required this.ageingBrackets,
    required this.future,
    required this.a0to30Days,
    required this.a31to60Days,
    required this.a61to90Days,
    required this.a91to180Days,
    required this.a181Days,
    required this.eKartNo,
    required this.commitment,
  });

  factory DebtorsAgingList.fromJson(Map<String, dynamic> json) {
    return DebtorsAgingList(
      salesManager: json['salesManager'],
      regionalManager: json['regionalManager'],
      salesRep: json['salesRep'],
      customerGroup: json['customerGroup'],
      bpGroup: json['bpGroup'],
      customerCode: json['customerCode'],
      customerName: json['customerName'],
      creditLimit: json['creditLimit'],
      postingDate: json['postingDate'],
      documentNumber: json['documentNumber'],
      documentRefNo: json['documentRefNo'],
      accountBalance: json['accountBalance'],
      invoiceIssues: json['invoiceIssues'],
      expectedPayment: json['expectedPayment'],
      expectedPaymentRemarks: json['expectedPaymentRemarks'],
      lastReceiptDate: json['lastReceiptDate'],
      documentType: json['documentType'],
      paymentTermsDays: json['paymentTermsDays'],
      paymentTerms: json['paymentTerms'],
      dueon: json['dueon'],
      dueDays: json['dueDays'],
      balance: json['balance'],
      ageingBrackets: json['ageingBrackets'],
      future: json['future'],
      a0to30Days: json['a0to30Days'],
      a31to60Days: json['a31to60Days'],
      a61to90Days: json['a61to90Days'],
      a91to180Days: json['a91to180Days'],
      a181Days: json['a181Days'],
      eKartNo: json['eKartNo'],
      commitment: json['commitment'],
    );
  }
}

class SalesList {
  final String invoiceType;
  final String salesType;
  final String type;
  final String invoiceNo;
  final DateTime invoiceDate;
  final String refNo;
  final String termsofDelivery;
  final String dispatchThrough;
  final String destinationDetails;
  final String customerGroup;
  final String customerCode;
  final String customerName;
  final String customerCity;
  final String customerState;
  final String countryZone;
  final String salesRep;
  final String salesManager;
  final String regionalManager;
  final String itemGroup;
  final String itemSubGroup;
  final String code;
  final String description;
  final String uom;
  final String quantity;
  final String currency;
  final String currencyRate;
  final String price;
  final String taxCode;
  final String rowTotal;
  final String documentTotal;
  final String branchName;
  final String whsCode;

  SalesList({
    required this.invoiceType,
    required this.salesType,
    required this.type,
    required this.invoiceNo,
    required this.invoiceDate, // DateTime now
    required this.refNo,
    required this.termsofDelivery,
    required this.dispatchThrough,
    required this.destinationDetails,
    required this.customerCode,
    required this.customerName,
    required this.customerGroup,
    required this.customerCity,
    required this.customerState,
    required this.countryZone,
    required this.salesRep,
    required this.salesManager,
    required this.regionalManager,
    required this.itemGroup,
    required this.itemSubGroup,
    required this.code,
    required this.description,
    required this.uom,
    required this.quantity,
    required this.currency,
    required this.currencyRate,
    required this.price,
    required this.taxCode,
    required this.rowTotal,
    required this.documentTotal,
    required this.branchName,
    required this.whsCode,
  });

  factory SalesList.fromJson(Map<String, dynamic> json) {
    return SalesList(
      invoiceType: json['invoiceType'] ?? '',
      salesType: json['salesType'] ?? '',
      type: json['type'] ?? '',
      invoiceNo: json['invoiceNo'] ?? '',

      // 🔥 Parse invoiceDate once here
      invoiceDate: DateFormat(
        'dd/MM/yyyy',
      ).parse(json['invoiceDate'] ?? '01/01/2000'),

      refNo: json['refNo'] ?? '',
      termsofDelivery: json['termsofDelivery'] ?? '',
      dispatchThrough: json['dispatchThrough'] ?? '',
      destinationDetails: json['destinationDetails'] ?? '',
      customerCode: json['customerCode'] ?? '',
      customerName: json['customerName'] ?? '',
      customerGroup: json['customerGroup'] ?? '',
      customerCity: json['customerCity'] ?? '',
      customerState: json['customerState'] ?? '',
      countryZone: json['countryZone'] ?? '',
      salesRep: json['salesRep'] ?? '',
      salesManager: json['salesManager'] ?? '',
      regionalManager: json['regionalManager'] ?? '',
      itemGroup: json['itemGroup'] ?? '',
      itemSubGroup: json['itemSubGroup'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      uom: json['uom'] ?? '',
      quantity: json['quantity'] ?? '',
      currency: json['currency'] ?? '',
      currencyRate: json['currencyRate'] ?? '',
      price: json['price'] ?? '',
      taxCode: json['taxCode'] ?? '',
      rowTotal: json['rowTotal']?.toString() ?? '0',
      documentTotal: json['documentTotal'] ?? '',
      branchName: json['branchName'] ?? '',
      whsCode: json['whsCode'] ?? '',
    );
  }
}

class PODetailList {
  final String soDate;
  final String orderValue;
  final String soStatus;
  final String remark;
  final String customerCode;
  PODetailList({
    required this.soDate,
    required this.orderValue,
    required this.soStatus,
    required this.remark,
    this.customerCode = "",
  });

  factory PODetailList.fromJson(Map<String, dynamic> json) {
    return PODetailList(
      soDate: json['soDate'],
      orderValue: json['orderValue'],
      soStatus: json['soStatus'],
      remark: json['remark'],
      customerCode: json['customerCode'],
    );
  }
}

class SODetailsList {
  final String soDate;
  final String soNo;
  final String poDate;
  final String poNo;
  final String customerCode;
  final String customerName;
  final String customerGroup;
  final String bpGroup;
  final String customerCity;
  final String customerState;
  final String countryZone;
  final String salesRep;
  final String salesManager;
  final String regionalManager;
  final String groupName;
  final String itemSubGroup;
  final String itemSubSubGroup;
  final String productCode;
  final String productName;
  final String uom;
  final String orderQuantity;
  final String rate;
  final String orderValue;
  final String speciality;
  final String dispatchQuantity;
  final String pendingQuantity;
  final String pendingValue;
  final String bngwhInStock;
  final String rjpmwhInStock;
  final String boxQty;
  final String soStatus;
  final String mrp;
  final String priority;
  final String branchName;
  final String warehouse;
  final String warehouseQty;
  final String expectedTimeofDelivey;
  final String overDueDays;
  final String paymentTerms;
  final String remark;
  final String gracePeriodTerms;
  final String expectedPayment;
  final String bomStatus;
  final String barCode;
  final String overDue;

  SODetailsList({
    required this.soDate,
    required this.soNo,
    required this.poDate,
    required this.poNo,
    required this.customerCode,
    required this.customerName,
    required this.customerGroup,
    required this.bpGroup,
    required this.customerCity,
    required this.customerState,
    required this.countryZone,
    required this.salesRep,
    required this.salesManager,
    required this.regionalManager,
    required this.groupName,
    required this.itemSubGroup,
    required this.itemSubSubGroup,
    required this.productCode,
    required this.productName,
    required this.uom,
    required this.orderQuantity,
    required this.rate,
    required this.orderValue,
    required this.speciality,
    required this.dispatchQuantity,
    required this.pendingQuantity,
    required this.pendingValue,
    required this.bngwhInStock,
    required this.rjpmwhInStock,
    required this.boxQty,
    required this.soStatus,
    required this.mrp,
    required this.priority,
    required this.branchName,
    required this.warehouse,
    required this.warehouseQty,
    required this.expectedTimeofDelivey,
    required this.overDueDays,
    required this.paymentTerms,
    required this.remark,
    required this.gracePeriodTerms,
    required this.expectedPayment,
    required this.bomStatus,
    required this.barCode,
    required this.overDue,
  });

  factory SODetailsList.fromJson(Map<String, dynamic> json) {
    return SODetailsList(
      soDate: json['soDate'],
      soNo: json['soNo'],
      poDate: json['poDate'],
      poNo: json['poNo'],
      customerCode: json['customerCode'],
      customerName: json['customerName'],
      customerGroup: json['customerGroup'],
      bpGroup: json['bpGroup'],
      customerCity: json['customerCity'],
      customerState: json['customerState'],
      countryZone: json['countryZone'],
      salesRep: json['salesRep'],
      salesManager: json['salesManager'],
      regionalManager: json['regionalManager'],
      groupName: json['groupName'],
      itemSubGroup: json['itemSubGroup'],
      itemSubSubGroup: json['itemSubSubGroup'],
      productCode: json['productCode'],
      productName: json['productName'],
      uom: json['uom'],
      orderQuantity: json['orderQuantity'],
      rate: json['rate'],
      orderValue: json['orderValue'],
      speciality: json['speciality'],
      dispatchQuantity: json['dispatchQuantity'],
      pendingQuantity: json['pendingQuantity'],
      pendingValue: json['pendingValue'],
      bngwhInStock: json['bngwhInStock'],
      rjpmwhInStock: json['rjpmwhInStock'],
      boxQty: json['boxQty'],
      soStatus: json['soStatus'],
      mrp: json['mrp'],
      priority: json['priority'],
      branchName: json['branchName'],
      warehouse: json['warehouse'],
      warehouseQty: json['warehouseQty'],
      expectedTimeofDelivey: json['expectedTimeofDelivey'],
      overDueDays: json['overDueDays'],
      paymentTerms: json['paymentTerms'],
      remark: json['remark'],
      gracePeriodTerms: json['gracePeriodTerms'],
      expectedPayment: json['expectedPayment'],
      bomStatus: json['bomStatus'],
      barCode: json['barCode'],
      overDue: json['overDue'],
    );
  }
}

class MonthlySalesOrderList {
  final List<MonthlySalesOrderData> soData;
  MonthlySalesOrderList({required this.soData});
}

class MonthlySalesOrderData {
  final String monthName;
  final double salesOrderAmount;
  final double salesOrderTarget;
  MonthlySalesOrderData({
    required this.monthName,
    required this.salesOrderAmount,
    required this.salesOrderTarget,
  });
}

String formatAmount(double amount) {
  bool isNegative = amount < 0;

  double positiveAmount = amount.abs();

  if (positiveAmount >= 10000000) {
    String formattedAmount =
        '${(positiveAmount / 10000000).toStringAsFixed(2)} Cr';
    return isNegative ? '-$formattedAmount' : formattedAmount;
  } else if (positiveAmount >= 100000) {
    String formattedAmount =
        '${(positiveAmount / 100000).toStringAsFixed(2)} L';
    return isNegative ? '-$formattedAmount' : formattedAmount;
  } else {
    String formattedAmount = '${(positiveAmount / 1000).toStringAsFixed(2)} K';
    return isNegative ? '-$formattedAmount' : formattedAmount;
  }
}

String formatCount(double count) {
  if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(2)} K';
  } else {
    return count.toString();
  }
}

String customAxisTitleFormatter(double value) {
  // Convert value from millions to lakhs or crores
  return formatAmount(value);
}

class OpenSOAgingList {
  final List<OpenSOAgingData> soAgingData;
  OpenSOAgingList({required this.soAgingData});
}

class OpenSOAgingData {
  final double percentage;
  final String group;
  final double receivableAmount;
  final double maxY;
  OpenSOAgingData({
    required this.receivableAmount,
    required this.percentage,
    required this.group,
    required this.maxY,
  });
}

class RsmVisitData {
  final int rsmId;
  final String rsmName;
  final int visitCount;
  final int visitPeriod;
  RsmVisitData({
    required this.rsmId,
    required this.rsmName,
    required this.visitCount,
    required this.visitPeriod,
  });
}

class RsmVisitList {
  final List<RsmVisitData> rsmvisitData;
  RsmVisitList({required this.rsmvisitData});
}

class AsmVisitData {
  final int asmId;
  final String asmName;
  final int visitCount;
  final int visitPeriod;
  AsmVisitData({
    required this.asmId,
    required this.asmName,
    required this.visitCount,
    required this.visitPeriod,
  });
}

class AsmVisitList {
  final List<AsmVisitData> asmvisitData;
  AsmVisitList({required this.asmvisitData});
}

class TsmVisitData {
  final int tsmId;
  final String tsmName;
  final int visitCount;
  final int visitPeriod;
  TsmVisitData({
    required this.tsmId,
    required this.tsmName,
    required this.visitCount,
    required this.visitPeriod,
  });
}

class TsmVisitList {
  final List<TsmVisitData> tsmvisitData;
  TsmVisitList({required this.tsmvisitData});
}

class DailyVisitData {
  final int userId;
  final String dateName;
  final int visitCount;
  final int userCount;
  DailyVisitData({
    required this.userId,
    required this.dateName,
    required this.visitCount,
    required this.userCount,
  });
}

class DailyVisitList {
  final List<DailyVisitData> dailyVisitData;
  DailyVisitList({required this.dailyVisitData});
}

class DailyVisitDataSummary {
  final String visitDate;
  final int visitCount;
  final int userId;
  final String userName;
  final int userLevel;
  final int visitPeriod;
  final String accountName;
  final String productName;
  final int productCount;
  final int focusedProducts;
  final int regularProducts;
  final int focusedAverage;
  final int regularAverage;
  DailyVisitDataSummary({
    required this.visitDate,
    required this.visitCount,
    required this.userId,
    required this.userName,
    required this.userLevel,
    required this.visitPeriod,
    required this.accountName,
    required this.productName,
    required this.productCount,
    required this.focusedProducts,
    required this.regularProducts,
    required this.focusedAverage,
    required this.regularAverage,
  });
}

class DailyVisitSummaryList {
  final List<DailyVisitDataSummary> dailyVisitDataSummary;
  DailyVisitSummaryList({required this.dailyVisitDataSummary});
}

extension DateExtensions on DateTime {
  bool isAtLeast(DateTime other) {
    return isAfter(other) || isAtSameMomentAs(other);
  }

  bool isAtMost(DateTime other) {
    return isBefore(other) || isAtSameMomentAs(other);
  }
}

class NumberOfVisitsAccWiseData {
  final String accountName;
  final int accountCount;
  NumberOfVisitsAccWiseData({
    required this.accountName,
    required this.accountCount,
  });
}

class NumberOfVisitsAccWiseList {
  final List<NumberOfVisitsAccWiseData> visitAccWiseData;
  NumberOfVisitsAccWiseList({required this.visitAccWiseData});
}

class ProductWisePromotionAnalysisData {
  final String productName;
  final int productCount;
  ProductWisePromotionAnalysisData({
    required this.productName,
    required this.productCount,
  });
}

class ProductWisePromotionAnalysisList {
  final List<ProductWisePromotionAnalysisData> productWisePromotionData;
  ProductWisePromotionAnalysisList({required this.productWisePromotionData});
}

class PromotionAnalysisData {
  final String chartCaption;
  final int chartValue;
  final int chartAverage;
  PromotionAnalysisData({
    required this.chartCaption,
    required this.chartValue,
    required this.chartAverage,
  });
}

class PromotionAnalysisDataList {
  final List<PromotionAnalysisData> promotionAnalysisData;
  PromotionAnalysisDataList({required this.promotionAnalysisData});
}

class RsmMenu {
  final String menuName;
  final int menuId;
  RsmMenu(this.menuName, this.menuId);
}

class AsmMenu {
  final String menuName;
  final int menuId;
  AsmMenu(this.menuName, this.menuId);
}

class VisitAnalysisData {
  final int leadID;
  final String visitDate;
  final String visitTime;
  final int visitCount;
  final int userId;
  final String userName;
  final int userLevel;
  final String accountName;
  final String leadActivitySummary;
  final String visitType;
  final String productCategory;
  final String productName;
  final String participantName;
  final String leadActivityLatitude;
  final String leadActivityLongitude;
  final String leadActivityLocation;
  final String leadActivityCheckin;
  final String leadActivityCheckout;
  final String leadActivityInLocation;
  final String leadInputMaterials;

  VisitAnalysisData({
    required this.leadID,
    required this.visitDate,
    required this.visitTime,
    required this.visitCount,
    required this.userId,
    required this.userName,
    required this.userLevel,
    required this.accountName,
    required this.leadActivitySummary,
    required this.visitType,
    required this.productCategory,
    required this.productName,
    required this.participantName,
    required this.leadActivityLatitude,
    required this.leadActivityLongitude,
    required this.leadActivityLocation,
    required this.leadActivityCheckin,
    required this.leadActivityCheckout,
    required this.leadActivityInLocation,
    required this.leadInputMaterials,
  });

  factory VisitAnalysisData.fromJson(Map<String, dynamic> j) {
    return VisitAnalysisData(
      leadID: int.tryParse(j['LeadID']?.toString() ?? '0') ?? 0,
      visitDate: j['VisitDate'] ?? '',
      visitTime: j['VisitTime'] ?? '',
      visitCount: j['VisitCount'] ?? 0,
      userId: int.tryParse(j['UserId']?.toString() ?? '0') ?? 0,
      userName: j['UserName'] ?? '',
      userLevel: j['UserLevel'] ?? 0,
      accountName: j['AccountName'] ?? '',
      leadActivitySummary: j['LeadActivitySummary'] ?? '',
      visitType: j['VisitType'] ?? '',
      productCategory: j['ProductCategory'] ?? '',
      productName: j['ProductName'] ?? '',
      participantName: j['ParticipantName'] ?? '',
      leadActivityLatitude: j['LeadActivityLatitude'] ?? '',
      leadActivityLongitude: j['LeadActivityLongitude'] ?? '',
      leadActivityLocation: j['LeadActivityLocation'] ?? '',
      leadActivityCheckin: j['LeadActivityCheckin'] ?? '',
      leadActivityCheckout: j['LeadActivityCheckout'] ?? '',
      leadActivityInLocation: j['LeadActivityInLocation'] ?? '',
      leadInputMaterials: j['LeadInputMaterials'] ?? '',
    );
  }
}

class VisitAnalysisList {
  final List<VisitAnalysisData> visitAnalysisData;
  VisitAnalysisList({required this.visitAnalysisData});
}

class AttendanceData {
  final int employeeId;
  final String employeeName;
  final String reportingEmployeeName;
  final Map<String, String> days;
  AttendanceData({
    required this.employeeId,
    required this.employeeName,
    required this.reportingEmployeeName,
    Map<String, String>? days,
  }) : days = days ?? {};

  void setAttendance(String day, String status) {
    days[day] = status;
  }

  String getAttendance(String day) {
    return days[day] ?? '';
  }
}

class AttendanceList {
  final List<AttendanceData> attendanceData;
  AttendanceList({required this.attendanceData});
}

class LeadAnalysisData {
  final String leadCustomerName;
  final int leadID;
  final String leadStageLevel;
  final String leadStartDate;
  final String leadAging;
  final DateTime? leadEntryDate;
  final String leadActivityType;
  final String leadFollowupTime;
  final String leadFollowupDate;
  final String leadStatus;
  final String leadStage7Status;
  LeadAnalysisData({
    required this.leadCustomerName,
    required this.leadID,
    required this.leadStageLevel,
    required this.leadStartDate,
    required this.leadAging,
    required this.leadEntryDate,
    required this.leadActivityType,
    required this.leadFollowupTime,
    required this.leadFollowupDate,
    required this.leadStatus,
    required this.leadStage7Status,
  });
}

class LeadAnalysisList {
  final List<LeadAnalysisData> leadAnalysisData;
  LeadAnalysisList({required this.leadAnalysisData});
}

class LeadStatusData {
  final String leadID;
  final String leadCustomerCode;
  final String leadStatus;
  final String stage1;
  final String stage2;
  final String stage3;
  final String stage4;
  final String stage5;
  final String stage6;
  LeadStatusData({
    required this.leadID,
    required this.leadCustomerCode,
    required this.leadStatus,
    required this.stage1,
    required this.stage2,
    required this.stage3,
    required this.stage4,
    required this.stage5,
    required this.stage6,
  });
}

class LeadStatusList {
  final List<LeadStatusData> leadStatusData;
  LeadStatusList({required this.leadStatusData});
}

class ReceivablesFinanceList {
  final List<ReceivablesFinanceData> agingData;
  ReceivablesFinanceList({required this.agingData});
}

class ReceivablesFinanceData {
  final String agingGroup;
  double agingPercentage;
  double agingGroupTotal;
  double agingTotal;
  ReceivablesFinanceData({
    required this.agingGroup,
    required this.agingPercentage,
    required this.agingGroupTotal,
    required this.agingTotal,
  });
}

class LeadStageData {
  final int leadID;
  final String leadCustomerCode;
  final double leadOpenCount;
  final double leadCloseCount;
  final double leadWonCount;
  final int leadStageNumber;
  final String leadStageLevel;
  LeadStageData({
    required this.leadID,
    required this.leadCustomerCode,
    required this.leadOpenCount,
    required this.leadCloseCount,
    required this.leadWonCount,
    required this.leadStageNumber,
    required this.leadStageLevel,
  });
}

class LeadStageList {
  final List<LeadStageData> leadStageData;
  LeadStageList({required this.leadStageData});
}

class AdvanceFromCustomersList {
  final List<AdvanceFromCustomersData> agingData;
  AdvanceFromCustomersList({required this.agingData});
}

class AdvanceFromCustomersData {
  final String agingGroup;
  double agingPercentage;
  double agingGroupTotal;
  double agingTotal;
  AdvanceFromCustomersData({
    required this.agingGroup,
    required this.agingPercentage,
    required this.agingGroupTotal,
    required this.agingTotal,
  });
}

class CustomerAnalysisFinanceList {
  final List<CustomerAnalysisFinanceData> customerData;
  CustomerAnalysisFinanceList({required this.customerData});
}

class CustomerAnalysisFinanceData {
  final String customerCode;
  final String customerName;
  final double collectionAmount;
  CustomerAnalysisFinanceData({
    required this.customerCode,
    required this.customerName,
    required this.collectionAmount,
  });
}

class CashFlowList {
  final String documentNo;
  final String postingDate;
  final String dueDate;
  final String documentDate;
  final String transactionType;
  final String accountCode;
  final String accountName;
  final String code;
  final String name;
  final String obBalance;
  final String debitAmount;
  final String creditAmount;
  final String clBalance;
  final String reference1;
  final String reference2;
  final String reference3;
  final String remarks;
  final String category;
  late DateTime postingDateParsed;

  CashFlowList({
    required this.documentNo,
    required this.postingDate,
    required this.dueDate,
    required this.documentDate,
    required this.transactionType,
    required this.accountCode,
    required this.accountName,
    required this.code,
    required this.name,
    required this.obBalance,
    required this.debitAmount,
    required this.creditAmount,
    required this.clBalance,
    required this.reference1,
    required this.reference2,
    required this.reference3,
    required this.remarks,
    required this.category,
  });

  factory CashFlowList.fromJson(Map<String, dynamic> json) {
    return CashFlowList(
      documentNo: json['documentNo'],
      postingDate: json['postingDate'],
      dueDate: json['dueDate'],
      documentDate: json['documentDate'],
      transactionType: json['transactionType'],
      accountCode: json['accountCode'],
      accountName: json['accountName'],
      code: json['code'],
      name: json['name'],
      obBalance: json['obBalance'],
      debitAmount: json['debitAmount'],
      creditAmount: json['creditAmount'],
      clBalance: json['clBalance'],
      reference1: json['reference1'],
      reference2: json['reference2'],
      reference3: json['reference3'],
      remarks: json['remarks'],
      category: json['category'],
    );
  }
}

class MonthlyAnalysisCashFlowList {
  final List<MonthlyAnalysisCashFlowData> monthData;
  MonthlyAnalysisCashFlowList({required this.monthData});
}

class MonthlyAnalysisCashFlowData {
  final String monthName;
  final double sumOfCr;
  final double sumOfDr;
  final double closingBalance;
  final double openingBalance;
  MonthlyAnalysisCashFlowData({
    required this.monthName,
    required this.sumOfCr,
    required this.sumOfDr,
    required this.closingBalance,
    required this.openingBalance,
  });
}

class LedgerAnalysisCashFlowList {
  final List<LedgerAnalysisCashFlowData> ledgerData;
  LedgerAnalysisCashFlowList({required this.ledgerData});
}

class LedgerAnalysisCashFlowData {
  final String ledgerName;
  final double ledgerBalance;
  final String ledgerType;
  final double? sumOfCr;
  final double? sumOfDr;
  final double? openingBal;
  final double? closingBal;
  LedgerAnalysisCashFlowData({
    required this.ledgerName,
    required this.ledgerBalance,
    required this.ledgerType,
    this.sumOfCr,
    this.sumOfDr,
    this.openingBal,
    this.closingBal,
  });
}

class DailyMovementCashFlowList {
  final List<DailyMovementCashFlowData> dailyData;
  DailyMovementCashFlowList({required this.dailyData});
}

class DailyMovementCashFlowData {
  final String date;
  final double sumOfCr;
  final double sumOfDr;
  final double closingBalance;
  final double openingBalance;
  DailyMovementCashFlowData({
    required this.date,
    required this.sumOfCr,
    required this.sumOfDr,
    required this.closingBalance,
    required this.openingBalance,
  });
}

class ExpensesList {
  final String group;
  final String subGroup;
  final String accountCode;
  final String accountName;
  final String openingBalance;
  final String monthYear;
  final String debit;
  final String credit;
  final String balance;
  final String closingBalance;
  final String category;
  final String foreignName;
  final String subSubGroup;

  ExpensesList({
    required this.group,
    required this.subGroup,
    required this.accountCode,
    required this.accountName,
    required this.openingBalance,
    required this.monthYear,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.closingBalance,
    required this.category,
    required this.foreignName,
    required this.subSubGroup,
  });

  factory ExpensesList.fromJson(Map<String, dynamic> json) {
    return ExpensesList(
      group: json['group'],
      subGroup: json['subGroup'],
      accountCode: json['accountCode'],
      accountName: json['accountName'],
      openingBalance: json['openingBalance'],
      monthYear: json['monthYear'],
      debit: json['debit'],
      credit: json['credit'],
      balance: json['balance'],
      closingBalance: json['closingBalance'],
      category: json['category'],
      foreignName: json['foreignName'],
      subSubGroup: json['subSubGroup'],
    );
  }
}

class GroupWiseAnalysisExpensesList {
  final List<GroupWiseAnalysisExpensesData> groupData;
  GroupWiseAnalysisExpensesList({required this.groupData});
}

class GroupWiseAnalysisExpensesData {
  final String groupName;
  double balance;
  GroupWiseAnalysisExpensesData({
    required this.groupName,
    required this.balance,
  });
}

class SubGroupWiseAnalysisExpensesList {
  final List<SubGroupWiseAnalysisExpensesData> subGroupData;
  SubGroupWiseAnalysisExpensesList({required this.subGroupData});
}

class SubGroupWiseAnalysisExpensesData {
  final String subGroupName;
  double balance;
  SubGroupWiseAnalysisExpensesData({
    required this.subGroupName,
    required this.balance,
  });
}

class SubSubGroupWiseAnalysisExpensesList {
  final List<SubSubGroupWiseAnalysisExpensesData> subSubGroupData;
  SubSubGroupWiseAnalysisExpensesList({required this.subSubGroupData});
}

class SubSubGroupWiseAnalysisExpensesData {
  final String subSubGroupName;
  double balance;
  SubSubGroupWiseAnalysisExpensesData({
    required this.subSubGroupName,
    required this.balance,
  });
}

class DailyAnalysisExpensesList {
  final List<DailyAnalysisExpensesData> dailyData;
  DailyAnalysisExpensesList({required this.dailyData});
}

class DailyAnalysisExpensesData {
  final String date;
  double balance;
  double? target;
  DailyAnalysisExpensesData({
    required this.date,
    required this.balance,
    this.target,
  });
}

class PayablesList {
  final String vendorGroup;
  final String vendorCode;
  final String vendorName;
  final String creditLimit;
  final String postingDate;
  final String documentNumber;
  final String documentRefNo;
  final String accountBalance;
  final String invoiceIssues;
  final String expectedPayment;
  final String expectedPaymentRemarks;
  final String lastPaymentDate;
  final String documentType;
  final String paymentTermsDays;
  final String paymentTerms;
  final String dueon;
  final String dueDays;
  final String balance;
  final String ageingBrackets;
  final String future;
  final String a0to30Days;
  final String a31to60Days;
  final String a61to90Days;
  final String a91to180Days;
  final String a181Days;
  final String bpSubGroup;
  late String commitment;

  late DateTime postingDateParsed;
  late int overDueDayAdvance;
  late double overDueDayReceivables;
  late double balanceParsed;

  PayablesList({
    required this.vendorGroup,
    required this.vendorCode,
    required this.vendorName,
    required this.creditLimit,
    required this.postingDate,
    required this.documentNumber,
    required this.documentRefNo,
    required this.accountBalance,
    required this.invoiceIssues,
    required this.expectedPayment,
    required this.expectedPaymentRemarks,
    required this.lastPaymentDate,
    required this.documentType,
    required this.paymentTermsDays,
    required this.paymentTerms,
    required this.dueon,
    required this.dueDays,
    required this.balance,
    required this.ageingBrackets,
    required this.future,
    required this.a0to30Days,
    required this.a31to60Days,
    required this.a61to90Days,
    required this.a91to180Days,
    required this.a181Days,
    required this.bpSubGroup,
    required this.commitment,
  });

  factory PayablesList.fromJson(Map<String, dynamic> json) {
    return PayablesList(
      vendorGroup: json['vendorGroup'],
      vendorCode: json['vendorCode'],
      vendorName: json['vendorName'],
      creditLimit: json['creditLimit'],
      postingDate: json['postingDate'],
      documentNumber: json['documentNumber'],
      documentRefNo: json['documentRefNo'],
      accountBalance: json['accountBalance'],
      invoiceIssues: json['invoiceIssues'],
      expectedPayment: json['expectedPayment'],
      expectedPaymentRemarks: json['expectedPaymentRemarks'],
      lastPaymentDate: json['lastPaymentDate'],
      documentType: json['documentType'],
      paymentTermsDays: json['paymentTermsDays'],
      paymentTerms: json['paymentTerms'],
      dueon: json['dueon'],
      dueDays: json['dueDays'],
      balance: json['balance'],
      ageingBrackets: json['ageingBrackets'],
      future: json['future'],
      a0to30Days: json['a0to30Days'],
      a31to60Days: json['a31to60Days'],
      a61to90Days: json['a61to90Days'],
      a91to180Days: json['a91to180Days'],
      a181Days: json['a181Days'],
      bpSubGroup: json['bpSubGroup'],
      commitment: json['commitment'],
    );
  }
}

class PayablesGraphList {
  final List<PayablesGraphData> agingData;
  PayablesGraphList({required this.agingData});
}

class PayablesGraphData {
  final String agingGroup;
  double agingPercentage;
  double agingGroupTotal;
  double agingTotal;
  PayablesGraphData({
    required this.agingGroup,
    required this.agingPercentage,
    required this.agingGroupTotal,
    required this.agingTotal,
  });
}

class AdvancePaidToSupplierPayablesList {
  final List<AdvancePaidToSupplierPayablesData> agingData;
  AdvancePaidToSupplierPayablesList({required this.agingData});
}

class AdvancePaidToSupplierPayablesData {
  final String agingGroup;
  double agingPercentage;
  double agingGroupTotal;
  double agingTotal;
  AdvancePaidToSupplierPayablesData({
    required this.agingGroup,
    required this.agingPercentage,
    required this.agingGroupTotal,
    required this.agingTotal,
  });
}

class SupplierAnalysisPayablesList {
  final List<SupplierAnalysisPayablesData> supplierData;
  SupplierAnalysisPayablesList({required this.supplierData});
}

class SupplierAnalysisPayablesData {
  final String supplierName;
  double balance;
  double? actualPaid;
  SupplierAnalysisPayablesData({
    required this.supplierName,
    required this.balance,
    this.actualPaid,
  });
}

class SupplierCategoryWiseAnalysisPayablesList {
  final List<SupplierCategoryWiseAnalysisPayablesData> supplierCategoryData;
  SupplierCategoryWiseAnalysisPayablesList({
    required this.supplierCategoryData,
  });
}

class SupplierCategoryWiseAnalysisPayablesData {
  final String supplierCategoryName;
  double balance;
  double? actualPaid;
  double? commitment;
  SupplierCategoryWiseAnalysisPayablesData({
    required this.supplierCategoryName,
    required this.balance,
    this.actualPaid,
    this.commitment,
  });
}

class DocumentTypeList {
  final List<DocumentTypeData> documentData;
  DocumentTypeList({required this.documentData});
}

class DocumentTypeData {
  final String documentType;
  double balance;
  DocumentTypeData({required this.documentType, required this.balance});
}

class InventoryList {
  final String itemNo;
  final String itemDescription;
  final String warehouseCode;
  final String warehouseName;
  final String groupName;
  final String itemSubGroup;
  final String uom;
  final String ageingBrackets;
  final String totalQuantity;
  final String totalValue;

  InventoryList({
    required this.itemNo,
    required this.itemDescription,
    required this.warehouseCode,
    required this.warehouseName,
    required this.groupName,
    required this.itemSubGroup,
    required this.uom,
    required this.ageingBrackets,
    required this.totalQuantity,
    required this.totalValue,
  });

  factory InventoryList.fromJson(Map<String, dynamic> json) {
    return InventoryList(
      itemNo: json['itemNo'],
      itemDescription: json['itemDescription'],
      warehouseCode: json['warehouseCode'],
      warehouseName: json['warehouseName'],
      groupName: json['groupName'],
      itemSubGroup: json['itemSubGroup'],
      uom: json['uom'],
      ageingBrackets: json['ageingBrackets'],
      totalQuantity: json['totalQuantity'],
      totalValue: json['totalValue'],
    );
  }
}

class InventoryLevelList {
  final String documentDate;
  final String groupName;
  final String itemSubGroup;
  final String itemNo;
  final String itemDescription;
  final String uom;
  final String batchNumber;
  final String mfgDate;
  final String expDate;
  final String bpName;
  final String boxQty;
  final String quantity;
  final String price;
  final String value;
  final String warehouseCode;
  final String warehouseName;
  final String mfgAgeingDays;
  final String mfgAgeingBrackets;
  final String inStock;
  final String minInventory;
  final String maxInventory;
  final String mainWHInStock;
  final String minInventoryDiff;
  final String maxInventoryDiff;

  InventoryLevelList({
    required this.documentDate,
    required this.groupName,
    required this.itemSubGroup,
    required this.itemNo,
    required this.itemDescription,
    required this.uom,
    required this.batchNumber,
    required this.mfgDate,
    required this.expDate,
    required this.bpName,
    required this.boxQty,
    required this.quantity,
    required this.price,
    required this.value,
    required this.warehouseCode,
    required this.warehouseName,
    required this.mfgAgeingDays,
    required this.mfgAgeingBrackets,
    required this.inStock,
    required this.minInventory,
    required this.maxInventory,
    required this.mainWHInStock,
    required this.minInventoryDiff,
    required this.maxInventoryDiff,
  });

  factory InventoryLevelList.fromJson(Map<String, dynamic> json) {
    return InventoryLevelList(
      documentDate: json['documentDate'],
      groupName: json['groupName'],
      itemSubGroup: json['itemSubGroup'],
      itemNo: json['itemNo'],
      itemDescription: json['itemDescription'],
      uom: json['uom'],
      batchNumber: json['batchNumber'],
      mfgDate: json['mfgDate'],
      expDate: json['expDate'],
      bpName: json['bpName'],
      boxQty: json['boxQty'],
      quantity: json['quantity'],
      price: json['price'],
      value: json['value'],
      warehouseCode: json['warehouseCode'],
      warehouseName: json['warehouseName'],
      mfgAgeingDays: json['mfgAgeingDays'],
      mfgAgeingBrackets: json['mfgAgeingBrackets'],
      inStock: json['inStock'],
      minInventory: json['minInventory'],
      maxInventory: json['maxInventory'],
      mainWHInStock: json['mainWHInStock'],
      minInventoryDiff: json['minInventoryDiff'],
      maxInventoryDiff: json['maxInventoryDiff'],
    );
  }
}

class InventoryAgingSummary {
  double a0to30DaysTotal = 0;
  double a31to45DaysTotal = 0;
  double a46to60DaysTotal = 0;
  double a61to90DaysTotal = 0;
  double a91to120DaysTotal = 0;
  double a121to150DaysTotal = 0;
  double a151to180DaysTotal = 0;
  double a181to365DaysTotal = 0;
  double a366to730DaysTotal = 0;
  double a730DaysTotal = 0;
}

class InventoryAgingSummaryMISReport {
  double a0to30DaysTotalQty = 0;
  double a0to30DaysTotalVal = 0;
  double a31to45DaysTotalQty = 0;
  double a31to45DaysTotalVal = 0;
  double a46to60DaysTotalQty = 0;
  double a46to60DaysTotalVal = 0;
  double a61to90DaysTotalQty = 0;
  double a61to90DaysTotalVal = 0;
  double a91to120DaysTotalQty = 0;
  double a91to120DaysTotalVal = 0;
  double a121to150DaysTotalQty = 0;
  double a121to150DaysTotalVal = 0;
  double a151to180DaysTotalQty = 0;
  double a151to180DaysTotalVal = 0;
  double a181to365DaysTotalQty = 0;
  double a181to365DaysTotalVal = 0;
  double a366to730DaysTotalQty = 0;
  double a366to730DaysTotalVal = 0;
  double a730DaysTotalQty = 0;
  double a730DaysTotalVal = 0;
}

class InventoryAgingList {
  final List<InventoryAgingData> agingData;
  InventoryAgingList({required this.agingData});
}

class InventoryAgingData {
  final String agingGroup;
  double agingTotal;
  InventoryAgingData({required this.agingGroup, required this.agingTotal});
}

class InventoryAgingMISList {
  final List<InventoryAgingMISData> agingData;
  InventoryAgingMISList({required this.agingData});
}

class InventoryAgingMISData {
  final String agingGroup;
  double agingTotalQty;
  double agingTotalVal;
  InventoryAgingMISData({
    required this.agingGroup,
    required this.agingTotalQty,
    required this.agingTotalVal,
  });
}

class WarehouseInventoryList {
  final List<WarehouseInventoryData> warehouseData;
  WarehouseInventoryList({required this.warehouseData});
}

class WarehouseInventoryData {
  final String warehouseCode;
  final String warehouseName;
  final double quantity;
  final double? targetMinimumStockValue;
  final double? actualMinimumStockValue;
  final double? excessValue;
  final double? stockValueOtherThanMinValue;
  final double? totalStockValue;
  final double? targetVsActualValuePercent;
  WarehouseInventoryData({
    required this.warehouseCode,
    required this.warehouseName,
    required this.quantity,
    this.targetMinimumStockValue,
    this.actualMinimumStockValue,
    this.excessValue,
    this.stockValueOtherThanMinValue,
    this.totalStockValue,
    this.targetVsActualValuePercent,
  });
}

class InventoryLevelGraphList {
  final List<InventoryLevelGraphData> levelData;
  InventoryLevelGraphList({required this.levelData});
}

class InventoryLevelGraphData {
  final String itemName;
  final double minLevel;
  final double maxLevel;
  final double inStock;
  final double total;
  InventoryLevelGraphData({
    required this.itemName,
    required this.minLevel,
    required this.maxLevel,
    required this.inStock,
    required this.total,
  });
}

class ItemGroupWiseInventoryList {
  final List<ItemGroupWiseInventoryData> itemGroupData;
  ItemGroupWiseInventoryList({required this.itemGroupData});
}

class ItemGroupWiseInventoryData {
  final String groupName;
  final double quantity;
  ItemGroupWiseInventoryData({required this.groupName, required this.quantity});
}

class ItemGroupWiseInventoryMISList {
  final List<ItemGroupWiseInventoryMISData> itemGroupData;
  ItemGroupWiseInventoryMISList({required this.itemGroupData});
}

class ItemGroupAgeingMISData {
  final String groupName;
  final String ageingBracket;
  final double totalQuantity;
  final double totalValue;

  ItemGroupAgeingMISData({
    required this.groupName,
    required this.ageingBracket,
    required this.totalQuantity,
    required this.totalValue,
  });
}

class ItemGroupAgeingMISList {
  final List<ItemGroupAgeingMISData> items;
  ItemGroupAgeingMISList({required this.items});
}

class ItemGroupWiseInventoryMISData {
  final String groupName;
  final double quantity;
  final double value;
  ItemGroupWiseInventoryMISData({
    required this.groupName,
    required this.quantity,
    required this.value,
  });
}

class ItemSubGroupWiseInventoryList {
  final List<ItemSubGroupWiseInventoryData> itemSubGroupData;
  ItemSubGroupWiseInventoryList({required this.itemSubGroupData});
}

class ItemSubGroupWiseInventoryData {
  final String subGroupName;
  final double quantity;
  ItemSubGroupWiseInventoryData({
    required this.subGroupName,
    required this.quantity,
  });
}

class PurchaseList {
  final String invoiceType;
  final String purchaseType;
  final String type;
  final String invoiceNo;
  final String invoiceDate;
  final String refNo;
  final String termsofDelivery;
  final String dispatchThrough;
  final String destinationDetails;
  final String vendorCode;
  final String vendorName;
  final String vendorGroup;
  final String vendorCity;
  final String vendorState;
  final String itemGroup;
  final String itemSubGroup;
  final String description;
  final String uom;
  final String quantity;
  final String currency;
  final String currencyRate;
  final String price;
  final String taxCode;
  final String rowTotal;
  final String documentTotal;
  final String branchName;
  final String whsCode;

  PurchaseList({
    required this.invoiceType,
    required this.purchaseType,
    required this.type,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.refNo,
    required this.termsofDelivery,
    required this.dispatchThrough,
    required this.destinationDetails,
    required this.vendorCode,
    required this.vendorName,
    required this.vendorGroup,
    required this.vendorCity,
    required this.vendorState,
    required this.itemGroup,
    required this.itemSubGroup,
    required this.description,
    required this.uom,
    required this.quantity,
    required this.currency,
    required this.currencyRate,
    required this.price,
    required this.taxCode,
    required this.rowTotal,
    required this.documentTotal,
    required this.branchName,
    required this.whsCode,
  });

  factory PurchaseList.fromJson(Map<String, dynamic> json) {
    return PurchaseList(
      invoiceType: json['invoiceType'],
      purchaseType: json['purchaseType'],
      type: json['type'],
      invoiceNo: json['invoiceNo'],
      invoiceDate: json['invoiceDate'],
      refNo: json['refNo'],
      termsofDelivery: json['termsofDelivery'],
      dispatchThrough: json['dispatchThrough'],
      destinationDetails: json['destinationDetails'],
      vendorCode: json['vendorCode'],
      vendorName: json['vendorName'],
      vendorGroup: json['vendorGroup'],
      vendorCity: json['vendorCity'],
      vendorState: json['vendorState'],
      itemGroup: json['itemGroup'],
      itemSubGroup: json['itemSubGroup'],
      description: json['description'],
      uom: json['uom'],
      quantity: json['quantity'],
      currency: json['currency'],
      currencyRate: json['currencyRate'],
      price: json['price'],
      taxCode: json['taxCode'],
      rowTotal: json['rowTotal'],
      documentTotal: json['documentTotal'],
      branchName: json['branchName'],
      whsCode: json['whsCode'],
    );
  }
}

class MonthlyPurchaseList {
  final List<MonthlyPurchaseData> monthlyData;
  MonthlyPurchaseList({required this.monthlyData});
}

class MonthlyPurchaseData {
  final String monthName;
  final double collectionAmount;
  MonthlyPurchaseData({
    required this.monthName,
    required this.collectionAmount,
  });
}

class PurchaseItemAnalysisList {
  final List<PurchaseItemAnalysisData> productData;
  PurchaseItemAnalysisList({required this.productData});
}

class PurchaseItemAnalysisData {
  final String productName;
  final double salesAmount;
  final double monthsAvg;
  PurchaseItemAnalysisData({
    required this.productName,
    required this.salesAmount,
    required this.monthsAvg,
  });
}

class PurchaseItemGroupWiseAnalysisList {
  final List<PurchaseItemGroupWiseAnalysisData> productGroupData;
  PurchaseItemGroupWiseAnalysisList({required this.productGroupData});
}

class PurchaseItemGroupWiseAnalysisData {
  final String groupName;
  final double salesAmount;
  PurchaseItemGroupWiseAnalysisData({
    required this.groupName,
    required this.salesAmount,
  });
}

class PurchaseItemSubGroupWiseAnalysisList {
  final List<PurchaseItemSubGroupWiseAnalysisData> productSubGroupData;
  PurchaseItemSubGroupWiseAnalysisList({required this.productSubGroupData});
}

class PurchaseItemSubGroupWiseAnalysisData {
  final String itemSubGroup;
  final double salesAmount;
  PurchaseItemSubGroupWiseAnalysisData({
    required this.itemSubGroup,
    required this.salesAmount,
  });
}

class PurchaseBranchAnalysisList {
  final List<PurchaseBranchAnalysisData> branchData;
  PurchaseBranchAnalysisList({required this.branchData});
}

class PurchaseBranchAnalysisData {
  final String branchName;
  final double rowTotal;
  final double monthAvg;
  PurchaseBranchAnalysisData({
    required this.branchName,
    required this.rowTotal,
    required this.monthAvg,
  });
}

class PurchaseSupplierAnalysisList {
  final List<PurchaseSupplierAnalysisData> supplierData;
  PurchaseSupplierAnalysisList({required this.supplierData});
}

class PurchaseSupplierAnalysisData {
  final String supplierName;
  final double rowTotal;
  final double monthAvg;
  PurchaseSupplierAnalysisData({
    required this.supplierName,
    required this.rowTotal,
    required this.monthAvg,
  });
}

class PurchaseSupplierStateWiseAnalysisList {
  final List<PurchaseSupplierStateWiseAnalysisData> supplierStateData;
  PurchaseSupplierStateWiseAnalysisList({required this.supplierStateData});
}

class PurchaseSupplierStateWiseAnalysisData {
  final String vendorState;
  final double rowTotal;
  final double monthAvg;
  PurchaseSupplierStateWiseAnalysisData({
    required this.vendorState,
    required this.rowTotal,
    required this.monthAvg,
  });
}

class PurchaseSupplierCityWiseAnalysisList {
  final List<PurchaseSupplierCityWiseAnalysisData> supplierCityData;
  PurchaseSupplierCityWiseAnalysisList({required this.supplierCityData});
}

class PurchaseSupplierCityWiseAnalysisData {
  final String vendorCity;
  final double rowTotal;
  final double monthAvg;
  PurchaseSupplierCityWiseAnalysisData({
    required this.vendorCity,
    required this.rowTotal,
    required this.monthAvg,
  });
}

class PurchaseSupplierCategoryWiseAnalysisList {
  final List<PurchaseSupplierCategoryWiseAnalysisData> supplierCategoryData;
  PurchaseSupplierCategoryWiseAnalysisList({
    required this.supplierCategoryData,
  });
}

class PurchaseSupplierCategoryWiseAnalysisData {
  final int categoryId;
  final String supplierCategory;
  double percentage;
  final double amount;
  PurchaseSupplierCategoryWiseAnalysisData({
    required this.supplierCategory,
    required this.categoryId,
    required this.percentage,
    required this.amount,
  });
}

class POList {
  final String type;
  final String poDate;
  final String poNo;
  final String vendorCode;
  final String vendorName;
  final String vendorCity;
  final String vendorState;
  final String groupName;
  final String itemSubGroup;
  final String code;
  final String description;
  final String uom;
  final String orderQuantity;
  final String rate;
  final String orderValue;
  final String dispatchQuantity;
  final String pendingQuantity;
  final String pendingValue;
  final String poStatus;
  final String priority;
  final String branchName;
  final String warehouse;
  final String warehouseQty;
  final String expectedTimeofDelivey;
  final String overDueDays;
  final String agingDays;
  final String paymentTermsDays;
  final String paymentTerms;
  final String remark;

  POList({
    required this.type,
    required this.poDate,
    required this.poNo,
    required this.vendorCode,
    required this.vendorName,
    required this.vendorCity,
    required this.vendorState,
    required this.groupName,
    required this.itemSubGroup,
    required this.code,
    required this.description,
    required this.uom,
    required this.orderQuantity,
    required this.rate,
    required this.orderValue,
    required this.dispatchQuantity,
    required this.pendingQuantity,
    required this.pendingValue,
    required this.poStatus,
    required this.priority,
    required this.branchName,
    required this.warehouse,
    required this.warehouseQty,
    required this.expectedTimeofDelivey,
    required this.overDueDays,
    required this.agingDays,
    required this.paymentTermsDays,
    required this.paymentTerms,
    required this.remark,
  });

  factory POList.fromJson(Map<String, dynamic> json) {
    return POList(
      type: json['type'],
      poDate: json['poDate'],
      poNo: json['poNo'],
      vendorCode: json['vendorCode'],
      vendorName: json['vendorName'],
      vendorCity: json['vendorCity'],
      vendorState: json['vendorState'],
      groupName: json['groupName'],
      itemSubGroup: json['itemSubGroup'],
      code: json['code'],
      description: json['description'],
      uom: json['uom'],
      orderQuantity: json['orderQuantity'],
      rate: json['rate'],
      orderValue: json['orderValue'],
      dispatchQuantity: json['dispatchQuantity'],
      pendingQuantity: json['pendingQuantity'],
      pendingValue: json['pendingValue'],
      poStatus: json['poStatus'],
      priority: json['priority'],
      branchName: json['branchName'],
      warehouse: json['warehouse'],
      warehouseQty: json['warehouseQty'],
      expectedTimeofDelivey: json['expectedTimeofDelivey'],
      overDueDays: json['overDueDays'],
      agingDays: json['agingDays'],
      paymentTermsDays: json['paymentTermsDays'],
      paymentTerms: json['paymentTerms'],
      remark: json['remark'],
    );
  }
}

class POMonthWiseList {
  final List<POMonthWiseData> monthlyData;
  POMonthWiseList({required this.monthlyData});
}

class POMonthWiseData {
  final String monthName;
  final double collectionAmount;
  POMonthWiseData({required this.monthName, required this.collectionAmount});
}

class OpenPOAgingList {
  final List<OpenPOAgingData> soAgingData;
  OpenPOAgingList({required this.soAgingData});
}

class OpenPOAgingData {
  final double percentage;
  final String group;
  final double receivableAmount;
  final double maxY;
  OpenPOAgingData({
    required this.receivableAmount,
    required this.percentage,
    required this.group,
    required this.maxY,
  });
}

class POItemAnalysisList {
  final List<POItemAnalysisData> productData;
  POItemAnalysisList({required this.productData});
}

class POItemAnalysisData {
  final String productName;
  final double salesAmount;
  final double monthsAvg;
  POItemAnalysisData({
    required this.productName,
    required this.salesAmount,
    required this.monthsAvg,
  });
}

class POItemGroupWiseAnalysisList {
  final List<POItemGroupWiseAnalysisData> productData;
  POItemGroupWiseAnalysisList({required this.productData});
}

class POItemGroupWiseAnalysisData {
  final String productGroupName;
  final double salesAmount;
  final double monthsAvg;
  POItemGroupWiseAnalysisData({
    required this.productGroupName,
    required this.salesAmount,
    required this.monthsAvg,
  });
}

class POItemSubGroupWiseAnalysisList {
  final List<POItemSubGroupWiseAnalysisData> productData;
  POItemSubGroupWiseAnalysisList({required this.productData});
}

class POItemSubGroupWiseAnalysisData {
  final String productSubGroupName;
  final double salesAmount;
  final double monthsAvg;
  POItemSubGroupWiseAnalysisData({
    required this.productSubGroupName,
    required this.salesAmount,
    required this.monthsAvg,
  });
}

class POBranchAnalysisList {
  final List<POBranchAnalysisData> branchData;
  POBranchAnalysisList({required this.branchData});
}

class POBranchAnalysisData {
  final String branchName;
  final double salesAmount;
  final double monthsAvg;
  POBranchAnalysisData({
    required this.branchName,
    required this.salesAmount,
    required this.monthsAvg,
  });
}

class POWarehouseWiseAnalysisList {
  final List<POWarehouseWiseAnalysisData> warehouseData;
  POWarehouseWiseAnalysisList({required this.warehouseData});
}

class POWarehouseWiseAnalysisData {
  final String warehouseName;
  final double salesAmount;
  final double monthsAvg;
  POWarehouseWiseAnalysisData({
    required this.warehouseName,
    required this.salesAmount,
    required this.monthsAvg,
  });
}

class POSupplierAnalysisList {
  final List<POSupplierAnalysisData> supplierData;
  POSupplierAnalysisList({required this.supplierData});
}

class POSupplierAnalysisData {
  final String supplierName;
  final double salesAmount;
  final double monthsAvg;
  POSupplierAnalysisData({
    required this.supplierName,
    required this.salesAmount,
    required this.monthsAvg,
  });
}

class POSupplierStateWiseAnalysisList {
  final List<POSupplierStateWiseAnalysisData> supplierStateData;
  POSupplierStateWiseAnalysisList({required this.supplierStateData});
}

class POSupplierStateWiseAnalysisData {
  final String supplierStateName;
  final double salesAmount;
  final double monthsAvg;
  POSupplierStateWiseAnalysisData({
    required this.supplierStateName,
    required this.salesAmount,
    required this.monthsAvg,
  });
}

class POSupplierCityWiseAnalysisList {
  final List<POSupplierCityWiseAnalysisData> supplierCityData;
  POSupplierCityWiseAnalysisList({required this.supplierCityData});
}

class POSupplierCityWiseAnalysisData {
  final String supplierCityName;
  final double salesAmount;
  final double monthsAvg;
  POSupplierCityWiseAnalysisData({
    required this.supplierCityName,
    required this.salesAmount,
    required this.monthsAvg,
  });
}

class PaymentAnalysisList {
  final String vendorGroup;
  final String vendorCode;
  final String vendorName;
  final String creditLimit;
  final String postingDate;
  final String documentNumber;
  final String documentRefNo;
  final String accountBalance;
  final String invoiceIssues;
  final String expectedPayment;
  final String expectedPaymentRemarks;
  final String lastPaymentDate;
  final String documentType;
  final String paymentTermsDays;
  final String paymentTerms;
  final String dueon;
  final String dueDays;
  final String balance;
  final String ageingBrackets;
  final String future;
  final String a0to30Days;
  final String a31to60Days;
  final String a61to90Days;
  final String a91to180Days;
  final String a181Days;

  PaymentAnalysisList({
    required this.vendorGroup,
    required this.vendorCode,
    required this.vendorName,
    required this.creditLimit,
    required this.postingDate,
    required this.documentNumber,
    required this.documentRefNo,
    required this.accountBalance,
    required this.invoiceIssues,
    required this.expectedPayment,
    required this.expectedPaymentRemarks,
    required this.lastPaymentDate,
    required this.documentType,
    required this.paymentTermsDays,
    required this.paymentTerms,
    required this.dueon,
    required this.dueDays,
    required this.balance,
    required this.ageingBrackets,
    required this.future,
    required this.a0to30Days,
    required this.a31to60Days,
    required this.a61to90Days,
    required this.a91to180Days,
    required this.a181Days,
  });

  factory PaymentAnalysisList.fromJson(Map<String, dynamic> json) {
    return PaymentAnalysisList(
      vendorGroup: json['vendorGroup'],
      vendorCode: json['vendorCode'],
      vendorName: json['vendorName'],
      creditLimit: json['creditLimit'],
      postingDate: json['postingDate'],
      documentNumber: json['documentNumber'],
      documentRefNo: json['documentRefNo'],
      accountBalance: json['accountBalance'],
      invoiceIssues: json['invoiceIssues'],
      expectedPayment: json['expectedPayment'],
      expectedPaymentRemarks: json['expectedPaymentRemarks'],
      lastPaymentDate: json['lastPaymentDate'],
      documentType: json['documentType'],
      paymentTermsDays: json['paymentTermsDays'],
      paymentTerms: json['paymentTerms'],
      dueon: json['dueon'],
      dueDays: json['dueDays'],
      balance: json['balance'],
      ageingBrackets: json['ageingBrackets'],
      future: json['future'],
      a0to30Days: json['a0to30Days'],
      a31to60Days: json['a31to60Days'],
      a61to90Days: json['a61to90Days'],
      a91to180Days: json['a91to180Days'],
      a181Days: json['a181Days'],
    );
  }
}

class PaymentMonthWiseList {
  final List<PaymentMonthWiseData> monthlyData;
  PaymentMonthWiseList({required this.monthlyData});
}

class PaymentMonthWiseData {
  final String monthName;
  final double collectionAmount;
  PaymentMonthWiseData({
    required this.monthName,
    required this.collectionAmount,
  });
}

class PaymentSupplierAnalysisList {
  final List<PaymentSupplierAnalysisData> supplierData;
  PaymentSupplierAnalysisList({required this.supplierData});
}

class PaymentSupplierAnalysisData {
  final String supplierName;
  final double salesAmount;
  final double monthsAvg;
  PaymentSupplierAnalysisData({
    required this.supplierName,
    required this.salesAmount,
    required this.monthsAvg,
  });
}

class PaymentSupplierCategoryAnalysisList {
  final List<PaymentSupplierCategoryAnalysisData> supplierCategoryData;
  PaymentSupplierCategoryAnalysisList({required this.supplierCategoryData});
}

class PaymentSupplierCategoryAnalysisData {
  final String supplierCategoryName;
  final double salesAmount;
  final double monthsAvg;
  PaymentSupplierCategoryAnalysisData({
    required this.supplierCategoryName,
    required this.salesAmount,
    required this.monthsAvg,
  });
}

class PaymentPayableAgingList {
  final List<PaymentPayableAgingData> agingData;
  PaymentPayableAgingList({required this.agingData});
}

class PaymentPayableAgingData {
  final String agingGroup;
  double agingPercentage;
  double agingGroupTotal;
  double agingTotal;
  PaymentPayableAgingData({
    required this.agingGroup,
    required this.agingPercentage,
    required this.agingGroupTotal,
    required this.agingTotal,
  });
}

class ModeOfPaymentList {
  final String documentNo;
  final String postingDate;
  final String sapInvoiceNo;
  final String sapInvoiceDate;
  final String vendorInvoiceNo;
  final String vendorInvoiceDate;
  final String vendorGroup;
  final String paymentTermsDays;
  final String paymentTerms;
  final String vendorCode;
  final String vendorName;
  final String modeofPayment;
  final String total;
  final String documentTotal;
  final String remarks;
  final String bpSubGroup;
  late DateTime postingDateParsed;

  ModeOfPaymentList({
    required this.documentNo,
    required this.postingDate,
    required this.sapInvoiceNo,
    required this.sapInvoiceDate,
    required this.vendorInvoiceNo,
    required this.vendorInvoiceDate,
    required this.vendorGroup,
    required this.paymentTermsDays,
    required this.paymentTerms,
    required this.vendorCode,
    required this.vendorName,
    required this.modeofPayment,
    required this.total,
    required this.documentTotal,
    required this.remarks,
    required this.bpSubGroup,
  });

  factory ModeOfPaymentList.fromJson(Map<String, dynamic> json) {
    return ModeOfPaymentList(
      documentNo: json['documentNo'],
      postingDate: json['postingDate'],
      sapInvoiceNo: json['sapInvoiceNo'],
      sapInvoiceDate: json['sapInvoiceDate'],
      vendorInvoiceNo: json['vendorInvoiceNo'],
      vendorInvoiceDate: json['vendorInvoiceDate'],
      vendorGroup: json['vendorGroup'],
      paymentTermsDays: json['paymentTermsDays'],
      paymentTerms: json['paymentTerms'],
      vendorCode: json['vendorCode'],
      vendorName: json['vendorName'],
      modeofPayment: json['modeofPayment'],
      total: json['total'],
      documentTotal: json['documentTotal'],
      remarks: json['remarks'],
      bpSubGroup: json['bpSubGroup'],
    );
  }
}

class PaymentModeOfPaymentGraphList {
  final List<PaymentModeOfPaymentGraphData> modeOfPaymentData;
  PaymentModeOfPaymentGraphList({required this.modeOfPaymentData});
}

class PaymentModeOfPaymentGraphData {
  final String modeOfPayment;
  final double salesAmount;
  final double monthsAvg;
  PaymentModeOfPaymentGraphData({
    required this.modeOfPayment,
    required this.salesAmount,
    required this.monthsAvg,
  });
}

class ProductionOrderList {
  final String orderNo;
  final String orderDate;
  final String plant;
  final String unit;
  final String branch;
  final String shift;
  final String customerCode;
  final String customerName;
  final String productCode;
  final String productDescription;
  final String groupName;
  final String itemSubGroup;
  final String uom;
  final String boxQty;
  final String plannedQty;
  final String completedQty;
  final String rejectedQty;
  final String status;
  final String soNo;
  final String soDate;
  final String proStartDate;
  final String proClosingDate;
  final String proDueDate;
  final String agingDays;
  final String kitRefNo;
  final String sterileStatus;
  final String batchNo;
  final String manfDate;
  final String expDate;
  final String dcNo;

  final DateTime? parsedOrderDate;

  ProductionOrderList({
    required this.orderNo,
    required this.orderDate,
    required this.plant,
    required this.unit,
    required this.branch,
    required this.shift,
    required this.customerCode,
    required this.customerName,
    required this.productCode,
    required this.productDescription,
    required this.groupName,
    required this.itemSubGroup,
    required this.uom,
    required this.boxQty,
    required this.plannedQty,
    required this.completedQty,
    required this.rejectedQty,
    required this.status,
    required this.soNo,
    required this.soDate,
    required this.proStartDate,
    required this.proClosingDate,
    required this.proDueDate,
    required this.agingDays,
    required this.kitRefNo,
    required this.sterileStatus,
    required this.batchNo,
    required this.manfDate,
    required this.expDate,
    required this.dcNo,
    required this.parsedOrderDate,
  });

  factory ProductionOrderList.fromJson(Map<String, dynamic> json) {
    final orderDate = (json['orderDate'] ?? '').toString();

    return ProductionOrderList(
      orderNo: (json['orderNo'] ?? '').toString(),
      orderDate: orderDate,
      plant: (json['plant'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      branch: (json['branch'] ?? '').toString(),
      shift: (json['shift'] ?? '').toString(),
      customerCode: (json['customerCode'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      productCode: (json['productCode'] ?? '').toString(),
      productDescription: (json['productDescription'] ?? '').toString(),
      groupName: (json['groupName'] ?? '').toString(),
      itemSubGroup: (json['itemSubGroup'] ?? '').toString(),
      uom: (json['uom'] ?? '').toString(),
      boxQty: (json['boxQty'] ?? '').toString(),
      plannedQty: (json['plannedQty'] ?? '').toString(),
      completedQty: (json['completedQty'] ?? '').toString(),
      rejectedQty: (json['rejectedQty'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      soNo: (json['soNo'] ?? '').toString(),
      soDate: (json['soDate'] ?? '').toString(),
      proStartDate: (json['proStartDate'] ?? '').toString(),
      proClosingDate: (json['proClosingDate'] ?? '').toString(),
      proDueDate: (json['proDueDate'] ?? '').toString(),
      agingDays: (json['agingDays'] ?? '').toString(),
      kitRefNo: (json['kitRefNo'] ?? '').toString(),
      sterileStatus: (json['sterileStatus'] ?? '').toString(),
      batchNo: (json['batchNo'] ?? '').toString(),
      manfDate: (json['manfDate'] ?? '').toString(),
      expDate: (json['expDate'] ?? '').toString(),
      dcNo: (json['dcNo'] ?? '').toString(),

      parsedOrderDate: orderDate.isNotEmpty
          ? DateFormat('dd/MM/yyyy').parseStrict(orderDate)
          : null,
    );
  }
}

class RCPList {
  final String plant;
  final String unit;
  final String wsmpp;
  final String costPerBox;
  final String date;
  final String shiftA;
  final String shiftB;
  final String shiftC;
  final String overTime;

  RCPList({
    required this.plant,
    required this.unit,
    required this.wsmpp,
    required this.costPerBox,
    required this.date,
    required this.shiftA,
    required this.shiftB,
    required this.shiftC,
    required this.overTime,
  });

  factory RCPList.fromJson(Map<String, dynamic> json) {
    return RCPList(
      plant: json['plant'],
      unit: json['unit'],
      wsmpp: json['wsmpp'],
      costPerBox: json['costPerBox'],
      date: json['date'],
      shiftA: json['shiftA'],
      shiftB: json['shiftB'],
      shiftC: json['shiftC'],
      overTime: json['overTime'],
    );
  }
}

// class MonthlyCTCList {
//   final int? CTCDetailsId;
//   final int? NoOfDays;
//   final int? TotalAmount;
//   final int? TotalPresentLabour;
//   final int? AvgMonthlyGrossSalaryPerHead;
//   final int? EmployerPFContribution;
//   final int? AnnualBonus;
//   final int? EmployerESIContribution;
//   final int? TotalAvgMonthlyCTCPerHead;
//   final int? TotalMonthlyGrossSalaryInclOT;
//   final int? ProductionIncentive;
//   final int? OverTime;
//   final int? IncrementArears;
//   final int? TotalManPower;
//   final int? AverageWorkForce;
//   final String? UserId;
//   final String? MonthYear;
//   final String? Department;
//
//   MonthlyCTCList({
//     this.CTCDetailsId,
//     this.NoOfDays,
//     this.TotalAmount,
//     this.TotalPresentLabour,
//     this.AvgMonthlyGrossSalaryPerHead,
//     this.EmployerPFContribution,
//     this.AnnualBonus,
//     this.EmployerESIContribution,
//     this.TotalAvgMonthlyCTCPerHead,
//     this.TotalMonthlyGrossSalaryInclOT,
//     this.ProductionIncentive,
//     this.OverTime,
//     this.IncrementArears,
//     this.TotalManPower,
//     this.AverageWorkForce,
//     this.UserId,
//     this.Department,
//     this.MonthYear,
//   });
//
//   // Helper: parse a dynamic value into int? safely
//   static int? _toInt(dynamic v) {
//     if (v == null) return null;
//     if (v is int) return v;
//     if (v is double) return v.toInt();
//     if (v is String) return int.tryParse(v);
//     if (v is num) return v.toInt();
//     return null;
//   }
//
//   // Helper: convert to string if not null
//   static String? _toStr(dynamic v) => v == null ? null : v.toString();
//
//   factory MonthlyCTCList.fromJson(Map<String, dynamic> json) {
//     return MonthlyCTCList(
//       CTCDetailsId: _toInt(json['CTCDetailsId']),
//       NoOfDays: _toInt(json['NoOfDays']),
//       TotalAmount: _toInt(json['TotalAmount']),
//       TotalPresentLabour: _toInt(json['TotalPresentLabour']),
//       AvgMonthlyGrossSalaryPerHead: _toInt(json['AvgMonthlyGrossSalaryPerHead']),
//       EmployerPFContribution: _toInt(json['EmployerPFContribution']),
//       AnnualBonus: _toInt(json['AnnualBonus']),
//       EmployerESIContribution: _toInt(json['EmployerESIContribution']),
//       TotalAvgMonthlyCTCPerHead: _toInt(json['TotalAvgMonthlyCTCPerHead']),
//       TotalMonthlyGrossSalaryInclOT: _toInt(json['TotalMonthlyGrossSalaryInclOT']),
//       ProductionIncentive: _toInt(json['ProductionIncentive']),
//       OverTime: _toInt(json['OverTime']),
//       IncrementArears: _toInt(json['IncrementArears']),
//       TotalManPower: _toInt(json['TotalManPower']),
//       AverageWorkForce: _toInt(json['AverageWorkForce']),
//       UserId: _toStr(json['UserId']),
//       Department: _toStr(json['Department']),
//       MonthYear: _toStr(json['MonthYear']),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'CTCDetailsId': CTCDetailsId,
//       'NoOfDays': NoOfDays,
//       'TotalAmount': TotalAmount,
//       'TotalPresentLabour': TotalPresentLabour,
//       'AvgMonthlyGrossSalaryPerHead': AvgMonthlyGrossSalaryPerHead,
//       'EmployerPFContribution': EmployerPFContribution,
//       'AnnualBonus': AnnualBonus,
//       'EmployerESIContribution': EmployerESIContribution,
//       'TotalAvgMonthlyCTCPerHead': TotalAvgMonthlyCTCPerHead,
//       'TotalMonthlyGrossSalaryInclOT': TotalMonthlyGrossSalaryInclOT,
//       'ProductionIncentive': ProductionIncentive,
//       'OverTime': OverTime,
//       'IncrementArears': IncrementArears,
//       'TotalManPower': TotalManPower,
//       'AverageWorkForce': AverageWorkForce,
//       'UserId': UserId,
//       'Department': Department,
//       'MonthYear': MonthYear,
//     };
//   }
//
//   static List<MonthlyCTCList> listFromJson(dynamic json) {
//     if (json == null) return <MonthlyCTCList>[];
//
//     if (json is List) {
//       return json
//           .where((e) => e != null)
//           .map((e) => MonthlyCTCList.fromJson(e as Map<String, dynamic>))
//           .toList();
//     }
//
//     if (json is Map && json['data'] is List) {
//       final list = json['data'] as List;
//       return list
//           .where((e) => e != null)
//           .map((e) => MonthlyCTCList.fromJson(e as Map<String, dynamic>))
//           .toList();
//     }
//
//     // fallback
//     return <MonthlyCTCList>[];
//   }
// }

class MonthlyCTCList {
  final int CTCDetailsId;
  final int NoOfDays;
  final int TotalAmount;
  final int TotalPresentLabour;
  final int AvgMonthlyGrossSalaryPerHead;
  final int EmployerPFContribution;
  final int AnnualBonus;
  final int EmployerESIContribution;
  final int TotalAvgMonthlyCTCPerHead;
  final int TotalMonthlyGrossSalaryInclOT;
  final int ProductionIncentive;
  final int OverTime;
  final int IncrementArears;
  final int TotalManPower;
  final int AverageWorkForce;
  final String UserId;
  final String MonthYear;
  final String Department;

  MonthlyCTCList({
    required this.CTCDetailsId,
    required this.NoOfDays,
    required this.TotalAmount,
    required this.TotalPresentLabour,
    required this.AvgMonthlyGrossSalaryPerHead,
    required this.EmployerPFContribution,
    required this.AnnualBonus,
    required this.EmployerESIContribution,
    required this.TotalAvgMonthlyCTCPerHead,
    required this.TotalMonthlyGrossSalaryInclOT,
    required this.ProductionIncentive,
    required this.OverTime,
    required this.IncrementArears,
    required this.TotalManPower,
    required this.AverageWorkForce,
    required this.UserId,
    required this.Department,
    required this.MonthYear,
  });

  // helper to parse ints reliably
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // helper to parse strings
  static String _toStr(dynamic v) => v?.toString() ?? '';

  factory MonthlyCTCList.fromJson(Map<String, dynamic> json) {
    return MonthlyCTCList(
      CTCDetailsId: _toInt(json['CTCDetailsId']),
      NoOfDays: _toInt(json['NoOfDays']),
      TotalAmount: _toInt(json['TotalAmount']),
      TotalPresentLabour: _toInt(json['TotalPresentLabour']),
      AvgMonthlyGrossSalaryPerHead: _toInt(
        json['AvgMonthlyGrossSalaryPerHead'],
      ),
      EmployerPFContribution: _toInt(json['EmployerPFContribution']),
      AnnualBonus: _toInt(json['AnnualBonus']),
      EmployerESIContribution: _toInt(json['EmployerESIContribution']),
      TotalAvgMonthlyCTCPerHead: _toInt(json['TotalAvgMonthlyCTCPerHead']),
      TotalMonthlyGrossSalaryInclOT: _toInt(
        json['TotalMonthlyGrossSalaryInclOT'],
      ),
      ProductionIncentive: _toInt(json['ProductionIncentive']),
      OverTime: _toInt(json['OverTime']),
      IncrementArears: _toInt(json['IncrementArears']),
      TotalManPower: _toInt(json['TotalManPower']),
      AverageWorkForce: _toInt(json['AverageWorkForce']),
      UserId: _toStr(json['UserId']),
      Department: _toStr(json['Department']),
      MonthYear: _toStr(json['MonthYear']),
    );
  }
}

class CheckinData {
  final String checkinDate;
  final String checkinUserName;
  final String checkinTime;
  final String checkoutTime;
  final String checkinDuration;
  CheckinData({
    required this.checkinDate,
    required this.checkinUserName,
    required this.checkinTime,
    required this.checkoutTime,
    required this.checkinDuration,
  });
}

class CheckinsDataList {
  final List<CheckinData> checkinData;
  CheckinsDataList({required this.checkinData});
}

class InventoryTypeSlowDeadList {
  final List<InventoryTypeSlowDeadData> inventoryType;
  InventoryTypeSlowDeadList({required this.inventoryType});
}

class InventoryTypeSlowDeadData {
  final String groupName;
  final double quantity;
  InventoryTypeSlowDeadData({required this.groupName, required this.quantity});
}

class InventoryItemWiseSlowDeadList {
  final List<InventoryItemWiseSlowDeadData> itemData;
  InventoryItemWiseSlowDeadList({required this.itemData});
}

class InventoryItemWiseSlowDeadData {
  final String itemName;
  final double quantity;
  InventoryItemWiseSlowDeadData({
    required this.itemName,
    required this.quantity,
  });
}

class InventoryItemGroupWiseSlowDeadList {
  final List<InventoryItemGroupWiseSlowDeadData> itemGroupData;
  InventoryItemGroupWiseSlowDeadList({required this.itemGroupData});
}

class InventoryItemGroupWiseSlowDeadData {
  final String itemGroupName;
  final double quantity;
  InventoryItemGroupWiseSlowDeadData({
    required this.itemGroupName,
    required this.quantity,
  });
}

class MonthlyProductionList {
  final List<MonthlyProductionData> monthlyData;
  MonthlyProductionList({required this.monthlyData});
}

class MonthlyProductionData {
  final String monthName;
  final double target;
  final double production;
  final int? boxNo;
  MonthlyProductionData({
    required this.monthName,
    required this.target,
    required this.production,
    this.boxNo,
  });
}

class DailyProductionList {
  final List<DailyProductionData> dailyData;
  DailyProductionList({required this.dailyData});
}

class DailyProductionData {
  final DateTime date;
  final String dayLabel; // e.g. "01 Aug"
  final double production; // sum of completedQty for that day
  final int boxNo; // summed boxes for that day (rounded)

  DailyProductionData({
    required this.date,
    required this.dayLabel,
    required this.production,
    required this.boxNo,
  });
}

class ItemWiseProductionList {
  final List<ItemWiseProductionData> itemWiseData;
  ItemWiseProductionList({required this.itemWiseData});
}

class ItemWiseProductionData {
  final String itemName;
  final double productionActual;
  final double production3Month;
  ItemWiseProductionData({
    required this.itemName,
    required this.productionActual,
    required this.production3Month,
  });
}

class BranchWiseProductionList {
  final List<BranchWiseProductionData> branchWiseData;
  BranchWiseProductionList({required this.branchWiseData});
}

class BranchWiseProductionData {
  final String branchName;
  final double productionActual;
  final double production3Month;
  BranchWiseProductionData({
    required this.branchName,
    required this.productionActual,
    required this.production3Month,
  });
}

class ItemGroupWiseProductionList {
  final List<ItemGroupWiseProductionData> itemGroupWiseData;
  ItemGroupWiseProductionList({required this.itemGroupWiseData});
}

class ItemGroupWiseProductionData {
  final String itemGroupName;
  final double productionActual;
  final double production3Month;
  ItemGroupWiseProductionData({
    required this.itemGroupName,
    required this.productionActual,
    required this.production3Month,
  });
}

class ItemSubGroupWiseProductionList {
  final List<ItemSubGroupWiseProductionData> itemSubGroupWiseData;
  ItemSubGroupWiseProductionList({required this.itemSubGroupWiseData});
}

class ItemSubGroupWiseProductionData {
  final String itemSubGroupName;
  final double productionActual;
  final double production3Month;
  ItemSubGroupWiseProductionData({
    required this.itemSubGroupName,
    required this.productionActual,
    required this.production3Month,
  });
}

class PlantWiseProductionList {
  final List<PlantWiseProductionData> plantData;
  PlantWiseProductionList({required this.plantData});
}

class PlantWiseProductionData {
  final String plantName;
  final double productionActual;
  final double production3Month;
  PlantWiseProductionData({
    required this.plantName,
    required this.productionActual,
    required this.production3Month,
  });
}

class UnitWiseProductionList {
  final List<UnitWiseProductionData> unitData;
  UnitWiseProductionList({required this.unitData});
}

class UnitWiseProductionData {
  final String unitName;
  final double productionActual;
  final double production3Month;
  UnitWiseProductionData({
    required this.unitName,
    required this.productionActual,
    required this.production3Month,
  });
}

class ShiftWiseProductionList {
  final List<ShiftWiseProductionData> shiftData;
  ShiftWiseProductionList({required this.shiftData});
}

class ShiftWiseProductionData {
  final String shiftName;
  final double productionActual;
  final double production3Month;
  ShiftWiseProductionData({
    required this.shiftName,
    required this.productionActual,
    required this.production3Month,
  });
}

class OpenProductionOrderList {
  final String orderNo;
  final String orderDate;
  final String plant;
  final String unit;
  final String branch;
  final String shift;
  final String customerCode;
  final String customerName;
  final String productCode;
  final String productDescription;
  final String groupName;
  final String itemSubGroup;
  final String uom;
  final String boxQty;
  final String plannedQty;
  final String completedQty;
  final String rejectedQty;
  final String status;
  final String soNo;
  final String soDate;
  final String proStartDate;
  final String proClosingDate;
  final String proDueDate;
  final String agingDays;
  final String kitRefNo;
  final String sterileStatus;
  final String batchNo;
  final String manfDate;
  final String expDate;
  final String dcNo;

  OpenProductionOrderList({
    required this.orderNo,
    required this.orderDate,
    required this.plant,
    required this.unit,
    required this.branch,
    required this.shift,
    required this.customerCode,
    required this.customerName,
    required this.productCode,
    required this.productDescription,
    required this.groupName,
    required this.itemSubGroup,
    required this.uom,
    required this.boxQty,
    required this.plannedQty,
    required this.completedQty,
    required this.rejectedQty,
    required this.status,
    required this.soNo,
    required this.soDate,
    required this.proStartDate,
    required this.proClosingDate,
    required this.proDueDate,
    required this.agingDays,
    required this.kitRefNo,
    required this.sterileStatus,
    required this.batchNo,
    required this.manfDate,
    required this.expDate,
    required this.dcNo,
  });

  factory OpenProductionOrderList.fromJson(Map<String, dynamic> json) {
    return OpenProductionOrderList(
      orderNo: json['orderNo'],
      orderDate: json['orderDate'],
      plant: json['plant'],
      unit: json['unit'],
      branch: json['branch'],
      shift: json['shift'],
      customerCode: json['customerCode'],
      customerName: json['customerName'],
      productCode: json['productCode'],
      productDescription: json['productDescription'],
      groupName: json['groupName'],
      itemSubGroup: json['itemSubGroup'],
      uom: json['uom'],
      boxQty: json['boxQty'],
      plannedQty: json['plannedQty'],
      completedQty: json['completedQty'],
      rejectedQty: json['rejectedQty'],
      status: json['status'],
      soNo: json['soNo'],
      soDate: json['soDate'],
      proStartDate: json['proStartDate'],
      proClosingDate: json['proClosingDate'],
      proDueDate: json['proDueDate'],
      agingDays: json['agingDays'],
      kitRefNo: json['kitRefNo'],
      sterileStatus: json['sterileStatus'],
      batchNo: json['batchNo'],
      manfDate: json['manfDate'],
      expDate: json['expDate'],
      dcNo: json['dcNo'],
    );
  }
}

class OrderStatusList {
  final List<OrderStatusData> statusData;
  OrderStatusList({required this.statusData});
}

class OrderStatusData {
  final int statusId;
  final String statusName;
  double statusAmount;
  double statusPercentage;
  OrderStatusData({
    required this.statusId,
    required this.statusName,
    required this.statusAmount,
    required this.statusPercentage,
  });
}

class AgeingAnalysisList {
  final List<AgeingAnalysisData> agingData;
  AgeingAnalysisList({required this.agingData});
}

class AgeingAnalysisData {
  final double percentage;
  final String group;
  final double receivableAmount;
  final double maxY;
  AgeingAnalysisData({
    required this.receivableAmount,
    required this.percentage,
    required this.group,
    required this.maxY,
  });
}

class ItemWiseOpenProductionList {
  final List<ItemWiseOpenProductionData> itemWiseData;
  ItemWiseOpenProductionList({required this.itemWiseData});
}

class ItemWiseOpenProductionData {
  final String itemName;
  final double productionActual;
  final double production3Month;
  ItemWiseOpenProductionData({
    required this.itemName,
    required this.productionActual,
    required this.production3Month,
  });
}

class BranchWiseOpenProductionList {
  final List<BranchWiseOpenProductionData> branchWiseData;
  BranchWiseOpenProductionList({required this.branchWiseData});
}

class BranchWiseOpenProductionData {
  final String branchName;
  final double productionActual;
  final double production3Month;
  BranchWiseOpenProductionData({
    required this.branchName,
    required this.productionActual,
    required this.production3Month,
  });
}

class ItemGroupWiseOpenProductionList {
  final List<ItemGroupWiseOpenProductionData> itemGroupWiseData;
  ItemGroupWiseOpenProductionList({required this.itemGroupWiseData});
}

class ItemGroupWiseOpenProductionData {
  final String itemGroupName;
  final double productionActual;
  final double production3Month;
  ItemGroupWiseOpenProductionData({
    required this.itemGroupName,
    required this.productionActual,
    required this.production3Month,
  });
}

class ItemSubGroupWiseOpenProductionList {
  final List<ItemSubGroupWiseOpenProductionData> itemSubGroupWiseData;
  ItemSubGroupWiseOpenProductionList({required this.itemSubGroupWiseData});
}

class ItemSubGroupWiseOpenProductionData {
  final String itemSubGroupName;
  final double productionActual;
  final double production3Month;
  ItemSubGroupWiseOpenProductionData({
    required this.itemSubGroupName,
    required this.productionActual,
    required this.production3Month,
  });
}

class OrderStatusOpenList {
  final List<OrderStatusOpenData> statusData;
  OrderStatusOpenList({required this.statusData});
}

class OrderStatusOpenData {
  final int statusId;
  final String statusName;
  double statusAmount;
  double statusPercentage;
  OrderStatusOpenData({
    required this.statusId,
    required this.statusName,
    required this.statusAmount,
    required this.statusPercentage,
  });
}

class PlantWiseOpenProductionList {
  final List<PlantWiseOpenProductionData> plantData;
  PlantWiseOpenProductionList({required this.plantData});
}

class PlantWiseOpenProductionData {
  final String plantName;
  final double productionActual;
  final double production3Month;
  PlantWiseOpenProductionData({
    required this.plantName,
    required this.productionActual,
    required this.production3Month,
  });
}

class UnitWiseOpenProductionList {
  final List<UnitWiseOpenProductionData> unitData;
  UnitWiseOpenProductionList({required this.unitData});
}

class UnitWiseOpenProductionData {
  final String unitName;
  final double productionActual;
  final double production3Month;
  UnitWiseOpenProductionData({
    required this.unitName,
    required this.productionActual,
    required this.production3Month,
  });
}

class ShiftWiseOpenProductionList {
  final List<ShiftWiseOpenProductionData> shiftData;
  ShiftWiseOpenProductionList({required this.shiftData});
}

class ShiftWiseOpenProductionData {
  final String shiftName;
  final double productionActual;
  final double production3Month;
  ShiftWiseOpenProductionData({
    required this.shiftName,
    required this.productionActual,
    required this.production3Month,
  });
}

class ConsumptionList {
  final String documentNo;
  final String documentDate;
  final String groupName;
  final String itemSubGroup;
  final String itemNo;
  final String itemDescription;
  final String uom;
  final String quantity;
  final String price;
  final String lineTotal;
  final String documentTotal;
  final String branchName;
  final String warehouseCode;
  final String warehouseName;
  final String remarks;

  ConsumptionList({
    required this.documentNo,
    required this.documentDate,
    required this.groupName,
    required this.itemSubGroup,
    required this.itemNo,
    required this.itemDescription,
    required this.uom,
    required this.quantity,
    required this.price,
    required this.lineTotal,
    required this.documentTotal,
    required this.branchName,
    required this.warehouseCode,
    required this.warehouseName,
    required this.remarks,
  });

  factory ConsumptionList.fromJson(Map<String, dynamic> json) {
    return ConsumptionList(
      documentNo: json['documentNo'],
      documentDate: json['documentDate'],
      groupName: json['groupName'],
      itemSubGroup: json['itemSubGroup'],
      itemNo: json['itemNo'],
      itemDescription: json['itemDescription'],
      uom: json['uom'],
      quantity: json['quantity'],
      price: json['price'],
      lineTotal: json['lineTotal'],
      documentTotal: json['documentTotal'],
      branchName: json['branchName'],
      warehouseCode: json['warehouseCode'],
      warehouseName: json['warehouseName'],
      remarks: json['remarks'],
    );
  }
}

class ProductionList {
  final String documentNo;
  final String documentDate;
  final String groupName;
  final String itemSubGroup;
  final String itemNo;
  final String itemDescription;
  final String uom;
  final String quantity;
  final String price;
  final String lineTotal;
  final String documentTotal;
  final String branchName;
  final String warehouseCode;
  final String warehouseName;
  final String remarks;

  ProductionList({
    required this.documentNo,
    required this.documentDate,
    required this.groupName,
    required this.itemSubGroup,
    required this.itemNo,
    required this.itemDescription,
    required this.uom,
    required this.quantity,
    required this.price,
    required this.lineTotal,
    required this.documentTotal,
    required this.branchName,
    required this.warehouseCode,
    required this.warehouseName,
    required this.remarks,
  });

  factory ProductionList.fromJson(Map<String, dynamic> json) {
    return ProductionList(
      documentNo: json['documentNo'],
      documentDate: json['documentDate'],
      groupName: json['groupName'],
      itemSubGroup: json['itemSubGroup'],
      itemNo: json['itemNo'],
      itemDescription: json['itemDescription'],
      uom: json['uom'],
      quantity: json['quantity'],
      price: json['price'],
      lineTotal: json['lineTotal'],
      documentTotal: json['documentTotal'],
      branchName: json['branchName'],
      warehouseCode: json['warehouseCode'],
      warehouseName: json['warehouseName'],
      remarks: json['remarks'],
    );
  }
}

class ProductionVsConsumptionProductionList {
  final List<ProductionVsConsumptionProductionData> productionData;
  ProductionVsConsumptionProductionList({required this.productionData});
}

class ProductionVsConsumptionProductionData {
  final String monthName;
  double productionQty;
  double productionValue;
  ProductionVsConsumptionProductionData({
    required this.monthName,
    required this.productionQty,
    required this.productionValue,
  });
}

class ProductionVsConsumptionConsumptionList {
  final List<ProductionVsConsumptionConsumptionData> consumptionData;
  ProductionVsConsumptionConsumptionList({required this.consumptionData});
}

class ProductionVsConsumptionConsumptionData {
  final String monthName;
  double consumptionQty;
  double consumptionValue;
  ProductionVsConsumptionConsumptionData({
    required this.monthName,
    required this.consumptionQty,
    required this.consumptionValue,
  });
}

class ItemWiseProductionProductAnalysisList {
  final List<ItemWiseProductionProductAnalysisData> itemWiseData;
  ItemWiseProductionProductAnalysisList({required this.itemWiseData});
}

class ItemWiseProductionProductAnalysisData {
  final String itemName;
  double productionQty;
  double productionValue;
  final String remarks;
  final String groupName;
  final String subGroupName;
  ItemWiseProductionProductAnalysisData({
    required this.itemName,
    required this.productionQty,
    required this.productionValue,
    required this.remarks,
    required this.groupName,
    required this.subGroupName,
  });
}

class ItemWiseConsumptionProductAnalysisList {
  final List<ItemWiseConsumptionProductAnalysisData> itemWiseConsumptionData;
  ItemWiseConsumptionProductAnalysisList({
    required this.itemWiseConsumptionData,
  });
}

class ItemWiseConsumptionProductAnalysisData {
  final String itemName;
  double consumptionQty;
  double consumptionValue;
  ItemWiseConsumptionProductAnalysisData({
    required this.itemName,
    required this.consumptionQty,
    required this.consumptionValue,
  });
}

class ItemGroupWiseProductionProductAnalysisList {
  final List<ItemGroupWiseProductionProductAnalysisData> itemGroupWiseData;
  ItemGroupWiseProductionProductAnalysisList({required this.itemGroupWiseData});
}

class ItemGroupWiseProductionProductAnalysisData {
  final String itemGroupName;
  double productionQty;
  double productionValue;
  final String remarks;
  ItemGroupWiseProductionProductAnalysisData({
    required this.itemGroupName,
    required this.productionQty,
    required this.productionValue,
    required this.remarks,
  });
}

class ItemGroupWiseConsumptionProductAnalysisList {
  final List<ItemGroupWiseConsumptionProductAnalysisData>
  itemGroupWiseConsumptionData;
  ItemGroupWiseConsumptionProductAnalysisList({
    required this.itemGroupWiseConsumptionData,
  });
}

class ItemGroupWiseConsumptionProductAnalysisData {
  final String itemGroupName;
  double consumptionQty;
  double consumptionValue;
  ItemGroupWiseConsumptionProductAnalysisData({
    required this.itemGroupName,
    required this.consumptionQty,
    required this.consumptionValue,
  });
}

class ItemSubGroupWiseProductionProductAnalysisList {
  final List<ItemSubGroupWiseProductionProductAnalysisData>
  itemSubGroupWiseProductionData;
  ItemSubGroupWiseProductionProductAnalysisList({
    required this.itemSubGroupWiseProductionData,
  });
}

class ItemSubGroupWiseProductionProductAnalysisData {
  final String itemSubGroupName;
  double productionQty;
  double productionValue;
  final String remarks;
  ItemSubGroupWiseProductionProductAnalysisData({
    required this.itemSubGroupName,
    required this.productionQty,
    required this.productionValue,
    required this.remarks,
  });
}

class ItemSubGroupWiseConsumptionProductAnalysisList {
  final List<ItemSubGroupWiseConsumptionProductAnalysisData>
  itemSubGroupWiseConsumptionData;
  ItemSubGroupWiseConsumptionProductAnalysisList({
    required this.itemSubGroupWiseConsumptionData,
  });
}

class ItemSubGroupWiseConsumptionProductAnalysisData {
  final String itemSubGroupName;
  double consumptionQty;
  double consumptionValue;
  ItemSubGroupWiseConsumptionProductAnalysisData({
    required this.itemSubGroupName,
    required this.consumptionQty,
    required this.consumptionValue,
  });
}

class WarehouseWiseProductionList {
  final List<WarehouseWiseProductionData> warehouseWiseProductionData;
  WarehouseWiseProductionList({required this.warehouseWiseProductionData});
}

class WarehouseWiseProductionData {
  final String warehouseCode;
  final String warehouseName;
  double productionQty;
  double productionValue;
  WarehouseWiseProductionData({
    required this.warehouseCode,
    required this.warehouseName,
    required this.productionQty,
    required this.productionValue,
  });
}

class WarehouseWiseConsumptionList {
  final List<WarehouseWiseConsumptionData> warehouseWiseConsumptionData;
  WarehouseWiseConsumptionList({required this.warehouseWiseConsumptionData});
}

class WarehouseWiseConsumptionData {
  final String warehouseCode;
  final String warehouseName;
  double consumptionQty;
  double consumptionValue;
  WarehouseWiseConsumptionData({
    required this.warehouseCode,
    required this.warehouseName,
    required this.consumptionQty,
    required this.consumptionValue,
  });
}

class DailyOrderQtyAnalysisList {
  final List<DailyOrderQtyAnalysisData> dailyData;
  DailyOrderQtyAnalysisList({required this.dailyData});
}

class DailyOrderQtyAnalysisData {
  final String date;
  final double orderedQty;
  final double dispatchedQty;
  final double pendingQty;
  DailyOrderQtyAnalysisData({
    required this.date,
    required this.orderedQty,
    required this.dispatchedQty,
    required this.pendingQty,
  });
}

class HospitalWiseAnalysisList {
  final List<HospitalWiseAnalysisData> hospitalData;
  HospitalWiseAnalysisList({required this.hospitalData});
}

class HospitalWiseAnalysisData {
  final String hospitalName;
  final double orderedQty;
  final double dispatchedQty;
  final double pendingQty;
  HospitalWiseAnalysisData({
    required this.hospitalName,
    required this.orderedQty,
    required this.dispatchedQty,
    required this.pendingQty,
  });
}

class ProductWiseAnalysisList {
  final List<ProductWiseAnalysisData> productData;
  ProductWiseAnalysisList({required this.productData});
}

class ProductWiseAnalysisData {
  final String productName;
  final double orderedQty;
  final double dispatchedQty;
  final double pendingQty;
  ProductWiseAnalysisData({
    required this.productName,
    required this.orderedQty,
    required this.dispatchedQty,
    required this.pendingQty,
  });
}

class PriorityWiseAnalysisList {
  final List<PriorityWiseAnalysisData> priorityData;
  PriorityWiseAnalysisList({required this.priorityData});
}

class PriorityWiseAnalysisData {
  final int priorityId;
  final String priorityName;
  double priorityQty;
  double priorityPercentage;
  PriorityWiseAnalysisData({
    required this.priorityId,
    required this.priorityName,
    required this.priorityQty,
    required this.priorityPercentage,
  });
}

class DailyCompletedQtyAnalysisList {
  final List<DailyCompletedQtyAnalysisData> dailyData;
  DailyCompletedQtyAnalysisList({required this.dailyData});
}

class DailyCompletedQtyAnalysisData {
  final String date;
  final double completedQty;
  DailyCompletedQtyAnalysisData({
    required this.date,
    required this.completedQty,
  });
}

class DailyProducedBoxAnalysisList {
  final List<DailyProducedBoxAnalysisData> dailyProducedData;
  DailyProducedBoxAnalysisList({required this.dailyProducedData});
}

class DailyProducedBoxAnalysisData {
  final String date;
  final double producedQty;
  DailyProducedBoxAnalysisData({required this.date, required this.producedQty});
}

class ItemWiseQtyAnalysisList {
  final List<ItemWiseQtyAnalysisData> itemWiseData;
  ItemWiseQtyAnalysisList({required this.itemWiseData});
}

class ItemWiseQtyAnalysisData {
  final String itemName;
  final double plannedQty;
  final double rejectedQty;
  final double completedQty;
  ItemWiseQtyAnalysisData({
    required this.itemName,
    required this.plannedQty,
    required this.rejectedQty,
    required this.completedQty,
  });
}

class SterileStatusAnalysisList {
  final List<SterileStatusAnalysisData> sterileData;
  SterileStatusAnalysisList({required this.sterileData});
}

class SterileStatusAnalysisData {
  final int categoryId;
  final String sterileStatus;
  double percentage;
  final double amount;
  SterileStatusAnalysisData({
    required this.sterileStatus,
    required this.categoryId,
    required this.percentage,
    required this.amount,
  });
}

class DeliveryReportList {
  final String deliveryNoteNo;
  final String soDate;
  final String actualDeliveryDate;
  final String customePODate;
  final String expectedDDDate;
  final String customerPONo;
  final String soNo;
  final String customerCode;
  final String customerName;
  final String customerGroup;
  final String bpGroup;
  final String customerCity;
  final String customerState;
  final String customerCountry;
  final String countryZone;
  final String salesRep;
  final String salesManager;
  final String regionalManager;
  final String groupName;
  final String itemSubGroup;
  final String itemSubSubGroup;
  final String speciality;
  final String productCode;
  final String productName;
  final String uom;
  final String soQuantity;
  final String soRate;
  final String soValue;
  final String currency;
  final String currencyRate;
  final String dnQuantity;
  final String dnRate;
  final String dnValue;
  final String totalTax;
  final String discPrcnt;
  final String totalDiscount;
  final String totalFreightCharges;
  final String documentTotal;
  final String taxCode;
  final String hsnCode;
  final String branchName;
  final String whsCode;
  final String boxQuantity;
  final String totalNoofBoxes;
  final String totalNoofBundles;
  final String lrNo;
  final String lrDate;
  final String paymentTermsDays;
  final String paymentTerms;
  final String priority;
  final String termsofDelivery;
  final String dispatchThrough;
  final String destinationDetails;
  final String ewbNo;
  final String ewbDate;
  final String ewbTransporterName;
  final String ewbVehicleNo;
  final String status;
  final String sOtoDDLeadtime;
  final String actualDDtoEstimatedDD;
  final String pendingQuantity;
  final String mrp;
  final String leadTime;
  final String admissionDate;
  final String batchNum;
  final String mnfDate;
  final String expDate;
  final String soStatus;

  DeliveryReportList({
    required this.deliveryNoteNo,
    required this.soDate,
    required this.actualDeliveryDate,
    required this.customePODate,
    required this.expectedDDDate,
    required this.customerPONo,
    required this.soNo,
    required this.customerCode,
    required this.customerName,
    required this.customerGroup,
    required this.bpGroup,
    required this.customerCity,
    required this.customerState,
    required this.customerCountry,
    required this.countryZone,
    required this.salesRep,
    required this.salesManager,
    required this.regionalManager,
    required this.groupName,
    required this.itemSubGroup,
    required this.itemSubSubGroup,
    required this.speciality,
    required this.productCode,
    required this.productName,
    required this.uom,
    required this.soQuantity,
    required this.soRate,
    required this.soValue,
    required this.currency,
    required this.currencyRate,
    required this.dnQuantity,
    required this.dnRate,
    required this.dnValue,
    required this.totalTax,
    required this.discPrcnt,
    required this.totalDiscount,
    required this.totalFreightCharges,
    required this.documentTotal,
    required this.taxCode,
    required this.hsnCode,
    required this.branchName,
    required this.whsCode,
    required this.boxQuantity,
    required this.totalNoofBoxes,
    required this.totalNoofBundles,
    required this.lrNo,
    required this.lrDate,
    required this.paymentTermsDays,
    required this.paymentTerms,
    required this.priority,
    required this.termsofDelivery,
    required this.dispatchThrough,
    required this.destinationDetails,
    required this.ewbNo,
    required this.ewbDate,
    required this.ewbTransporterName,
    required this.ewbVehicleNo,
    required this.status,
    required this.sOtoDDLeadtime,
    required this.actualDDtoEstimatedDD,
    required this.pendingQuantity,
    required this.mrp,
    required this.leadTime,
    required this.admissionDate,
    required this.batchNum,
    required this.mnfDate,
    required this.expDate,
    required this.soStatus,
  });

  factory DeliveryReportList.fromJson(Map<String, dynamic> json) {
    return DeliveryReportList(
      deliveryNoteNo: json['deliveryNoteNo'],
      soDate: json['soDate'],
      actualDeliveryDate: json['actualDeliveryDate'],
      customePODate: json['customePODate'],
      expectedDDDate: json['expectedDDDate'],
      customerPONo: json['customerPONo'],
      soNo: json['soNo'],
      customerCode: json['customerCode'],
      customerName: json['customerName'],
      customerGroup: json['customerGroup'],
      bpGroup: json['bpGroup'],
      customerCity: json['customerCity'],
      customerState: json['customerState'],
      customerCountry: json['customerCountry'],
      countryZone: json['countryZone'],
      salesRep: json['salesRep'],
      salesManager: json['salesManager'],
      regionalManager: json['regionalManager'],
      groupName: json['groupName'],
      itemSubGroup: json['itemSubGroup'],
      itemSubSubGroup: json['itemSubSubGroup'],
      speciality: json['speciality'],
      productCode: json['productCode'],
      productName: json['productName'],
      uom: json['uom'],
      soQuantity: json['soQuantity'],
      soRate: json['soRate'],
      soValue: json['soValue'],
      currency: json['currency'],
      currencyRate: json['currencyRate'],
      dnQuantity: json['dnQuantity'],
      dnRate: json['dnRate'],
      dnValue: json['dnValue'],
      totalTax: json['totalTax'],
      discPrcnt: json['discPrcnt'],
      totalDiscount: json['totalDiscount'],
      totalFreightCharges: json['totalFreightCharges'],
      documentTotal: json['documentTotal'],
      taxCode: json['taxCode'],
      hsnCode: json['hsnCode'],
      branchName: json['branchName'],
      whsCode: json['whsCode'],
      boxQuantity: json['boxQuantity'],
      totalNoofBoxes: json['totalNoofBoxes'],
      totalNoofBundles: json['totalNoofBundles'],
      lrNo: json['lrNo'],
      lrDate: json['lrDate'],
      paymentTermsDays: json['paymentTermsDays'],
      paymentTerms: json['paymentTerms'],
      priority: json['priority'],
      termsofDelivery: json['termsofDelivery'],
      dispatchThrough: json['dispatchThrough'],
      destinationDetails: json['destinationDetails'],
      ewbNo: json['ewbNo'],
      ewbDate: json['ewbDate'],
      ewbTransporterName: json['ewbTransporterName'],
      ewbVehicleNo: json['ewbVehicleNo'],
      status: json['status'],
      sOtoDDLeadtime: json['sOtoDDLeadtime'],
      actualDDtoEstimatedDD: json['actualDDtoEstimatedDD'],
      pendingQuantity: json['pendingQuantity'],
      mrp: json['mrp'],
      leadTime: json['leadTime'],
      admissionDate: json['admissionDate'],
      batchNum: json['batchNum'],
      mnfDate: json['mnfDate'],
      expDate: json['expDate'],
      soStatus: json['soStatus'],
    );
  }
}

class PriorityStatusAnalysisList {
  final List<PriorityStatusAnalysisData> priorityData;
  PriorityStatusAnalysisList({required this.priorityData});
}

class PriorityStatusAnalysisData {
  final int priorityId;
  final String priority;
  double percentage;
  final double amount;
  PriorityStatusAnalysisData({
    required this.priority,
    required this.priorityId,
    required this.percentage,
    required this.amount,
  });
}

class OrderStatusAnalysisList {
  final List<OrderStatusAnalysisData> orderData;
  OrderStatusAnalysisList({required this.orderData});
}

class OrderStatusAnalysisData {
  final int orderStatusId;
  final String orderStatus;
  double percentage;
  final double amount;
  OrderStatusAnalysisData({
    required this.orderStatus,
    required this.orderStatusId,
    required this.percentage,
    required this.amount,
  });
}

class HospitalWiseCompletedReportList {
  final List<HospitalWiseCompletedReportData> hospitalData;
  HospitalWiseCompletedReportList({required this.hospitalData});
}

class HospitalWiseCompletedReportData {
  final String hospitalName;
  final double plannedQty;
  final double completedQty;
  HospitalWiseCompletedReportData({
    required this.hospitalName,
    required this.plannedQty,
    required this.completedQty,
  });
}

class DailyCompletedQtyDayWisewrtMPList {
  final List<DailyCompletedQtyDayWisewrtMPData> dailyData;
  DailyCompletedQtyDayWisewrtMPList({required this.dailyData});
}

class DailyCompletedQtyDayWisewrtMPData {
  final String date;
  final double gownQty;
  final double wrapSheetQty;
  DailyCompletedQtyDayWisewrtMPData({
    required this.date,
    required this.gownQty,
    required this.wrapSheetQty,
  });
}

class MonthWiseAnalysisJobCardList {
  final List<MonthWiseAnalysisJobCardData> monthData;
  MonthWiseAnalysisJobCardList({required this.monthData});
}

class MonthWiseAnalysisJobCardData {
  final String monthName;
  final double production;
  MonthWiseAnalysisJobCardData({
    required this.monthName,
    required this.production,
  });
}

class BranchWiseJobCardList {
  final List<BranchWiseJobCardData> branchWiseData;
  BranchWiseJobCardList({required this.branchWiseData});
}

class BranchWiseJobCardData {
  final int branchId;
  final String branchName;
  double branchAmount;
  double percentage;
  BranchWiseJobCardData({
    required this.branchId,
    required this.branchName,
    required this.branchAmount,
    required this.percentage,
  });
}

class ItemGroupWiseAnalysisJobCardList {
  final List<ItemGroupWiseAnalysisJobCardData> itemGroupData;
  ItemGroupWiseAnalysisJobCardList({required this.itemGroupData});
}

class ItemGroupWiseAnalysisJobCardData {
  final String itemGroupName;
  final double lineTotal;
  final double quantity;
  ItemGroupWiseAnalysisJobCardData({
    required this.itemGroupName,
    required this.lineTotal,
    required this.quantity,
  });
}

class ItemSubGroupWiseAnalysisJobCardList {
  final List<ItemSubGroupWiseAnalysisJobCardData> itemSubGroupData;
  ItemSubGroupWiseAnalysisJobCardList({required this.itemSubGroupData});
}

class ItemSubGroupWiseAnalysisJobCardData {
  final String itemSubGroupName;
  final double lineTotal;
  final double quantity;
  ItemSubGroupWiseAnalysisJobCardData({
    required this.itemSubGroupName,
    required this.lineTotal,
    required this.quantity,
  });
}

class ItemDescriptionWiseAnalysisJobCardList {
  final List<ItemDescriptionWiseAnalysisJobCardData> itemData;
  ItemDescriptionWiseAnalysisJobCardList({required this.itemData});
}

class ItemDescriptionWiseAnalysisJobCardData {
  final String itemName;
  final double lineTotal;
  final double quantity;
  ItemDescriptionWiseAnalysisJobCardData({
    required this.itemName,
    required this.lineTotal,
    required this.quantity,
  });
}

class WarehouseWiseAnalysisJobCardList {
  final List<WarehouseWiseAnalysisJobCardData> warehouseData;
  WarehouseWiseAnalysisJobCardList({required this.warehouseData});
}

class WarehouseWiseAnalysisJobCardData {
  final String warehouseName;
  final double lineTotal;
  final double quantity;
  WarehouseWiseAnalysisJobCardData({
    required this.warehouseName,
    required this.lineTotal,
    required this.quantity,
  });
}

class InventoryMovementList {
  final String itemNo;
  final String itemDescription;
  final String groupName;
  final String itemSubGroup;
  final String uom;
  final String obQty;
  final String? toDate;
  final String obVal;
  final String inQty;
  final String inVal;
  final String outQty;
  final String outVal;
  final String cbQty;
  final String cbVal;

  InventoryMovementList({
    required this.itemNo,
    required this.itemDescription,
    required this.groupName,
    required this.itemSubGroup,
    required this.uom,
    required this.obQty,
    required this.toDate,
    required this.obVal,
    required this.inQty,
    required this.inVal,
    required this.outQty,
    required this.outVal,
    required this.cbQty,
    required this.cbVal,
  });

  factory InventoryMovementList.fromJson(Map<String, dynamic> json) {
    return InventoryMovementList(
      itemNo: json['itemNo'],
      itemDescription: json['itemDescription'],
      groupName: json['groupName'],
      itemSubGroup: json['itemSubGroup'],
      uom: json['uom'],
      obQty: json['obQty'],
      toDate: json['toDate'] ?? "",
      obVal: json['obVal'],
      inQty: json['inQty'],
      inVal: json['inVal'],
      outQty: json['outQty'],
      outVal: json['outVal'],
      cbQty: json['cbQty'],
      cbVal: json['cbVal'],
    );
  }
}

class ItemWiseInventoryMovementList {
  final List<ItemWiseInventoryMovementData> itemData;
  ItemWiseInventoryMovementList({required this.itemData});
}

class ItemWiseInventoryMovementData {
  final String itemName;
  final double obQuantity;
  final double inQuantity;
  final double outQuantity;
  final double cbQuantity;
  final double cbValue;
  ItemWiseInventoryMovementData({
    required this.itemName,
    required this.obQuantity,
    required this.inQuantity,
    required this.outQuantity,
    required this.cbQuantity,
    required this.cbValue,
  });
}

class ItemGroupWiseInventoryMovementList {
  final List<ItemGroupWiseInventoryMovementData> itemGroupData;
  ItemGroupWiseInventoryMovementList({required this.itemGroupData});
}

class ItemGroupWiseInventoryMovementData {
  final String itemGroupName;
  final double obQuantity;
  final double inQuantity;
  final double outQuantity;
  final double cbQuantity;
  final double cbValue;
  ItemGroupWiseInventoryMovementData({
    required this.itemGroupName,
    required this.obQuantity,
    required this.inQuantity,
    required this.outQuantity,
    required this.cbQuantity,
    required this.cbValue,
  });
}

class ItemSubGroupWiseInventoryMovementList {
  final List<ItemSubGroupWiseInventoryMovementData> itemSubGroupData;
  ItemSubGroupWiseInventoryMovementList({required this.itemSubGroupData});
}

class ItemSubGroupWiseInventoryMovementData {
  final String itemSubGroupName;
  final double obQuantity;
  final double inQuantity;
  final double outQuantity;
  final double cbQuantity;
  final double cbValue;
  ItemSubGroupWiseInventoryMovementData({
    required this.itemSubGroupName,
    required this.obQuantity,
    required this.inQuantity,
    required this.outQuantity,
    required this.cbQuantity,
    required this.cbValue,
  });
}

class PriceAnalysisList {
  final List<PriceAnalysisData> itemWiseData;
  PriceAnalysisList({required this.itemWiseData});
}

class PriceAnalysisData {
  final String itemName;
  final double price;
  PriceAnalysisData({required this.itemName, required this.price});
}

class TopProductsByPriceList {
  final List<TopProductsByPriceData> itemWiseData;
  TopProductsByPriceList({required this.itemWiseData});
}

class TopProductsByPriceData {
  final String itemName;
  final double price;
  TopProductsByPriceData({required this.itemName, required this.price});
}

class BottomProductsByPriceList {
  final List<BottomProductsByPriceData> itemWiseData;
  BottomProductsByPriceList({required this.itemWiseData});
}

class BottomProductsByPriceData {
  final String itemName;
  final double price;
  BottomProductsByPriceData({required this.itemName, required this.price});
}

class ProductsWiseAvgList {
  final List<ProductsWiseAvgData> itemWiseData;
  ProductsWiseAvgList({required this.itemWiseData});
}

class ProductsWiseAvgData {
  final String itemName;
  final double price;
  final double averagePrice;
  ProductsWiseAvgData({
    required this.itemName,
    required this.price,
    required this.averagePrice,
  });
}

class ProcurementLeadTimeList {
  final String grnNo;
  final String poDate;
  final String actualDeliveryDate;
  final String supplierPODate;
  final String expectedDDDate;
  final String supplierPONo;
  final String poNo;
  final String poStatus;
  final String supplierCode;
  final String supplierName;
  final String supplierGroup;
  final String bpGroup;
  final String supplierCity;
  final String supplierState;
  final String supplierCountry;
  final String countryZone;
  final String groupName;
  final String itemSubGroup;
  final String itemSubSubGroup;
  final String speciality;
  final String productCode;
  final String productName;
  final String uom;
  final String poQuantity;
  final String poRate;
  final String poValue;
  final String currency;
  final String currencyRate;
  final String grnQuantity;
  final String grnRate;
  final String grnValue;
  final String totalTax;
  final String discPrcnt;
  final String totalDiscount;
  final String totalFreightCharges;
  final String documentTotal;
  final String taxCode;
  final String hsnCode;
  final String branchName;
  final String whsCode;
  final String boxQuantity;
  final String totalNoofBoxes;
  final String totalNoofBundles;
  final String lrNo;
  final String lrDate;
  final String paymentTermsDays;
  final String paymentTerms;
  final String priority;
  final String termsofDelivery;
  final String dispatchThrough;
  final String destinationDetails;
  final String status;
  final String pOtoDDLeadtime;
  final String actualDDtoEstimatedDD;
  final String pendingQuantity;
  final String mrp;
  final String leadTime;

  ProcurementLeadTimeList({
    required this.grnNo,
    required this.poDate,
    required this.actualDeliveryDate,
    required this.supplierPODate,
    required this.expectedDDDate,
    required this.supplierPONo,
    required this.poNo,
    required this.poStatus,
    required this.supplierCode,
    required this.supplierName,
    required this.supplierGroup,
    required this.bpGroup,
    required this.supplierCity,
    required this.supplierState,
    required this.supplierCountry,
    required this.countryZone,
    required this.groupName,
    required this.itemSubGroup,
    required this.itemSubSubGroup,
    required this.speciality,
    required this.productCode,
    required this.productName,
    required this.uom,
    required this.poQuantity,
    required this.poRate,
    required this.poValue,
    required this.currency,
    required this.currencyRate,
    required this.grnQuantity,
    required this.grnRate,
    required this.grnValue,
    required this.totalTax,
    required this.discPrcnt,
    required this.totalDiscount,
    required this.totalFreightCharges,
    required this.documentTotal,
    required this.taxCode,
    required this.hsnCode,
    required this.branchName,
    required this.whsCode,
    required this.boxQuantity,
    required this.totalNoofBoxes,
    required this.totalNoofBundles,
    required this.lrNo,
    required this.lrDate,
    required this.paymentTermsDays,
    required this.paymentTerms,
    required this.priority,
    required this.termsofDelivery,
    required this.dispatchThrough,
    required this.destinationDetails,
    required this.status,
    required this.pOtoDDLeadtime,
    required this.actualDDtoEstimatedDD,
    required this.pendingQuantity,
    required this.mrp,
    required this.leadTime,
  });

  factory ProcurementLeadTimeList.fromJson(Map<String, dynamic> json) {
    return ProcurementLeadTimeList(
      grnNo: json['grnNo'] ?? "",
      poDate: json['poDate'] ?? "",
      actualDeliveryDate: json['actualDeliveryDate'] ?? "",
      supplierPODate: json['supplierPODate'] ?? "",
      expectedDDDate: json['expectedDDDate'] ?? "",
      supplierPONo: json['cussupplierPONotomerPONo'] ?? "",
      poNo: json['poNo'] ?? "",
      poStatus: json['poStatus'] ?? "",
      supplierCode: json['supplierCode'] ?? "",
      supplierName: json['supplierName'] ?? "",
      supplierGroup: json['supplierGroup'] ?? "",
      bpGroup: json['bpGroup'] ?? "",
      supplierCity: json['supplierCity'] ?? "",
      supplierState: json['supplierState'] ?? "",
      supplierCountry: json['supplierCountry'] ?? "",
      countryZone: json['countryZone'] ?? "",
      groupName: json['groupName'] ?? "",
      itemSubGroup: json['itemSubGroup'] ?? "",
      itemSubSubGroup: json['itemSubSubGroup'] ?? "",
      speciality: json['speciality'] ?? "",
      productCode: json['productCode'] ?? "",
      productName: json['productName'] ?? "",
      uom: json['uom'] ?? "",
      poQuantity: json['poQuantity'] ?? "",
      poRate: json['poRate'] ?? "",
      poValue: json['poValue'] ?? "",
      currency: json['currency'] ?? "",
      currencyRate: json['currencyRate'] ?? "",
      grnQuantity: json['grnQuantity'] ?? "",
      grnRate: json['grnRate'] ?? "",
      grnValue: json['grnValue'] ?? "",
      totalTax: json['totalTax'] ?? "",
      discPrcnt: json['discPrcnt'] ?? "",
      totalDiscount: json['totalDiscount'] ?? "",
      totalFreightCharges: json['totalFreightCharges'] ?? "",
      documentTotal: json['documentTotal'] ?? "",
      taxCode: json['taxCode'] ?? "",
      hsnCode: json['hsnCode'] ?? "",
      branchName: json['branchName'] ?? "",
      whsCode: json['whsCode'] ?? "",
      boxQuantity: json['boxQuantity'] ?? "",
      totalNoofBoxes: json['totalNoofBoxes'] ?? "",
      totalNoofBundles: json['totalNoofBundles'] ?? "",
      lrNo: json['lrNo'] ?? "",
      lrDate: json['lrDate'] ?? "",
      paymentTermsDays: json['paymentTermsDays'] ?? "",
      paymentTerms: json['paymentTerms'] ?? "",
      priority: json['priority'] ?? "",
      termsofDelivery: json['termsofDelivery'] ?? "",
      dispatchThrough: json['dispatchThrough'] ?? "",
      destinationDetails: json['destinationDetails'] ?? "",
      status: json['status'] ?? "",
      pOtoDDLeadtime: json['pOtoDDLeadtime'] ?? "",
      actualDDtoEstimatedDD: json['actualDDtoEstimatedDD'] ?? "",
      pendingQuantity: json['pendingQuantity'] ?? "",
      mrp: json['mrp'] ?? "",
      leadTime: json['leadTime'] ?? "",
    );
  }
}

class SupplierWiseLeadTimeList {
  final List<SupplierWiseLeadTimeData> supplierLeadTime;
  SupplierWiseLeadTimeList({required this.supplierLeadTime});
}

class SupplierWiseLeadTimeData {
  final String supplierName;
  final double leadTime;
  SupplierWiseLeadTimeData({
    required this.supplierName,
    required this.leadTime,
  });
}

class ItemWiseLeadTimeList {
  final List<ItemWiseLeadTimeData> itemLeadTime;
  ItemWiseLeadTimeList({required this.itemLeadTime});
}

class ItemWiseLeadTimeData {
  final String itemName;
  final double leadTime;
  ItemWiseLeadTimeData({required this.itemName, required this.leadTime});
}

class SupplierWiseDeliveryList {
  final List<SupplierWiseDeliveryData> supplierLeadTime;
  SupplierWiseDeliveryList({required this.supplierLeadTime});
}

class SupplierWiseDeliveryData {
  final String supplierName;
  final double leadTime;
  SupplierWiseDeliveryData({
    required this.supplierName,
    required this.leadTime,
  });
}

class ItemWiseDeliveryList {
  final List<ItemWiseDeliveryData> itemLeadTime;
  ItemWiseDeliveryList({required this.itemLeadTime});
}

class ItemWiseDeliveryData {
  final String itemName;
  final double leadTime;
  ItemWiseDeliveryData({required this.itemName, required this.leadTime});
}

class PurchaseWarehouseAnalysisList {
  final List<PurchaseWarehouseAnalysisData> warehouseData;
  PurchaseWarehouseAnalysisList({required this.warehouseData});
}

class PurchaseWarehouseAnalysisData {
  final String warehouseName;
  final double rowTotal;
  final double monthAvg;
  PurchaseWarehouseAnalysisData({
    required this.warehouseName,
    required this.rowTotal,
    required this.monthAvg,
  });
}

class ItemYTDSalesData {
  final String itemGroup;
  final double aprValue;
  final double mayValue;
  final double junValue;
  final double q1Avg;
  final double julValue;
  final double augValue;
  final double sepValue;
  final double q2Avg;
  final double octValue;
  final double novValue;
  final double decValue;
  final double q3Avg;
  final double janValue;
  final double febValue;
  final double marValue;
  final double q4Avg;
  final double ytdTotalValue;
  final double ytdTotalAvg;
  ItemYTDSalesData({
    required this.itemGroup,
    required this.aprValue,
    required this.mayValue,
    required this.junValue,
    required this.q1Avg,
    required this.julValue,
    required this.augValue,
    required this.sepValue,
    required this.q2Avg,
    required this.octValue,
    required this.novValue,
    required this.decValue,
    required this.q3Avg,
    required this.janValue,
    required this.febValue,
    required this.marValue,
    required this.q4Avg,
    required this.ytdTotalValue,
    required this.ytdTotalAvg,
  });
}

class ItemYTDSalesList {
  final List<ItemYTDSalesData> ytdData;
  ItemYTDSalesList({required this.ytdData});
}

class AllReceivablesFinanceList {
  final List<AllReceivablesFinanceData> agingData;
  AllReceivablesFinanceList({required this.agingData});
}

class AllReceivablesFinanceData {
  final String agingGroup;
  double agingPercentage;
  double agingGroupTotal;
  double agingTotal;
  AllReceivablesFinanceData({
    required this.agingGroup,
    required this.agingPercentage,
    required this.agingGroupTotal,
    required this.agingTotal,
  });
}

class InventoryItemSubGroupWiseSlowDeadList {
  final List<InventoryItemSubGroupWiseSlowDeadData> itemGroupData;
  InventoryItemSubGroupWiseSlowDeadList({required this.itemGroupData});
}

class InventoryItemSubGroupWiseSlowDeadData {
  final String itemSubGroupName;
  final double quantity;
  InventoryItemSubGroupWiseSlowDeadData({
    required this.itemSubGroupName,
    required this.quantity,
  });
}

class InventoryWarehouseList {
  final List<InventoryWarehouseData> warehouseData;
  InventoryWarehouseList({required this.warehouseData});
}

class InventoryWarehouseData {
  final String warehouseName;
  final double quantity;
  InventoryWarehouseData({required this.warehouseName, required this.quantity});
}

class TrialBalance {
  final String group;
  final String subGroup;
  final String accountCode;
  final String accountName;
  final String openingBalance;
  final String monthYear;
  final String debit;
  final String credit;
  final String balance;
  final String closingBalance;
  final String category;
  final String foreignName;

  TrialBalance({
    required this.group,
    required this.subGroup,
    required this.accountCode,
    required this.accountName,
    required this.openingBalance,
    required this.monthYear,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.closingBalance,
    required this.category,
    required this.foreignName,
  });

  factory TrialBalance.fromJson(Map<String, dynamic> json) {
    return TrialBalance(
      group: json['group'],
      subGroup: json['subGroup'],
      accountCode: json['accountCode'],
      accountName: json['accountName'],
      openingBalance: json['openingBalance'],
      monthYear: json['monthYear'],
      debit: json['debit'],
      credit: json['credit'],
      balance: json['balance'],
      closingBalance: json['closingBalance'],
      category: json['category'],
      foreignName: json['foreignName'],
    );
  }
}

class ItemCostList {
  final String itemCode;
  final String itemName;
  final String createDate;
  final String itemCost;
  final String groupName;
  final String itemSubGroup;
  final String itemSubSubGroup;
  final String speciality;
  final String uom;
  final String boxQty;

  ItemCostList({
    required this.itemCode,
    required this.itemName,
    required this.createDate,
    required this.itemCost,
    required this.groupName,
    required this.itemSubGroup,
    required this.itemSubSubGroup,
    required this.speciality,
    required this.uom,
    required this.boxQty,
  });

  factory ItemCostList.fromJson(Map<String, dynamic> json) {
    return ItemCostList(
      itemCode: json['itemCode'],
      itemName: json['itemName'],
      createDate: json['createDate'],
      itemCost: json['itemCost'],
      groupName: json['groupName'],
      itemSubGroup: json['itemSubGroup'],
      itemSubSubGroup: json['itemSubSubGroup'],
      speciality: json['speciality'],
      uom: json['uom'],
      boxQty: json['boxQty'],
    );
  }
}

class ProductMarginData {
  final String itemNo;
  final String itemDescription;
  final String itemSubGroup;
  final String quantity;
  final String saleAmt;
  final String avgSellingPrice;
  final String bomCost;
  final String perUnitMarginAmount;
  final String totalMarginAmount;
  final double marginPercent;

  ProductMarginData({
    required this.itemNo,
    required this.itemDescription,
    required this.itemSubGroup,
    required this.quantity,
    required this.saleAmt,
    required this.avgSellingPrice,
    required this.bomCost,
    required this.perUnitMarginAmount,
    required this.totalMarginAmount,
    required this.marginPercent,
  });
}

class ProductMarginList {
  final List<ProductMarginData> productMarginData;
  ProductMarginList({required this.productMarginData});
}

class CashConversionGraphList {
  final List<CashConversionGraphData> monthData;
  CashConversionGraphList({required this.monthData});
}

class CashConversionGraphData {
  final String monthName;
  final double dsoDaysSales;
  final double dsoDaysNH;
  final double dsoDaysOffice;
  final double dsoAllDays;
  final double payableDays;
  final double inventoryDays;
  CashConversionGraphData({
    required this.monthName,
    required this.dsoDaysSales,
    required this.dsoDaysNH,
    required this.dsoDaysOffice,
    required this.dsoAllDays,
    required this.payableDays,
    required this.inventoryDays,
  });
}

class NotificationList {
  final String alertName;
  final String vendorName;
  final String location;
  final String startDate;
  final String endDate;
  final String dueDate;
  final String frequency;
  final String department;

  NotificationList({
    required this.alertName,
    required this.vendorName,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.dueDate,
    required this.frequency,
    required this.department,
  });
  factory NotificationList.fromJson(Map<String, dynamic> json) {
    return NotificationList(
      alertName: json['alertName'],
      vendorName: json['vendorName'],
      location: json['location'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      dueDate: json['dueDate'],
      frequency: json['frequency'],
      department: json['department'],
    );
  }
}

class NotificationItem {
  final String department;
  final String alertName;
  final String location;
  final String vendorName;
  final String dueDate;

  NotificationItem({
    required this.department,
    required this.alertName,
    required this.location,
    required this.vendorName,
    required this.dueDate,
  });
}

class PendingOrderList {
  final int SlNo;
  final String PoNo;
  final String PoDate;
  final String HospitalName;
  final String ItemCode;
  final String ItemName;
  final double OrderedQty;
  final double DespatchedQty;
  final double BangStock;
  final double RajStock;
  final double PendingQty;
  final double BoxQty;
  final double ItemMrp;
  final String OrderPriority;

  PendingOrderList({
    required this.SlNo,
    required this.PoNo,
    required this.PoDate,
    required this.HospitalName,
    required this.ItemCode,
    required this.ItemName,
    required this.OrderedQty,
    required this.DespatchedQty,
    required this.BangStock,
    required this.RajStock,
    required this.PendingQty,
    required this.BoxQty,
    required this.ItemMrp,
    required this.OrderPriority,
  });

  factory PendingOrderList.fromJson(Map<String, dynamic> json) {
    return PendingOrderList(
      SlNo: json['SlNo'],
      PoNo: json['PoNo'],
      PoDate: json['PoDate'],
      HospitalName: json['HospitalName'],
      ItemCode: json['ItemCode'],
      ItemName: json['ItemName'],
      OrderedQty: (json['OrderedQty'] as num).toDouble(),
      DespatchedQty: (json['DespatchedQty'] as num).toDouble(),
      BangStock: (json['BangStock'] as num).toDouble(),
      RajStock: (json['RajStock'] as num).toDouble(),
      PendingQty: (json['PendingQty'] as num).toDouble(),
      BoxQty: (json['BoxQty'] as num).toDouble(),
      ItemMrp: (json['ItemMrp'] as num).toDouble(),
      OrderPriority: json['OrderPriority'],
    );
  }
}

class MonthlyCollectionReportData {
  String? customerName;
  final String regionalManager;
  final String salesManager;
  final String salesPerson;
  double targetMonth;
  double weekOneCommitted;
  double weekOneReceived;
  double weekTwoCommitted;
  double weekTwoReceived;
  double weekThreeCommitted;
  double weekThreeReceived;
  double weekFourCommitted;
  double weekFourReceived;
  MonthlyCollectionReportData({
    this.customerName,
    required this.regionalManager,
    required this.salesManager,
    required this.salesPerson,
    required this.targetMonth,
    required this.weekOneCommitted,
    required this.weekOneReceived,
    required this.weekTwoCommitted,
    required this.weekTwoReceived,
    required this.weekThreeCommitted,
    required this.weekThreeReceived,
    required this.weekFourCommitted,
    required this.weekFourReceived,
  });
}

class MonthlyCollectionReportList {
  final List<MonthlyCollectionReportData> weeklyData;
  MonthlyCollectionReportList({required this.weeklyData});
}

class VendorsPaymentProjectionList {
  final List<VendorsPaymentProjectionData> vendorData;
  VendorsPaymentProjectionList({required this.vendorData});
}

class VendorsPaymentProjectionData {
  final String vendorName;
  final String vendorCode;
  double balanceDue;
  double a0to30;
  double a31to60;
  double a61to90;
  double a90to180;
  double a180above;
  double commitment;
  double currentMonthPayable;
  double actualPayable;
  VendorsPaymentProjectionData({
    required this.vendorName,
    required this.vendorCode,
    required this.balanceDue,
    required this.a0to30,
    required this.a31to60,
    required this.a61to90,
    required this.a90to180,
    required this.a180above,
    required this.commitment,
    required this.currentMonthPayable,
    required this.actualPayable,
  });
}

class SubGroupMonthWiseExpensesList {
  final List<SubGroupMonthWiseExpensesData> subGroupData;
  SubGroupMonthWiseExpensesList({required this.subGroupData});
}

class SubGroupMonthWiseExpensesData {
  String subGroupName;
  double aprBalance;
  double mayBalance;
  double junBalance;
  double julBalance;
  double augBalance;
  double septBalance;
  double octBalance;
  double novBalance;
  double decBalance;
  double janBalance;
  double febBalance;
  double marBalance;

  SubGroupMonthWiseExpensesData({
    required this.subGroupName,
    required this.aprBalance,
    required this.mayBalance,
    required this.junBalance,
    required this.julBalance,
    required this.augBalance,
    required this.septBalance,
    required this.octBalance,
    required this.novBalance,
    required this.decBalance,
    required this.janBalance,
    required this.febBalance,
    required this.marBalance,
  });
}

class SubGroupMonthWiseRevenueExpensesList {
  final List<SubGroupMonthWiseRevenueExpensesData> subGroupData;
  SubGroupMonthWiseRevenueExpensesList({required this.subGroupData});
}

class SubGroupMonthWiseRevenueExpensesData {
  String subGroupName;
  double aprBalance;
  double mayBalance;
  double junBalance;
  double julBalance;
  double augBalance;
  double septBalance;
  double octBalance;
  double novBalance;
  double decBalance;
  double janBalance;
  double febBalance;
  double marBalance;

  SubGroupMonthWiseRevenueExpensesData({
    required this.subGroupName,
    required this.aprBalance,
    required this.mayBalance,
    required this.junBalance,
    required this.julBalance,
    required this.augBalance,
    required this.septBalance,
    required this.octBalance,
    required this.novBalance,
    required this.decBalance,
    required this.janBalance,
    required this.febBalance,
    required this.marBalance,
  });
}

class InvoiceCustomers {
  final String customerName;
  final String customerCode;
  final String? salesManager;
  final String? regionalManager;

  InvoiceCustomers({
    required this.customerName,
    required this.customerCode,
    this.salesManager,
    this.regionalManager,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceCustomers &&
          other.customerCode == customerCode &&
          other.customerName == customerName &&
          other.salesManager == salesManager &&
          other.regionalManager == regionalManager;

  @override
  int get hashCode =>
      customerCode.hashCode ^
      customerName.hashCode ^
      (salesManager?.hashCode ?? 0) ^
      (regionalManager?.hashCode ?? 0);
}

class UsersForSearch {
  final String menuName;
  final String menuId;

  UsersForSearch({required this.menuName, required this.menuId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsersForSearch &&
          runtimeType == other.runtimeType &&
          menuName == other.menuName &&
          menuId == other.menuId;

  @override
  int get hashCode => menuName.hashCode ^ menuId.hashCode;

  @override
  String toString() {
    return 'Users(menuName: $menuName, menuId: $menuId)';
  }
}

class DailyCostingGraphList {
  List<DailyCostingGraphData> graphData;
  DailyCostingGraphList({required this.graphData});
}

class DailyCostingGraphData {
  final String name;
  double target;
  double achievement;
  double percentage;
  DailyCostingGraphData({
    required this.name,
    required this.target,
    required this.achievement,
    required this.percentage,
  });
}

class GRNList {
  final String grnNo;
  final String grnDate;
  final String vendorInvNo;
  final String vendorInvDate;
  final String termsofDelivery;
  final String dispatchThrough;
  final String destinationDetails;
  final String vendorCode;
  final String vendorName;
  final String vendorGroup;
  final String vendorCity;
  final String vendorState;
  final String itemGroup;
  final String itemSubGroup;
  final String code;
  final String description;
  final String uom;
  final String grnQty;
  final String currency;
  final String currencyRate;
  final String price;
  final String taxCode;
  final String rowTotal;
  final String documentTotal;
  final String branchName;
  final String whsCode;

  GRNList({
    required this.grnNo,
    required this.grnDate,
    required this.vendorInvNo,
    required this.vendorInvDate,
    required this.termsofDelivery,
    required this.dispatchThrough,
    required this.destinationDetails,
    required this.vendorCode,
    required this.vendorName,
    required this.vendorGroup,
    required this.vendorCity,
    required this.vendorState,
    required this.itemGroup,
    required this.itemSubGroup,
    required this.code,
    required this.description,
    required this.uom,
    required this.grnQty,
    required this.currency,
    required this.currencyRate,
    required this.price,
    required this.taxCode,
    required this.rowTotal,
    required this.documentTotal,
    required this.branchName,
    required this.whsCode,
  });

  factory GRNList.fromJson(Map<String, dynamic> json) {
    return GRNList(
      grnNo: json['grnNo'],
      grnDate: json['grnDate'],
      vendorInvNo: json['vendorInvNo'],
      vendorInvDate: json['vendorInvDate'],
      termsofDelivery: json['termsofDelivery'],
      dispatchThrough: json['dispatchThrough'],
      destinationDetails: json['destinationDetails'],
      vendorCode: json['vendorCode'],
      vendorName: json['vendorName'],
      vendorGroup: json['vendorGroup'],
      vendorCity: json['vendorCity'],
      vendorState: json['vendorState'],
      itemGroup: json['itemGroup'],
      itemSubGroup: json['itemSubGroup'],
      code: json['code'],
      description: json['description'],
      uom: json['uom'],
      grnQty: json['grnQty'],
      currency: json['currency'],
      currencyRate: json['currencyRate'],
      price: json['price'],
      taxCode: json['taxCode'],
      rowTotal: json['rowTotal'],
      documentTotal: json['documentTotal'],
      branchName: json['branchName'],
      whsCode: json['whsCode'],
    );
  }
}

class DSOGraphList {
  final List<DSOGraphData> monthData;
  DSOGraphList({required this.monthData});
}

class DSOGraphData {
  final String monthname;
  final String name;
  final double target;
  final double achievement;
  DSOGraphData({
    required this.monthname,
    required this.name,
    required this.target,
    required this.achievement,
  });
}

class MonthlyInventoryData {
  final String monthYear; // e.g. "Mar 2025"
  final List<InventoryList> inventory;
  MonthlyInventoryData({required this.monthYear, required this.inventory});
}

class MonthlyCogsData {
  final String monthYear;
  final double openingStock;
  final double purchases;
  final double closingStock;
  final double cogs;

  MonthlyCogsData({
    required this.monthYear,
    required this.openingStock,
    required this.purchases,
    required this.closingStock,
    required this.cogs,
  });
}

class StockItemData {
  final String itemSubGroup;
  final double targetStock;
  final double actualStock;
  final double difference;
  StockItemData({
    required this.itemSubGroup,
    required this.targetStock,
    required this.actualStock,
    required this.difference,
  });
}

class StockItemList {
  final List<StockItemData> stockData;
  StockItemList({required this.stockData});
}

class SalesVsProductionMIS {
  final String deliveryNoteNo;
  final String soDate;
  final String actualDeliveryDate;
  final String customePODate;
  final String expectedDDDate;
  final String customerPONo;
  final String soNo;
  final String soStatus;
  final String customerCode;
  final String customerName;
  final String customerGroup;
  final String bpGroup;
  final String customerCity;
  final String customerState;
  final String customerCountry;
  final String countryZone;
  final String salesRep;
  final String salesManager;
  final String regionalManager;
  final String groupName;
  final String itemSubGroup;
  final String itemSubSubGroup;
  final String speciality;
  final String productCode;
  final String productName;
  final String uom;
  final String soQuantity;
  final String soRate;
  final String soValue;
  final String currency;
  final String currencyRate;
  final String dnQuantity;
  final String dnRate;
  final String dnValue;
  final String totalTax;
  final String discPrcnt;
  final String totalDiscount;
  final String totalFreightCharges;
  final String documentTotal;
  final String taxCode;
  final String hsnCode;
  final String branchName;
  final String whsCode;
  final String boxQuantity;
  final String totalNoofBoxes;
  final String totalNoofBundles;
  final String lrNo;
  final String lrDate;
  final String paymentTermsDays;
  final String paymentTerms;
  final String priority;
  final String termsofDelivery;
  final String dispatchThrough;
  final String destinationDetails;
  final String ewbNo;
  final String ewbDate;
  final String ewbTransporterName;
  final String ewbVehicleNo;
  final String status;
  final String sOtoDDLeadtime;
  final String actualDDtoEstimatedDD;
  final String pendingQuantity;
  final String mrp;
  final String leadTime;
  final String admissionDate;
  final String batchNum;
  final String mnfDate;
  final String expDate;

  SalesVsProductionMIS({
    required this.deliveryNoteNo,
    required this.soDate,
    required this.actualDeliveryDate,
    required this.customePODate,
    required this.expectedDDDate,
    required this.customerPONo,
    required this.soNo,
    required this.soStatus,
    required this.customerCode,
    required this.customerName,
    required this.customerGroup,
    required this.bpGroup,
    required this.customerCity,
    required this.customerState,
    required this.customerCountry,
    required this.countryZone,
    required this.salesRep,
    required this.salesManager,
    required this.regionalManager,
    required this.groupName,
    required this.itemSubGroup,
    required this.itemSubSubGroup,
    required this.speciality,
    required this.productCode,
    required this.productName,
    required this.uom,
    required this.soQuantity,
    required this.soRate,
    required this.soValue,
    required this.currency,
    required this.currencyRate,
    required this.dnQuantity,
    required this.dnRate,
    required this.dnValue,
    required this.totalTax,
    required this.discPrcnt,
    required this.totalDiscount,
    required this.totalFreightCharges,
    required this.documentTotal,
    required this.taxCode,
    required this.hsnCode,
    required this.branchName,
    required this.whsCode,
    required this.boxQuantity,
    required this.totalNoofBoxes,
    required this.totalNoofBundles,
    required this.lrNo,
    required this.lrDate,
    required this.paymentTermsDays,
    required this.paymentTerms,
    required this.priority,
    required this.termsofDelivery,
    required this.dispatchThrough,
    required this.destinationDetails,
    required this.ewbNo,
    required this.ewbDate,
    required this.ewbTransporterName,
    required this.ewbVehicleNo,
    required this.status,
    required this.sOtoDDLeadtime,
    required this.actualDDtoEstimatedDD,
    required this.pendingQuantity,
    required this.mrp,
    required this.leadTime,
    required this.admissionDate,
    required this.batchNum,
    required this.mnfDate,
    required this.expDate,
  });

  factory SalesVsProductionMIS.fromJson(Map<String, dynamic> json) {
    return SalesVsProductionMIS(
      deliveryNoteNo: json['deliveryNoteNo'],
      soDate: json['soDate'],
      actualDeliveryDate: json['actualDeliveryDate'],
      customePODate: json['customePODate'],
      expectedDDDate: json['expectedDDDate'],
      customerPONo: json['customerPONo'],
      soNo: json['soNo'],
      soStatus: json['soStatus'],
      customerCode: json['customerCode'],
      customerName: json['customerName'],
      customerGroup: json['customerGroup'],
      bpGroup: json['bpGroup'],
      customerCity: json['customerCity'],
      customerState: json['customerState'],
      customerCountry: json['customerCountry'],
      countryZone: json['countryZone'],
      salesRep: json['salesRep'],
      salesManager: json['salesManager'],
      regionalManager: json['regionalManager'],
      groupName: json['groupName'],
      itemSubGroup: json['itemSubGroup'],
      itemSubSubGroup: json['itemSubSubGroup'],
      speciality: json['speciality'],
      productCode: json['productCode'],
      productName: json['productName'],
      uom: json['uom'],
      soQuantity: json['soQuantity'],
      soRate: json['soRate'],
      soValue: json['soValue'],
      currency: json['currency'],
      currencyRate: json['currencyRate'],
      dnQuantity: json['dnQuantity'],
      dnRate: json['dnRate'],
      dnValue: json['dnValue'],
      totalTax: json['totalTax'],
      discPrcnt: json['discPrcnt'],
      totalDiscount: json['totalDiscount'],
      totalFreightCharges: json['totalFreightCharges'],
      documentTotal: json['documentTotal'],
      taxCode: json['taxCode'],
      hsnCode: json['hsnCode'],
      branchName: json['branchName'],
      whsCode: json['whsCode'],
      boxQuantity: json['boxQuantity'],
      totalNoofBoxes: json['totalNoofBoxes'],
      totalNoofBundles: json['totalNoofBundles'],
      lrNo: json['lrNo'],
      lrDate: json['lrDate'],
      paymentTermsDays: json['paymentTermsDays'],
      paymentTerms: json['paymentTerms'],
      priority: json['priority'],
      termsofDelivery: json['termsofDelivery'],
      dispatchThrough: json['dispatchThrough'],
      destinationDetails: json['destinationDetails'],
      ewbNo: json['ewbNo'],
      ewbDate: json['ewbDate'],
      ewbTransporterName: json['ewbTransporterName'],
      ewbVehicleNo: json['ewbVehicleNo'],
      status: json['status'],
      sOtoDDLeadtime: json['sOtoDDLeadtime'],
      actualDDtoEstimatedDD: json['actualDDtoEstimatedDD'],
      pendingQuantity: json['pendingQuantity'],
      mrp: json['mrp'],
      leadTime: json['leadTime'],
      admissionDate: json['admissionDate'],
      batchNum: json['batchNum'],
      mnfDate: json['mnfDate'],
      expDate: json['expDate'],
    );
  }
}

class SalesVsProductionPieChartList {
  final List<SalesVsProductionPieChartData> categoryData;
  SalesVsProductionPieChartList({required this.categoryData});
}

class SalesVsProductionPieChartData {
  final int categoryId;
  final String categoryName;
  double noOfOrders;
  double? noOfOrdersPercentage;
  SalesVsProductionPieChartData({
    required this.categoryId,
    required this.categoryName,
    required this.noOfOrders,
    this.noOfOrdersPercentage,
  });
}

class MonthlySalesVsProductionList {
  final List<MonthlySalesVsProductionData> monthlyData;
  MonthlySalesVsProductionList({required this.monthlyData});
}

class MonthlySalesVsProductionData {
  final String monthName;
  final double noOfOrders;
  final double completed;
  final double pending;
  MonthlySalesVsProductionData({
    required this.monthName,
    required this.noOfOrders,
    required this.completed,
    required this.pending,
  });
}

class JobCardDetails {
  final String type;
  final String documentNo;
  final String postingDate;
  final String fgItemGroup;
  final String fgItemSubGroup;
  final String fgProductCode;
  final String fgProductName;
  final String fguom;
  final String fgPlannnedQty;
  final String completedQty;
  final String groupName;
  final String rmItemSubGroup;
  final String rmItemSubSubGroup;
  final String rmProductCode;
  final String rmProductName;
  final String rmuom;
  final String alterItemCode;
  final String alterItemName;
  final String alterItemUOM;
  final String alterItemLastPurPrc;
  final String standardConsumption;
  final String jcActualConsumption;
  final String actualConsumption;
  final String processRemark;
  final String aditionalWastageRemark;
  final String warehouseCode;
  final String remarks;
  final String branchName;

  JobCardDetails({
    required this.type,
    required this.documentNo,
    required this.postingDate,
    required this.fgItemGroup,
    required this.fgItemSubGroup,
    required this.fgProductCode,
    required this.fgProductName,
    required this.fguom,
    required this.fgPlannnedQty,
    required this.completedQty,
    required this.groupName,
    required this.rmItemSubGroup,
    required this.rmItemSubSubGroup,
    required this.rmProductCode,
    required this.rmProductName,
    required this.rmuom,
    required this.alterItemCode,
    required this.alterItemName,
    required this.alterItemUOM,
    required this.alterItemLastPurPrc,
    required this.standardConsumption,
    required this.jcActualConsumption,
    required this.actualConsumption,
    required this.processRemark,
    required this.aditionalWastageRemark,
    required this.warehouseCode,
    required this.remarks,
    required this.branchName,
  });

  factory JobCardDetails.fromJson(Map<String, dynamic> json) {
    return JobCardDetails(
      type: json['type'],
      documentNo: json['documentNo'],
      postingDate: json['postingDate'],
      fgItemGroup: json['fgItemGroup'],
      fgItemSubGroup: json['fgItemSubGroup'],
      fgProductCode: json['fgProductCode'],
      fgProductName: json['fgProductName'],
      fguom: json['fguom'],
      fgPlannnedQty: json['fgPlannnedQty'],
      completedQty: json['completedQty'],
      groupName: json['groupName'],
      rmItemSubGroup: json['rmItemSubGroup'],
      rmItemSubSubGroup: json['rmItemSubSubGroup'],
      rmProductCode: json['rmProductCode'],
      rmProductName: json['rmProductName'],
      rmuom: json['rmuom'],
      alterItemCode: json['alterItemCode'],
      alterItemName: json['alterItemName'],
      alterItemUOM: json['alterItemUOM'],
      alterItemLastPurPrc: json['alterItemLastPurPrc'],
      standardConsumption: json['standardConsumption'],
      jcActualConsumption: json['jcActualConsumption'],
      actualConsumption: json['actualConsumption'],
      processRemark: json['processRemark'],
      aditionalWastageRemark: json['aditionalWastageRemark'],
      warehouseCode: json['warehouseCode'],
      remarks: json['remarks'],
      branchName: json['branchName'],
    );
  }
}

class ProductBarData {
  final String fgProductName;
  final double sumCompletedQty;

  ProductBarData({required this.fgProductName, required this.sumCompletedQty});
}

class ProductBarDataList {
  final List<ProductBarData> list;

  ProductBarDataList({required this.list});
}

class ItemProductionData {
  final String itemDescription;
  final double totalOutput;
  final double productionTarget;

  ItemProductionData({
    required this.itemDescription,
    required this.totalOutput,
    required this.productionTarget,
  });
}

class ItemProductionDataList {
  final List<ItemProductionData> list;

  ItemProductionDataList({required this.list});
}

class LoginlogData {
  final String logDate;
  final String logUserMailId;
  final String logUserDeviceIp;
  final String logDeviceType;
  final String logRemarks;
  LoginlogData({
    required this.logDate,
    required this.logUserMailId,
    required this.logUserDeviceIp,
    required this.logDeviceType,
    required this.logRemarks,
  });
}

class LoginlogDataList {
  final List<LoginlogData> loginLogData;
  LoginlogDataList({required this.loginLogData});
}

class SampleRequest {
  final String documentNo;
  final String sampleReqNo;
  final String srfDate;
  final String customerExpDOD;
  final String nameoftheHospital;
  final String counterType;
  final String placeHQ;
  final String distributorName;
  final String sampleDeliverytoAddress;
  final String marketingRep;
  final String marketingManager;
  final String product;
  final String refNo;
  final String productCategory;
  final String designType;
  final String uom;
  final String requestQty;
  final String price;
  final String rowTotal;
  final String priority;
  final String deliveryStatus;
  final String dispatchedDate;
  final String lrDetails;
  final String remarks;

  SampleRequest({
    required this.documentNo,
    required this.sampleReqNo,
    required this.srfDate,
    required this.customerExpDOD,
    required this.nameoftheHospital,
    required this.counterType,
    required this.placeHQ,
    required this.distributorName,
    required this.sampleDeliverytoAddress,
    required this.marketingRep,
    required this.marketingManager,
    required this.product,
    required this.refNo,
    required this.productCategory,
    required this.designType,
    required this.uom,
    required this.requestQty,
    required this.price,
    required this.rowTotal,
    required this.priority,
    required this.deliveryStatus,
    required this.dispatchedDate,
    required this.lrDetails,
    required this.remarks,
  });

  factory SampleRequest.fromJson(Map<String, dynamic> json) {
    return SampleRequest(
      documentNo: json['documentNo'],
      sampleReqNo: json['sampleReqNo'],
      srfDate: json['srfDate'],
      customerExpDOD: json['customerExpDOD'],
      nameoftheHospital: json['nameoftheHospital'],
      counterType: json['counterType'],
      placeHQ: json['placeHQ'],
      distributorName: json['distributorName'],
      sampleDeliverytoAddress: json['sampleDeliverytoAddress'],
      marketingRep: json['marketingRep'],
      marketingManager: json['marketingManager'],
      product: json['product'],
      refNo: json['refNo'],
      productCategory: json['productCategory'],
      designType: json['designType'],
      uom: json['uom'],
      requestQty: json['requestQty'],
      price: json['price'],
      rowTotal: json['rowTotal'],
      priority: json['priority'],
      deliveryStatus: json['deliveryStatus'],
      dispatchedDate: json['dispatchedDate'],
      lrDetails: json['lrDetails'],
      remarks: json['remarks'],
    );
  }
}

class CustomerComplaint {
  final String callID;
  final String dateReceived;
  final String customerCode;
  final String customerName;
  final String plant;
  final String salesRep;
  final String salesManager;
  final String natureOfComplaint;
  final String productCode;
  final String productName;
  final String mfrLotNo;
  final String origin;
  final String rootCause;
  final String correctiveAction;
  final String preventiveAction;
  final String priority;
  final String status;
  final String closedOn;
  final String callType;
  final String problemType;
  final String handledBy;

  CustomerComplaint({
    required this.callID,
    required this.dateReceived,
    required this.customerCode,
    required this.customerName,
    required this.plant,
    required this.salesRep,
    required this.salesManager,
    required this.natureOfComplaint,
    required this.productCode,
    required this.productName,
    required this.mfrLotNo,
    required this.origin,
    required this.rootCause,
    required this.correctiveAction,
    required this.preventiveAction,
    required this.priority,
    required this.status,
    required this.closedOn,
    required this.callType,
    required this.problemType,
    required this.handledBy,
  });

  factory CustomerComplaint.fromJson(Map<String, dynamic> json) {
    return CustomerComplaint(
      callID: json['callID'],
      dateReceived: json['dateReceived'],
      customerCode: json['customerCode'],
      customerName: json['customerName'],
      plant: json['plant'],
      salesRep: json['salesRep'],
      salesManager: json['salesManager'],
      natureOfComplaint: json['natureOfComplaint'],
      productCode: json['productCode'],
      productName: json['productName'],
      mfrLotNo: json['mfrLotNo'],
      origin: json['origin'],
      rootCause: json['rootCause'],
      correctiveAction: json['correctiveAction'],
      preventiveAction: json['preventiveAction'],
      priority: json['priority'],
      status: json['status'],
      closedOn: json['closedOn'],
      callType: json['callType'],
      problemType: json['problemType'],
      handledBy: json['handledBy'],
    );
  }
}

class CustomerChartData {
  final String customerName;
  final String customerCode;
  final double value;
  final int count;
  final List<String> docNos; // SO No / Invoice No

  CustomerChartData({
    required this.customerName,
    required this.customerCode,
    required this.value,
    required this.count,
    required this.docNos,
  });
}

class CombinedCustomerData {
  final String customerCode;
  final String customerName;
  final double soValue;
  final double salesValue;

  final List<String> soNos;
  final List<String> invoiceNos;

  CombinedCustomerData({
    required this.customerCode,
    required this.customerName,
    required this.soValue,
    required this.salesValue,
    required this.soNos,
    required this.invoiceNos,
  });
}

class CombinedMonthData {
  final String docDate;
  final double soValue;
  final double salesValue;
  final List<String> soNos;
  final List<String> invoiceNos;

  CombinedMonthData({
    required this.docDate,
    required this.soValue,
    required this.salesValue,
    required this.soNos,
    required this.invoiceNos,
  });
}

class StockInTransitList {
  final String documentDate;
  final String documentNo;
  final String customerCode;
  final String customerName;
  final String itemNo;
  final String itemDescription;
  final String quantity;
  final String price;
  final String lineTotal;
  final String totalTax;
  final String totalAmount;
  final String fromWarehouse;
  final String toWarehouse;

  StockInTransitList({
    required this.documentDate,
    required this.documentNo,
    required this.customerCode,
    required this.customerName,
    required this.itemNo,
    required this.itemDescription,
    required this.quantity,
    required this.price,
    required this.lineTotal,
    required this.totalTax,
    required this.totalAmount,
    required this.fromWarehouse,
    required this.toWarehouse,
  });

  factory StockInTransitList.fromJson(Map<String, dynamic> json) {
    return StockInTransitList(
      documentDate: json["documentDate"] ?? "",
      documentNo: json["documentNo"] ?? "",
      customerCode: json["customerCode"] ?? "",
      customerName: json["customerName"] ?? "",
      itemNo: json["itemNo"] ?? "",
      itemDescription: json["itemDescription"] ?? "",
      quantity: json["quantity"]?.toString() ?? "0",
      price: json["price"]?.toString() ?? "0",
      lineTotal: json["lineTotal"]?.toString() ?? "0",
      totalTax: json["totalTax"]?.toString() ?? "0",
      totalAmount: json["totalAmount"]?.toString() ?? "0",
      fromWarehouse: json["fromWarehouse"] ?? "",
      toWarehouse: json["toWarehouse"] ?? "",
    );
  }
}

class CustomerCommitmentSummary {
  String customerCode;
  String customerName;
  double totalOutstanding;
  double totalCommitment;

  CustomerCommitmentSummary({
    required this.customerCode,
    required this.customerName,
    required this.totalOutstanding,
    this.totalCommitment = 0,
  });
}

class CustomerWeekCommitment {
  String customerCode;

  double week1;
  double week2;
  double week3;
  double week4;

  CustomerWeekCommitment({
    required this.customerCode,
    this.week1 = 0,
    this.week2 = 0,
    this.week3 = 0,
    this.week4 = 0,
  });
}

class VendorCommitmentSummary {
  String vendorCode;
  String vendorName;
  double totalOutstanding;
  double totalCommitment;

  VendorCommitmentSummary({
    required this.vendorCode,
    required this.vendorName,
    required this.totalOutstanding,
    this.totalCommitment = 0,
  });
}

class VendorMonthCommitment {
  String vendorCode;
  double commitment;

  VendorMonthCommitment({required this.vendorCode, this.commitment = 0});
}

class AdvancePaidCustomerData {
  String customerName;

  Map<String, double> monthlyAmounts;

  double total;

  AdvancePaidCustomerData({
    required this.customerName,
    required this.monthlyAmounts,
    required this.total,
  });
}
