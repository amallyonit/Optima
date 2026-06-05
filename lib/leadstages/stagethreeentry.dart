// ignore_for_file: use_build_context_synchronously, avoid_print, non_constant_identifier_names, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:optima/classes/footerConstants.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/tabs/tabspage.dart';
import 'package:http/http.dart' as http;
import 'package:optima/api_helper.dart';
import 'package:optima/classes/leads.dart';
import 'package:optima/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import '../notificationService.dart';
import '../pages/footer.dart';
import '../pages/header.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

String? feedbackStatus = "Next Action";
String leadId = "", leadPrdId = "", agingDays = "", leadHospitalCode = "";
List<Map<String, Object>> productList = [];
List<Map<String, Object>> selectedProductList = [];
String deviceOrientation = "";
TextEditingController feedbackController = TextEditingController();
TextEditingController sampleReceivedDateController = TextEditingController(
  text: DateFormat(
    'dd/MM/yyyy',
  ).format(DateTime.now()).toString().substring(0, 10),
);
TextEditingController sampleSubmittedDateController = TextEditingController(
  text: DateFormat(
    'dd/MM/yyyy',
  ).format(DateTime.now()).toString().substring(0, 10),
);
TextEditingController sampleSubmittedToController = TextEditingController();
TextEditingController feedbackDateController = TextEditingController();
bool selectedMailValue = false;
bool stage3Edit = false;
String stage3EntryId = "";

class StageThreeLeadEntryPage extends StatefulWidget {
  final String leadsId;
  const StageThreeLeadEntryPage({super.key, required this.leadsId});
  @override
  StageThreeLeadEntryPageState createState() => StageThreeLeadEntryPageState();
}

class LeadProductsStage3Provider with ChangeNotifier {
  List<LeadProducts> _leadProducts = [];
  List<LeadProducts> get leadProducts => _leadProducts;
  void updateLeadProducts(List<LeadProducts> newLeadProducts) {
    _leadProducts = newLeadProducts;
    notifyListeners();
  }
}

class LeadProductsStage4Provider with ChangeNotifier {
  List<LeadProducts> _leadProducts = [];
  List<LeadProducts> get leadProducts => _leadProducts;
  void updateLeadProducts(List<LeadProducts> newLeadProducts) {
    _leadProducts = newLeadProducts;
    notifyListeners();
  }
}

class Contacts {
  String CustomerName;
  String CustomerCode;
  Contacts({required this.CustomerCode, required this.CustomerName});
}

