// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use
import 'dart:convert';
import 'dart:io';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:optima/classes/footerConstants.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/login_screen.dart';
import 'package:optima/tabs/tabspage.dart';
import 'package:http/http.dart' as http;
import 'package:optima/api_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:optima/classes/leads.dart';
import '../notificationService.dart';
import '../pages/addUpateMeeting/productMultiDropDown.dart';
import '../pages/footer.dart';
import '../pages/header.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

String leadId = "", leadPrdId = "";
String deviceOrientation = "";
List<Map<String, Object>> productList = [];
List<Map<String, dynamic>> allProductList = [];
List<Product> selectedProduct = [];
List<LeadParticipant> selectedParticipantStg2 = [];
TextEditingController summaryControllerStg2 = TextEditingController();
TextEditingController followupDateControllerStg2 = TextEditingController();
String? selectedStatusStg2;

List<Map<String, String>> selectedParticipantList = [];

class StageTwoLeadEntryPage extends StatefulWidget {
  final String leadsId;
  const StageTwoLeadEntryPage({super.key, required this.leadsId});
  @override
  StageTwoLeadEntryState createState() => StageTwoLeadEntryState();
}

class LeadProductsProvider with ChangeNotifier {
  List<LeadProducts> _leadProducts = [];
  List<LeadProducts> get leadProducts => _leadProducts;
  void updateLeadProducts(List<LeadProducts> newLeadProducts) {
    _leadProducts = newLeadProducts;
    notifyListeners();
  }
}

