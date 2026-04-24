// ignore_for_file: file_names, use_build_context_synchronously, non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:easy_stepper/easy_stepper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';

import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/classes/dashBoard.dart';

import '../../../api_helper.dart';
import '../../../classes/globals.dart';
import '../../../login_screen.dart';

bool touchedLastMonthGoals = false;
bool touchedThisMonthGoals = false;
bool touchedYTDGoals = false;
String deviceOrientation = "";
String selectedCustomerCode = "";
String selectedCustomerName = "";
LeadAnalysisList leadAnalysisList = LeadAnalysisList(leadAnalysisData: []);
LeadStatusList leadStatusList = LeadStatusList(leadStatusData: []);
LeadStageList leadStageList = LeadStageList(leadStageData: []);

int activeStep = 0;
TextEditingController fromDateController = TextEditingController();
TextEditingController toDateController = TextEditingController();

class OpportunityAnalysisPage extends StatefulWidget {
  const OpportunityAnalysisPage({super.key});

  @override
  State<OpportunityAnalysisPage> createState() =>
      _OpportunityAnalysisPageState();
}

class _OpportunityAnalysisPageState extends State<OpportunityAnalysisPage> {
  late Future<void> loadDataFuture;
  List<Map<String, dynamic>> customerList = [];
  var hospitalKey = GlobalKey();
  final TextEditingController _hospitalSearchController =
      TextEditingController();
  DateTime? currentDate;
  DateTime? currentMonthFromDate;
  DateTime? lastMonthFromDate;
  DateTime? lastMonthToDate;
  DateTime? currentQuarterFromDate;
  DateTime? currentQuarterToDate;
  DateTime? lastQuarterFromDate;
  DateTime? lastQuarterToDate;
  DateTime? fiscalYearStartDate;
  DateTime? prevFiscalYearStartDate;
  DateTime? prevFiscalYearEndDate;
  DateTime? q1FromDate;
  DateTime? q1ToDate;
  DateTime? q2FromDate;
  DateTime? q2ToDate;
  DateTime? q3FromDate;
  DateTime? q3ToDate;
  DateTime? q4FromDate;
  DateTime? q4ToDate;
  String financialYear = "";
  String prevFinancialYear = "";
  double selectedProduct = 0;
  int currentQuarter = 0;

  double Q1OpenCount = 0;
  int Q1OpenPercentage = 0;
  String Q1OpenPercentageStr = "";

  double Q1LostCount = 0;
  int Q1LostPercentage = 0;
  String Q1LostPercentageStr = "";

  double Q1WonCount = 0;
  int Q1WonPercentage = 0;
  String Q1WonPercentageStr = "";

  double Q2OpenCount = 0;
  int Q2OpenPercentage = 0;
  String Q2OpenPercentageStr = "";

  double Q2LostCount = 0;
  int Q2LostPercentage = 0;
  String Q2LostPercentageStr = "";

  double Q2WonCount = 0;
  int Q2WonPercentage = 0;
  String Q2WonPercentageStr = "";

  double Q3OpenCount = 0;
  int Q3OpenPercentage = 0;
  String Q3OpenPercentageStr = "";

  double Q3LostCount = 0;
  int Q3LostPercentage = 0;
  String Q3LostPercentageStr = "";

  double Q3WonCount = 0;
  int Q3WonPercentage = 0;
  String Q3WonPercentageStr = "";

  double Q4OpenCount = 0;
  int Q4OpenPercentage = 0;
  String Q4OpenPercentageStr = "";

  double Q4LostCount = 0;
  int Q4LostPercentage = 0;
  String Q4LostPercentageStr = "";

  double Q4WonCount = 0;
  int Q4WonPercentage = 0;
  String Q4WonPercentageStr = "";

  double Q1TotalCount = 0;
  double Q2TotalCount = 0;
  double Q3TotalCount = 0;
  double Q4TotalCount = 0;

  double YtdOpenCount = 0;
  double YtdLostCount = 0;
  double YtdWonCount = 0;
  double YtdTotalCount = 0;

  int YtdOpenPercentage = 0;
  int YtdLostPercentage = 0;
  int YtdWonPercentage = 0;

