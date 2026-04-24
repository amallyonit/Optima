// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:optima/classes/globals.dart';
import 'package:optima/pages/header.dart';
import 'package:optima/tabs/tabspage.dart';
import 'package:http/http.dart' as http;
import 'package:optima/api_helper.dart';
import 'package:optima/classes/leads.dart';
import 'package:optima/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import '../pages/header.dart';

String? nextActionValue;
List<Map<String, Object>> quotationList = [];
List<Map<String, Object>> selectedQuotationList = [];
String leadId = "",
    leadPrdId = "",
    agingDays = "",
    leadHospitalCode = "",
    leadDistributorCode = "",
    leadDistributorName = "";
List<Map<String, Object>> productList = [];
List<Map<String, Object>> selectedProductList = [];
List<LeadParticipant> selectedParticipantStg5 = [];
TextEditingController summaryControllerStg5 = TextEditingController();
TextEditingController followupDateControllerStg5 = TextEditingController();
String? selectedStatusStg5;

List<bool> checkboxStateList = List.generate(0, (index) => false);

const List<String> list = <String>[
  'In Progress',
  'Requote',
  'Aprroved',
  'Rejected',
];

class StageFiveLeadEntryPage extends StatefulWidget {
  final String leadsId;
  const StageFiveLeadEntryPage({super.key, required this.leadsId});
  @override
  StageFiveLeadEntryPageState createState() => StageFiveLeadEntryPageState();
}

class LeadProductsStage6Provider with ChangeNotifier {
  List<LeadQuotation> _leadQuotation = [];
  List<LeadQuotation> get leadQuotation => _leadQuotation;
  void updateLeadQuotation(List<LeadQuotation> newLeadQuotation) {
    _leadQuotation = newLeadQuotation;
    notifyListeners();
  }
}

