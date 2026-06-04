// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/classes/globals.dart';
import '../../../api_helper.dart';
import '../../../login_screen.dart';
import '../../../notificationService.dart';

class DeliveryAnalysisTableData {
  final String invoiceDate;
  final double deliveryValue;
  final String deliveryStatus;
  final String deliveryRemarks;
  DeliveryAnalysisTableData({
    required this.invoiceDate,
    required this.deliveryValue,
    required this.deliveryStatus,
    required this.deliveryRemarks,
  });
}

class Distributor {
  String customerName;
  String customerCode;
  Distributor({required this.customerCode, required this.customerName});
}

List<DeliveryAnalysisTableData> deliveryDataList = [
  DeliveryAnalysisTableData(
    invoiceDate: "Xxxxx/05/04/23",
    deliveryValue: 60.00,
    deliveryStatus: "75 days",
    deliveryRemarks: "Partially Pending",
  ),
  DeliveryAnalysisTableData(
    invoiceDate: "Xxxxx/05/04/23",
    deliveryValue: 60.00,
    deliveryStatus: "75 days",
    deliveryRemarks: "Partially Pending",
  ),
  DeliveryAnalysisTableData(
    invoiceDate: "Xxxxx/05/04/23",
    deliveryValue: 60.00,
    deliveryStatus: "75 days",
    deliveryRemarks: "Partially Pending",
  ),
  DeliveryAnalysisTableData(
    invoiceDate: "Xxxxx/05/04/23",
    deliveryValue: 60.00,
    deliveryStatus: "75 days",
    deliveryRemarks: "Partially Pending",
  ),
  DeliveryAnalysisTableData(
    invoiceDate: "Xxxxx/05/04/23",
    deliveryValue: 60.00,
    deliveryStatus: "75 days",
    deliveryRemarks: "Partially Pending",
  ),
  DeliveryAnalysisTableData(
    invoiceDate: "Xxxxx/05/04/23",
    deliveryValue: 60.00,
    deliveryStatus: "75 days",
    deliveryRemarks: "Partially Pending",
  ),
  DeliveryAnalysisTableData(
    invoiceDate: "Xxxxx/05/04/23",
    deliveryValue: 60.00,
    deliveryStatus: "75 days",
    deliveryRemarks: "Partially Pending",
  ),
];
String deviceOrientation = "";
final TextEditingController customerController = TextEditingController();
late Future<void> loadDataFuture;

class CustomerDeliverAnalysis extends StatefulWidget {
  final String customerCode;
  const CustomerDeliverAnalysis({super.key, required this.customerCode});

  @override
  State<CustomerDeliverAnalysis> createState() =>
      _CustomerDeliverAnalysisState();
}

List<PieChartSectionData> showingSections() {
  return List.generate(4, (i) {
    final isTouched = i == touchedIndex;
    final fontSize = isTouched ? 12.0 : 11.0;
    final radius = isTouched ? 80.0 : 75.0;
    const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
    switch (i) {
      case 0:
        return PieChartSectionData(
          color: Colors.green,
          value: 45,
          title: '45 %',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            color: Colors.black,
            shadows: shadows,
          ),
        );
      case 1:
        return PieChartSectionData(
          color: Colors.orange,
          value: 30,
          title: '30 %',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            color: Colors.black,
            shadows: shadows,
          ),
        );
      case 2:
        return PieChartSectionData(
          color: Colors.grey,
          value: 15,
          title: '15 %',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            color: Colors.black,
            shadows: shadows,
          ),
        );
      case 3:
        return PieChartSectionData(
          color: Colors.blue,
          value: 20,
          title: '20 %',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            color: Colors.black,
            shadows: shadows,
          ),
        );
      default:
        throw Error();
    }
  });
}

int touchedIndex = -1;

class _CustomerDeliverAnalysisState extends State<CustomerDeliverAnalysis> {
  var distributorKey = GlobalKey();
  List<Map<String, dynamic>> distributorList = [];
  String selectedDistributorName = "";
  String selectedDistributorId = "";