  String YtdOpenPercentageStr = "";
  String YtdLostPercentageStr = "";
  String YtdWonPercentageStr = "";

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _loadLeadsAnalysis(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectleadsanalysis';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            List<LeadAnalysisData> leadAnalysisDataList = [];
            for (var visit in data) {
              LeadAnalysisData leadAnalysisData = LeadAnalysisData(
                leadCustomerName: visit['LeadCustomerName'],
                leadID: visit['LeadID'],
                leadStageLevel: visit['LeadStageLevel'],
                leadStartDate: visit['LeadStartDate'],
                leadAging: visit['LeadAging'],
                leadEntryDate: visit['LeadEntryDate'],
                leadActivityType: visit['LeadActivityType'],
                leadFollowupTime: visit['LeadFollowupTime'],
                leadFollowupDate: visit['LeadFollowupDate'],
                leadStatus: visit['LeadStatus'],
                leadStage7Status: visit['LeadStage7Status'],
              );
              leadAnalysisDataList.add(leadAnalysisData);
            }
            setState(() {
              leadAnalysisList = LeadAnalysisList(
                leadAnalysisData: leadAnalysisDataList,
              );
            });
          }
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            final snackBar = SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(
                responseJson["Error"].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e.message'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadLeadStages(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    DateTime parsedDate = DateFormat(
      'dd/MM/yyyy',
    ).parse(fromDateController.text);
    String fromDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    parsedDate = DateFormat('dd/MM/yyyy').parse(toDateController.text);
    String toDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserId': userId,
      'FromDt': fromDate,
      'ToDt': toDate,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectleadstageanalysis';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            List<LeadStageData> leadStageDataList = [];
            for (var visit
                in selectedCustomerCode == ""
                    ? data
                    : data.where(
                        (item) =>
                            item['LeadCustomerCode'] == selectedCustomerCode,
                      )) {
              LeadStageData leadStageData = LeadStageData(
                leadID: visit['LeadID'],
                leadCustomerCode: visit['LeadCustomerCode'],
                leadOpenCount: visit['LeadOpenCount'].toDouble(),
                leadCloseCount: visit['LeadCloseCount'].toDouble(),
                leadWonCount: visit['LeadWonCount'].toDouble(),
                leadStageNumber: visit['LeadStageNumber'],
                leadStageLevel: '',
              );
              leadStageDataList.add(leadStageData);
            }
            setState(() {
              leadStageList = LeadStageList(leadStageData: leadStageDataList);
            });
          }
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            final snackBar = SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(
                responseJson["Error"].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadLeadStatus(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    DateTime parsedDate = DateFormat(
      'dd/MM/yyyy',
    ).parse(fromDateController.text);
    String fromDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    parsedDate = DateFormat('dd/MM/yyyy').parse(toDateController.text);
    String toDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserId': userId,
      'FromDt': fromDate,
      'ToDt': toDate,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectleadstatusanalysis';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            List<LeadStatusData> leadStatusDataList = [];
            for (var visit
                in selectedCustomerCode == ""
                    ? data
                    : data.where(
                        (item) =>
                            item['LeadCustomerCode'] == selectedCustomerCode,
                      )) {
              LeadStatusData leadStatusData = LeadStatusData(
                leadID: visit['LeadID'],
                leadCustomerCode: visit['LeadCustomerCode'],
                leadStatus: visit['LeadStatus'],
                stage1: visit['Stage1'],
                stage2: visit['Stage2'],
                stage3: visit['Stage3'],
                stage4: visit['Stage4'],
                stage5: visit['Stage5'],
                stage6: visit['Stage6'],
              );
              leadStatusDataList.add(leadStatusData);
            }
            setState(() {
              leadStatusList = LeadStatusList(
                leadStatusData: leadStatusDataList,
              );
            });
          }
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            final snackBar = SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(
                responseJson["Error"].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  int monthDifference(DateTime startDate, DateTime endDate) {
    int years = endDate.year - startDate.year;
    int months = endDate.month - startDate.month;
    int differenceInMonths = (years * 12) + months;
    return differenceInMonths;
  }

  Future<void> _loadEachQtrValues() async {
    double wonCount = 0, openCount = 0, lostCount = 0;
    for (int i = 1; i <= getCurrentQuarter(); i++) {
      switch (i) {
        case 1:
          wonCount = 0;
          openCount = 0;
          lostCount = 0;
          var curQtrLeads = leadAnalysisList.leadAnalysisData.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.leadStartDate);
            return invoiceDate.isAtLeast(q1FromDate!) &&
                invoiceDate.isAtMost(q1ToDate!);
          });
          for (var target in curQtrLeads.toList()) {
            if (target.leadStage7Status == "Won") {
              wonCount += 1;
            } else {
              openCount += target.leadStatus == "Open" ? 1 : 0;
              lostCount += target.leadStatus == "Close" ? 1 : 0;
            }
          }
          Q1OpenCount = openCount;
          Q1LostCount = lostCount;
          Q1WonCount = wonCount;
          Q1TotalCount = openCount + lostCount + wonCount;
          if (Q1OpenCount == 0) {
            Q1OpenPercentage = 0;
          } else {
            Q1OpenPercentage =
                double.tryParse(
                  ((Q1OpenCount / Q1TotalCount) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q1OpenPercentageStr = "${Q1OpenPercentage.toString()}%";

          if (Q1LostCount == 0) {
            Q1LostPercentage = 0;
          } else {
            Q1LostPercentage =
                double.tryParse(
                  ((Q1LostCount / Q1TotalCount) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q1LostPercentageStr = "${Q1LostPercentage.toString()}%";

          if (Q1WonCount == 0) {
            Q1LostPercentage = 0;
          } else {
            Q1WonPercentage =
                double.tryParse(
                  ((Q1WonCount / Q1TotalCount) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q1WonPercentageStr = "${Q1WonPercentage.toString()}%";
          break;
        case 2:
          wonCount = 0;
          openCount = 0;
          lostCount = 0;
          var curQtrLeads = leadAnalysisList.leadAnalysisData.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.leadStartDate);
            return invoiceDate.isAtLeast(q2FromDate!) &&
                invoiceDate.isAtMost(q2ToDate!);
          });
          for (var target in curQtrLeads.toList()) {
            if (target.leadStage7Status == "Won") {
              wonCount += 1;
            } else {
              openCount += target.leadStatus == "Open" ? 1 : 0;
              lostCount += target.leadStatus == "Close" ? 1 : 0;
            }
          }
          Q2OpenCount = openCount;
          Q2LostCount = lostCount;
          Q2WonCount = wonCount;
          Q2TotalCount = openCount + lostCount + wonCount;
          if (Q2OpenCount == 0) {
            Q2OpenPercentage = 0;
          } else {
            Q2OpenPercentage =
                double.tryParse(
                  ((Q2OpenCount / Q2TotalCount) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q2OpenPercentageStr = "${Q2OpenPercentage.toString()}%";

          if (Q2LostCount == 0) {
            Q2LostPercentage = 0;
          } else {
            Q2LostPercentage =
                double.tryParse(
                  ((Q2LostCount / Q2TotalCount) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q2LostPercentageStr = "${Q2LostPercentage.toString()}%";

          if (Q2WonCount == 0) {
            Q2LostPercentage = 0;
          } else {
            Q2WonPercentage =
                double.tryParse(
                  ((Q2WonCount / Q2TotalCount) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q2WonPercentageStr = "${Q2WonPercentage.toString()}%";
          break;
        case 3:
          wonCount = 0;
          openCount = 0;
          lostCount = 0;
          var curQtrLeads = leadAnalysisList.leadAnalysisData.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.leadStartDate);
            return invoiceDate.isAtLeast(q3FromDate!) &&
                invoiceDate.isAtMost(q3ToDate!);
          });
          for (var target in curQtrLeads.toList()) {
            if (target.leadStage7Status == "Won") {
              wonCount += 1;
            } else {
              openCount += target.leadStatus == "Open" ? 1 : 0;
              lostCount += target.leadStatus == "Close" ? 1 : 0;
            }
          }
          Q3OpenCount = openCount;
          Q3LostCount = lostCount;
          Q3WonCount = wonCount;
          Q3TotalCount = openCount + lostCount + wonCount;
          if (Q3OpenCount == 0) {
            Q3OpenPercentage = 0;
          } else {
            Q3OpenPercentage =
                double.tryParse(
                  ((Q3OpenCount / Q3TotalCount) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q3OpenPercentageStr = "${Q3OpenPercentage.toString()}%";

          if (Q3LostCount == 0) {
            Q3LostPercentage = 0;
          } else {
            Q3LostPercentage =
                double.tryParse(
                  ((Q3LostCount / Q3TotalCount) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q3LostPercentageStr = "${Q3LostPercentage.toString()}%";

          if (Q3WonCount == 0) {
            Q3LostPercentage = 0;
          } else {
            Q3WonPercentage =
                double.tryParse(
                  ((Q3WonCount / Q3TotalCount) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q3WonPercentageStr = "${Q3WonPercentage.toString()}%";
          break;
        case 4:
          wonCount = 0;
          openCount = 0;
          lostCount = 0;
          var curQtrLeads = leadAnalysisList.leadAnalysisData.where((target) {
            DateTime invoiceDate = DateFormat(
              'dd/MM/yyyy',
            ).parse(target.leadStartDate);
            return invoiceDate.isAtLeast(q4FromDate!) &&
                invoiceDate.isAtMost(q4ToDate!);
          });
          for (var target in curQtrLeads.toList()) {
            if (target.leadStage7Status == "Won") {
              wonCount += 1;
            } else {
              openCount += target.leadStatus == "Open" ? 1 : 0;
              lostCount += target.leadStatus == "Close" ? 1 : 0;
            }
          }
          Q4OpenCount = openCount;
          Q4LostCount = lostCount;
          Q4WonCount = wonCount;
          Q4TotalCount = openCount + lostCount + wonCount;
          if (Q4OpenCount == 0) {
            Q4OpenPercentage = 0;
          } else {
            Q4OpenPercentage =
                double.tryParse(
                  ((Q4OpenCount / Q4TotalCount) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q4OpenPercentageStr = "${Q4OpenPercentage.toString()}%";

          if (Q4LostCount == 0) {
            Q4LostPercentage = 0;
          } else {
            Q4LostPercentage =
                double.tryParse(
                  ((Q4LostCount / Q4TotalCount) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q4LostPercentageStr = "${Q4LostPercentage.toString()}%";

          if (Q4WonCount == 0) {
            Q4LostPercentage = 0;
          } else {
            Q4WonPercentage =
                double.tryParse(
                  ((Q4WonCount / Q4TotalCount) * 100).toStringAsFixed(2),
                )?.ceil() ??
                0;
          }
          Q4WonPercentageStr = "${Q4WonPercentage.toString()}%";
          break;
        default:
      }
    }
  }

  Future<void> _loadYTDValues() async {
    double wonCount = 0, openCount = 0, lostCount = 0;
    wonCount = 0;
    openCount = 0;
    lostCount = 0;

    var curQtrLeads = leadAnalysisList.leadAnalysisData.where((target) {
      DateTime startDate = DateFormat('dd/MM/yyyy').parse(target.leadStartDate);
      return startDate.isAtLeast(fiscalYearStartDate!) &&
          startDate.isAtMost(currentDate!);
    });
    for (var target in curQtrLeads.toList()) {
      if (target.leadStage7Status == "Won") {
        wonCount += 1;
      } else {
        openCount += target.leadStatus == "Open" ? 1 : 0;
        lostCount += target.leadStatus == "Close" ? 1 : 0;
      }
    }
    YtdOpenCount = openCount;
    YtdLostCount = lostCount;
    YtdWonCount = wonCount;
    YtdTotalCount = YtdOpenCount + YtdLostCount + YtdWonCount;
    if (YtdOpenCount == 0) {
      YtdOpenPercentage = 0;
    } else {
      YtdOpenPercentage =
          double.tryParse(
            ((YtdOpenCount / YtdTotalCount) * 100).toStringAsFixed(2),
          )?.ceil() ??
          0;
    }
    YtdOpenPercentageStr = "${YtdOpenPercentage.toString()}%";
    if (YtdLostCount == 0) {
      YtdLostPercentage = 0;
    } else {
      YtdLostPercentage =
          double.tryParse(
            ((YtdLostCount / YtdTotalCount) * 100).toStringAsFixed(2),
          )?.ceil() ??
          0;
    }
    YtdLostPercentageStr = "${YtdLostPercentage.toString()}%";
    if (YtdWonCount == 0) {
      YtdWonPercentage = 0;
    } else {
      YtdWonPercentage =
          double.tryParse(
            ((YtdWonCount / YtdTotalCount) * 100).toStringAsFixed(2),
          )?.ceil() ??
          0;
    }
    YtdWonPercentageStr = "${YtdWonPercentage.toString()}%";
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loadcustomer(userId, userJwtToken, userMailID);
    await _loadLeadsAnalysis(userId, userJwtToken, userMailID);
    await _loadLeadStages(userId, userJwtToken, userMailID);
    await _loadLeadStageChart();
    await _loadLeadStatus(userId, userJwtToken, userMailID);
    await _loadYTDValues();
    await _loadEachQtrValues();
  }

  Future<void> filterLeadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loadLeadStages(userId, userJwtToken, userMailID);
    await _loadLeadStatus(userId, userJwtToken, userMailID);
    await _loadLeadStageChart();
  }

  Future<void> _loadLeadStageChart() async {
    double openCount = 0;
    double closeCount = 0;
    double wonCount = 0;
    List<LeadStageData> leadStageDataList = [];
    for (int i = 1; i <= 6; i++) {
      for (var stage in leadStageList.leadStageData.where(
        (item) => item.leadStageNumber == i,
      )) {
        openCount += stage.leadOpenCount;
        closeCount += stage.leadCloseCount;
        wonCount += stage.leadWonCount;
      }
      leadStageDataList.add(
        LeadStageData(
          leadID: 0,
          leadCustomerCode: '',
          leadOpenCount: openCount,
          leadCloseCount: closeCount,
          leadWonCount: wonCount,
          leadStageNumber: i,
          leadStageLevel: 'Stage $i',
        ),
      );
      openCount = 0;
      closeCount = 0;
      wonCount = 0;
    }
    leadStageList = LeadStageList(leadStageData: leadStageDataList);
  }

  List<Hospital> convertList(List<Map<String, dynamic>> customerList) {
    return customerList
        .map(
          (map) => Hospital(
            customerCode: map['CustomerCode']?.toString() ?? '',
            customerName: map['CustomerName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  Future<List<Hospital>> getCustomer(String search) async {
    List<Hospital> hospitalList = convertList(customerList);
    List<Hospital> filteredHospitals = hospitalList
        .where(
          (element) =>
              element.customerName.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();

    return filteredHospitals;
  }

  Future<void> _loadcustomer(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectcustomermaster';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          final List data = jsonDecode(response.body)["Data"];
          List<Map<String, dynamic>> newCustomerList = [];
          for (var item in data) {
            final cust = {
              "CustomerCode": item["CustomerCode"],
              "CustomerName": item["CustomerName"],
            };
            newCustomerList.add(cust);
          }
          setState(() {
            customerList = newCustomerList;
          });
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            final snackBar = SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(
                responseJson["Error"].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } else {
        final snackBar = SnackBar(
          content: Text('HTTP Error: ${response.statusCode}'),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text(e.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  SideTitles get _bottomTitlesCustomer => SideTitles(
    reservedSize: 30,
    showTitles: true,
    getTitlesWidget: (value, meta) {
      String text = '';
      List<LeadStageData> customerWiseData = leadStageList.leadStageData;
      text = customerWiseData.elementAt(value.toInt()).leadStageLevel;
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      );
    },
  );

  List<BarChartGroupData> _customerAnalysisChartData(
    List<LeadStageData> leadStageData,
  ) {
    return leadStageData
        .map(
          (sales) => BarChartGroupData(
            x: leadStageData.indexOf(sales),
            barRods: [
              BarChartRodData(
                borderRadius: BorderRadius.zero,
                color: const Color(0xFF6CCC3F),
                toY: sales.leadWonCount,
                width: 15,
              ),
              BarChartRodData(
                borderRadius: BorderRadius.zero,
                color: const Color(0xFF2CA9DF),
                toY: sales.leadOpenCount,
                width: 15,
              ),
              BarChartRodData(
                borderRadius: BorderRadius.zero,
                color: const Color(0xFFF49136),
                toY: sales.leadCloseCount,
                width: 15,
              ),
            ],
          ),
        )
        .toList();
  }

  int getCurrentQuarter() {
    int monthIndex = DateTime.now().month;
    switch (monthIndex) {
      case 4:
      case 5:
      case 6:
        return 1;
      case 7:
      case 8:
      case 9:
        return 2;
      case 10:
      case 11:
      case 12:
        return 3;
      case 1:
      case 2:
      case 3:
        return 4;
      default:
        throw Error();
    }
  }

  void getLastQuarterDates() {
    DateTime now = DateTime.now();
    switch (getCurrentQuarter()) {
      case 1:
        lastQuarterFromDate = DateTime(now.year, 1, 1);
        lastQuarterToDate = DateTime(now.year, 3, 31);
        break;
      case 2:
        lastQuarterFromDate = DateTime(now.year, 4, 1);
        lastQuarterToDate = DateTime(now.year, 6, 30);
        break;
      case 3:
        lastQuarterFromDate = DateTime(now.year, 7, 1);
        lastQuarterToDate = DateTime(now.year, 9, 30);
        break;
      case 4:
        lastQuarterFromDate = DateTime(now.year - 1, 10, 1);
        lastQuarterToDate = DateTime(now.year - 1, 12, 31);
        break;
      default:
        throw Error();
    }
  }

  DateTime addMonth(DateTime date, int addMonth) {
    int currentMonth = date.month;
    int currentYear = date.year;
    int nextMonth = currentMonth + addMonth;
    int nextYear = currentYear;
    // Handle the case when the next month is December
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }

    int lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    // Handle the case when the original date is at the end of the month
    int originalDay = date.day;
    if (originalDay > lastDayOfNextMonth) {
      originalDay = lastDayOfNextMonth;
    }
    return DateTime(nextYear, nextMonth, originalDay);
  }

  void LoadDates() {
    currentDate = DateTime.now();
    currentMonthFromDate = DateTime(currentDate!.year, currentDate!.month, 1);
    lastMonthFromDate = DateTime(currentDate!.year, currentDate!.month - 1, 1);
    lastMonthToDate = DateTime(currentDate!.year, currentDate!.month, 0);
    int fiscalYearStartMonth = 4;
    currentQuarter = getCurrentQuarter();
    getLastQuarterDates();
    DateTime now = DateTime.now();
    switch (currentQuarter) {
      case 1:
        currentQuarterFromDate = DateTime(now.year, 4, 1);
        currentQuarterToDate = DateTime(now.year, 6, 30);
      case 2:
        currentQuarterFromDate = DateTime(now.year, 7, 1);
        currentQuarterToDate = DateTime(now.year, 9, 30);
      case 3:
        currentQuarterFromDate = DateTime(now.year, 10, 1);
        currentQuarterToDate = DateTime(now.year, 12, 31);
      case 4:
        currentQuarterFromDate = DateTime(now.year - 1, 1, 1);
        currentQuarterToDate = DateTime(now.year - 1, 3, 31);
      default:
        throw Error();
    }
    int fiscalYear = currentDate!.month >= fiscalYearStartMonth
        ? currentDate!.year
        : currentDate!.year - 1;
    fiscalYearStartDate = DateTime(fiscalYear, fiscalYearStartMonth, 1);
    prevFiscalYearStartDate = addMonth(fiscalYearStartDate!, -12);
    prevFiscalYearEndDate = DateTime(prevFiscalYearStartDate!.year + 1, 4, 0);
    int fiscalYearStartYear = currentDate!.month >= 4
        ? currentDate!.year
        : currentDate!.year - 1;

    int fiscalYearEndYear = fiscalYearStartYear + 1;
    financialYear =
        'FY${fiscalYearStartYear.toString().substring(2)}-${fiscalYearEndYear.toString().substring(2)}';

    int prevFiscalYearStartYear = fiscalYearStartYear - 1;
    int prevFiscalYearEndYear = prevFiscalYearStartYear + 1;
    prevFinancialYear =
        'FY${prevFiscalYearStartYear.toString().substring(2)}-${prevFiscalYearEndYear.toString().substring(2)}';
    setState(() {
      String formattedDate = DateFormat('dd/MM/yyyy').format(
        DateTime(
          fiscalYearStartDate!.year,
          fiscalYearStartDate!.month,
          fiscalYearStartDate!.day,
        ),
      );
      fromDateController.text = formattedDate;
      formattedDate = DateFormat('dd/MM/yyyy').format(
        DateTime(currentDate!.year, currentDate!.month, currentDate!.day),
      );
      toDateController.text = formattedDate;
    });
  }

  void LoadAllQuarterFromToDates() {
    DateTime now = DateTime.now();

    // Determine the financial year start
    int financialYearStart = (now.month >= 4) ? now.year : now.year - 1;

    // Define quarters
    q1FromDate = DateTime(financialYearStart, 4, 1);
    q1ToDate = DateTime(financialYearStart, 7, 0);

    q2FromDate = DateTime(financialYearStart, 7, 1);
    q2ToDate = DateTime(financialYearStart, 10, 0);

    q3FromDate = DateTime(financialYearStart, 10, 1);
    q3ToDate = DateTime(financialYearStart + 1, 1, 0); // December 31

    q4FromDate = DateTime(financialYearStart + 1, 1, 1);
    q4ToDate = DateTime(financialYearStart + 1, 4, 0); // March 31
  }

  @override
  void initState() {
    super.initState();
    LoadDates();
    LoadAllQuarterFromToDates();
    if (isUserLoggedIn && isBiDashboardStart) {
      loadDataFuture = loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      deviceOrientation = "Portrait";
    } else {
      deviceOrientation = "Landscape";
    }
    final screenHeight = MediaQuery.of(context).size.height;

    double containerHeight = 0;

    if (deviceOrientation == "Portrait") {
      containerHeight = screenHeight * 0.06;
    } else {}
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [SizedBox(width: 15), Text("DD/MM/YY - DD/MM/YY")],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_alt_outlined),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ],
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                        child: CircularPercentIndicator(
                          arcType: ArcType.HALF,
                          radius: 55.0,
                          lineWidth: 20.0,
                          animation: true,
                          percent: YtdWonPercentage.toDouble() / 100,
                          center: Column(
                            children: [
                              const SizedBox(height: 30),
                              Text(
                                YtdWonPercentageStr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: touchedLastMonthGoals ? 13.0 : 12.0,
                                  color: touchedLastMonthGoals
                                      ? Colors.cyan
                                      : Colors.black,
                                ),
                              ),
                              Text(
                                YtdWonCount.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: touchedLastMonthGoals ? 11.0 : 10.0,
                                  color: touchedLastMonthGoals
                                      ? Colors.cyan
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Center(
                                child: Text(
                                  'Won\n(${YtdTotalCount.toStringAsFixed(0)})',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: touchedLastMonthGoals
                                        ? 11.0
                                        : 10.0,
                                    color: touchedLastMonthGoals
                                        ? Colors.cyan
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          curve: Curves.linear,
                          circularStrokeCap: CircularStrokeCap.butt,
                          progressColor: const Color(0xFF6CCC3F),
                          arcBackgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CircularPercentIndicator(
                          arcType: ArcType.HALF,
                          radius: 55.0,
                          lineWidth: 20.0,
                          animation: true,
                          percent: YtdOpenPercentage.toDouble() / 100,
                          center: Column(
                            children: [
                              const SizedBox(height: 30),
                              Text(
                                YtdOpenPercentageStr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: touchedLastMonthGoals ? 13.0 : 12.0,
                                  color: touchedLastMonthGoals
                                      ? Colors.cyan
                                      : Colors.black,
                                ),
                              ),
                              Text(
                                YtdOpenCount.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: touchedLastMonthGoals ? 11.0 : 10.0,
                                  color: touchedLastMonthGoals
                                      ? Colors.cyan
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Center(
                                child: Text(
                                  'Open\n(${YtdTotalCount.toStringAsFixed(0)})',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: touchedLastMonthGoals
                                        ? 11.0
                                        : 10.0,
                                    color: touchedLastMonthGoals
                                        ? Colors.cyan
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          curve: Curves.linear,
                          circularStrokeCap: CircularStrokeCap.butt,
                          progressColor: const Color(0xFF2CA9DF),
                          arcBackgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CircularPercentIndicator(
                          arcType: ArcType.HALF,
                          radius: 55.0,
                          lineWidth: 20.0,
                          animation: true,
                          percent: YtdLostPercentage.toDouble() / 100,
                          center: Column(
                            children: [
                              const SizedBox(height: 30),
                              Text(
                                YtdLostPercentageStr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: touchedLastMonthGoals ? 13.0 : 12.0,
                                  color: touchedLastMonthGoals
                                      ? Colors.cyan
                                      : Colors.black,
                                ),
                              ),
                              Text(
                                YtdLostCount.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: touchedLastMonthGoals ? 11.0 : 10.0,
                                  color: touchedLastMonthGoals
                                      ? Colors.cyan
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Center(
                                child: Text(
                                  'Lost\n(${YtdTotalCount.toStringAsFixed(0)})',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: touchedLastMonthGoals
                                        ? 11.0
                                        : 10.0,
                                    color: touchedLastMonthGoals
                                        ? Colors.cyan
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          curve: Curves.linear,
                          circularStrokeCap: CircularStrokeCap.butt,
                          progressColor: const Color(0xFFF49136),
                          arcBackgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Total Leads: ${YtdTotalCount.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                preferBelow: false,
                richMessage: WidgetSpan(
                  child: Column(
                    children: [
                      const Text(
                        "Quarter 1 Analysis",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Column(
                        children: [
                          Text("Open : $Q1OpenCount"),
                          Text("Lost : $Q1LostCount"),
                          Text("Won : $Q1WonCount"),
                        ],
                      ),
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                triggerMode: TooltipTriggerMode.longPress,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff6CCC3F).withValues(alpha: 0.5),
                    border: const Border(
                      left: BorderSide(color: Colors.black, width: 1.0),
                      top: BorderSide(color: Colors.black, width: 1.0),
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Q1",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              Tooltip(
                preferBelow: false,
                richMessage: WidgetSpan(
                  child: Column(
                    children: [
                      const Text(
                        "Quarter 1 Analysis",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Column(
                        children: [
                          Text("Open : $Q1OpenCount"),
                          Text("Lost : $Q1LostCount"),
                          Text("Won : $Q1WonCount"),
                        ],
                      ),
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                triggerMode: TooltipTriggerMode.longPress,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.black, width: 1.0),
                      top: BorderSide(color: Colors.black, width: 1.0),
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Q1OpenPercentageStr != ""
                        ? Text(Q1OpenPercentageStr)
                        : const Text("      "),
                  ),
                ),
              ),
              Tooltip(
                preferBelow: false,
                richMessage: WidgetSpan(
                  child: Column(
                    children: [
                      const Text(
                        "Quarter 2 Analysis",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Column(
                        children: [
                          Text("Open : $Q2OpenCount"),
                          Text("Lost : $Q2LostCount"),
                          Text("Won : $Q2WonCount"),
                        ],
                      ),
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                triggerMode: TooltipTriggerMode.longPress,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF49136).withValues(alpha: 0.5),
                    border: const Border(
                      left: BorderSide(color: Colors.black, width: 1.0),
                      top: BorderSide(color: Colors.black, width: 1.0),
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Q2",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              Tooltip(
                preferBelow: false,
                richMessage: WidgetSpan(
                  child: Column(
                    children: [
                      const Text(
                        "Quarter 2 Analysis",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Column(
                        children: [
                          Text("Open : $Q2OpenCount"),
                          Text("Lost : $Q2LostCount"),
                          Text("Won : $Q2WonCount"),
                        ],
                      ),
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                triggerMode: TooltipTriggerMode.longPress,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.black, width: 1.0),
                      top: BorderSide(color: Colors.black, width: 1.0),
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Q2OpenPercentageStr != ""
                        ? Text(Q2OpenPercentageStr)
                        : const Text("      "),
                  ),
                ),
              ),
              Tooltip(
                preferBelow: false,
                richMessage: WidgetSpan(
                  child: Column(
                    children: [
                      const Text(
                        "Quarter 3 Analysis",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Column(
                        children: [
                          Text("Open : $Q3OpenCount"),
                          Text("Lost : $Q3LostCount"),
                          Text("Won : $Q3WonCount"),
                        ],
                      ),
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                triggerMode: TooltipTriggerMode.longPress,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE92729).withValues(alpha: 0.5),
                    border: const Border(
                      left: BorderSide(color: Colors.black, width: 1.0),
                      top: BorderSide(color: Colors.black, width: 1.0),
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Q3",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              Tooltip(
                preferBelow: false,
                richMessage: WidgetSpan(
                  child: Column(
                    children: [
                      const Text(
                        "Quarter 3 Analysis",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Column(
                        children: [
                          Text("Open : $Q3OpenCount"),
                          Text("Lost : $Q3LostCount"),
                          Text("Won : $Q3WonCount"),
                        ],
                      ),
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                triggerMode: TooltipTriggerMode.longPress,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.black, width: 1.0),
                      top: BorderSide(color: Colors.black, width: 1.0),
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Q3OpenPercentageStr != ""
                        ? Text(Q3OpenPercentageStr)
                        : const Text("      "),
                  ),
                ),
              ),
              Tooltip(
                preferBelow: false,
                richMessage: WidgetSpan(
                  child: Column(
                    children: [
                      const Text(
                        "Quarter 4 Analysis",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Column(
                        children: [
                          Text("Open : $Q4OpenCount"),
                          Text("Lost : $Q4LostCount"),
                          Text("Won : $Q4WonCount"),
                        ],
                      ),
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                triggerMode: TooltipTriggerMode.longPress,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6CCC3F).withValues(alpha: 0.5),
                    border: const Border(
                      left: BorderSide(color: Colors.black, width: 1.0),
                      top: BorderSide(color: Colors.black, width: 1.0),
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Q4",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              Tooltip(
                preferBelow: false,
                richMessage: WidgetSpan(
                  child: Column(
                    children: [
                      const Text(
                        "Quarter 4 Analysis",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Column(
                        children: [
                          Text("Open : $Q4OpenCount"),
                          Text("Lost : $Q4LostCount"),
                          Text("Won : $Q4WonCount"),
                        ],
                      ),
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                triggerMode: TooltipTriggerMode.longPress,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.black, width: 1.0),
                      right: BorderSide(color: Colors.black, width: 1.0),
                      top: BorderSide(color: Colors.black, width: 1.0),
                      bottom: BorderSide(color: Colors.black, width: 1.0),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Q4OpenPercentageStr != ""
                        ? Text(Q4OpenPercentageStr)
                        : const Text("      "),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0),
            child: Divider(thickness: 2),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 15),
                  Text(
                    "Stage Wise Analysis",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert_outlined),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: _customerAnalysis(),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0),
            child: Divider(thickness: 2),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 5),
                  Text(
                    "Lead Status",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: SizedBox(
                        height: deviceOrientation == "Portrait"
                            ? containerHeight
                            : MediaQuery.of(context).size.height * 0.13,

                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    elevation: 0,
                                    child: AsyncAutocomplete<Hospital>(
                                      onChanged: (s) {
                                        setState(() {
                                          _hospitalSearchController.text == s;
                                        });
                                      },
                                      onSaved: (s) {
                                        setState(() {
                                          _hospitalSearchController.text == s;
                                        });
                                      },
                                      maxListHeight:
                                          deviceOrientation == "Portrait"
                                          ? 370
                                          : 220,
                                      decoration: InputDecoration(
                                        border: UnderlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,
                                        labelText: 'Hospital Name',
                                        labelStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF8F8F8F),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: const BorderSide(
                                            color: Colors
                                                .blue, // Set your desired focus color
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6.0,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.only(
                                          left: 0,
                                          right: 30,
                                          top: 0,
                                          bottom: 0,
                                        ),
                                      ),
                                      controller: _hospitalSearchController,
                                      inputKey: hospitalKey,
                                      onTapItem: (Hospital hospital) async {
                                        if (!mounted) return;
                                        setState(() {
                                          _hospitalSearchController.text =
                                              hospital.customerName;
                                          selectedCustomerCode =
                                              hospital.customerCode;
                                        });
                                      },
                                      suggestionBuilder: (data) => ListTile(
                                        title: Text(
                                          data.customerName,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      asyncSuggestions: (searchValue) async {
                                        final result = await getCustomer(
                                          searchValue,
                                        );

                                        if (!mounted) return []; // << FIX
                                        return result;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: -1,
                              bottom: 0,
                              child: Visibility(
                                child: SizedBox(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (!mounted) return;
                                      setState(() {
                                        _hospitalSearchController.text = "";
                                        selectedCustomerCode = "";
                                      });
                                    },
                                    child: _hospitalSearchController.text == ""
                                        ? Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.transparent,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.only(
                                                top: 14,
                                                right: 2,
                                              ),
                                              child: Icon(
                                                Icons.search,
                                                color: Color(0xff2ca9df),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.transparent,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.only(
                                                top: 14,
                                                right: 2,
                                              ),
                                              child: Icon(
                                                Icons.close_rounded,
                                                size: 20,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 10),
                        const Text(
                          "From",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8F8F8F),
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 5.0,
                              right: 5,
                              bottom: 5,
                            ),
                            child: TextField(
                              controller: fromDateController,
                              readOnly: true,
                              style: const TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF8F8F8F),
                              ),
                              decoration: InputDecoration(
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFF8F8F8F),
                                  ),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFF8F8F8F),
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 20,
                                    color: Color(0xFF8F8F8F),
                                  ),
                                  onPressed: () async {
                                    DateTime? selectedDate =
                                        await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2101),
                                          initialEntryMode:
                                              DatePickerEntryMode.calendar,
                                        );
                                    String formattedDateTime =
                                        DateFormat('dd/MM/yyyy').format(
                                          DateTime(
                                            selectedDate!.year,
                                            selectedDate.month,
                                            selectedDate.day,
                                          ),
                                        );
                                    fromDateController.text = formattedDateTime;
                                  },
                                ),
                                hintText: 'dd/MM/yyyy',
                                border: const UnderlineInputBorder(),
                                hintStyle: const TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8F8F8F),
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "To",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8F8F8F),
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 5.0,
                                right: 5,
                                bottom: 5,
                              ),
                              child: TextField(
                                controller: toDateController,
                                readOnly: true,
                                style: const TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF8F8F8F),
                                ),
                                decoration: InputDecoration(
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF8F8F8F),
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF8F8F8F),
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 20,
                                      color: Color(0xFF8F8F8F),
                                    ),
                                    onPressed: () async {
                                      DateTime? selectedDate =
                                          await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2101),
                                            initialEntryMode:
                                                DatePickerEntryMode.calendar,
                                          );
                                      String formattedDate =
                                          DateFormat('dd/MM/yyyy').format(
                                            DateTime(
                                              selectedDate!.year,
                                              selectedDate.month,
                                              selectedDate.day,
                                            ),
                                          );
                                      toDateController.text = formattedDate;
                                    },
                                  ),
                                  hintText: 'dd/MM/yyyy',
                                  border: const UnderlineInputBorder(),
                                  hintStyle: const TextStyle(
                                    fontFamily: "Poppins",
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF8F8F8F),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        filterLeadStatus();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Container(
                          color: const Color(0xff2CA9DF),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Go',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.only(left: 8, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'L.Id',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xff454545),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Stage 1',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xff454545),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Stage 2',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xff454545),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Stage 3',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xff454545),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Stage 4',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xff454545),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Stage 5',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xff454545),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Stage 6',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xff454545),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: _leadStages(context),
          ),
        ],
      ),
    );
  }

  Widget _leadStages(BuildContext context) {
    return SizedBox(
      height: 350,
      child: ListView.builder(
        itemCount: leadStatusList.leadStatusData.length,
        itemBuilder: (context, index) {
          LeadStatusData leadStage = leadStatusList.leadStatusData[index];

          List<String> stages = [
            leadStage.stage1,
            leadStage.stage2,
            leadStage.stage3,
            leadStage.stage4,
            leadStage.stage5,
            leadStage.stage6,
          ];
          int nonEmptyStagesCount = stages
              .where((stage) => stage.isNotEmpty)
              .length;
          return Container(
            height: 100,
            color: const Color(0xffffffff),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    leadStage.leadID,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff454545),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: EasyStepper(
                        activeStep: 0,
                        lineStyle: const LineStyle(
                          lineLength: 40,
                          lineSpace: 0,
                          lineType: LineType.normal,
                          defaultLineColor: Color(0xffCFCFCF),
                        ),
                        activeStepTextColor: Colors.black87,
                        finishedStepTextColor: Colors.black87,
                        internalPadding: 0,
                        showLoadingAnimation: false,
                        stepRadius: 8,
                        showStepBorder: false,
                        steps: List.generate(stages.length, (stepIndex) {
                          return EasyStep(
                            customStep: CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 7,
                                backgroundColor: stages[stepIndex].isNotEmpty
                                    ? leadStage.leadStatus != 'Close'
                                          ? const Color(0xff6CCC3F)
                                          : nonEmptyStagesCount - 1 == stepIndex
                                          ? const Color.fromARGB(
                                              255,
                                              235,
                                              89,
                                              5,
                                            )
                                          : const Color(0xff6CCC3F)
                                    : const Color(0xffCFCFCF),
                              ),
                            ),
                            customTitle: Text(
                              stages[stepIndex],
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }),
                        onStepReached: (index) =>
                            setState(() => activeStep = index),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _customerAnalysis() {
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 350,
        width: screenWidth * 1.6,
        child: BarChart(
          BarChartData(
            // maxY: getMaxValue(monthlySalesList),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30),
              ),
              topTitles: AxisTitles(sideTitles: _emptyTitlesTop),
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitlesCustomer,
                axisNameSize: 20,
              ),
            ),
            gridData: FlGridData(
              show: true,
              checkToShowHorizontalLine: (value) => value % 10 == 0,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade300, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade400, width: 0.7),
                top: BorderSide(color: Colors.grey.shade400, width: 0.7),
              ),
            ),
            barGroups: _customerAnalysisChartData(leadStageList.leadStageData),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchTooltipData: BarTouchTooltipData(
                maxContentWidth: 200,
                tooltipBorder: const BorderSide(
                  width: 2.0,
                  color: Colors.black12,
                  style: BorderStyle.none,
                ),
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    '',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    children: <TextSpan>[
                      const TextSpan(
                        text: "Total : 64\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "Total Value : 121.00 L\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "--------------\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "Won : 21\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "Percentage : 64%\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "Value : 61.01 L\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "--------------\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "Open : 10\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "Percentage : 24%\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "Value : 24.00 L\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "--------------\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "Lost : 2\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "Percentage : 24%\n",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const TextSpan(
                        text: "Value : 24.00 L",
                        style: TextStyle(
                          color: Colors.black, //widget.touchedBarColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    textAlign: TextAlign.start,
                  );
                },
                getTooltipColor: (group) => Colors.white,
                fitInsideVertically: true,
                fitInsideHorizontally: true,
              ),
              handleBuiltInTouches: true,
              touchExtraThreshold: const EdgeInsets.all(10),
            ),
          ),
        ),
      ),
    );
  }
}

class Hospital {
  String customerName;
  String customerCode;
  Hospital({required this.customerCode, required this.customerName});
}