class StageFiveLeadEntryPageState extends State<StageFiveLeadEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _quotationnumberController = TextEditingController();
  final _poreleaseController = TextEditingController();
  final _referencenumberController = TextEditingController();
  final _deliveredonController = TextEditingController();
  List<bool> checkboxStateList = List.generate(0, (index) => false);
  List<String> selectedQuotationNumbers = [];
  List<int> selectedQuotationIds = [];
  final FocusNode _quotationNumberFocusNode = FocusNode();

  TextEditingController orderNoController = TextEditingController();
  TextEditingController referenceNoController = TextEditingController();
  TextEditingController releaseDateController = TextEditingController();
  TextEditingController orderNoCardController = TextEditingController();
  TextEditingController referenceNoCardController = TextEditingController();
  TextEditingController releaseDateCardController = TextEditingController();

  bool showWON = false;

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void initState() {
    super.initState();
    leadId = widget.leadsId;
    showWON = false;
    if (isUserLoggedIn) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loadLeadQuotation(userJwtToken, userMailID);
  }

  Future<void> _loadLeadQuotation(
    String userJwtToken,
    String userMailID,
  ) async {
    quotationList = [];

    leadId = widget.leadsId;
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadId': widget.leadsId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectleadquotation';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = json.decode(response.body);
        if (responseJson['Status'] == true &&
            responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data[0] is List) {
            List<LeadQuotation> newLeadQuotation = (data[0] as List)
                .map((item) => LeadQuotation.fromJson(item))
                .toList();
            setState(() {
              context.read<LeadProductsStage6Provider>().updateLeadQuotation(
                newLeadQuotation,
              );
              quotationList = convertLeadQuotationToMapList(newLeadQuotation);
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
      final snackBar = SnackBar(content: Text('$e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  List<Map<String, Object>> convertLeadQuotationToMapList(
    List<LeadQuotation> leadQuotation,
  ) {
    return leadQuotation
        .where(
          (leadQuotation) =>
              leadQuotation.leadStage5Id != 0 &&
              leadQuotation.leadStage7EntryId == 0,
        )
        .map((leadQuotation) {
          DateTime? parseDateString(String dateString) {
            if (dateString == '01/01/1900') {
              return null; // Treat '01/01/1900' as an invalid date
            }
            try {
              List<String> parts = dateString.split('/');
              int day = int.parse(parts[0]);
              int month = int.parse(parts[1]);
              int year = int.parse(parts[2]);

              return DateTime(year, month, day);
            } catch (e) {
              return null;
            }
          }

          DateTime? parsedDate = parseDateString(
            leadQuotation.leadStage5QuotationDate,
          );
          String leadStage5QuotationDate = parsedDate != null
              ? leadQuotation.leadStage5QuotationDate
              : '';

          bool leadEditable = leadQuotation.leadStage6EntryId.toString() != '0'
              ? true
              : false;
          return {
            "leadStage5Id": leadQuotation.leadStage5Id,
            "leadStage5ProductId": leadQuotation.leadStage5ProductId,
            "leadStage5ProductName": leadQuotation.leadStage5ProductName,
            "leadStage5QuotationRefNo": leadQuotation.leadStage5QuotationRefNo,
            "leadStage5QuotationDate": leadStage5QuotationDate,
            "leadStage5QuotationStatus":
                leadQuotation.leadStage5QuotationStatus,
            "leadStage5Remarks": leadQuotation.leadStage5Remarks,
            "leadEditable": leadEditable,
            "leadStage6EntryId": leadQuotation.leadStage6EntryId,
            "leadStage6Id": leadQuotation.leadStage6Id,
            "leadStage7EntryId": leadQuotation.leadStage7EntryId,
            "leadStage6PoNumber": leadQuotation.leadStage6PoNumber,
            "leadStage6RefNo": leadQuotation.leadStage6RefNo,
            "leadStage6PoDate": leadQuotation.leadStage6PoDate,
          };
        })
        .toList();
  }

  bool isValidDateString(String dateString) {
    try {
      DateTime.parse(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }

  void loadQuotationDetailsForEdit(
    Map<String, Object> item,
    List<Map<String, Object>> quotationList,
  ) async {
    int leadStage6EntryId = item['leadStage6EntryId'] as int;
    selectedQuotationList = quotationList
        .where(
          (quotationItem) =>
              quotationItem['leadStage6EntryId'] == leadStage6EntryId,
        )
        .toList();

    selectedQuotationNumbers.clear();
    selectedQuotationIds.clear();
    for (Map<String, Object> quotationItem in quotationList) {
      selectedQuotationNumbers.add(
        quotationItem['leadStage5QuotationRefNo'] as String,
      );
      selectedQuotationIds.add(quotationItem['leadStage6Id'] as int);
      _poreleaseController.text = quotationItem['leadStage6PoNumber'] as String;
      _referencenumberController.text =
          quotationItem['leadStage6RefNo'] as String;
      setState(() {
        _deliveredonController.text =
            quotationItem['leadStage6PoDate'] as String;
      });
    }
    _quotationnumberController.text = selectedQuotationNumbers.join(', ');
  }

  void loadSelectedQuotations() async {
    selectedQuotationList = quotationList
        .where(
          (product) => selectedQuotationNumbers.contains(
            product['leadStage5QuotationRefNo'],
          ),
        )
        .toList();
  }

  Future<void> submitStageSix() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    final leadstagesix = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadID': leadId,
      'LeadStage6PoNumber': orderNoController.text,
      'LeadStage6RefNo': referenceNoController.text,
      'LeadStage6PoDate': releaseDateController.text == ""
          ? DateFormat('dd/MM/yyyy').format(DateTime.now())
          : releaseDateController.text,
      'quotationList': selectedQuotationList,
    };
    const apiUrl = '${ApiHelper.baseUrl}insertleadstagesix';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(leadstagesix),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          _quotationnumberController.clear();
          _poreleaseController.clear();
          _referencenumberController.clear();
          _deliveredonController.clear();
          selectedQuotationNumbers = [];
          selectedQuotationIds = [];

          const snackBar = SnackBar(content: Text('Saved Successfully...'));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
      final snackBar = SnackBar(content: Text('$e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> submitFinalStage() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    final leadfinalstage = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadID': leadId,
      'LeadStage7Status': 'Won',
      'LeadStage7Remarks': '',
      'quotationList': selectedQuotationList,
    };
    const apiUrl = '${ApiHelper.baseUrl}insertleadfinalstage';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(leadfinalstage),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          setState(() {
            quotationList.clear();
            selectedQuotationList.clear();
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
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('$e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  void dispose() {
    _poreleaseController.dispose();
    _referencenumberController.dispose();
    _deliveredonController.dispose();
    _quotationnumberController.dispose();

    orderNoController.dispose();
    referenceNoController.dispose();
    releaseDateController.dispose();
    orderNoCardController.dispose();
    referenceNoCardController.dispose();
    releaseDateCardController.dispose();

    super.dispose();
  }

  void navigateToHomePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TabsPage(selectedIndex: 0, selectedRoleCode: ""),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textFieldDropDownWidth =
        screenWidth * (screenWidth <= 600 ? 0.82 : 0.901);
    // ignore: unused_local_variable
    final textFieldWidth = screenWidth * 0.9;
    final textFieldWidth2 = screenWidth * 0.8;
    final containerHeight = screenHeight * (screenWidth <= 600 ? 0.06 : 0.12);

    return PopScope(
      canPop: false,
      onPopInvoked: (onPop) => navigateToHomePage(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Align(
            alignment: Alignment.topLeft,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    navigateToHomePage();
                  },
                  child: const Icon(
                    Icons.keyboard_arrow_left,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Stage 5 - Order.',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    navigateToHomePage();
                  },
                  child: const Icon(Icons.home_outlined, color: Colors.white),
                ),
              ],
            ),
          ),
          backgroundColor: const Color(0xFF2CA9DF),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: 160, // Set a fixed height or adjust as needed
                  child: HeaderPage(leadsId: leadId, leadStageForEdit: "5"),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: SizedBox(
                      width: 375,
                      height: 125 * quotationList.length.toDouble() <= 375
                          ? 125 * quotationList.length.toDouble()
                          : 325,
                      child: ListView.builder(
                        itemCount: quotationList.length,
                        itemBuilder: (context, index) {
                          final item = quotationList[index];
                          bool initialCheckboxState =
                              item['leadEditable'] as bool;
                          while (checkboxStateList.length <= index) {
                            checkboxStateList.add(initialCheckboxState);
                          }
                          bool checkboxState = checkboxStateList[index];
                          return Container(
                            height: 170,
                            color: index % 2 == 0
                                ? const Color(0xFFfdfdfd)
                                : const Color(0xFFfdfdfd),
                            child: Column(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Transform.scale(
                                          scale: 0.7,
                                          child: Checkbox(
                                            value: checkboxState,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                checkboxStateList[index] =
                                                    value!;
                                                if (value == true) {
                                                  selectedQuotationNumbers.add(
                                                    item['leadStage5QuotationRefNo']
                                                        as String,
                                                  );
                                                  selectedQuotationIds.add(
                                                    item['leadStage5Id'] as int,
                                                  );
                                                } else {
                                                  selectedQuotationNumbers.remove(
                                                    item['leadStage5QuotationRefNo'],
                                                  );
                                                  selectedQuotationIds.remove(
                                                    item['leadStage5Id'],
                                                  );
                                                }
                                                _quotationnumberController
                                                        .text =
                                                    selectedQuotationNumbers
                                                        .join(', ');
                                              });
                                            },
                                          ),
                                        ),
                                        Text(
                                          'Quotation No. : ${item['leadStage5QuotationRefNo']}',
                                          style: const TextStyle(
                                            fontFamily: "Poppins",
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Padding(
                                          padding: EdgeInsets.only(right: 12.0),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16.0,
                                        right: 16,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'PO Release Date',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xff454545),
                                            ),
                                          ),
                                          releaseDateCardController.text != ""
                                              ? Text(
                                                  releaseDateCardController
                                                      .text,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                )
                                              : Text(
                                                  '${item['leadStage5QuotationDate']}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16.0,
                                        right: 16,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Order No.:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xff454545),
                                            ),
                                          ),
                                          Visibility(
                                            visible: checkboxStateList[index],
                                            child: Text(
                                              orderNoCardController.text,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xff454545),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16.0,
                                        right: 16,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Reference No.:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xff454545),
                                            ),
                                          ),
                                          Visibility(
                                            visible: checkboxStateList[index],
                                            child: Text(
                                              referenceNoCardController.text,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xff454545),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16.0,
                                        right: 16,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${item['leadStage5ProductName']}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xff454545),
                                            ),
                                          ),
                                          Visibility(
                                            visible: checkboxStateList[index],
                                            child: Visibility(
                                              visible: showWON,
                                              child: const Text(
                                                "Won",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xff454545),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Divider(
                                          color: Color(0xff454545),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: SizedBox(
                    width: textFieldWidth,
                    height: containerHeight,
                    child: TextFormField(
                      canRequestFocus: false,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      controller: _quotationnumberController,
                      keyboardType: TextInputType.text,
                      readOnly: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.only(top: 15, bottom: 5),
                        border: UnderlineInputBorder(),
                        labelText: 'Quotation Number',
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                      focusNode: _quotationNumberFocusNode,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: SizedBox(
                    width: textFieldWidth,
                    height: containerHeight,
                    child: TextField(
                      style: const TextStyle(fontSize: 13),
                      controller: orderNoController,
                      textInputAction: TextInputAction.none,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.only(top: 15),
                        border: UnderlineInputBorder(),
                        labelText: 'PO Release Number',
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: SizedBox(
                    width: textFieldWidth,
                    height: containerHeight,
                    child: TextField(
                      style: const TextStyle(fontSize: 13),
                      controller: referenceNoController,
                      textInputAction: TextInputAction.none,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.only(top: 15),
                        border: UnderlineInputBorder(),
                        labelText: 'Reference Number',
                        labelStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PO Delivered Date', // Update the text here
                        style: TextStyle(
                          color: Color(0xFF454545),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: textFieldWidth2,
                            height: containerHeight,
                            padding: const EdgeInsets.only(
                              left: 20.0,
                              right: 6.0,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: TextField(
                                    style: const TextStyle(fontSize: 13),
                                    readOnly: true,
                                    controller: _deliveredonController,
                                    decoration: InputDecoration(
                                      hintText: DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(DateTime.now()),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.calendar_month_outlined,
                                  ),
                                  onPressed: () async {
                                    DateTime? selectedDate =
                                        await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime.now(),
                                          initialEntryMode:
                                              DatePickerEntryMode.calendarOnly,
                                        );
                                    // String formattedDate =
                                    //     DateFormat('dd/MM/yyyy')
                                    //         .format(selectedDate!);
                                    String formattedDate = selectedDate != null
                                        ? DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(selectedDate)
                                        : DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(DateTime.now());
                                    _deliveredonController.text = formattedDate;
                                    releaseDateController.text = formattedDate;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            releaseDateCardController = releaseDateController;
                            referenceNoCardController = referenceNoController;
                            orderNoCardController = orderNoController;
                            showWON = true;
                          });
                        },
                        child: Container(
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2CA9DF),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Update',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: textFieldDropDownWidth,
                  child: GestureDetector(
                    onTap: () async {
                      loadSelectedQuotations();
                      if (selectedQuotationList.isNotEmpty) {
                        submitStageSix().then((_) {
                          submitFinalStage().then((_) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TabsPage(
                                  selectedIndex: 0,
                                  selectedRoleCode: "",
                                ),
                              ),
                            );
                          });
                        });
                      } else {
                        const snackBar = SnackBar(
                          content: Text(
                            'Select at least one quotation from the list to proceed.',
                          ),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    },
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2CA9DF),
                        borderRadius: BorderRadius.circular(0.0),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Save',
                            style: TextStyle(
                              color: Color(0xfffdfdfd),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration({
    InputBorder? enabledBorder,
    InputBorder? border,
    Color? fillColor,
    bool? filled,
    Widget? prefixIcon,
    String? hintText,
    String? labelText,
  }) => InputDecoration(
    enabledBorder:
        enabledBorder ??
        const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blueGrey, width: 2.0),
        ),
    border: border ?? const UnderlineInputBorder(borderSide: BorderSide()),
    fillColor: fillColor ?? Colors.white,
    filled: filled ?? true,
    prefixIcon: prefixIcon,
    hintText: hintText,
    labelText: labelText,
  );
}