class StageTwoLeadEntryState extends State<StageTwoLeadEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _competitorController = TextEditingController();
  final _hospitalPriceController = TextEditingController();
  final _distributorPriceController = TextEditingController();
  final _dateofPurchaseController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _dateofSubmissionController = TextEditingController();
  final _dclrNumberController = TextEditingController();
  final _targetedPriceController = TextEditingController();
  final _remarkController = TextEditingController();
  final _targetedRemarkController = TextEditingController();
  final _targetedHPController = TextEditingController();
  final _targetedDPController = TextEditingController();
  var productKey = GlobalKey();
  var productKey2 = GlobalKey();

  bool selectedPurchasedValue = true;
  bool selectedSubmittedValue = true;

  late stt.SpeechToText _speech;
  bool _isProductRemarksListening = false;
  bool _isTargetedRemarksListening = false;

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
      loadData();
    }
    _focus3 = FocusNode();
    _focus3.addListener(_handleFocusChange);
  }

  void loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userId = prefs.getString('userId') ?? '';
    await _selectLeadProducts(userJwtToken, userMailID);
    await _loadproducts(userId, userJwtToken, userMailID);
  }

  late FocusNode _focus3;

  @override
  void dispose() {
    _productController.dispose();
    _competitorController.dispose();
    _hospitalPriceController.dispose();
    _distributorPriceController.dispose();
    _dateofPurchaseController.dispose();
    _purchasePriceController.dispose();
    _dateofSubmissionController.dispose();
    _dclrNumberController.dispose();
    _targetedPriceController.dispose();
    _remarkController.dispose();
    _targetedRemarkController.dispose();
    _targetedHPController.dispose();
    _targetedDPController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focus3.hasFocus != _focused3) {
      setState(() {
        _focused3 = _focus3.hasFocus;
      });
    }
  }

  bool _focused3 = false;

  void addDataToList() {
    final productName = _productController.text;
    final competitorName = _competitorController.text;
    final hospitalPrice = _hospitalPriceController.text;
    final distributorPrice = _distributorPriceController.text;
    final dateofPurchase = _dateofPurchaseController.text == ""
        ? DateFormat('dd/MM/yyyy').format(DateTime.now())
        : _dateofPurchaseController.text;
    final purchasePrice = _purchasePriceController.text;
    final dateofSubmission = _dateofSubmissionController.text == ""
        ? DateFormat('dd/MM/yyyy').format(DateTime.now())
        : _dateofSubmissionController.text;
    final dclrNumber = _dclrNumberController.text;
    final targetedPrice = _targetedPriceController.text;
    final remark = _remarkController.text;
    final targetedRemarks = _targetedRemarkController.text;
    final targetedHP = _targetedHPController.text;
    final targetedDP = _targetedDPController.text;

    if (productName.isNotEmpty) {
      final newData = {
        "leadProductId": leadPrdId,
        "leadProductName": productName,
        "leadCompetitorName": competitorName,
        "leadHospitalPrice": hospitalPrice,
        "leadDistributorPrice": distributorPrice,
        "leadDateofPurchase": dateofPurchase,
        "leadPurchasePrice": purchasePrice,
        "leadDateofSubmission": dateofSubmission,
        "leadDclrNumber": dclrNumber,
        "leadTargetedPrice": targetedPrice,
        "leadRemark": remark,
        "leadTargetRemark": targetedRemarks,
        "leadSamplePurchased": selectedPurchasedValue ? "Yes" : "No",
        "leadSampleSubmitted": selectedSubmittedValue ? "Yes" : "No",
        "leadTargetHP": targetedHP,
        "leadTargetDP": targetedDP,
      };
      setState(() {
        productList.add(newData);
      });
      _productController.clear();
      _competitorController.clear();
      _hospitalPriceController.clear();
      _distributorPriceController.clear();
      _dateofPurchaseController.clear();
      _purchasePriceController.clear();
      _dateofSubmissionController.clear();
      _dclrNumberController.clear();
      _targetedPriceController.clear();
      _remarkController.clear();
      _targetedRemarkController.clear();
      _targetedHPController.clear();
      _targetedDPController.clear();
      selectedPurchasedValue = true;
      selectedSubmittedValue = true;
      leadPrdId = "";
    } else {
      if (!mounted) return;
      NotificationService.info(
        title: "Info",
        message: "Product adding failed.",
      );
    }
  }

  Future<void> _loadproducts(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'ItemCode': "0",
    };
    const apiUrl = '${ApiHelper.baseUrl}selectitemmaster';
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
          final List products = jsonDecode(response.body)["Data"];
          List<Map<String, dynamic>> newProductList = [];
          for (var item in products) {
            final cust = {
              "ItemId": item["ItemId"],
              "ItemCode": item["ItemCode"],
              "ItemName": item["ItemName"],
            };
            newProductList.add(cust);
          }
          setState(() {
            allProductList = newProductList;
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
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading lead products.",
      );
    }
  }

  Future<List<Product>> getProductData(String search) async {
    List<Product> prdList = convertProductList(allProductList);
    List<Product> newPrdList = [];
    await Future.delayed(const Duration(microseconds: 500));
    newPrdList = prdList
        .where(
          (element) =>
              element.ProductName.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();

    return newPrdList;
  }

  List<Product> convertProductList(List<Map<String, dynamic>> productList) {
    return productList
        .map(
          (map) => Product(
            ProductId: int.tryParse(map['ItemId']?.toString() ?? '') ?? 0,
            ProductCode: map['ItemCode']?.toString() ?? '',
            ProductName: map['ItemName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  void loadProductDetails(Map<String, Object> item) async {
    leadPrdId = item['leadProductId'].toString();
    _productController.text = item['leadProductName'].toString();
    _competitorController.text = item['leadCompetitorName'].toString();
    _hospitalPriceController.text = item['leadHospitalPrice'].toString();
    _distributorPriceController.text = item['leadDistributorPrice'].toString();
    _dateofPurchaseController.text = item['leadDateofPurchase'].toString();
    _purchasePriceController.text = item['leadPurchasePrice'].toString();
    _dateofSubmissionController.text = item['leadDateofSubmission'].toString();
    _dclrNumberController.text = item['leadDclrNumber'].toString();
    _targetedPriceController.text = item['leadTargetedPrice'].toString();
    _remarkController.text = item['leadRemark'].toString();
    _targetedRemarkController.text = item['leadTargetRemark'].toString();
    _targetedHPController.text = item['leadTargetHP'].toString();
    _targetedDPController.text = item['leadTargetDP'].toString();
    selectedPurchasedValue = item['leadSamplePurchased'] == "Yes"
        ? true
        : false;
    selectedSubmittedValue = item['leadSampleSubmitted'] == "Yes"
        ? true
        : false;
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> submitStageTwo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final leadstagetwo = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadID': leadId,
      'productList': productList,
    };
    const apiUrl = '${ApiHelper.baseUrl}insertleadstagetwo';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(leadstagetwo),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          _productController.clear();
          _competitorController.clear();
          _hospitalPriceController.clear();
          _distributorPriceController.clear();
          _dateofPurchaseController.clear();
          _purchasePriceController.clear();
          _dateofSubmissionController.clear();
          _dclrNumberController.clear();
          _targetedPriceController.clear();
          _remarkController.clear();
          _targetedRemarkController.clear();
          _targetedHPController.clear();
          _targetedDPController.clear();
          selectedPurchasedValue = true;
          selectedSubmittedValue = true;
          leadPrdId = "";
          setState(() {
            productList.clear();
          });
          if (!mounted) return;
          NotificationService.success(
            title: "Success",
            message: "Saved successfully.",
          );
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
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while submitting stage 2.",
      );
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
      'LeadActivityStageLevel': "2",
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
          if (!mounted) return;
          NotificationService.success(
            title: "Success",
            message: "Saved successfully.",
          );
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
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while submitting stage summary.",
      );
    }
  }

  List<Map<String, Object>> convertLeadProductsToMapList(
    List<LeadProducts> leadProducts,
  ) {
    return leadProducts.map((leadProducts) {
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
        "leadTargetHP": leadProducts.leadTargetHP,
        "leadTargetDP": leadProducts.leadTargetDP,
        "leadTargetRemark": leadProducts.leadTargetRemark,
      };
    }).toList();
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
              context.read<LeadProductsProvider>().updateLeadProducts(
                newLeadProducts,
              );
              productList = convertLeadProductsToMapList(newLeadProducts);
            });
          }
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
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        title: "Error",
        message: "Error occured while loading lead products.",
      );
    }
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
                  'Stage 2 - Sample Data Collection.',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          backgroundColor: const Color(0xFF2CA9DF),
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth > 600) {
              return _buildWideContainers();
            } else {
              return _buildNormalContainer();
            }
          },
        ),
      ),
    );
  }

  Widget _buildNormalContainer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonWidth = screenWidth * 0.8;
    final textFieldWidth = screenWidth * 0.9;
    // final containerHeight = screenHeight * 0.05;

    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      deviceOrientation = "Portrait";
    } else {
      deviceOrientation = "Landscape";
    }
    double containerDropDownHeight = 0;
    double containerHeight = 0;

    if (deviceOrientation == "Portrait") {
      containerDropDownHeight = screenHeight * 0.06;
      containerHeight = screenHeight * 0.06;
    } else {
      containerDropDownHeight = screenHeight * 0.12;
    }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: NotificationListener(
        onNotification: (notificationInfo) {
          if (notificationInfo is ScrollUpdateNotification) {
            if (_focus3.hasFocus) {
              _focus3.unfocus();
            }
            // else {
            //   _focus.requestFocus();
            // }
          }
          return true;
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 160, // Set a fixed height or adjust as needed
                    child: HeaderPage(leadsId: leadId, leadStageForEdit: "2"),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    color: const Color(0xffefefef),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Padding(
                        //   padding: const EdgeInsets.symmetric(horizontal: 15),
                        //   child: SizedBox(
                        //     width: textFieldWidth,
                        //     height: containerHeight,
                        //     child: TextFormField(
                        //       controller: _productController,
                        //       keyboardType: TextInputType.name,
                        //       decoration: const InputDecoration(
                        //         border: UnderlineInputBorder(),
                        //         hintText: 'Product Name',
                        //         hintStyle: TextStyle(
                        //           fontSize: 14,
                        //           fontFamily: 'Poppins',
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        Padding(
                          padding: const EdgeInsets.only(
                            right: 15.0,
                            left: 15.0,
                          ),
                          child: SizedBox(
                            height: deviceOrientation == "Portrait"
                                ? containerHeight
                                : containerDropDownHeight / 1.5,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: AsyncAutocomplete<Product>(
                                    onChanged: (s) {
                                      setState(() {});
                                    },
                                    onSubmitted: (prod) {
                                      setState(() {
                                        _productController.text = prod;
                                      });
                                    },
                                    focusNode: _focus3,
                                    maxListHeight:
                                        deviceOrientation == "Portrait"
                                        ? 370
                                        : 200,
                                    decoration: InputDecoration(
                                      labelText: 'Products',
                                      labelStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: "Poppins",
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Colors.blue,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          0.0,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.only(
                                        left: 0,
                                        right: 26,
                                        top: 0,
                                        bottom: 0,
                                      ),
                                    ),
                                    controller: _productController,
                                    inputKey: productKey,
                                    onTapItem: (Product product) {
                                      setState(() {
                                        _productController.text =
                                            product.ProductName;
                                      });
                                    },
                                    suggestionBuilder: (data) => ListTile(
                                      title: Text(
                                        data.ProductName,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    asyncSuggestions: (searchValue) =>
                                        getProductData(searchValue),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: -15,
                                  child: SizedBox(
                                    child: _productController.text == ""
                                        ? Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.transparent,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.only(
                                                top: 14,
                                                right: 20,
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
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 7,
                                                right: 2,
                                              ),
                                              child: IconButton(
                                                onPressed: () {
                                                  _productController.clear();
                                                },
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 20,
                                                ),
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: SizedBox(
                            width: textFieldWidth,
                            height: containerHeight,
                            child: TextFormField(
                              controller: _competitorController,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                border: UnderlineInputBorder(),
                                labelText: 'Competitor Name',
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                  color: Color(0xff454545),
                                  fontWeight: FontWeight.w400,
                                ),
                                contentPadding: EdgeInsets.only(
                                  left: 0,
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 15.0,
                                      ),
                                      child: SizedBox(
                                        height: containerHeight,
                                        child: TextFormField(
                                          controller: _hospitalPriceController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            border: UnderlineInputBorder(),
                                            labelText: 'Current HP',
                                            labelStyle: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                            ),
                                            contentPadding: EdgeInsets.only(
                                              left: 0,
                                              right: 0,
                                              top: 0,
                                              bottom: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: SizedBox(
                                        height: containerHeight,
                                        child: TextFormField(
                                          controller:
                                              _distributorPriceController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            border: UnderlineInputBorder(),
                                            labelText: ' Current DP',
                                            labelStyle: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                            ),
                                            contentPadding: EdgeInsets.only(
                                              left: 0,
                                              right: 0,
                                              top: 0,
                                              bottom: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 15.0,
                                      ),
                                      child: SizedBox(
                                        height: containerHeight,
                                        child: TextFormField(
                                          controller: _targetedHPController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            border: UnderlineInputBorder(),
                                            labelText: 'Targeted HP',
                                            labelStyle: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                            ),
                                            contentPadding: EdgeInsets.only(
                                              left: 0,
                                              right: 0,
                                              top: 0,
                                              bottom: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: SizedBox(
                                        height: containerHeight,
                                        child: TextFormField(
                                          controller: _targetedDPController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            border: UnderlineInputBorder(),
                                            labelText: ' Targeted DP',
                                            labelStyle: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                            ),
                                            contentPadding: EdgeInsets.only(
                                              left: 0,
                                              right: 0,
                                              top: 0,
                                              bottom: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            color: Colors.white,
                            width: textFieldWidth,
                            height: 60,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                                right: 8,
                              ),
                              child: TextField(
                                controller: _remarkController,
                                maxLines: 6,
                                decoration: InputDecoration(
                                  labelText: 'Remark.',
                                  labelStyle: const TextStyle(
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
                                      _isProductRemarksListening
                                          ? Icons.mic
                                          : Icons.mic_none,
                                    ),
                                    onPressed: () {
                                      _listen(
                                        _remarkController,
                                        _isProductRemarksListening,
                                        (bool isListening) {
                                          _isProductRemarksListening =
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
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Sample Purchased ?:',
                                style: TextStyle(
                                  color: Color(0xFF454545),
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Checkbox(
                                value: selectedPurchasedValue,
                                onChanged: (value) {
                                  setState(() {
                                    selectedPurchasedValue = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 150,
                                    height: containerHeight,
                                    padding: const EdgeInsets.only(
                                      left: 5.0,
                                      right: 6.0,
                                    ),
                                    decoration: BoxDecoration(
                                      border: const Border(
                                        bottom: BorderSide(color: Colors.grey),
                                      ),
                                      borderRadius: BorderRadius.circular(0.0),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            readOnly: true,
                                            style: const TextStyle(
                                              color: Color(0xFF454545),
                                              fontSize: 13,
                                            ),
                                            controller:
                                                _dateofPurchaseController,
                                            decoration: const InputDecoration(
                                              hintText: 'Date Of Purchase',
                                              contentPadding: EdgeInsets.only(
                                                left: 18,
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
                                            _dateofPurchaseController.text =
                                                formattedDate;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: SizedBox(
                                        // width: 150,
                                        height: containerHeight,
                                        child: TextFormField(
                                          controller: _purchasePriceController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            border: UnderlineInputBorder(),
                                            labelText: 'Purchase Price',
                                            labelStyle: TextStyle(
                                              color: Color(0xFF454545),
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Sample Submitted to Factory ?',
                                style: TextStyle(
                                  color: Color(0xFF454545),
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Checkbox(
                                value: selectedSubmittedValue,
                                onChanged: (value) {
                                  setState(() {
                                    selectedSubmittedValue = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 150,
                                    height: containerHeight,
                                    padding: const EdgeInsets.only(
                                      left: 20.0,
                                      right: 6.0,
                                    ),
                                    decoration: BoxDecoration(
                                      border: const Border(
                                        bottom: BorderSide(color: Colors.grey),
                                      ),
                                      borderRadius: BorderRadius.circular(0.0),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            readOnly: true,
                                            style: const TextStyle(
                                              color: Color(0xFF454545),
                                              fontFamily: 'Poppins',
                                              fontSize: 13,
                                            ),
                                            controller:
                                                _dateofSubmissionController,
                                            decoration: const InputDecoration(
                                              hintText: "Date of submission",
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
                                            _dateofSubmissionController.text =
                                                formattedDate;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: SizedBox(
                                        height: containerHeight,
                                        child: TextFormField(
                                          controller: _dclrNumberController,
                                          keyboardType: TextInputType.text,
                                          decoration: const InputDecoration(
                                            border: UnderlineInputBorder(),
                                            labelText: 'DC/LR Number',
                                            labelStyle: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: SizedBox(
                            width: textFieldWidth,
                            height: containerHeight,
                            child: TextFormField(
                              controller: _targetedPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: UnderlineInputBorder(),
                                labelText: 'Targeted Price',
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF454545),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 16,
                            bottom: 16,
                          ),
                          child: Container(
                            color: const Color(0xffffffff),
                            width: textFieldWidth,
                            height: 60,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                                right: 8,
                              ),
                              child: TextField(
                                controller: _targetedRemarkController,
                                maxLines: 6,
                                decoration: InputDecoration(
                                  labelText: 'Remark.',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF454545),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Poppins',
                                  ),
                                  contentPadding: const EdgeInsets.only(
                                    top: 20.0,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isTargetedRemarksListening
                                          ? Icons.mic
                                          : Icons.mic_none,
                                    ),
                                    onPressed: () {
                                      _listen(
                                        _targetedRemarkController,
                                        _isTargetedRemarksListening,
                                        (bool isListening) {
                                          _isTargetedRemarksListening =
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
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 100,
                                child: InkWell(
                                  onTap: () {
                                    addDataToList();
                                  },
                                  child: Container(
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2CA9DF),
                                      borderRadius: BorderRadius.circular(0.0),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Add',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: "Poppins",
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.add_circle_outline,
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
                        const SizedBox(height: 10),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            itemCount: productList.length,
                            itemBuilder: (context, int ind) {
                              return Container(
                                margin: const EdgeInsets.only(
                                  bottom: 10,
                                  left: 10,
                                  right: 10,
                                ),
                                color: const Color(0xFFffffff),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Text('Lead No : $leadId'),
                                            Expanded(
                                              child: Text(
                                                'Product Name : ${productList[ind]['leadProductName'] ?? ''}',
                                                style: const TextStyle(
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xff454545),
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                loadProductDetails(
                                                  productList[ind],
                                                );
                                                setState(() {
                                                  productList.remove(
                                                    productList[ind],
                                                  );
                                                });
                                              },
                                              child: const Icon(
                                                Icons.edit,
                                                size: 16.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${productList[ind]['leadCompetitorName'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xff454545),
                                        ),
                                      ),
                                      // Text(
                                      //     'Product : ${item['leadProductName'] ?? ''}'),
                                      const Text(
                                        'Sample Purchased / Sent to Factory',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xff454545),
                                        ),
                                      ),
                                      const Text(
                                        'on 04-03-2024 PM',
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xff454545),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // trailing: GestureDetector(
                                  //   onTap: () {
                                  //     loadProductDetails(item);
                                  //     setState(() {
                                  //       productList.remove(item);
                                  //     });
                                  //   },
                                  //   child: const Icon(Icons.edit, size: 16.0),
                                  // ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 460, // Set a fixed height or adjust as needed
                          child: FooterPage(
                            leadsId: leadId,
                            leadStageForEdit: "2",
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: buttonWidth,
                      child: GestureDetector(
                        onTap: () async {
                          if (locationControllerFooter.text == "" ||
                              productList.isEmpty) {
                            final snackBar = SnackBar(
                              backgroundColor: const Color(0xFF2CA9DF),
                              duration: const Duration(seconds: 2),
                              content: Text(
                                productList.isEmpty
                                    ? 'Select at least one product from the list to proceed.'
                                    : 'Location is missing, Please add location and try again...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
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
                              await submitStageTwo();
                              await submitStageSummary();
                              Navigator.of(dialogContext!).pop();
                              navigateToHomePage();
                            } catch (error) {
                              // print('Error: $error');
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
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideContainers() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonWidth = screenWidth * 0.8;
    final textFieldWidth = screenWidth * 0.9;
    final containerHeight = screenHeight * 0.09;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: NotificationListener(
        onNotification: (notificationInfo) {
          if (notificationInfo is ScrollUpdateNotification) {
            if (_focus3.hasFocus) {
              _focus3.unfocus();
            }
          }
          return true;
        },
        child: Center(
          child: SingleChildScrollView(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                // ignore: sized_box_for_whitespace
                Expanded(
                  child: Form(
                    key: _formKey2,
                    child: Column(
                      children: [
                        Container(
                          color: const Color(0xffEFEFEF),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 15.0,
                                  left: 15.0,
                                ),
                                child: SizedBox(
                                  height: deviceOrientation == "Portrait"
                                      ? containerHeight
                                      : containerHeight / 1.5,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 400, // Set a fixed height
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: AsyncAutocomplete<Product>(
                                                  onChanged: (s) {
                                                    setState(() {});
                                                  },
                                                  onSubmitted: (prod) {
                                                    setState(() {
                                                      _productController.text =
                                                          prod;
                                                    });
                                                  },
                                                  focusNode: _focus3,
                                                  maxListHeight:
                                                      deviceOrientation ==
                                                          "Portrait"
                                                      ? 370
                                                      : 200,
                                                  decoration: InputDecoration(
                                                    labelText: 'Products',
                                                    labelStyle: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontFamily: "Poppins",
                                                    ),
                                                    focusedBorder:
                                                        UnderlineInputBorder(
                                                          borderSide:
                                                              const BorderSide(
                                                                color:
                                                                    Colors.blue,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                0.0,
                                                              ),
                                                        ),
                                                    contentPadding:
                                                        const EdgeInsets.only(
                                                          left: 0,
                                                          right: 10,
                                                          top: 0,
                                                          bottom: 0,
                                                        ),
                                                  ),
                                                  controller:
                                                      _productController,
                                                  inputKey: productKey2,
                                                  onTapItem: (Product product) {
                                                    setState(() {
                                                      _productController.text =
                                                          product.ProductName;
                                                    });
                                                  },
                                                  suggestionBuilder: (data) =>
                                                      ListTile(
                                                        title: Text(
                                                          data.ProductName,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                      ),
                                                  asyncSuggestions:
                                                      (searchValue) =>
                                                          getProductData(
                                                            searchValue,
                                                          ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: -15,
                                                child: SizedBox(
                                                  child:
                                                      _productController.text ==
                                                          ""
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
                                                                  right: 20,
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
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 7,
                                                                  right: 2,
                                                                ),
                                                            child: IconButton(
                                                              onPressed: () {
                                                                _productController
                                                                    .clear();
                                                              },
                                                              icon: const Icon(
                                                                Icons
                                                                    .close_rounded,
                                                                size: 20,
                                                              ),
                                                              color:
                                                                  Colors.grey,
                                                            ),
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
                                ),
                              ),
                              SizedBox(
                                width: textFieldWidth,
                                height: containerHeight,
                                child: TextFormField(
                                  controller: _competitorController,
                                  keyboardType: TextInputType.text,
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                    labelText: 'Competitor Name',
                                    labelStyle: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      color: Color(0xff454545),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    contentPadding: EdgeInsets.only(
                                      left: 0,
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 15.0,
                                            ),
                                            child: SizedBox(
                                              height: containerHeight,
                                              child: TextFormField(
                                                controller:
                                                    _hospitalPriceController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                      border:
                                                          UnderlineInputBorder(),
                                                      labelText: 'Current HP',
                                                      labelStyle: TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.only(
                                                            left: 0,
                                                            right: 0,
                                                            top: 0,
                                                            bottom: 0,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                            ),
                                            child: SizedBox(
                                              height: containerHeight,
                                              child: TextFormField(
                                                controller:
                                                    _distributorPriceController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                      border:
                                                          UnderlineInputBorder(),
                                                      labelText: ' Current DP',
                                                      labelStyle: TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.only(
                                                            left: 0,
                                                            right: 0,
                                                            top: 0,
                                                            bottom: 0,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 15.0,
                                            ),
                                            child: SizedBox(
                                              height: containerHeight,
                                              child: TextFormField(
                                                controller:
                                                    _targetedHPController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                      border:
                                                          UnderlineInputBorder(),
                                                      labelText: 'Targeted HP',
                                                      labelStyle: TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.only(
                                                            left: 0,
                                                            right: 0,
                                                            top: 0,
                                                            bottom: 0,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                            ),
                                            child: SizedBox(
                                              height: containerHeight,
                                              child: TextFormField(
                                                controller:
                                                    _targetedDPController,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    const InputDecoration(
                                                      border:
                                                          UnderlineInputBorder(),
                                                      labelText: ' Targeted DP',
                                                      labelStyle: TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.only(
                                                            left: 0,
                                                            right: 0,
                                                            top: 0,
                                                            bottom: 0,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                child: SizedBox(
                                  width: textFieldWidth,
                                  height: 60,
                                  child: TextField(
                                    controller: _remarkController,
                                    maxLines: 6,
                                    decoration: InputDecoration(
                                      labelText: 'Remark.',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF454545),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Poppins',
                                      ),
                                      contentPadding: const EdgeInsets.all(
                                        20.0,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isProductRemarksListening
                                              ? Icons.mic
                                              : Icons.mic_none,
                                        ),
                                        onPressed: () {
                                          _listen(
                                            _remarkController,
                                            _isProductRemarksListening,
                                            (bool isListening) {
                                              _isProductRemarksListening =
                                                  isListening;
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 38.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Sample Purchased ?:',
                                      style: TextStyle(
                                        color: Color(0xFF454545),
                                      ), // Text color
                                    ),
                                    Row(
                                      children: [
                                        Radio(
                                          value: true,
                                          groupValue: selectedPurchasedValue,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedPurchasedValue = true;
                                            });
                                          },
                                        ),
                                        const Text(
                                          'Yes',
                                          style: TextStyle(
                                            color: Color(0xFF454545),
                                          ), // Text color
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Radio(
                                          value: false,
                                          groupValue: selectedPurchasedValue,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedPurchasedValue = false;
                                            });
                                          },
                                        ),
                                        const Text(
                                          'No',
                                          style: TextStyle(
                                            color: Color(0xFF454545),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 38.0,
                                  right: 38,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date of Purchase',
                                      style: TextStyle(
                                        color: Color(0xFF454545),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: containerHeight,
                                            child: Stack(
                                              alignment: Alignment.centerRight,
                                              children: [
                                                TextFormField(
                                                  readOnly: true,
                                                  controller:
                                                      _dateofPurchaseController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: InputDecoration(
                                                    border:
                                                        const UnderlineInputBorder(),
                                                    hintText: DateFormat(
                                                      'dd/MM/yyyy',
                                                    ).format(DateTime.now()),
                                                    hintStyle: const TextStyle(
                                                      fontSize: 14,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize:
                                                        14, // Adjust the size as needed
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons
                                                        .calendar_month_outlined,
                                                  ),
                                                  onPressed: () async {
                                                    DateTime? selectedDate =
                                                        await showDatePicker(
                                                          context: context,
                                                          initialDate:
                                                              DateTime.now(),
                                                          firstDate: DateTime(
                                                            2000,
                                                          ),
                                                          lastDate:
                                                              DateTime.now(),
                                                          initialEntryMode:
                                                              DatePickerEntryMode
                                                                  .calendarOnly,
                                                        );
                                                    String formattedDate =
                                                        DateFormat(
                                                          'dd/MM/yyyy',
                                                        ).format(selectedDate!);
                                                    _dateofPurchaseController
                                                            .text =
                                                        formattedDate;
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: SizedBox(
                                            height: containerHeight,
                                            child: TextFormField(
                                              controller:
                                                  _purchasePriceController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                border: UnderlineInputBorder(),
                                                labelText: 'Purchase Price',
                                                hintText: 'Purchase Price',
                                                hintStyle: TextStyle(
                                                  fontSize: 14,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 38.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sample Submitted to Factory ?',
                                      style: TextStyle(
                                        color: Color(0xFF454545),
                                        fontFamily: "Poppins",
                                        fontSize: 14,
                                      ), // Text color
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 38.0,
                                  right: 38,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Date of Submission',
                                      style: TextStyle(
                                        color: Color(0xFF454545),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: containerHeight,
                                            child: Stack(
                                              alignment: Alignment.centerRight,
                                              children: [
                                                TextFormField(
                                                  readOnly: true,
                                                  controller:
                                                      _dateofSubmissionController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: InputDecoration(
                                                    border:
                                                        const UnderlineInputBorder(),
                                                    hintText: DateFormat(
                                                      'dd/MM/yyyy',
                                                    ).format(DateTime.now()),
                                                    hintStyle: const TextStyle(
                                                      fontSize: 14,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons
                                                        .calendar_month_outlined,
                                                  ),
                                                  onPressed: () async {
                                                    DateTime? selectedDate =
                                                        await showDatePicker(
                                                          context: context,
                                                          initialDate:
                                                              DateTime.now(),
                                                          firstDate: DateTime(
                                                            2000,
                                                          ),
                                                          lastDate:
                                                              DateTime.now(),
                                                          initialEntryMode:
                                                              DatePickerEntryMode
                                                                  .calendarOnly,
                                                        );
                                                    String formattedDate =
                                                        DateFormat(
                                                          'dd/MM/yyyy',
                                                        ).format(selectedDate!);
                                                    _dateofSubmissionController
                                                            .text =
                                                        formattedDate;
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: SizedBox(
                                            height: containerHeight,
                                            child: TextFormField(
                                              controller: _dclrNumberController,
                                              keyboardType: TextInputType.text,
                                              decoration: const InputDecoration(
                                                border: UnderlineInputBorder(),
                                                labelText: 'DC/LR Number',
                                                hintText: 'DC/LR Number',
                                                hintStyle: TextStyle(
                                                  fontSize: 14,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: SizedBox(
                                  width: textFieldWidth,
                                  height: containerHeight,
                                  child: TextFormField(
                                    controller: _targetedPriceController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: UnderlineInputBorder(),
                                      labelText: 'Targeted Price',
                                      hintText: 'Targeted Price',
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                child: SizedBox(
                                  width: textFieldWidth,
                                  height: 60,
                                  child: TextField(
                                    controller: _targetedRemarkController,
                                    maxLines: 6,
                                    decoration: InputDecoration(
                                      labelText: 'Remark.',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF454545),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Poppins',
                                      ),
                                      contentPadding: const EdgeInsets.all(
                                        10.0,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isTargetedRemarksListening
                                              ? Icons.mic
                                              : Icons.mic_none,
                                        ),
                                        onPressed: () {
                                          _listen(
                                            _remarkController,
                                            _isTargetedRemarksListening,
                                            (bool isListening) {
                                              _isTargetedRemarksListening =
                                                  isListening;
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: buttonWidth,
                                child: InkWell(
                                  onTap: () {
                                    addDataToList();
                                  },
                                  child: Container(
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2CA9DF),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Add',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SingleChildScrollView(
                                child: Column(
                                  children: <Widget>[
                                    for (var item in productList)
                                      SizedBox(
                                        width: 320,
                                        height: 80,
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          color:
                                              productList.indexOf(item) % 2 == 0
                                              ? const Color(0xFFEAEAEA)
                                              : const Color(0xFFEAEAEA),
                                          child: ListTile(
                                            title: Text('Lead No : $leadId'),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Product : ${item['leadProductName'] ?? ''}',
                                                ),
                                                Text(
                                                  'Competitor : ${item['leadCompetitorName'] ?? ''}',
                                                ),
                                              ],
                                            ),
                                            trailing: GestureDetector(
                                              onTap: () {
                                                loadProductDetails(item);
                                                setState(() {
                                                  productList.remove(item);
                                                });
                                              },
                                              child: const Icon(
                                                Icons.edit,
                                                size: 16.0,
                                              ),
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
                        const SizedBox(height: 20),
                      ],
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
