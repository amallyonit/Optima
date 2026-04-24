// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:optima/classes/footerConstants.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/leadstages/stagefiveentry.dart';
import 'package:optima/tabs/tabspage.dart';
import 'package:http/http.dart' as http;
import 'package:optima/api_helper.dart';
import 'package:optima/classes/leads.dart';
import 'package:optima/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/footer.dart';
import '../pages/header.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

String deviceOrientation = "";

String selectedOption = 'Option 1';
String selectedDistributorId = "";
String selectedDistributorName = "";

double textFieldDropDownWidth = 0;
double containerDropDownHeight = 0;
double textFieldWidth = 0;
double containerHeight = 0;

TextEditingController referenceNumberCardController = TextEditingController();
TextEditingController quotationSubmittedOnCardController =
    TextEditingController();
TextEditingController statusCardController = TextEditingController();

class Distributor {
  String customerName;
  String customerCode;
  Distributor({required this.customerCode, required this.customerName});
}

String leadId = "", leadPrdId = "", agingDays = "", leadHospitalCode = "";
List<Map<String, Object>> productList = [];
List<Map<String, Object>> selectedProductList = [];
int _value = 0;
final TextEditingController searchController = TextEditingController();
List<LeadParticipant> selectedParticipantStg4 = [];
TextEditingController summaryControllerStg4 = TextEditingController();
TextEditingController followupDateControllerStg4 = TextEditingController();
final _productnamestagefiveController = TextEditingController();
String? selectedStatusStg4;
bool detailsSentToHo = false;
String? nextActionValue;

class StageFourLeadEntryPage extends StatefulWidget {
  final String leadsId;
  const StageFourLeadEntryPage({super.key, required this.leadsId});
  @override
  StageFourLeadEntryPageState createState() => StageFourLeadEntryPageState();
}

class LeadProductsStage5Provider with ChangeNotifier {
  List<LeadProducts> _leadProducts = [];
  List<LeadProducts> get leadProducts => _leadProducts;
  void updateLeadProducts(List<LeadProducts> newLeadProducts) {
    _leadProducts = newLeadProducts;
    notifyListeners();
  }
}