class StageThreeLeadEntryPageState extends State<StageThreeLeadEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final contactKey = GlobalKey();
  final _sampleSubmittedToCustomerController = TextEditingController();
  final _sampleRecivedfromHOController = TextEditingController();
  final _productNameController = TextEditingController();
  final _agingInDaysController = TextEditingController();
  List<bool> checkboxStateList = List.generate(0, (index) => false);
  String selectedContactId = "";
  List<String> selectedProductNames = [];
  List<int> selectedProductIds = [];
  final TextEditingController _searchController2 = TextEditingController();

  bool selectedPurchasedValue = true;
  bool selectedSubmittedValue = true;
  List<Map<String, dynamic>> contactMasterList = [];
  final ScrollController scrollController = ScrollController();

  late FocusNode _focusContact;
  late stt.SpeechToText _speech;
  bool _isFeedbackListening = false;
  Timer? _timer;
  bool _isSummaryListening = false;

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

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _showLocationFetchFailedAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text('Location fetch failed, Retry now'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> getCurrentLocation() async {
    try {
      Position? position;
      if (!kIsWeb) {
        position = await Geolocator.getLastKnownPosition();
      }
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // same as desiredAccuracy before
        ),
      );
      latitudeFooter = position.latitude.toString();
      longitudeFooter = position.longitude.toString();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String location = [
          placemark.name ?? '',
          placemark.subLocality ?? '',
          placemark.locality ?? '',
          '${placemark.administrativeArea ?? ''}${placemark.postalCode != null ? ' - ' : ''}${placemark.postalCode ?? ''}',
          placemark.country ?? '',
        ].where((part) => part.isNotEmpty).join(', ');
        locationControllerFooter.text = location;
      } else {
        locationControllerFooter.clear();
      }
      setState(() {
        locationLoading = true;
      });
      if (locationControllerFooter.text == "") {
        _timer = Timer(const Duration(seconds: 30), () {
          if (locationLoading) {
            setState(() {
              locationLoading = false;
            });
            _showLocationFetchFailedAlert();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.warning(
        title: "Warning",
        message: "Error getting location.",
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _focusContact = FocusNode();
    _focusContact.addListener(_handleFocusChange);
    _speech = stt.SpeechToText();
    leadId = widget.leadsId;
    if (isUserLoggedIn) {
      _selectLeadAndContacts();
    }
  }

  void _handleFocusChange() {
    if (_focusContact.hasFocus != _focused) {
      setState(() {
        _focused = _focusContact.hasFocus;
      });
    }
  }

  bool _focused = false;

  Future<void> _selectLeadAndContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _selectLeadProducts(userJwtToken, userMailID);
    if (stage3Edit) {
      await loadProductDetailsForEdit(stage3EntryId, productList);
    }
    _loadContacs(userJwtToken, userMailID);
  }

  @override
  void dispose() {
    _timer?.cancel();
    scrollController.dispose();
    _agingInDaysController.dispose();
    sampleSubmittedDateController.dispose();
    sampleSubmittedToController.dispose();
    sampleReceivedDateController.dispose();
    _sampleRecivedfromHOController.dispose();
    _productNameController.dispose();
    super.dispose();
  }

  bool isValidDateString(String dateString) {
    try {
      DateTime.parse(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }

  List<Map<String, Object>> convertLeadProductsToMapList(
    List<LeadProducts> leadProducts,
  ) {
    return leadProducts
        .where(
          (leadProduct) =>
              leadProduct.leadStage4EntryId == 0 ||
              leadProduct.leadStage4Status == 'Re sampling',
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

          bool leadEditable =
              leadProducts.leadStage3Id.toString() != '0' &&
                  leadProducts.leadStage4Id.toString() == '0'
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
            "leadStage3Id": leadProducts.leadStage3Id,
            "leadEditable": leadEditable,
            "leadStage3RecievedDate": leadStage3RecievedDate,
            "leadStage3SubmittedDate": leadStage3SubmittedDate,
            "leadStage3ContactName": leadProducts.leadStage3ContactName,
            "leadStage3ContactCode": leadProducts.leadStage3ContactCode,
            "leadStage3EntryId": leadProducts.leadStage3EntryId,
          };
        })
        .toList();
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
              context.read<LeadProductsStage3Provider>().updateLeadProducts(
                newLeadProducts,
              );
              productList = convertLeadProductsToMapList(newLeadProducts);
              if (data[0].length > 0) {
                agingDays = data[0][0]['LeadAgingDays'].toString();
                leadHospitalCode = data[0][0]['LeadHospitalCode'].toString();
                stage3Edit = data[0][0]['LeadStage3EntryId'].toString() == "0"
                    ? false
                    : true;
                stage3EntryId = data[0][0]['LeadStage3EntryId'].toString();
              } else {
                agingDays = '';
                leadHospitalCode = '';
                stage3Edit = false;
                stage3EntryId = "";
              }
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

  Future<void> _loadContacs(String userJwtToken, String userMailID) async {
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'CustomerCode': leadHospitalCode,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectcustomercontactperson';
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
          List<Map<String, dynamic>> newContactList = [];
          for (var item in data) {
            final cont = {
              "CustContactId": item["CustContactId"],
              "CustContactName": item["CustContactName"],
              "CustContactMobileNo": item["CustContactMobileNo"],
              "CustContactEmailId": item["CustContactEmailId"],
              "DesignationName": item["DesignationName"],
              "DepartmentName": item["DepartmentName"],
            };
            newContactList.add(cont);
          }
          setState(() {
            contactMasterList = newContactList;
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
        message: "Error occured while loading lead contacts.",
      );
    }
  }

  void loadSelectedProducts() async {
    selectedProductList = productList
        .where(
          (product) => selectedProductIds.contains(product['leadProductId']),
        )
        .toList();
  }

  Future<void> submitStageThree() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    final leadstagethree = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadID': leadId,
      'LeadStage3RecievedDate': _sampleRecivedfromHOController.text == ""
          ? DateFormat('dd/MM/yyyy').format(DateTime.now())
          : _sampleRecivedfromHOController.text,
      'LeadStage3SubmittedDate': _sampleSubmittedToCustomerController.text == ""
          ? DateFormat('dd/MM/yyyy').format(DateTime.now())
          : _sampleSubmittedToCustomerController.text,
      'LeadStage3SubmittedPersonId': selectedContactId,
      'productList': selectedProductList,
    };
    const apiUrl = '${ApiHelper.baseUrl}insertleadstagethree';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(leadstagethree),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          _agingInDaysController.clear();
          _sampleSubmittedToCustomerController.clear();
          _sampleRecivedfromHOController.clear();
          _productNameController.clear();
          selectedContactId = "";
          leadPrdId = "";
          selectedProductNames = [];
          selectedProductIds = [];
          setState(() {
            productList.clear();
            selectedProductList.clear();
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
        message: "Error occured while submitting stage 3.",
      );
    }
  }

  Future<void> submitStageFour() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    final leadstagefour = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadID': leadId,
      'LeadStage4FeedbackDate': feedbackDateController.text == ""
          ? DateFormat('dd/MM/yyyy').format(DateTime.now())
          : feedbackDateController.text,
      'LeadStage4Status': feedbackStatus,
      'LeadStage4SubmittedToHo': selectedMailValue == true ? "Yes" : "No",
      'LeadStage4Remarks': feedbackController.text,
      'productList': selectedProductList,
    };
    const apiUrl = '${ApiHelper.baseUrl}insertleadstagefour';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(leadstagefour),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          feedbackController.clear();
          feedbackDateController.clear();
          leadPrdId = "";
          selectedProductNames = [];
          selectedProductIds = [];
          feedbackStatus = 'Next Action';
          selectedMailValue = false;
          setState(() {
            productList.clear();
            selectedProductList.clear();
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
        message: "Error occured while submitting stage 4.",
      );
    }
  }

  Future<void> submitStageSummary(String stageLevel) async {
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
      'LeadActivityStageLevel': stageLevel,
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

  Future<void> loadProductDetailsForEdit(
    String Stage3EntryId,
    List<Map<String, Object>> productList,
  ) async {
    int? leadStage3EntryId = int.tryParse(Stage3EntryId);
    selectedProductList = productList
        .where(
          (productItem) =>
              productItem['leadStage3EntryId'] == leadStage3EntryId,
        )
        .toList();
    selectedProductNames.clear();
    selectedProductIds.clear();

    for (Map<String, Object> productItem in selectedProductList) {
      selectedProductNames.add(productItem['leadProductName'] as String);
      selectedProductIds.add(productItem['leadProductId'] as int);
      _sampleRecivedfromHOController.text =
          productItem['leadStage3RecievedDate'] as String;
      _sampleSubmittedToCustomerController.text =
          productItem['leadStage3SubmittedDate'] as String;
      _searchController2.text = productItem['leadStage3ContactName'] as String;
      selectedContactId = productItem['leadStage3ContactCode'] as String;
    }
    _productNameController.text = selectedProductNames.join(', ');
  }

  void navigateToHomePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TabsPage(selectedIndex: 0, selectedRoleCode: ""),
      ),
    );
  }

  Future<List<Contacts>> getContacts(String search) async {
    List<Contacts> contList = convertContact(contactMasterList);
    List<Contacts> filteredList = contList
        .where(
          (element) =>
              element.CustomerName.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();

    return filteredList;
  }

  List<Contacts> convertContact(List<Map<String, dynamic>> contList) {
    return contList
        .map(
          (map) => Contacts(
            CustomerCode: map['CustContactId']?.toString() ?? '',
            CustomerName: map['CustContactName']?.toString() ?? '',
          ),
        )
        .toList();
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
                    sampleSubmittedToController.clear();
                    navigateToHomePage();
                  },
                  child: const Icon(
                    Icons.keyboard_arrow_left,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Stage 3 - Sample Submission - Feedback',
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
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth > 600) {
              deviceOrientation = "Landscape";
            } else {
              deviceOrientation = "Portrait";
            }
            return _buildContainer();
          },
        ),
      ),
    );
  }

  Widget _buildContainer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textFieldDropDownWidth =
        screenWidth * (screenWidth <= 600 ? 0.82 : 0.901);
    final containerHeight = screenHeight * (screenWidth <= 600 ? 0.06 : 0.12);
    double containerDropDownHeight = 0;
    final textFieldWidth = screenWidth * 0.4;
    final textFieldDateWidth = screenWidth * 0.9;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: NotificationListener(
        onNotification: (notificationInfo) {
          if (notificationInfo is ScrollUpdateNotification) {
            if (_focusContact.hasFocus) {
              _focusContact.unfocus();
            }
          }
          return true;
        },
        child: Center(
          child:
              // ignore: sized_box_for_whitespace
              SingleChildScrollView(
                reverse: false,
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 160, // Set a fixed height or adjust as needed
                        child: HeaderPage(
                          leadsId: leadId,
                          leadStageForEdit: "3",
                        ),
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
                          child: ListView.separated(
                            itemCount: productList.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
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
                                      const SizedBox(height: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                      _productNameController
                                                              .text =
                                                          selectedProductNames
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
                                                padding: EdgeInsets.only(
                                                  right: 12.0,
                                                ),
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  'Sample Received:',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xff454545),
                                                  ),
                                                ),
                                                Visibility(
                                                  visible:
                                                      checkboxStateList[index],
                                                  child: Text(
                                                    ' ${sampleReceivedDateController.text}',
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  'Submitted to Key Contact:',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xff454545),
                                                  ),
                                                ),
                                                Visibility(
                                                  visible:
                                                      checkboxStateList[index],
                                                  child: Text(
                                                    ' ${sampleSubmittedDateController.text}',
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  'Sample Submitted to:',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xff454545),
                                                  ),
                                                ),
                                                Visibility(
                                                  visible:
                                                      checkboxStateList[index],
                                                  child: Text(
                                                    sampleSubmittedToController
                                                        .text,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          const Padding(
                                            padding: EdgeInsets.only(
                                              left: 16.0,
                                              right: 16,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Sample/ \nRe Sample :',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xff454545),
                                                  ),
                                                ),
                                                Text(
                                                  'View History',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    decoration: TextDecoration
                                                        .underline,
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
                      const SizedBox(height: 25),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Sample Submission",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        color: const Color(0xffefefef),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Sample Received Date \n From HO',
                                        style: TextStyle(
                                          color: Color(0xff454545),
                                          fontWeight: FontWeight.w500,
                                          fontFamily: "Poppins",
                                          fontSize: 14.0,
                                        ),
                                      ),
                                      Container(
                                        width: 140,
                                        height: containerHeight,
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
                                                    _sampleRecivedfromHOController,
                                                decoration: InputDecoration(
                                                  hintText: DateFormat(
                                                    'dd/MM/yyyy',
                                                  ).format(DateTime.now()),
                                                  hintStyle: const TextStyle(
                                                    color: Color(0xff454545),
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily: "Poppins",
                                                    fontSize: 14.0,
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
                                                      initialDate:
                                                          DateTime.now(),
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
                                                _sampleRecivedfromHOController
                                                        .text =
                                                    formattedDate;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Sample Submitted \n Date ',
                                        style: TextStyle(
                                          color: Color(0xff454545),
                                          fontWeight: FontWeight.w500,
                                          fontFamily: "Poppins",
                                          fontSize: 14.0,
                                        ),
                                      ),
                                      Container(
                                        width: 140,
                                        height: containerHeight,
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
                                                    _sampleSubmittedToCustomerController,
                                                decoration: InputDecoration(
                                                  hintText: DateFormat(
                                                    'dd/MM/yyyy',
                                                  ).format(DateTime.now()),
                                                  hintStyle: const TextStyle(
                                                    color: Color(0xff454545),
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily: "Poppins",
                                                    fontSize: 14.0,
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
                                                      initialDate:
                                                          DateTime.now(),
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
                                                _sampleSubmittedToCustomerController
                                                        .text =
                                                    formattedDate;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: deviceOrientation == "Portrait"
                                    ? const EdgeInsets.only(left: 2.0)
                                    : const EdgeInsets.only(right: 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: deviceOrientation == "Portrait"
                                          ? containerHeight
                                          : containerDropDownHeight + 2,
                                      width: textFieldDropDownWidth,
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: AsyncAutocomplete<Contacts>(
                                              inputTextStyle: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontFamily: "Poppins",
                                                fontSize: 14,
                                              ),
                                              focusNode: _focusContact,
                                              maxListHeight:
                                                  deviceOrientation ==
                                                      "Portrait"
                                                  ? 370
                                                  : 200,
                                              decoration: InputDecoration(
                                                border: UnderlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(0),
                                                ),
                                                labelText:
                                                    'Sample Submitted to',
                                                labelStyle: const TextStyle(
                                                  color: Color(0xff454545),
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: "Poppins",
                                                  fontSize: 14.0,
                                                ),
                                                focusedBorder:
                                                    const UnderlineInputBorder(),
                                                contentPadding:
                                                    const EdgeInsets.only(
                                                      left: 0,
                                                      right: 30,
                                                      top: 2,
                                                      bottom: 0,
                                                    ),
                                                suffixIcon: const Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 10.0,
                                                  ),
                                                  child: Icon(
                                                    Icons.search,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                              controller: _searchController2,
                                              inputKey: contactKey,
                                              onTapItem: (Contacts contact) {
                                                setState(() {
                                                  _searchController2.text =
                                                      contact.CustomerName;
                                                  var customer = contactMasterList
                                                      .firstWhere(
                                                        (map) =>
                                                            map['CustContactName'] ==
                                                            contact
                                                                .CustomerName,
                                                        orElse: () =>
                                                            <String, dynamic>{
                                                              'CustContactId':
                                                                  null,
                                                            },
                                                      );
                                                  selectedContactId =
                                                      customer['CustContactId']
                                                          .toString();
                                                });
                                              },
                                              suggestionBuilder: (data) =>
                                                  ListTile(
                                                    title: Text(
                                                      data.CustomerName,
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xff454545,
                                                        ),
                                                        fontSize: 14.0,
                                                        fontFamily: "Poppins",
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                              asyncSuggestions: (searchValue) =>
                                                  getContacts(searchValue),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  right: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Sample/Re Sample'),
                                    SizedBox(
                                      child: GestureDetector(
                                        onTap: () async {
                                          setState(() {
                                            if (_sampleRecivedfromHOController
                                                    .text ==
                                                "") {
                                              sampleReceivedDateController
                                                  .text = DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(DateTime.now());
                                            } else {
                                              sampleReceivedDateController
                                                      .text =
                                                  _sampleRecivedfromHOController
                                                      .text;
                                            }

                                            if (_sampleSubmittedToCustomerController
                                                    .text ==
                                                "") {
                                              sampleSubmittedDateController
                                                  .text = DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(DateTime.now());
                                            } else {
                                              sampleSubmittedDateController
                                                      .text =
                                                  _sampleSubmittedToCustomerController
                                                      .text;
                                            }
                                            if (_searchController2.text == "") {
                                              return;
                                            } else {
                                              sampleSubmittedToController.text =
                                                  _searchController2.text;
                                            }
                                          });
                                          loadSelectedProducts();
                                        },
                                        child: Container(
                                          height: 30,
                                          width: 80,
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
                                                ),
                                              ),
                                              Icon(
                                                Icons.update,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ],
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
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Sample FeedBack",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      AbsorbPointer(
                        absorbing: !stage3Edit,
                        child: Container(
                          color: const Color(0xffefefef),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 140,
                                      height: containerHeight,
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
                                                  feedbackDateController,
                                              decoration: const InputDecoration(
                                                hintText: 'Feedback Date',
                                                hintStyle: TextStyle(
                                                  color: Color(0xff454545),
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: "Poppins",
                                                  fontSize: 13.0,
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
                                              feedbackDateController.text =
                                                  formattedDate;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Container(
                                      width: textFieldDropDownWidth / 2.97,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 10.0,
                                        ),
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          value: feedbackStatus,
                                          hint: const Text(
                                            "Status ",
                                            style: TextStyle(
                                              fontFamily: "Poppins",
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xff454545),
                                              height: 12 / 10,
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              feedbackStatus = newValue;
                                            });
                                          },
                                          underline: Container(),
                                          icon: const Icon(
                                            Icons.search,
                                            size: 20,
                                          ),
                                          items:
                                              <String>[
                                                'Next Action',
                                                'Re Sampling',
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
                                                      fontFamily: "Poppins",
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xff454545),
                                                      height: 12 / 10,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: deviceOrientation == "Portrait"
                                      ? const EdgeInsets.only(left: 2.0)
                                      : const EdgeInsets.only(right: 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          color: Colors.white,
                                          height: 60,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                              right: 8,
                                            ),
                                            child: TextField(
                                              controller: feedbackController,
                                              maxLines: 6,
                                              decoration: InputDecoration(
                                                labelText: 'Feedback.',
                                                labelStyle: const TextStyle(
                                                  color: Color(0xFF454545),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  fontFamily: 'Poppins',
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.only(
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
                                                      feedbackController,
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
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Details Send to HO \nvia Mail ?',
                                      ),
                                      Checkbox(
                                        value: selectedMailValue,
                                        onChanged: (value) {
                                          setState(() {
                                            selectedMailValue = value!;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // SizedBox(
                      //   height: 460, // Set a fixed height or adjust as needed
                      //   child: FooterPage(leadsId: leadId, leadStageForEdit: "3"),
                      // ),
                      SizedBox(
                        height: 500,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10.0, bottom: 0),
                          child: Column(
                            children: [
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(18.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "Meeting Summary",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Visibility(
                                              visible:
                                                  locationControllerFooter
                                                      .text ==
                                                  "",
                                              child: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    manualLocationFetchStart =
                                                        true;
                                                  });
                                                  getCurrentLocation();
                                                },
                                                icon:
                                                    locationLoading &&
                                                        manualLocationFetchStart
                                                    ? const CircularProgressIndicator()
                                                    : const Icon(
                                                        Icons.location_on,
                                                        color: Color(
                                                          0xFF2CA9DF,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Participant',
                                          style: TextStyle(
                                            color: Color(0xFF454545),
                                            fontFamily: "Poppins",
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 150,
                                          width: textFieldDropDownWidth,
                                          child: MultiLevelDropDown(
                                            stageNumber: "3",
                                            selectedParticipantFooter:
                                                selectedParticipantFooter,
                                            availableParticipant:
                                                availableParticipant,
                                            initialParticipant:
                                                initialParticipant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                    ),
                                    child: SizedBox(
                                      width: textFieldDropDownWidth,
                                      height: 120,
                                      child: TextField(
                                        controller: summaryControllerFooter,
                                        maxLines: 4,
                                        maxLength: 1000,
                                        decoration: InputDecoration(
                                          labelText: 'Summary of Discussion.',
                                          labelStyle: const TextStyle(
                                            fontFamily: "Poppins",
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xff909090),
                                            height: 15 / 10,
                                          ),
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.only(
                                            left: 15,
                                            right: 0,
                                            top: 15,
                                            bottom: 0,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isSummaryListening
                                                  ? Icons.mic
                                                  : Icons.mic_none,
                                            ),
                                            onPressed: () {
                                              _listen(
                                                summaryControllerFooter,
                                                _isSummaryListening,
                                                (bool isListening) {
                                                  _isSummaryListening =
                                                      isListening;
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 10.0,
                                      right: 0.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            SizedBox(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 8.0,
                                                        ),
                                                    child: Container(
                                                      width:
                                                          textFieldDateWidth /
                                                          2.8,
                                                      decoration:
                                                          const BoxDecoration(
                                                            border: Border(
                                                              bottom: BorderSide(
                                                                color:
                                                                    Colors.grey,
                                                              ), // Add bottom border
                                                            ),
                                                          ),
                                                      child: DropdownButton<String>(
                                                        isExpanded: true,
                                                        value:
                                                            selectedStatusFooter,
                                                        hint: const Text(
                                                          "Next Action ",
                                                          style: TextStyle(
                                                            fontFamily:
                                                                "Poppins",
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color: Color(
                                                              0xff454545,
                                                            ),
                                                            height: 12 / 10,
                                                          ),
                                                          textAlign:
                                                              TextAlign.left,
                                                        ),
                                                        onChanged:
                                                            (String? newValue) {
                                                              setState(() {
                                                                selectedStatusFooter =
                                                                    newValue;
                                                              });
                                                            },
                                                        underline:
                                                            Container(), // Remove the default underline
                                                        icon: const Icon(
                                                          Icons.search,
                                                          size: 20,
                                                        ),
                                                        items:
                                                            <String>[
                                                              'Next Action',
                                                              'Sampling',
                                                              'Re Sampling',
                                                              'Approved',
                                                              'Rejected',
                                                            ].map<
                                                              DropdownMenuItem<
                                                                String
                                                              >
                                                            >((String value) {
                                                              return DropdownMenuItem<
                                                                String
                                                              >(
                                                                value: value,
                                                                child: Text(
                                                                  value,
                                                                ),
                                                              );
                                                            }).toList(),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width:
                                                        textFieldDateWidth /
                                                        1.7,
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 10.0,
                                                          right: 0.0,
                                                        ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        const Text(
                                                          "On",
                                                          style: TextStyle(
                                                            fontFamily:
                                                                "Poppins",
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color: Color(
                                                              0xff454545,
                                                            ),
                                                          ),
                                                          textAlign:
                                                              TextAlign.left,
                                                        ),
                                                        const SizedBox(
                                                          width: 15,
                                                        ),
                                                        Expanded(
                                                          child: TextField(
                                                            controller:
                                                                followupDateControllerFooter,
                                                            readOnly: true,
                                                            decoration: InputDecoration(
                                                              hintText:
                                                                  DateFormat(
                                                                    'dd/MM/yyyy hh:mm a',
                                                                  ).format(
                                                                    DateTime.now(),
                                                                  ),
                                                              border:
                                                                  const UnderlineInputBorder(),
                                                              hintStyle: const TextStyle(
                                                                fontFamily:
                                                                    "Poppins",
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color: Color(
                                                                  0xff454545,
                                                                ),
                                                                height: 12 / 10,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                right: 10.0,
                                                              ),
                                                          child: IconButton(
                                                            icon: const Icon(
                                                              Icons
                                                                  .calendar_month_outlined,
                                                            ),
                                                            onPressed: () async {
                                                              DateTime?
                                                              selectedDate = await showDatePicker(
                                                                context:
                                                                    context,
                                                                initialDate:
                                                                    DateTime.now(),
                                                                firstDate:
                                                                    DateTime(
                                                                      2000,
                                                                    ),
                                                                lastDate:
                                                                    DateTime(
                                                                      2101,
                                                                    ),
                                                                initialEntryMode:
                                                                    DatePickerEntryMode
                                                                        .calendar,
                                                              );
                                                              TimeOfDay?
                                                              selectedTime =
                                                                  await showTimePicker(
                                                                    context:
                                                                        context,
                                                                    initialTime:
                                                                        TimeOfDay.now(),
                                                                  );
                                                              if (selectedTime !=
                                                                  null) {
                                                                String
                                                                formattedDateTime =
                                                                    DateFormat(
                                                                      'dd/MM/yyyy hh:mm a',
                                                                    ).format(
                                                                      DateTime(
                                                                        selectedDate!
                                                                            .year,
                                                                        selectedDate
                                                                            .month,
                                                                        selectedDate
                                                                            .day,
                                                                        selectedTime
                                                                            .hour,
                                                                        selectedTime
                                                                            .minute,
                                                                      ),
                                                                    );

                                                                followupDateControllerFooter
                                                                        .text =
                                                                    formattedDateTime;
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            width: textFieldWidth,
                            child: GestureDetector(
                              onTap: () async {
                                if (locationControllerFooter.text == "" ||
                                    selectedProductList.isEmpty) {
                                  final snackBar = SnackBar(
                                    backgroundColor: const Color(0xFF2CA9DF),
                                    duration: const Duration(seconds: 2),
                                    content: Text(
                                      selectedProductList.isEmpty
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      );
                                    },
                                  );
                                  try {
                                    await submitStageThree();
                                    await submitStageSummary("3");
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
                                      'Sample Submit',
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
                          SizedBox(
                            width: textFieldWidth,
                            child: GestureDetector(
                              onTap: () async {
                                loadSelectedProducts();
                                if (locationControllerFooter.text == "" ||
                                    selectedProductList.isEmpty) {
                                  final snackBar = SnackBar(
                                    backgroundColor: const Color(0xFF2CA9DF),
                                    duration: const Duration(seconds: 2),
                                    content: Text(
                                      selectedProductList.isEmpty
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      );
                                    },
                                  );
                                  try {
                                    await submitStageFour();
                                    await submitStageSummary("4");
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
                                      'Sample Feedback',
                                      style: TextStyle(
                                        color: Colors.white,
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
                      const SizedBox(height: 10),
                    ],
                  ),
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