  List<Distributor> convertDist(List<Map<String, dynamic>> distributorList) {
    return distributorList
        .map(
          (map) => Distributor(
            customerCode: map['CustomerCode']?.toString() ?? '',
            customerName: map['CustomerName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  Future<List<Distributor>> getDistributor(String search) async {
    List<Distributor> distList = convertDist(distributorList);
    List<Distributor> filteredList = distList
        .where(
          (element) => element.customerName.toLowerCase().startsWith(
            search.toLowerCase(),
          ),
        )
        .toList();

    return filteredList;
  }

  Future<void> _loaddistributor(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectdistributormaster';
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
        // int dataLength = data.length;
        if (status && responseJson["Data"].toString().isNotEmpty) {
          final List data = jsonDecode(response.body)["Data"];
          List<Map<String, dynamic>> newDistributorList = [];
          for (var item in data) {
            final dist = {
              "CustomerCode": item["CustomerCode"],
              "CustomerName": item["CustomerName"],
            };
            newDistributorList.add(dist);
          }
          setState(() {
            distributorList = newDistributorList;
          });
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            if (!mounted) return;
            NotificationService.warning(
              title: "Security Alert",
              message: "Invalid or Expired Token.",
            );
            navigateToLoginScreen();
          } else {
            if (!mounted) return;
            NotificationService.error(
              title: "Error",
              message: responseJson["Error"].toString(),
            );
          }
        }
      } else {
        if (!mounted) return;
        NotificationService.info(
          title: "Info",
          message: "Distributor details not available.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(title: "Error", message: e.toString());
    }
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> loadData(String selectedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loaddistributor(userId, userJwtToken, userMailID);
  }

  @override
  void initState() {
    super.initState();
    if (isUserLoggedIn && isCustomerDashboardStart) {
      loadDataFuture = loadData("");
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
    double containerDropDownHeight = 0;
    double containerHeight = 0;

    if (deviceOrientation == "Portrait") {
      containerDropDownHeight = screenHeight * 0.06;
      containerHeight = screenHeight * 0.06;
    } else {
      containerDropDownHeight = screenHeight * 0.12;
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Monthly Delivery", style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 32.0,
            ),
            child: SizedBox(
              height: deviceOrientation == "Portrait"
                  ? containerHeight
                  : containerDropDownHeight / 1.5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AsyncAutocomplete<Distributor>(
                      onChanged: (s) {
                        setState(() {
                          customerController.text == s;
                        });
                      },
                      onSaved: (s) {
                        setState(() {
                          customerController.text == s;
                        });
                      },
                      maxListHeight: deviceOrientation == "Portrait"
                          ? 370
                          : 220,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.only(
                          left: 0,
                          right: 30,
                          top: 0,
                          bottom: 0,
                        ),
                        border: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        hintText: 'Account Name',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8F8F8F),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.blue, // Set your desired focus color
                          ),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                      controller: customerController,
                      inputKey: distributorKey,
                      onTapItem: (Distributor distributor) async {
                        setState(() {
                          // selectedOption2 = distributor.CustomerName;
                          customerController.text = distributor.customerName;
                          var customer = distributorList.firstWhere(
                            (map) =>
                                map['CustomerName'] == distributor.customerName,
                            // orElse: () =>
                            //     <String, dynamic>{'CustomerCode': null},
                          );
                          selectedDistributorId = customer['CustomerCode']
                              .toString();
                          selectedDistributorName = distributor.customerName;
                        });
                      },
                      suggestionBuilder: (data) =>
                          ListTile(title: Text(data.customerName)),
                      asyncSuggestions: (searchValue) =>
                          getDistributor(searchValue),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: -1,
                    bottom: 2,
                    child: Visibility(
                      child: SizedBox(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              // selectedOption2 = '';
                              selectedDistributorId = "";
                              selectedDistributorName = "";
                              customerController.clear();
                              // _clearControls();
                            });
                          },
                          child: customerController.text == ""
                              ? Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.only(top: 14, right: 2),
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
                                    padding: EdgeInsets.only(top: 14, right: 2),
                                    child: Icon(
                                      Icons.cancel_outlined,
                                      color: Color(0xff2ca9df),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 0.0, top: 32),
                child: CircularPercentIndicator(
                  arcType: ArcType.HALF,
                  radius: 80.0,
                  lineWidth: 35.0,
                  animation: true,
                  percent: 0.65,
                  center: const Column(
                    children: [
                      SizedBox(height: 40),
                      Text(
                        "65%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        "64,00,000",
                        style: TextStyle(fontSize: 14.0, color: Colors.black),
                      ),
                      Center(
                        child: Text(
                          "Collection Progress (%)",
                          style: TextStyle(fontSize: 10.0, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  curve: Curves.linear,
                  circularStrokeCap: CircularStrokeCap.butt,
                  progressColor: Colors.red,
                  arcBackgroundColor: Colors.grey.shade200,
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0, right: 24),
                    child: SizedBox(
                      height: 100,
                      width: 100,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      touchedIndex = -1;
                                      return;
                                    }
                                    touchedIndex = pieTouchResponse
                                        .touchedSection!
                                        .touchedSectionIndex;
                                  });
                                },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 0,
                          centerSpaceRadius: 0,
                          startDegreeOffset: 180,
                          sections: showingSections(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 8,
                              width: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 8),
                            Container(height: 8, width: 16, color: Colors.blue),
                          ],
                        ),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              "On Time",
                              textAlign: TextAlign.left,
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              "0 - 5 Days Delay",
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                height: 8,
                                width: 16,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                height: 8,
                                width: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              "6 - 15 Days Delay",
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              "16+ Days Delay",
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0),
            child: Divider(thickness: 2),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 16.0, left: 16),
                child: Text("Open PO", style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Center(
              child: Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.all(20),
                    child: Table(
                      defaultColumnWidth: const FixedColumnWidth(150.0),
                      border: TableBorder.all(
                        color: Colors.black,
                        style: BorderStyle.solid,
                        width: 0.5,
                      ),
                      children: [
                        const TableRow(
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Invoice No/Date',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Value (in L)',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Remarks',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        for (var data in deliveryDataList)
                          TableRow(
                            children: [
                              Column(children: [Text(data.invoiceDate)]),
                              Column(
                                children: [Text(data.deliveryValue.toString())],
                              ),
                              Column(children: [Text(data.deliveryStatus)]),
                              Column(children: [Text(data.deliveryRemarks)]),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
