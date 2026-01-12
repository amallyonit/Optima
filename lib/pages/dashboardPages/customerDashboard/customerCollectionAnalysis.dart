// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api_helper.dart';
import '../../../login_screen.dart';

class ReceivablesData {
  final double receivableAmount;
  ReceivablesData({
    required this.receivableAmount,
  });
}

class CollectionAnalysisTableData {
  final String invoiceDate;
  final double deliveryValue;
  final String deliveryStatus;
  final String deliveryRemarks;
  CollectionAnalysisTableData({
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

List<CollectionAnalysisTableData> deliveryDataList = [
  CollectionAnalysisTableData(
      invoiceDate: "Xxxxx/05/04/23",
      deliveryValue: 60.00,
      deliveryStatus: "75 days",
      deliveryRemarks: "Partially Pending"),
  CollectionAnalysisTableData(
      invoiceDate: "Xxxxx/05/04/23",
      deliveryValue: 60.00,
      deliveryStatus: "75 days",
      deliveryRemarks: "Partially Pending"),
  CollectionAnalysisTableData(
      invoiceDate: "Xxxxx/05/04/23",
      deliveryValue: 60.00,
      deliveryStatus: "75 days",
      deliveryRemarks: "Partially Pending"),
  CollectionAnalysisTableData(
      invoiceDate: "Xxxxx/05/04/23",
      deliveryValue: 60.00,
      deliveryStatus: "75 days",
      deliveryRemarks: "Partially Pending"),
  CollectionAnalysisTableData(
      invoiceDate: "Xxxxx/05/04/23",
      deliveryValue: 60.00,
      deliveryStatus: "75 days",
      deliveryRemarks: "Partially Pending"),
  CollectionAnalysisTableData(
      invoiceDate: "Xxxxx/05/04/23",
      deliveryValue: 60.00,
      deliveryStatus: "75 days",
      deliveryRemarks: "Partially Pending"),
  CollectionAnalysisTableData(
      invoiceDate: "Xxxxx/05/04/23",
      deliveryValue: 60.00,
      deliveryStatus: "75 days",
      deliveryRemarks: "Partially Pending"),
];

List<ReceivablesData> receivableList = [
  ReceivablesData(receivableAmount: 600000),
  ReceivablesData(receivableAmount: 400000),
  ReceivablesData(receivableAmount: 200000),
  ReceivablesData(receivableAmount: 100000),
  ReceivablesData(receivableAmount: 50000),
];

String deviceOrientation = "";
final TextEditingController customerController = TextEditingController();
final TextEditingController valueController = TextEditingController();
late Future<void> loadDataFuture;

double totalValue = 0.0;

class CustomerCollectionAnalysis extends StatefulWidget {
  const CustomerCollectionAnalysis({super.key});

  @override
  State<CustomerCollectionAnalysis> createState() =>
      _CustomerCollectionAnalysisState();
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

class _CustomerCollectionAnalysisState
    extends State<CustomerCollectionAnalysis> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  String? selectedModeOfPayment;

  SideTitles get _emptyTitlesTop =>
      SideTitles(showTitles: true, getTitlesWidget: getEmptyTopTitle);

  Widget getEmptyTopTitle(double val, TitleMeta meta) {
    return const Text("");
  }

  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontSize: 10,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('Credit \nPeriod', style: style);
        break;
      case 1:
        text = const Text('0-30 \nDays', style: style);
        break;
      case 2:
        text = const Text('31-60 \nDays', style: style);
        break;
      case 3:
        text = const Text('61-90 \nDays', style: style);
        break;
      case 4:
        text = const Text('91+ \nDays', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
    }
    return SideTitleWidget(
      meta: meta,
      space: 16,
      child: text,
    );
  }

  List<BarChartGroupData> _receivablesChartData(
      List<ReceivablesData> receivableList) {
    return receivableList
        .map((data) =>
            BarChartGroupData(x: receivableList.indexOf(data), barRods: [
              BarChartRodData(
                  color: Colors.cyan,
                  borderRadius: BorderRadius.zero,
                  toY: data.receivableAmount,
                  width: 30)
            ]))
        .toList();
  }

  List<bool> collectionCheckList =
      List.generate(deliveryDataList.length, (index) => false);

  var distributorKey = GlobalKey();
  List<Map<String, dynamic>> distributorList = [];
  String selectedDistributorName = "";
  String selectedDistributorId = "";

  List<Distributor> convertDist(List<Map<String, dynamic>> distributorList) {
    return distributorList
        .map((map) => Distributor(
              customerCode: map['CustomerCode']?.toString() ?? '',
              customerName: map['CustomerName']?.toString() ?? '',
            ))
        .toList();
  }

  Future<List<Distributor>> getDistributor(String search) async {
    List<Distributor> distList = convertDist(distributorList);
    List<Distributor> filteredList = distList
        .where((element) =>
            element.customerName.toLowerCase().startsWith(search.toLowerCase()))
        .toList();

    return filteredList;
  }

  Future<void> _loaddistributor(
      String userId, String userJwtToken, String userMailID) async {
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserId': userId
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
            final snackBar = SnackBar(
              duration: const Duration(seconds: 1),
              content: Text(
                responseJson["Error"].toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } else {
        const snackBar = SnackBar(
          content: Text('Distributor details not available.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loaddistributor(userId, userJwtToken, userMailID);
  }

  @override
  void initState() {
    selectedModeOfPayment = null;
    loadDataFuture = loadData();
    super.initState();
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
                child: Text(
                  "Monthly Collection",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 32.0),
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
                      maxListHeight:
                          deviceOrientation == "Portrait" ? 370 : 220,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.only(
                            left: 0, right: 30, top: 0, bottom: 0),
                        border: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        hintText: 'Account Name',
                        hintStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8F8F8F)),
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
                          selectedDistributorId =
                              customer['CustomerCode'].toString();
                          selectedDistributorName = distributor.customerName;
                        });
                      },
                      suggestionBuilder: (data) => ListTile(
                        title: Text(data.customerName),
                      ),
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
                      SizedBox(
                        height: 40,
                      ),
                      Text(
                        "65%",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                            color: Colors.red),
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
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(
                            show: false,
                          ),
                          sectionsSpace: 0,
                          centerSpaceRadius: 0,
                          startDegreeOffset: 180,
                          sections: showingSections(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
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
                            const SizedBox(
                              height: 8,
                            ),
                            Container(
                              height: 8,
                              width: 16,
                              color: Colors.blue,
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
                              "On Time",
                              textAlign: TextAlign.left,
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text("0 - 5 Days Delay",
                                style: TextStyle(fontSize: 10)),
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
                            const SizedBox(
                              height: 8,
                            ),
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
                            child: Text("6 - 15 Days Delay",
                                style: TextStyle(fontSize: 10)),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              "16+ Days Delay",
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0),
            child: Divider(
              thickness: 2,
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                child: Text(
                  "Receivables",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
            child: _buildDeliveryReceivablesChart(),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0),
            child: Divider(
              thickness: 2,
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 16.0, left: 16.0),
                child: Text(
                  "Pending Invoice-Collection Remark",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Center(
                child: Column(children: <Widget>[
              Container(
                margin: const EdgeInsets.all(20),
                child: Table(
                  defaultColumnWidth: const FixedColumnWidth(175.0),
                  border: TableBorder.all(
                      color: Colors.black,
                      style: BorderStyle.solid,
                      width: 0.5),
                  children: [
                    const TableRow(children: [
                      Column(children: [
                        Text('Invoice No/Date',
                            style: TextStyle(
                                fontSize: 14.0, fontWeight: FontWeight.w600))
                      ]),
                      Column(children: [
                        Text('Value (in L)',
                            style: TextStyle(
                                fontSize: 14.0, fontWeight: FontWeight.w600))
                      ]),
                      Column(children: [
                        Text('Status',
                            style: TextStyle(
                                fontSize: 14.0, fontWeight: FontWeight.w600))
                      ]),
                      Column(children: [
                        Text('Remarks',
                            style: TextStyle(
                                fontSize: 14.0, fontWeight: FontWeight.w600))
                      ]),
                    ]),
                    for (var i = 0; i < deliveryDataList.length; i++)
                      TableRow(children: [
                        Column(children: [
                          Row(
                            children: [
                              Transform.scale(
                                scale: .7,
                                child: Checkbox(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(2.0),
                                    ),
                                    side: WidgetStateBorderSide.resolveWith(
                                      (states) => const BorderSide(
                                          width: 1.0, color: Color(0xFF8F8F8F)),
                                    ),
                                    value: collectionCheckList[i],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        collectionCheckList[i] = value ?? false;
                                        if (collectionCheckList[i] == true) {
                                          totalValue +=
                                              deliveryDataList[i].deliveryValue;
                                          valueController.text =
                                              totalValue.toString();
                                        }
                                        if (collectionCheckList[i] == false) {
                                          if (totalValue != 0) {
                                            totalValue -= deliveryDataList[i]
                                                .deliveryValue;
                                            valueController.text =
                                                totalValue.toString();
                                          }
                                        }
                                      });
                                    }),
                              ),
                              Text(deliveryDataList[i].invoiceDate),
                            ],
                          )
                        ]),
                        TableCell(
                            verticalAlignment:
                                TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                  deliveryDataList[i].deliveryValue.toString()),
                            )),
                        TableCell(
                            verticalAlignment:
                                TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(deliveryDataList[i].deliveryStatus),
                            )),
                        TableCell(
                            verticalAlignment:
                                TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(deliveryDataList[i].deliveryRemarks),
                            )),
                      ]),
                  ],
                ),
              ),
            ])),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                width: 20,
              ),
              Container(
                color: const Color(0xFFD9D9D9),
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text("Total Outstanding - 390 L"),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0),
            child: Divider(
              thickness: 2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 8.0, bottom: 16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: AbsorbPointer(
                        absorbing: true,
                        child: TextField(
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF8F8F8F)),
                          controller: valueController,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: '0.00 L',
                            hintStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF8F8F8F)),
                          ),
                        ),
                      )),
                ),
                const SizedBox(
                  width: 20,
                ),
                Flexible(
                  child: TextField(
                    canRequestFocus: false,
                    style: const TextStyle(
                      color: Color(0xFF8F8F8F),
                    ),
                    keyboardType: TextInputType.none,
                    controller: _dateController,
                    decoration: const InputDecoration(
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(left: 20.0),
                        child: Icon(
                          Icons.calendar_today,
                          color: Color(0xffD9D9D9),
                          size: 20,
                        ),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      labelText: 'On',
                      contentPadding: EdgeInsets.only(bottom: 0),
                      labelStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8F8F8F)),
                    ),
                    onTap:
                        () /*async {
                                    DateTime? newDate = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2040),
                                    );
                                    if (newDate != null) {
                                      setState(() {
                                        _selectedDate = newDate;
                                        _dateController.text = DateFormat.yMMMd().format(_selectedDate);
                                      });
                                    }
                                  }*/
                        async {
                      DateTime? selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                        initialEntryMode: DatePickerEntryMode.calendar,
                      );
                      TimeOfDay? selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (selectedTime != null) {
                        String formattedDateTime =
                            DateFormat('dd/MM/yyyy hh:mm a').format(
                          DateTime(
                            selectedDate!.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          ),
                        );
                        _dateController.text = formattedDateTime;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
            child: SizedBox(
              height: 70,
              width: 400,
              child: Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: DropdownButtonFormField<String>(
                    hint: const Text(
                      'Committed Mode of Payment',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8F8F8F)),
                    ),
                    initialValue: selectedModeOfPayment,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xffD9D9D9),
                      size: 30,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedModeOfPayment = newValue!;
                      });
                    },
                    items: <String>[
                      'Cheque',
                      'DD',
                      'NEFT/RTGS',
                      'UPI',
                      'Cash',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF8F8F8F)),
                        ),
                      );
                    }).toList(),
                  )),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: TextField(
              controller: remarksController,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF8F8F8F)),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  hintText: "Remarks",
                  hintStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8F8F8F)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: Colors.grey))),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2ca9df),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                onPressed: () {},
                child: const SizedBox(
                  width: 400,
                  child: Center(
                    child: Text(
                      "Save",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryReceivablesChart() {
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        height: 400,
        width: screenWidth,
        child: BarChart(
          BarChartData(
            // maxY: getMaxValue(monthlySalesList),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: _emptyTitlesTop,
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: getTitles,
                  reservedSize: 45,
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: const Color(0xff37434d),
                width: 1,
              ),
            ),
            barGroups: _receivablesChartData(receivableList),
            barTouchData: BarTouchData(
              allowTouchBarBackDraw: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (groupData, grpIndex, rodData, rodIndex) {
                  return BarTooltipItem(
                    '',
                    const TextStyle(color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(
                        text: "Target :${rodData.backDrawRodData.toY} ",
                        style: TextStyle(
                          color: Colors.cyan.shade100, //widget.touchedBarColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: "Achieved: ${rodData.toY}",
                        style: const TextStyle(
                          color: Colors.cyan, //widget.touchedBarColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
                getTooltipColor: (group) => Colors.black87,
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