class StageFourLeadEntryPageState extends State<StageFourLeadEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _productNameStageFourController = TextEditingController();
  final _remarksController = TextEditingController();

  final _distributornameController = TextEditingController();
  final _quotationsubmitteddateController = TextEditingController();
  final _referencenumberController = TextEditingController();

  List<bool> checkboxStateList = List.generate(0, (index) => false);
  String selectedProductName = '';
  List<String> selectedProductNames = [];
  List<int> selectedProductIds = [];
  List<Map<String, dynamic>> distributorList = [];

  bool selectedValue = false;
  String selectedStatus = 'In Progress';
  bool distributorAvailable = false;

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  late stt.SpeechToText _speech;
  bool _isFeedbackListening = false;

  void _listen(
    TextEditingController txtController,
    bool isListening,
    Function setListeningState,
  ) async {
    if (!isListening) {
      _checkMicPermissions();
      bool available = await _speech.initialize();
      if (available) {
        setState(() => setListeningState(true));
        _speech.listen(
          onResult: (val) => setState(() {
            txtController.text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              // Optionally handle confidence here
            }
          }),
        );
      }
    } else {
      setState(() => setListeningState(false));
      _speech.stop();
    }
  }

  Future<void> _checkMicPermissions() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    leadId = widget.leadsId;
    if (isUserLoggedIn) {
      _selectAndLoadContacts();
    }
  }

  Future<void> _selectAndLoadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _selectLeadProducts(userJwtToken, userMailID);
    await _loaddistributor(userJwtToken, userMailID);
  }

  Future<void> _loaddistributor(String userJwtToken, String userMailID) async {
    final data = {'UserJwtToken': userJwtToken, 'UsermailID': userMailID};
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

  Future<void> _selectLeadProducts(
    String userJwtToken,
    String userMailID,
  ) async {
    productList = [];

    leadId = widget.leadsId;
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadId': widget.leadsId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectleadproducts';
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
            List<LeadProducts> newLeadProducts = (data[0] as List)
                .map((item) => LeadProducts.fromJson(item))
                .toList();
            setState(() {
              context.read<LeadProductsStage5Provider>().updateLeadProducts(
                newLeadProducts,
              );
              productList = convertLeadProductsToMapList(newLeadProducts);
              if (data[0].length >= 1) {
                agingDays = data[0][0]['LeadAgingDays'].toString();
                leadHospitalCode = data[0][0]['LeadHospitalCode'].toString();
                leadDistributorCode = data[0][0]['LeadDistributorCode']
                    .toString();
                leadDistributorName = data[0][0]['LeadDistributorName']
                    .toString();
                distributorAvailable = leadDistributorCode != "" ? true : false;
                _distributornameController.text = leadDistributorName;
              } else {
                agingDays = '';
                leadHospitalCode = '';
                leadDistributorCode = '';
                leadDistributorName = '';
              }
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

  List<Map<String, Object>> convertLeadProductsToMapList(
    List<LeadProducts> leadProducts,
  ) {
    return leadProducts
        .where(
          (leadProduct) =>
              leadProduct.leadStage4Status == 'Approved' &&
              leadProduct.leadStage3EntryId != 0 &&
              leadProduct.leadStage4EntryId != 0 &&
              leadProduct.leadStage6EntryId == 0,
        )
        .map((leadProducts) {
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
            leadProducts.leadStage3RecievedDate,
          );
          String leadStage3RecievedDate = parsedDate != null
              ? leadProducts.leadStage3RecievedDate
              : '';

          parsedDate = parseDateString(leadProducts.leadStage3SubmittedDate);
          String leadStage3SubmittedDate = parsedDate != null
              ? leadProducts.leadStage3SubmittedDate
              : '';

          parsedDate = parseDateString(leadProducts.leadStage4FeedbackDate);
          String leadStage4FeedbackDate = parsedDate != null
              ? leadProducts.leadStage4FeedbackDate
              : '';

          parsedDate = parseDateString(leadProducts.leadStage5QuotationDate);
          String leadStage5QuotationDate = parsedDate != null
              ? leadProducts.leadStage5QuotationDate
              : '';

          bool leadEditable = leadProducts.leadStage5Id.toString() != '0'
              ? true
              : false;
          return {
            "leadProductId": leadProducts.leadProductId,
            "leadProductName": leadProducts.leadProductName,
            "leadCompetitorName": leadProducts.leadCompetitorName,
            "leadHospitalPrice": leadProducts.leadHospitalPrice,
            "leadDistributorPrice": leadProducts.leadDistributorPrice,
            "leadDateofPurchase": leadProducts.leadDateofPurchase,
            "leadPurchasePrice": leadProducts.leadPurchasePrice,
            "leadDateofSubmission": leadProducts.leadDateofSubmission,
            "leadDclrNumber": leadProducts.leadDclrNumber,
            "leadTargetedPrice": leadProducts.leadTargetedPrice,
            "leadRemark": leadProducts.leadRemark,
            "leadSamplePurchased": leadProducts.leadSamplePurchased,
            "leadSampleSubmitted": leadProducts.leadSampleSubmitted,
            "leadAgingDays": leadProducts.leadAgingDays,
            "leadHospitalCode": leadProducts.leadHospitalCode,
            "leadDistributorCode": leadProducts.leadDistributorCode,
            "leadDistributorName": leadProducts.leadDistributorName,
            "leadStage3Id": leadProducts.leadStage3Id,
            "leadEditable": leadEditable,
            "leadStage3RecievedDate": leadStage3RecievedDate,
            "leadStage3SubmittedDate": leadStage3SubmittedDate,
            "leadStage3ContactName": leadProducts.leadStage3ContactName,
            "leadStage3ContactCode": leadProducts.leadStage3ContactCode,
            "leadStage3EntryId": leadProducts.leadStage3EntryId,
            "leadStage4Id": leadProducts.leadStage4Id,
            "leadStage4FeedbackDate": leadStage4FeedbackDate,
            "leadStage4Status": leadProducts.leadStage4Status,
            "leadStage4SubmittedToHo": leadProducts.leadStage4SubmittedToHo,
            "leadStage4Remarks": leadProducts.leadStage4Remarks,
            "leadStage4EntryId": leadProducts.leadStage4EntryId,
            "leadStage5Id": leadProducts.leadStage5Id,
            "leadStage5QuotationDate": leadStage5QuotationDate,
            "leadStage5DistributorCode": leadProducts.leadStage5DistributorCode,
            "leadStage5QuotationRefNo": leadProducts.leadStage5QuotationRefNo,
            "leadStage5QuotationStatus": leadProducts.leadStage5QuotationStatus,
            "leadStage5Remarks": leadProducts.leadStage5Remarks,
            "leadStage5EntryId": leadProducts.leadStage5EntryId,
            "leadStage6EntryId": leadProducts.leadStage6EntryId,
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

  void loadSelectedProducts() async {
    selectedProductList = productList
        .where(
          (product) => selectedProductIds.contains(product['leadProductId']),
        )
        .toList();
  }

  Future<void> submitStageFive() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    final leadstagefive = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadID': leadId,
      'LeadStage5DistributorCode': distributorAvailable == true
          ? leadDistributorCode
          : '',
      'LeadStage5QuotationDate': quotationSubmittedOnController.text == ""
          ? DateFormat('dd/MM/yyyy').format(DateTime.now())
          : quotationSubmittedOnController.text,
      'LeadStage5QuotationRefNo': referenceNumberController.text,
      'LeadStage5QuotationStatus': statusController.text,
      'LeadStage5Remarks': _remarksController.text,
      'productList': selectedProductList,
    };
    const apiUrl = '${ApiHelper.baseUrl}insertleadstagefive';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(leadstagefive),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          _quotationsubmitteddateController.clear();
          _remarksController.clear();
          _referencenumberController.clear();
          _productnamestagefiveController.clear();
          leadPrdId = "";
          selectedProductNames = [];
          selectedProductIds = [];
          selectedStatus = 'In Progress';
          distributorAvailable = false;
          detailsSentToHo = false;
          setState(() {
            productList.clear();
            selectedProductList.clear();
          });
          const snackBar = SnackBar(
            duration: Duration(seconds: 1),
            content: Text(
              'Saved Successfully...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
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

  Future<void> submitStageSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    List<Map<String, Object>> selectedParticipantList =
        selectedParticipantFooter
            .whereType<LeadParticipant>()
            .map(
              (LeadParticipant item) => {
                'ParticipantName': item.leadParticipantUserName,
                'LeadParticipantId': 0,
                'ParticipantId': item.leadParticipantUserId,
              },
            )
            .toList();
    final leadactivity = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadID': leadId,
      'LeadActivityId': leadActivityId,
      'LeadActivityStageLevel': "5",
      'LeadActivitySummary': summaryControllerFooter.text,
      'LeadActivityFollowupDate': followupDateControllerFooter.text == ""
          ? DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())
          : followupDateControllerFooter.text,
      'LeadActivityLatitude': latitudeFooter,
      'LeadActivityLongitude': longitudeFooter,
      'LeadActivityLocation': locationControllerFooter.text,
      'LeadActivityStatus': selectedStatusFooter,
      'LeadActivityImage': "",
      'LeadActivityType': "On Site",
      'participantList': selectedParticipantList,
    };
    const apiUrl = '${ApiHelper.baseUrl}insertleadactivity';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(leadactivity),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          summaryControllerFooter.clear();
          followupDateControllerFooter.text = DateFormat(
            'dd/MM/yyyy hh:mm a',
          ).format(DateTime.now());
          selectedStatusFooter = 'Next Action';
          leadId = "";
          setState(() {
            selectedParticipantList.clear();
            selectedParticipantList = [];
            selectedParticipantFooter.clear();
            selectedParticipantFooter = [];
          });
          const snackBar = SnackBar(
            duration: Duration(seconds: 1),
            content: Text(
              'Saved Successfully...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
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
      final snackBar = SnackBar(
        duration: const Duration(seconds: 1),
        content: Text('$e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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

  void loadProductDetailsForEdit(
    Map<String, Object> item,
    List<Map<String, Object>> productList,
  ) async {
    int leadStage4EntryId = item['leadStage4EntryId'] as int;
    selectedProductList = productList
        .where(
          (productItem) =>
              productItem['leadStage4EntryId'] == leadStage4EntryId,
        )
        .toList();
    selectedProductNames.clear();
    selectedProductIds.clear();
    String selValue = "";
    for (Map<String, Object> productItem in selectedProductList) {
      selectedProductNames.add(productItem['leadProductName'] as String);
      selectedProductIds.add(productItem['leadProductId'] as int);
      _feedbackController.text =
          productItem['leadStage4FeedbackDate'] as String;
      _remarksController.text = productItem['leadStage4Remarks'] as String;
      setState(() {
        selectedStatus = productItem['leadStage4Status'] as String;
        selValue = productItem['leadStage4SubmittedToHo'] as String;
        selectedValue = selValue == "Yes" ? true : false;
      });
    }
    _productNameStageFourController.text = selectedProductNames.join(', ');
  }

  void navigateToHomePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TabsPage(selectedIndex: 0, selectedRoleCode: ""),
      ),
    );
  }

  TextEditingController referenceNumberController = TextEditingController();
  TextEditingController quotationSubmittedOnController =
      TextEditingController();
  TextEditingController statusController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    _remarksController.dispose();
    _productNameStageFourController.dispose();
    referenceNumberController.dispose();
    quotationSubmittedOnController.dispose();
    statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var distributorKey = GlobalKey();

    List<Map<String, dynamic>> customerList = [];

    final screenWidth = MediaQuery.of(context).size.width;
    screenWidth * (screenWidth <= 600 ? 0.82 : 0.901);

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
                  'Stage 4 - Quotation',
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
                  child: const Icon(
                    Icons.home_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
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
                const SizedBox(height: 10),
                SizedBox(
                  height: 160, // Set a fixed height or adjust as needed
                  child: HeaderPage(leadsId: leadId, leadStageForEdit: "4"),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: SizedBox(
                    width: 500,
                    height: 125 * productList.length.toDouble() <= 375
                        ? 150 * productList.length.toDouble()
                        : 325,
                    child: ListView.builder(
                      itemCount: productList.length,
                      itemBuilder: (context, index) {
                        final item = productList[index];
                        bool initialCheckboxState =
                            item['leadEditable'] as bool;
                        while (checkboxStateList.length <= index) {
                          checkboxStateList.add(initialCheckboxState);
                        }
                        bool checkboxState = checkboxStateList[index];
                        return Container(
                          height: 160,
                          color: index % 2 == 0
                              ? const Color(0xFFfdfdfd)
                              : const Color(0xFFfdfdfd),
                          child: SingleChildScrollView(
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
                                                  selectedProductNames.add(
                                                    item['leadProductName']
                                                        as String,
                                                  );
                                                  selectedProductIds.add(
                                                    item['leadProductId']
                                                        as int,
                                                  );
                                                } else {
                                                  selectedProductNames.remove(
                                                    item['leadProductName'],
                                                  );
                                                  selectedProductIds.remove(
                                                    item['leadProductId'],
                                                  );
                                                }
                                                _productNameStageFourController
                                                    .text = selectedProductNames
                                                    .join(', ');
                                              });
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Product : ${item['leadProductName']}',
                                            style: const TextStyle(
                                              fontFamily: "Poppins",
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
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
                                            'Sample Approved On',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xff454545),
                                            ),
                                          ),
                                          Text(
                                            '${item['leadStage4FeedbackDate']}',
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
                                            'Quotation Submitted On',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xff454545),
                                            ),
                                          ),
                                          Visibility(
                                            visible: checkboxStateList[index],
                                            child: Text(
                                              item['leadStage5QuotationDate'] !=
                                                          null &&
                                                      (item['leadStage5QuotationDate']
                                                              as String)
                                                          .isNotEmpty
                                                  ? item['leadStage5QuotationDate']
                                                        as String
                                                  : quotationSubmittedOnCardController
                                                        .text,
                                              style: const TextStyle(
                                                fontSize: 14,
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
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Reference No.',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xff454545),
                                                ),
                                              ),
                                              Visibility(
                                                visible:
                                                    checkboxStateList[index],
                                                child: Text(
                                                  referenceNumberCardController
                                                      .text,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xff454545),
                                                  ),
                                                ),
                                              ),
                                              Visibility(
                                                visible:
                                                    checkboxStateList[index],
                                                child: Text(
                                                  item['leadStage5QuotationRefNo'] !=
                                                              null &&
                                                          (item['leadStage5QuotationRefNo']
                                                                  as String)
                                                              .isNotEmpty
                                                      ? item['leadStage5QuotationRefNo']
                                                            as String
                                                      : referenceNumberCardController
                                                            .text,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Visibility(
                                            visible: checkboxStateList[index],
                                            child: Text(
                                              statusCardController.text,
                                              style: const TextStyle(
                                                fontSize: 14,
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
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 15),
                //   child: SizedBox(
                //     width: textFieldWidth,
                //     height: containerHeight,
                //     child: TextFormField(
                //       maxLines: 1,
                //       controller: _productNameStageFourController,
                //       keyboardType: TextInputType.text,
                //       readOnly: true,
                //       decoration: const InputDecoration(
                //         border: UnderlineInputBorder(),
                //         labelText: 'Product Name',
                //         hintText: 'Product Name',
                //         hintStyle: TextStyle(
                //           fontSize: 14,
                //           fontFamily: 'Poppins',
                //         ),
                //       ),
                //       focusNode: _productNamesFocusNode,
                //     ),
                //   ),
                // ),
                Center(
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xffefefef),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Radio(
                                  value: 0,
                                  groupValue: _value,
                                  onChanged: (value) {
                                    setState(() {
                                      _value = value as int;
                                    });
                                  },
                                ),
                                const Text(
                                  'Direct Supply',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    color: Color(0xff454545),
                                  ),
                                ),
                                const SizedBox(width: 20.0),
                                Radio(
                                  value: 1,
                                  groupValue: _value,
                                  onChanged: (value) {
                                    setState(() {
                                      _value = value as int;
                                    });
                                  },
                                ),
                                const Text(
                                  'Distributor',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    color: Color(0xff454545),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16,
                              ),
                              child: Visibility(
                                visible: _value == 1,
                                child: SizedBox(
                                  height: 50,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: AsyncAutocomplete<Distributor>(
                                          maxListHeight:
                                              deviceOrientation == "Portrait"
                                              ? 370
                                              : 220,
                                          decoration: InputDecoration(
                                            border: UnderlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            hintText: 'Distributor',
                                            hintStyle: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xff454545),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: const BorderSide(
                                                color: Colors
                                                    .blue, // Set your desired focus color
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6.0),
                                            ),
                                          ),
                                          controller: searchController,
                                          inputKey: distributorKey,
                                          onTapItem:
                                              (Distributor distributor) async {
                                                setState(() {
                                                  selectedOption =
                                                      distributor.customerName;
                                                  searchController.text =
                                                      distributor.customerName;
                                                  var customer = customerList
                                                      .firstWhere(
                                                        (map) =>
                                                            map['CustomerName'] ==
                                                            distributor
                                                                .customerName,
                                                        orElse: () =>
                                                            <String, dynamic>{
                                                              'CustomerCode':
                                                                  null,
                                                            },
                                                      );
                                                  selectedDistributorId =
                                                      customer['CustomerCode']
                                                          .toString();
                                                  selectedDistributorName =
                                                      distributor.customerName;
                                                });
                                              },
                                          suggestionBuilder: (data) => ListTile(
                                            title: Text(
                                              data.customerName,
                                              style: const TextStyle(
                                                color: Color(0xff454545),
                                                fontSize: 14.0,
                                                fontFamily: "Poppins",
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          asyncSuggestions: (searchValue) =>
                                              getDistributor(searchValue),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Visibility(
                                          child: SizedBox(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedOption = '';
                                                  selectedDistributorId = "";
                                                  searchController.clear();
                                                });
                                              },
                                              child: searchController.text == ""
                                                  ? Container(
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                          ),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              top: 14,
                                                              right: 2,
                                                            ),
                                                        child: Icon(
                                                          Icons.search,
                                                          color: Color(
                                                            0xff2ca9df,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors
                                                                .transparent,
                                                          ),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              top: 14,
                                                              right: 2,
                                                            ),
                                                        child: Icon(
                                                          Icons.cancel_outlined,
                                                          color: Color(
                                                            0xff2ca9df,
                                                          ),
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
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: referenceNumberController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: UnderlineInputBorder(),
                                        labelText: 'Reference No.',
                                        labelStyle: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins',
                                          color: Color(0xff454545),
                                        ),
                                        contentPadding: EdgeInsets.all(5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  Expanded(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              readOnly: true,
                                              controller:
                                                  quotationSubmittedOnController,
                                              decoration: const InputDecoration(
                                                //   hintText: DateFormat('dd/MM/yyyy')
                                                //       .format(DateTime.now()),
                                                //       hintStyle: const TextStyle(
                                                //           fontSize: 14,
                                                // fontFamily: 'Poppins',
                                                // color: Color(0xff454545)
                                                //       ),
                                                hintText: 'Date',
                                                hintStyle: TextStyle(
                                                  color: Color(0xff454545),
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                ),
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
                                                        DatePickerEntryMode
                                                            .calendarOnly,
                                                  );
                                              String formattedDate =
                                                  selectedDate != null
                                                  ? DateFormat(
                                                      'dd/MM/yyyy',
                                                    ).format(selectedDate)
                                                  : DateFormat(
                                                      'dd/MM/yyyy',
                                                    ).format(DateTime.now());
                                              quotationSubmittedOnController
                                                      .text =
                                                  formattedDate;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Container(
                                color: Colors.white,
                                height: 60,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    right: 8,
                                  ),
                                  child: TextField(
                                    controller: _remarksController,
                                    maxLines: 6,
                                    decoration: InputDecoration(
                                      hintText: 'Feedback.',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFF454545),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Poppins',
                                      ),
                                      contentPadding: const EdgeInsets.only(
                                        top: 15.0,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isFeedbackListening
                                              ? Icons.mic
                                              : Icons.mic_none,
                                        ),
                                        onPressed: () {
                                          _listen(
                                            _remarksController,
                                            _isFeedbackListening,
                                            (bool isListening) {
                                              _isFeedbackListening =
                                                  isListening;
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 0),
                                      child: DropdownButtonFormField<String>(
                                        hint: const Text(
                                          'Next Action',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF8F8F8F),
                                          ),
                                        ),
                                        initialValue: nextActionValue,
                                        icon: const Icon(
                                          Icons.search,
                                          color: Color(0xff2ca9df),
                                        ),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            nextActionValue = newValue!;
                                            statusController.text =
                                                nextActionValue!;
                                          });
                                        },
                                        items:
                                            <String>[
                                              'In Progress',
                                              'Re Quote',
                                              'Approved',
                                              'Rejected',
                                            ].map<DropdownMenuItem<String>>((
                                              String value,
                                            ) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(
                                                  value,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Color(0xFF454545),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 50),
                                  SizedBox(
                                    width: 130,
                                    height: 39,
                                    child: GestureDetector(
                                      // Changed from InkWell to GestureDetector
                                      onTap: () {
                                        setState(() {
                                          if (quotationSubmittedOnCardController
                                                  .text ==
                                              "") {
                                            quotationSubmittedOnCardController
                                                .text = DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(DateTime.now());
                                          } else {
                                            quotationSubmittedOnCardController
                                                    .text =
                                                quotationSubmittedOnController
                                                    .text;
                                          }

                                          referenceNumberCardController.text =
                                              referenceNumberController.text;
                                          statusCardController.text =
                                              statusController.text;
                                        });
                                      },

                                      child: Container(
                                        height: 38,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2CA9DF),
                                          borderRadius: BorderRadius.circular(
                                            0.0,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Update',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.update,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            const SizedBox(
                              height:
                                  460, // Set a fixed height or adjust as needed
                              child: FooterPage(
                                leadsId: "0",
                                leadStageForEdit: "1",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () async {
                    loadSelectedProducts();
                    if (locationControllerFooter.text == "" ||
                        selectedProductList.isEmpty) {
                      final snackBar = SnackBar(
                        backgroundColor: const Color(0xFF2CA9DF),
                        duration: const Duration(seconds: 2),
                        content: Text(
                          selectedProductList.isEmpty
                              ? 'Select at least one product from the list to proceed..'
                              : 'Location is missing, Please add location and try again...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    } else {
                      BuildContext? dialogContext;
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          dialogContext = context;
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        },
                      );
                      try {
                        await submitStageFive();
                        await submitStageSummary();
                        Navigator.of(dialogContext!).pop();
                        navigateToHomePage();
                      } catch (e) {
                        final snackBar = SnackBar(content: Text('$e'));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
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
                        SizedBox(width: 8),
                        Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
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
