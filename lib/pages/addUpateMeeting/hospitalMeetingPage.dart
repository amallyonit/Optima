// ignore_for_file: file_names, use_build_context_synchronously, avoid_print, non_constant_identifier_names
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:optima/classes/globals.dart';
import 'package:optima/login_screen.dart';
import 'package:optima/pages/addUpateMeeting/participantMultiDropDown.dart';
import 'package:optima/pages/addUpateMeeting/productMultiDropDown.dart';
import 'package:optima/pages/addUpateMeeting/stageMultiDropDown.dart';
import 'package:optima/tabs/tabspage.dart';
import '../../api_helper.dart';
import '../../classes/leads.dart';
import 'contactSummaryWidget.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class InputMaterial {
  final int MaterialId;
  String MaterialName;
  InputMaterial({required this.MaterialId, required this.MaterialName});
}

String leadId = "";
int checkinId = 0;
bool dataLoaded = false;
bool validInputMaterial = true;
List<Product> selectedProduct = [];
List<ProductCategoryList> selectedProductCategory = [];
List<InputMaterial> selectedMaterial = [];
List<Map<String, dynamic>> selectedMaterialList = [];
List<StageList> selectedStages = [];
List<Map<String, dynamic>> selectedProductList = [];
List<Map<String, String>> contactList = [];
List<Map<String, String>> selectedParticipantList = [];
List<LeadParticipant> selectedParticipantHospital = [];
List<Map<String, dynamic>> participantList = [];
List<LeadParticipant> availableParticipant = [];
List<LeadParticipant> initialParticipantHospital = [];
String leadActivityId = "0";
bool loading = true;
bool summarySave = false;
bool locationLoading = false;
String selectedContactId = "";
String selectedLeadContactId = "";
bool selectedValue = true;
bool locationAlertLoading = true;

List<Map<String, dynamic>> productList = [];
List<Product> newPrdList = [];
List<Product> prodListWeb = [];

List<Map<String, dynamic>> customerList = [];
List<Hospital> hspList = [];
List<Hospital> prodList = [];
List<Map<String, dynamic>> productCategoryList = [];
List<ProductCategoryList> prodCatgList = [];
List<InputMaterial> inputMaterialWeb = [];
List<Contacts> contactListWeb = [];

class DisableScrollGlowBehavior extends ScrollBehavior {}

class HospitalMeetingPage extends StatefulWidget {
  final CheckinDetails? checkInDetails;
  final bool fromHomePage;
  const HospitalMeetingPage({
    super.key,
    this.checkInDetails,
    required this.fromHomePage,
  });

  @override
  State<HospitalMeetingPage> createState() => _HospitalMeetingPageState();
}

class _HospitalMeetingPageState extends State<HospitalMeetingPage> {
  bool reverseScroll = false;
  bool _isFunctionExecuted = false;
  late Future<void> loadDataFuture;
  String selectedHospitalId = "";
  List<Map<String, dynamic>> contactMasterList = [];
  final TextEditingController _searchController = TextEditingController();

  late stt.SpeechToText _speech;
  bool _isSummaryListening = false;
  bool _isSupportListening = false;

  bool newBusinessCheck = false;
  bool inputMaterialCheck = false;
  bool campaignProductsCheck = false;
  bool existingBusinessCheck = false;
  bool regularProductsCheck = false;
  final TextEditingController summaryController = TextEditingController();
  final TextEditingController inputMaterialController = TextEditingController();
  final TextEditingController supportController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String selectedHospitalName = "";
  var hospitalKey = GlobalKey();
  String selectedOption = 'Option 1';
  List<Map<String, dynamic>> distributorList = [];
  List<Map<String, dynamic>> materialList = [];
  String selectedHospitalName2 = "";
  String selectedDistributorId = "";
  TextEditingController locationControllerFooter = TextEditingController();
  String latitudeFooter = "";
  String longitudeFooter = "";
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  final TextEditingController _searchController3 = TextEditingController();
  final TextEditingController productController = TextEditingController();
  final TextEditingController productCategoryController =
      TextEditingController();
  final TextEditingController materialController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  var contactKey = GlobalKey();
  var productKey = GlobalKey();
  var productCategoryKey = GlobalKey();
  var materialKey = GlobalKey();
  final ScrollController scrollControllerMain = ScrollController();
  Timer? _timer;

  void _clearControls() {
    setState(() {
      _searchController.clear();
    });
  }

  void _clearContactSummary() {
    setState(() {
      _searchController3.clear();
      _designationController.clear();
      _departmentController.clear();
      _phoneController.clear();
      _emailController.clear();
    });
  }

  void accountNameEmptyChecker() {
    if (_searchController.text == "") {
      SnackBar snackBar = const SnackBar(
        showCloseIcon: true,
        duration: Duration(seconds: 1),
        content: Text(
          "Please Enter Account Name",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void addDataToList() {
    final contactPerson = _searchController3.text;
    final email = _emailController.text;
    final phone = _phoneController.text;
    final department = _departmentController.text;
    final designation = _designationController.text;

    if (contactPerson.isNotEmpty &&
        phone.isNotEmpty &&
        department.isNotEmpty &&
        designation.isNotEmpty) {
      final newData = {
        "leadContactId": selectedContactId == ''
            ? '0'
            : selectedContactId, //Id from LeadEntryContacts table
        "leadContactParentId": selectedLeadContactId == ''
            ? '0'
            : selectedLeadContactId, //Id from CustomerContactPerson table
        "leadContactName": contactPerson,
        "leadContactDesignation": designation,
        "leadContactDepartment": department,
        "leadContactEmailId": email,
        "leadContactContactNo": phone,
        "leadContactDecisionMaker": selectedValue ? "Yes" : "No",
      };
      setState(() {
        contactList.add(newData);
      });
      _searchController3.clear();
      _emailController.clear();
      _phoneController.clear();
      _departmentController.clear();
      _designationController.clear();
      selectedValue = true;
    }
  }

  void loadContactDetails(Map<String, String> item) async {
    setState(() {
      selectedContactId = item['leadContactId'] ?? '';
      selectedLeadContactId = item['leadContactParentId'] ?? '';
      _searchController3.text = item['leadContactName'] ?? '';
      _emailController.text = item['leadContactEmailId'] ?? '';
      _phoneController.text = item['leadContactContactNo'] ?? '';
      _departmentController.text = item['leadContactDepartment'] ?? '';
      _designationController.text = item['leadContactDesignation'] ?? '';
      selectedValue = item['leadContactDecisionMaker'] == "Yes" ? true : false;
    });
  }

  void _executeFunctionOnce() {
    if (!_isFunctionExecuted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (scrollControllerMain.hasClients) {
          scrollControllerMain.jumpTo(
            scrollControllerMain.position.maxScrollExtent,
          );
          _isFunctionExecuted = true;
        }
      });
    }
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loadCustomer(userId, userJwtToken, userMailID);
    await _loadProducts(userId, userJwtToken, userMailID);
    await _loadProductCategory(userId, userJwtToken, userMailID);
    await _loadMaterials(userJwtToken, userMailID);
    if (widget.checkInDetails != null) {
      await loadContacs();
    }
    if (!kIsWeb) {
      await getCurrentLocation();
    } else {
      await getCurrentLocationWeb();
    }
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
      setState(() {
        locationLoading = true;
      });
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
        if (location != "") {
          locationControllerFooter.text = location;
          setState(() {
            locationLoading = false;
          });
        }
      } else {
        locationControllerFooter.clear();
      }

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
      if (mounted) {
        final snackBar = SnackBar(content: Text('Error getting location: $e'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> getCurrentLocationWeb() async {
    try {
      setState(() {
        locationLoading = true;
      });
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Location Permission Denied'),
              content: const Text(
                'Location access is required to use this feature. Please enable location permissions in your browser settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }

      // If permission granted, get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // same as desiredAccuracy before
        ),
      );

      latitudeFooter = position.latitude.toString();
      longitudeFooter = position.longitude.toString();

      final double latitude = double.parse(latitudeFooter);
      final double longitude = double.parse(longitudeFooter);
      await getPlacemarkFromCoordinates(latitude, longitude);

      if (locationControllerFooter.text == "") {
        _timer = Timer(const Duration(seconds: 30), () {
          if (locationLoading) {
            setState(() {
              locationLoading = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text('Error getting location: $e'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> getPlacemarkFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    const apiKey =
        'pk.2f409db63cf27b6b04b7dc624ff8b704'; // Replace with your LocationIQ API key
    final url = Uri.parse(
      'https://us1.locationiq.com/v1/reverse.php?key=$apiKey&lat=$latitude&lon=$longitude&format=json',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'];
        if (address != "") {
          locationControllerFooter.text = address;
          setState(() {
            locationLoading = true;
          });
        } else {
          locationControllerFooter.clear();
          setState(() {
            locationLoading = false;
          });
          _showLocationFetchFailedAlert();
        }
      } else {}
    } catch (e) {
      print('Error fetching placemark: $e');
    }
  }

  Future<List<Product>> getProductData(String search) async {
    List<Product> prdList = convertProductList(productList);
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

  Future<List<ProductCategoryList>> getProductCategoryData(
    String search,
  ) async {
    List<ProductCategoryList> prdList = convertProductCategoryList(
      productCategoryList,
    );
    List<ProductCategoryList> newPrdList = [];
    await Future.delayed(const Duration(microseconds: 500));
    newPrdList = prdList
        .where(
          (element) =>
              element.prodCatgName.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();

    return newPrdList;
  }

  List<ProductCategoryList> convertProductCategoryList(
    List<Map<String, dynamic>> categoryList,
  ) {
    return productCategoryList
        .map(
          (map) => ProductCategoryList(
            prodCatgId: int.tryParse(map['ProdCatgId']?.toString() ?? '') ?? 0,
            prodCatgName: map['ProdCatgName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  Future<List<InputMaterial>> getInputMaterialData(String search) async {
    List<InputMaterial> matList = convertMaterialList(materialList);
    List<InputMaterial> newMatList = [];
    await Future.delayed(const Duration(microseconds: 500));
    newMatList = matList
        .where(
          (element) =>
              element.MaterialName.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
    return newMatList;
  }

  List<InputMaterial> convertMaterialList(
    List<Map<String, dynamic>> materialList,
  ) {
    return materialList
        .map(
          (map) => InputMaterial(
            MaterialId: int.tryParse(map['MaterialId']?.toString() ?? '') ?? 0,
            MaterialName: map['MaterialName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  List<Hospital> convertList(List<Map<String, dynamic>> customerList) {
    return customerList
        .map(
          (map) => Hospital(
            CustomerCode: map['CustomerCode']?.toString() ?? '',
            CustomerName: map['CustomerName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  Future<void> getLocation() async {
    try {
      late LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 10),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.fitness,
          distanceFilter: 100,
          pauseLocationUpdatesAutomatically: true,
          // Only set to true if our app will be started up in the background.
          showBackgroundLocationIndicator: false,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        );
      }

      // ignore: unused_local_variable
      StreamSubscription<Position> positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) async {
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
          });
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error getting location: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<List<Hospital>> getCustomer(String search) async {
    List<Hospital> hospitalList = convertList(customerList);
    List<Hospital> filteredHospitals = hospitalList
        .where(
          (element) =>
              element.CustomerName.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();

    return filteredHospitals;
  }

  Future<void> _loadCustomer(
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
            hspList = convertList(customerList);
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

  Future<void> _loadProducts(
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
            productList = newProductList;
            prodListWeb = convertProductList(productList);
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
      final snackBar = SnackBar(content: Text(e.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadProductCategory(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final data = {'UserJwtToken': userJwtToken, 'UsermailID': userMailID};
    const apiUrl = '${ApiHelper.baseUrl}selectproductcategory';
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
          final List productCategory = jsonDecode(response.body)["Data"];
          List<Map<String, dynamic>> newProductCategoryList = [];
          for (var item in productCategory) {
            final cust = {
              "ProdCatgId": item["ProdCatgId"],
              "ProdCatgName": item["ProdCatgName"],
            };
            newProductCategoryList.add(cust);
          }
          setState(() {
            productCategoryList = newProductCategoryList;
            prodCatgList = convertProductCategoryList(newProductCategoryList);
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
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadMaterials(String userJwtToken, String userMailID) async {
    final data = {'UserJwtToken': userJwtToken, 'UsermailID': userMailID};
    const apiUrl = '${ApiHelper.baseUrl}getinputmateriallist';
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
          final List materials = jsonDecode(response.body)["Data"];
          List<Map<String, dynamic>> newMaterialList = [];
          for (var item in materials) {
            final cust = {
              "MaterialId": item["InputMaterialId"],
              "MaterialName": item["InputMaterialName"],
            };
            newMaterialList.add(cust);
          }
          setState(() {
            materialList = newMaterialList;
            inputMaterialWeb = convertMaterialList(newMaterialList);
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
      final snackBar = SnackBar(content: Text(e.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  List<LeadParticipant> convertToList(
    List<Map<String, dynamic>> participantList,
  ) {
    return participantList.map((participant) {
      return LeadParticipant(
        leadParticipantId: 0,
        leadParticipantMasterId: 0,
        leadParticipantUserId:
            int.tryParse(participant["ParticipantId"].toString()) ?? 0,
        leadParticipantUserName: participant["ParticipantName"].toString(),
      );
    }).toList();
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

  bool isValidPhoneNumber(String phoneNumber) {
    RegExp regex = RegExp(r'^(\+91[\-\s]?)?\s*?[6-9]\d{9}$');

    return regex.hasMatch(phoneNumber);
  }

  Future<void> loadContacs() async {
    contactList.clear();
    contactList = [];
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'CustomerCode': selectedHospitalId,
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
            if (mounted) {
              setState(() {
                if (_searchController3.text == "") {
                  selectedLeadContactId = item["CustContactId"].toString();
                  _searchController3.text = item["CustContactName"] ?? "";
                  _designationController.text = item["DesignationName"] ?? "";
                  _departmentController.text = item["DepartmentName"] ?? "";
                  _phoneController.text = item["CustContactMobileNo"] ?? "";
                  _emailController.text = item["CustContactEmailId"] ?? "";
                }
              });
            }
          }
          setState(() {
            contactMasterList = newContactList;
            contactListWeb = convertContact(contactMasterList);
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
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void navigateToHomePage() {
    selectedParticipantHospital.clear();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TabsPage(selectedIndex: 0, selectedRoleCode: ""),
      ),
    );
  }

  void showSnackBar(String message) {
    SnackBar snackBar = SnackBar(
      showCloseIcon: true,
      duration: const Duration(seconds: 1),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void validateInputMaterials() {
    List<InputMaterial> inputMaterialList = convertMaterialList(materialList);
    List<InputMaterial> matchingMaterial = inputMaterialList
        .where(
          (element) =>
              element.MaterialName.toLowerCase() ==
              inputMaterialController.text.toLowerCase(),
        )
        .toList();
    validInputMaterial = true;
    if (matchingMaterial.isEmpty) {
      validInputMaterial = false;
      inputMaterialController.clear();
      materialController.clear();
    }
  }

  Future<void> submitLeads() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userId = prefs.getString('userId') ?? '';
    List<Map<String, Object>> selectedStagesList = selectedStages
        .whereType<StageList>()
        .map((StageList item) => {'StageId': item.id, 'StageName': item.name})
        .toList();
    participantList = selectedParticipantHospital
        .whereType<LeadParticipant>()
        .map(
          (LeadParticipant item) => {
            'LeadParticipantId': item.leadParticipantId,
            'ParticipantId': item.leadParticipantUserId,
          },
        )
        .toList();
    selectedProductList = selectedProduct
        .whereType<Product>()
        .map(
          (Product item) => {
            'leadProductId': item.ProductId,
            'leadProductCode': item.ProductCode,
            'leadProductName': item.ProductName,
          },
        )
        .toList();

    String selectedPromotionType = "";

    if (selectedProductCategory.length == 1) {
      selectedPromotionType = selectedProductCategory.first.prodCatgName[0]
          .toUpperCase();
    } else if (selectedProductCategory.length > 1) {
      selectedPromotionType = "O";
    }

    final leadmaster = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadID': leadId,
      'LeadUserId': userId,
      'LeadHospitalCode': selectedHospitalId,
      'LeadHospitalName': _searchController.text,
      'LeadDistributorCode': "",
      'LeadDistributorName': "",
      'LeadAssigneeId': "0",
      'LeadDealValue': expectedValue,
      'LeadStatus': 'A',
      'LeadType': "A",
      'LeadCategory': 'H',
      'LeadBusinessType': newBusinessCheck && existingBusinessCheck == true
          ? 'O'
          : newBusinessCheck == true
          ? 'N'
          : 'E',
      'LeadPromotionType': selectedPromotionType,
      'LeadSummary': summaryController.text,
      'LeadStages': selectedStagesList,
      'LeadExpectedWithin': businessExpectedWithin,
      'LeadNextAction': nextActionValue,
      'LeadNextActionDate': _dateController.text,
      'LeadHelpRequired': supportController.text,
      'LeadInputMaterials': inputMaterialController.text,
      'LeadCheckinId': widget.checkInDetails?.checkinId ?? 0,
      'contactList': contactList,
      'participantList': participantList,
      'productList': selectedProductList,
    };
    const apiUrl = '${ApiHelper.baseUrl}insertleadentry';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(leadmaster),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        setState(() {
          leadId = responseJson["Data"]["LeadID"].toString();
        });
        await submitStageSummary();
        if (status) {
          setState(() {
            contactList.clear();
            contactList = [];
            selectedLeadContactId = "";
            _searchController.clear();
          });
        }
        if (status &&
            summarySave &&
            responseJson["Data"].toString().isNotEmpty) {
          summarySave = false;
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
      } else {
        const snackBar = SnackBar(content: Text('Lead entry save failed'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> submitCheckin() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userId = prefs.getString('userId') ?? '';
    int retries = 0;
    const maxRetries = 5;
    do {
      if (!kIsWeb) {
        await getCurrentLocation();
      } else {
        await getCurrentLocationWeb();
      }
      retries++;
      if (retries >= maxRetries) {
        const snackBar = SnackBar(
          duration: Duration(seconds: 1),
          content: Text(
            'Location missing, Please try again...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        break;
      }
    } while (locationControllerFooter.text.isEmpty);
    if (locationControllerFooter.text.isNotEmpty) {
      await submitCustomerMaster();
      final checkin = {
        'UserJwtToken': userJwtToken,
        'UsermailID': userMailID,
        'CheckinId': widget.checkInDetails?.checkinId ?? 0,
        'CheckinUserId': userId,
        'CheckinCustomerType': 'H',
        'CheckinCustomerCode': selectedHospitalId,
        'CheckinLatitude': latitudeFooter,
        'CheckinLongitude': longitudeFooter,
        'CheckinLocation': locationControllerFooter.text,
        'CheckoutLatitude': "",
        'CheckoutLongitude': "",
        'CheckoutLocation': "",
        'CheckinPlaceOfVisit': "",
      };
      const apiUrl = '${ApiHelper.baseUrl}insertorupdatecheckindetails';
      var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          body: jsonEncode(checkin),
          headers: headerss,
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          bool status = responseJson["Status"];

          if (status && responseJson["Data"].toString().isNotEmpty) {
            summarySave = false;
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
                responseJson["Error"].toString() ==
                    "Invalid or Expired Token") {
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
          const snackBar = SnackBar(content: Text('Checkin failed'));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } catch (e) {
        final snackBar = SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> submitCheckout() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userId = prefs.getString('userId') ?? '';
    final checkin = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'CheckinId': widget.checkInDetails?.checkinId ?? 0,
      'CheckinUserId': userId,
      'CheckinCustomerType': 'H',
      'CheckinCustomerCode': selectedHospitalId,
      'CheckinLatitude': "",
      'CheckinLongitude': "",
      'CheckinLocation': "",
      'CheckoutLatitude': latitudeFooter,
      'CheckoutLongitude': longitudeFooter,
      'CheckoutLocation': locationControllerFooter.text,
      'CheckinPlaceOfVisit': "",
    };
    const apiUrl = '${ApiHelper.baseUrl}insertorupdatecheckindetails';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(checkin),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];

        if (status && responseJson["Data"].toString().isNotEmpty) {
          summarySave = false;
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
      } else {
        const snackBar = SnackBar(content: Text('Checkout failed'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> submitStageSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJwtToken = prefs.getString('userJwtToken') ?? '';
      final userMailID = prefs.getString('userMailID') ?? '';
      summarySave = false;
      List<Map<String, Object>> selectedParticipantList =
          selectedParticipantHospital
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
        'LeadActivityStageLevel': "1",
        'LeadActivitySummary': summaryController.text,
        'LeadActivityFollowupDate': _dateController.text == ""
            ? "" //DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())
            : _dateController.text,
        'LeadActivityLatitude': latitudeFooter,
        'LeadActivityLongitude': longitudeFooter,
        'LeadActivityLocation': locationControllerFooter.text,
        'LeadActivityStatus': nextActionValue,
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
            if (widget.checkInDetails != null) {
              await submitCheckout();
            }
            summarySave = true;
            summaryController.clear();
            inputMaterialController.clear();
            _dateController.text = DateFormat(
              'dd/MM/yyyy hh:mm a',
            ).format(DateTime.now());
            nextActionValue = 'Stages';
            leadId = "";
            setState(() {
              selectedParticipantList.clear();
              selectedParticipantList = [];
              participantList.clear();
              participantList = [];
              selectedProductCategory.clear();
              selectedProductCategory = [];
            });
          } else {
            if (responseJson.containsKey("Error") &&
                responseJson["Error"].toString() ==
                    "Invalid or Expired Token") {
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
          const snackBar = SnackBar(
            duration: Duration(seconds: 1),
            content: Text('Lead activity save failed'),
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } catch (e) {
        final snackBar = SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> submitCustomerMaster() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJwtToken = prefs.getString('userJwtToken') ?? '';
      final userMailID = prefs.getString('userMailID') ?? '';
      final userId = prefs.getString('userId') ?? '';

      final customer = {
        'UserJwtToken': userJwtToken,
        'UsermailID': userMailID,
        'UserId': userId,
        'LeadHospitalCode': selectedHospitalId,
        'LeadHospitalName': _searchController.text,
        'LeadDistributorCode': "",
        'LeadDistributorName': "",
      };
      const apiUrl = '${ApiHelper.baseUrl}insertcustomermaster';
      var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          body: jsonEncode(customer),
          headers: headerss,
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseJson = jsonDecode(response.body);
          bool status = responseJson["Status"];
          if (status && responseJson["AccountCode"].toString().isNotEmpty) {
            setState(() {
              selectedHospitalId = responseJson["AccountCode"].toString();
            });
          } else {
            if (responseJson.containsKey("Error") &&
                responseJson["Error"].toString() ==
                    "Invalid or Expired Token") {
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
              if (responseJson["AccountCode"].toString().isNotEmpty) {
                final snackBar = SnackBar(
                  content: Text(responseJson["Error"].toString()),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            }
          }
        } else {
          const snackBar = SnackBar(
            duration: Duration(seconds: 1),
            content: Text('Customer save failed'),
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } catch (e) {
        final snackBar = SnackBar(
          duration: const Duration(seconds: 2),
          content: Text('Error: $e'),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  late FocusNode _focus;
  late FocusNode _focus2;
  late FocusNode _focus3;
  late FocusNode _focusInputMaterial;

  @override
  void dispose() {
    _searchController.dispose();
    _searchController3.dispose();
    scrollControllerMain.dispose();
    selectedParticipantHospital.clear();
    contactList.clear();
    _timer?.cancel();
    dataLoaded = false;
    validInputMaterial = true;
    super.dispose();
  }

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
    if (widget.fromHomePage == true) {
      selectedHospitalId = widget.checkInDetails?.checkinCustomerCode ?? "";
      selectedHospitalName = widget.checkInDetails?.checkinCustomerName ?? "";
      _searchController.text = widget.checkInDetails?.checkinCustomerName ?? "";
    }
    dataLoaded = false;
    validInputMaterial = true;
    _speech = stt.SpeechToText();
    formKey = GlobalKey<FormState>();
    _focus = FocusNode();
    _focus2 = FocusNode();
    _focus3 = FocusNode();
    _focusInputMaterial = FocusNode();
    selectedProduct = [];
    selectedParticipantHospital = [];
    initialParticipantHospital = [];
    selectedProductCategory = [];
    selectedMaterial = [];
    contactList.clear();
    contactList = [];
    _focus.addListener(_handleFocusChange);
    _focus2.addListener(_handleFocusChange);
    _focus3.addListener(_handleFocusChange);
    if (isUserLoggedIn) {
      loadDataFuture = loadData();
    }
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        dataLoaded = true;
      });
    });
  }

  void _handleFocusChange() {
    if (_focus.hasFocus != _focused) {
      setState(() {
        _focused = _focus.hasFocus;
      });
    }
    if (_focus2.hasFocus != _focused2) {
      setState(() {
        _focused2 = _focus2.hasFocus;
      });
    }
    if (_focus3.hasFocus != _focused3) {
      setState(() {
        _focused3 = _focus3.hasFocus;
      });
    }
  }

  bool _focused = false;
  bool _focused2 = false;
  bool _focused3 = false;

  String dropdownvalue = '';
  String? businessExpectedWithin;
  String? expectedValue;
  String? nextActionValue;
  String? stageValue;

  @override
  Widget build(BuildContext context) {
    _executeFunctionOnce();
    final prodCategoryList = prodCatgList
        .map(
          (participant) => MultiSelectItem<ProductCategoryList>(
            participant,
            participant.prodCatgName,
          ),
        )
        .toList();

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
      containerHeight = screenHeight * 0.08;
    } else {
      containerDropDownHeight = screenHeight * 0.12;
    }
    if (!dataLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (dataLoaded) {
      return Scaffold(
        appBar: widget.fromHomePage
            ? AppBar(
                automaticallyImplyLeading: false,
                titleSpacing: 16,
                title: Align(
                  alignment: Alignment.topLeft,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: const Icon(
                          Icons.keyboard_arrow_left,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Hospital Meeting',
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
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: const Color(0xFF2CA9DF),
              )
            : PreferredSize(
                preferredSize: const Size(0.0, 0.0),
                child: Container(),
              ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: /*widget.fromHomePage ?  const EdgeInsets.only(top: 50.0, bottom: 8.0, left: 8.0, right: 8.0)
              : */ const EdgeInsets.only(
            top: 8.0,
            bottom: 8.0,
            left: 8.0,
            right: 8.0,
          ),
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: NotificationListener(
              onNotification: (notificationInfo) {
                if (notificationInfo is ScrollUpdateNotification) {}
                return true;
              },
              child: Container(
                color: Colors.white,
                child: ScrollConfiguration(
                  behavior: DisableScrollGlowBehavior(),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    reverse: true,
                    keyboardDismissBehavior: kIsWeb
                        ? ScrollViewKeyboardDismissBehavior.manual
                        : ScrollViewKeyboardDismissBehavior.onDrag,
                    controller: scrollControllerMain,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AbsorbPointer(
                          absorbing: widget.checkInDetails != null,
                          child: kIsWeb
                              ? RawAutocomplete<Hospital>(
                                  textEditingController: _searchController,
                                  focusNode: _focus,
                                  optionsBuilder: (TextEditingValue val) {
                                    if (val.text == '') {
                                      return const Iterable<Hospital>.empty();
                                    }
                                    return hspList.where((Hospital option) {
                                      return option.CustomerName.toLowerCase()
                                          .contains(val.text.toLowerCase());
                                    });
                                  },
                                  displayStringForOption: (Hospital option) =>
                                      option.CustomerName,
                                  fieldViewBuilder:
                                      (
                                        context,
                                        textEditingController,
                                        focusNode,
                                        onFieldSubmitted,
                                      ) {
                                        return TextField(
                                          controller: textEditingController,
                                          focusNode: focusNode,
                                          onSubmitted: (value) =>
                                              onFieldSubmitted(),
                                          decoration: InputDecoration(
                                            labelText: 'Enter Account Name',
                                            labelStyle: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF8F8F8F),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: _searchController.text == ""
                                                  ? const Icon(
                                                      Icons.search,
                                                      color: Color(0xff2ca9df),
                                                    )
                                                  : const Icon(Icons.clear),
                                              onPressed: () {
                                                _searchController.clear();
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                  onSelected: (Hospital value) {
                                    _searchController.text = value.CustomerName;
                                    setState(() {
                                      selectedOption = value.CustomerName;
                                      _searchController.text =
                                          value.CustomerName;
                                      var customer = customerList.firstWhere(
                                        (map) =>
                                            map['CustomerName'] ==
                                            value.CustomerName,
                                      );
                                      selectedHospitalId =
                                          customer['CustomerCode'].toString();
                                      selectedHospitalName = value.CustomerName;
                                    });
                                  },
                                  optionsViewBuilder:
                                      (
                                        BuildContext context,
                                        void Function(Hospital) onSelected,
                                        Iterable<Hospital> options,
                                      ) {
                                        return Material(
                                          elevation: 4.0,
                                          child: Container(
                                            constraints: const BoxConstraints(
                                              maxHeight: 200,
                                            ),
                                            child: ListView.builder(
                                              padding: EdgeInsets.zero,
                                              physics:
                                                  const ClampingScrollPhysics(),
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              itemBuilder:
                                                  (
                                                    BuildContext context,
                                                    int index,
                                                  ) {
                                                    final Hospital option =
                                                        options.elementAt(
                                                          index,
                                                        );
                                                    return GestureDetector(
                                                      onTap: () {
                                                        onSelected(option);
                                                      },
                                                      child: ListTile(
                                                        title: Text(
                                                          option.CustomerName,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                        );
                                      },
                                )
                              : SizedBox(
                                  height: deviceOrientation == "Portrait"
                                      ? containerHeight
                                      : containerDropDownHeight / 1.5,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: AsyncAutocomplete<Hospital>(
                                          onChanged: (s) {
                                            setState(() {
                                              _searchController.text == s;
                                            });
                                          },
                                          onSaved: (s) {
                                            setState(() {
                                              _searchController.text == s;
                                            });
                                          },
                                          focusNode: _focus,
                                          maxListHeight:
                                              deviceOrientation == "Portrait"
                                              ? 370
                                              : 220,
                                          decoration: InputDecoration(
                                            border: UnderlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.never,
                                            labelText: 'Account Name',
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
                                              borderRadius:
                                                  BorderRadius.circular(6.0),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.only(
                                                  left: 0,
                                                  right: 30,
                                                  top: 0,
                                                  bottom: 0,
                                                ),
                                          ),
                                          controller: _searchController,
                                          inputKey: hospitalKey,
                                          onTapItem: (Hospital hospital) async {
                                            setState(() {
                                              selectedOption =
                                                  hospital.CustomerName;
                                              _searchController.text =
                                                  hospital.CustomerName;
                                              var customer = customerList
                                                  .firstWhere(
                                                    (map) =>
                                                        map['CustomerName'] ==
                                                        hospital.CustomerName,
                                                  );
                                              selectedHospitalId =
                                                  customer['CustomerCode']
                                                      .toString();
                                              selectedHospitalName =
                                                  hospital.CustomerName;
                                            });
                                            await loadContacs();
                                          },
                                          suggestionBuilder: (data) => ListTile(
                                            title: Text(
                                              data.CustomerName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          asyncSuggestions: (searchValue) =>
                                              getCustomer(searchValue),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: -1,
                                        child: Visibility(
                                          child: SizedBox(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedOption = '';
                                                  selectedHospitalId = "";
                                                  selectedDistributorId = "";
                                                  _searchController.clear();
                                                  selectedProductCategory
                                                      .clear();
                                                  selectedProduct.clear();
                                                  _clearControls();
                                                  _clearContactSummary();
                                                  contactMasterList.clear();
                                                });
                                                // loadContacs();
                                              },
                                              child:
                                                  _searchController.text == ""
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
                        GestureDetector(
                          onTap: () {
                            accountNameEmptyChecker();
                          },
                          child: AbsorbPointer(
                            absorbing: _searchController.text == "",
                            child: SizedBox(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        const Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              "New\nBusiness",
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF8F8F8F),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Transform.scale(
                                              scale: .7,
                                              child: Checkbox(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        2.0,
                                                      ),
                                                ),
                                                side:
                                                    WidgetStateBorderSide.resolveWith(
                                                      (states) =>
                                                          const BorderSide(
                                                            width: 1.0,
                                                            color: Color(
                                                              0xFF8F8F8F,
                                                            ),
                                                          ),
                                                    ),
                                                value: newBusinessCheck,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    newBusinessCheck =
                                                        value ?? false;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Existing\nBusiness",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xFF8F8F8F),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Transform.scale(
                                              scale: .7,
                                              child: Checkbox(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        2.0,
                                                      ),
                                                ),
                                                side:
                                                    WidgetStateBorderSide.resolveWith(
                                                      (states) =>
                                                          const BorderSide(
                                                            width: 1.0,
                                                            color: Color(
                                                              0xFF8F8F8F,
                                                            ),
                                                          ),
                                                    ),
                                                value: existingBusinessCheck,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    existingBusinessCheck =
                                                        value ?? false;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        AbsorbPointer(
                                          absorbing:
                                              widget.checkInDetails != null,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              BuildContext? dialogContext;
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (BuildContext context) {
                                                  dialogContext = context;
                                                  return const Center(
                                                    child: CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  );
                                                },
                                              );
                                              try {
                                                await submitCheckin();
                                                Navigator.of(
                                                  dialogContext!,
                                                ).pop();
                                                navigateToHomePage();
                                              } catch (error) {
                                                // print('Error: $error');
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  widget.checkInDetails == null
                                                  ? const Color(0xff2ca9df)
                                                  : Colors.grey,
                                              shape:
                                                  const RoundedRectangleBorder(),
                                            ),
                                            child: const Text(
                                              "Check In",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  kIsWeb
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            MultiSelectDialogField<
                                              ProductCategoryList
                                            >(
                                              checkColor: Colors.white,
                                              searchable: true,
                                              listType:
                                                  MultiSelectListType.LIST,
                                              separateSelectedItems: false,
                                              items: prodCategoryList,
                                              title: const Text(
                                                "Product Category",
                                              ),
                                              selectedColor: const Color(
                                                0xff2ca9df,
                                              ),
                                              buttonIcon: const Icon(
                                                Icons.search,
                                                color: Color(0xff2ca9df),
                                              ),
                                              buttonText: const Text(
                                                "Product Category",
                                                style: TextStyle(
                                                  color: Color(0xFF454545),
                                                  fontFamily: "Poppins",
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              // Hides the default chip display
                                              chipDisplay:
                                                  MultiSelectChipDisplay.none(),
                                              onConfirm: (results) {
                                                setState(() {
                                                  selectedProductCategory
                                                      .clear();
                                                  for (var ex in results) {
                                                    if (ex
                                                        .prodCatgName
                                                        .isNotEmpty) {
                                                      selectedProductCategory
                                                          .add(
                                                            ProductCategoryList(
                                                              prodCatgId: 0,
                                                              prodCatgName: ex
                                                                  .prodCatgName,
                                                            ),
                                                          );
                                                    } else {
                                                      SnackBar
                                                      snackBar = const SnackBar(
                                                        showCloseIcon: true,
                                                        duration: Duration(
                                                          seconds: 1,
                                                        ),
                                                        content: Text(
                                                          "Please Enter Product Category",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(snackBar);
                                                    }
                                                  }
                                                });
                                              },
                                            ),

                                            // Custom chip display for handling tap to remove chips
                                            MultiSelectChipDisplay<
                                              ProductCategoryList
                                            >(
                                              items: selectedProductCategory
                                                  .map(
                                                    (item) => MultiSelectItem(
                                                      item,
                                                      item.prodCatgName,
                                                    ),
                                                  )
                                                  .toList(),
                                              chipColor: const Color(
                                                0xff2ca9df,
                                              ),
                                              textStyle: const TextStyle(
                                                color: Colors.white,
                                              ),
                                              onTap: (selected) {
                                                setState(() {
                                                  // Remove the tapped item from the selectedProductCategory list
                                                  selectedProductCategory
                                                      .remove(selected);
                                                });
                                              },
                                            ),
                                          ],
                                        )
                                      : SizedBox(
                                          height:
                                              deviceOrientation == "Portrait"
                                              ? containerHeight
                                              : containerDropDownHeight / 1.5,
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: AsyncAutocomplete<ProductCategoryList>(
                                                  onChanged: (s) {
                                                    setState(() {});
                                                  },
                                                  onSubmitted: (prod) {
                                                    setState(() {
                                                      if (prod != "") {
                                                        selectedProductCategory
                                                            .add(
                                                              ProductCategoryList(
                                                                prodCatgId: 0,
                                                                prodCatgName:
                                                                    prod,
                                                              ),
                                                            );
                                                      } else {
                                                        SnackBar
                                                        snackBar = const SnackBar(
                                                          showCloseIcon: true,
                                                          duration: Duration(
                                                            seconds: 1,
                                                          ),
                                                          content: Text(
                                                            "Please Enter Product Category",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        );
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          snackBar,
                                                        );
                                                      }
                                                      productCategoryController
                                                          .clear();
                                                    });
                                                  },
                                                  maxListHeight:
                                                      deviceOrientation ==
                                                          "Portrait"
                                                      ? 370
                                                      : 200,
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        'Product Category',
                                                    labelStyle: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF8F8F8F),
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                          right: 0,
                                                          top: 0,
                                                          bottom: 0,
                                                        ),
                                                  ),
                                                  controller:
                                                      productCategoryController,
                                                  inputKey: productCategoryKey,
                                                  onTap: () {
                                                    reverseScroll = true;
                                                  },
                                                  onTapItem:
                                                      (
                                                        ProductCategoryList
                                                        categoryList,
                                                      ) {
                                                        setState(() {
                                                          selectedProductCategory
                                                              .add(
                                                                categoryList,
                                                              );
                                                        });
                                                      },
                                                  suggestionBuilder: (data) =>
                                                      ListTile(
                                                        title: Text(
                                                          data.prodCatgName,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                      ),
                                                  asyncSuggestions:
                                                      (searchValue) =>
                                                          getProductCategoryData(
                                                            searchValue,
                                                          ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: SizedBox(
                                                  child:
                                                      productCategoryController
                                                              .text ==
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
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 7,
                                                                  right: 2,
                                                                ),
                                                            child: IconButton(
                                                              onPressed: () {
                                                                setState(() {
                                                                  productCategoryController
                                                                      .clear();
                                                                });
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
                                  Visibility(
                                    visible: !kIsWeb,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        height: 100,
                                        child: ListView.builder(
                                          physics:
                                              const ClampingScrollPhysics(),
                                          itemCount:
                                              selectedProductCategory.length,
                                          itemBuilder: (BuildContext context, int index) {
                                            return Card(
                                              color: const Color(0xff2ca9df),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: Text(
                                                        selectedProductCategory[index]
                                                            .prodCatgName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        selectedProductCategory
                                                            .remove(
                                                              selectedProductCategory[index],
                                                            );
                                                      });
                                                    },
                                                    icon: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  kIsWeb
                                      ? RawAutocomplete<Product>(
                                          textEditingController:
                                              productController,
                                          focusNode: _focus3,
                                          optionsBuilder: (TextEditingValue val) {
                                            if (val.text == '') {
                                              return const Iterable<
                                                Product
                                              >.empty();
                                            }
                                            return prodListWeb.where((
                                              Product option,
                                            ) {
                                              return option
                                                      .ProductName.toLowerCase()
                                                  .contains(
                                                    val.text.toLowerCase(),
                                                  );
                                            });
                                          },
                                          displayStringForOption:
                                              (Product option) =>
                                                  option.ProductName,
                                          fieldViewBuilder:
                                              (
                                                context,
                                                textEditingController,
                                                focusNode,
                                                onFieldSubmitted,
                                              ) {
                                                return TextField(
                                                  controller:
                                                      textEditingController,
                                                  focusNode: focusNode,
                                                  onSubmitted: (value) {
                                                    setState(() {
                                                      selectedProduct.add(
                                                        Product(
                                                          ProductId: 0,
                                                          ProductCode: "0",
                                                          ProductName: value,
                                                        ),
                                                      );
                                                      productController.clear();
                                                    });
                                                  },
                                                  decoration: InputDecoration(
                                                    labelText: '   Products',
                                                    labelStyle: const TextStyle(
                                                      color: Color(0xFF454545),
                                                      fontFamily: "Poppins",
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontSize: 14,
                                                    ),
                                                    suffixIcon: IconButton(
                                                      icon:
                                                          _searchController
                                                                  .text ==
                                                              ""
                                                          ? const Icon(
                                                              Icons.search,
                                                              color: Color(
                                                                0xff2ca9df,
                                                              ),
                                                            )
                                                          : const Icon(
                                                              Icons.clear,
                                                            ),
                                                      onPressed: () {
                                                        _searchController
                                                            .clear();
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                          onSelected: (Product value) {
                                            setState(() {
                                              if (value.ProductName != "") {
                                                selectedProduct.add(
                                                  Product(
                                                    ProductId: 0,
                                                    ProductCode: "0",
                                                    ProductName:
                                                        value.ProductName,
                                                  ),
                                                );
                                              } else {
                                                SnackBar
                                                snackBar = const SnackBar(
                                                  showCloseIcon: true,
                                                  duration: Duration(
                                                    seconds: 1,
                                                  ),
                                                  content: Text(
                                                    "Please Enter Product Name",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(snackBar);
                                              }
                                              productController.clear();
                                            });
                                          },
                                          optionsViewBuilder:
                                              (
                                                BuildContext context,
                                                void Function(Product)
                                                onSelected,
                                                Iterable<Product> options,
                                              ) {
                                                return Material(
                                                  elevation: 4.0,
                                                  child: Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                          maxHeight: 200,
                                                        ),
                                                    child: ListView.builder(
                                                      padding: EdgeInsets.zero,
                                                      physics:
                                                          const ClampingScrollPhysics(),
                                                      shrinkWrap: true,
                                                      itemCount: options.length,
                                                      itemBuilder:
                                                          (
                                                            BuildContext
                                                            context,
                                                            int index,
                                                          ) {
                                                            final Product
                                                            option = options
                                                                .elementAt(
                                                                  index,
                                                                );
                                                            return GestureDetector(
                                                              onTap: () {
                                                                onSelected(
                                                                  option,
                                                                );
                                                              },
                                                              child: ListTile(
                                                                title: Text(
                                                                  option
                                                                      .ProductName,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                    ),
                                                  ),
                                                );
                                              },
                                        )
                                      : SizedBox(
                                          height:
                                              deviceOrientation == "Portrait"
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
                                                      if (prod != "") {
                                                        selectedProduct.add(
                                                          Product(
                                                            ProductId: 0,
                                                            ProductCode: "0",
                                                            ProductName: prod,
                                                          ),
                                                        );
                                                      } else {
                                                        SnackBar
                                                        snackBar = const SnackBar(
                                                          showCloseIcon: true,
                                                          duration: Duration(
                                                            seconds: 1,
                                                          ),
                                                          content: Text(
                                                            "Please Enter Product Name",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        );
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          snackBar,
                                                        );
                                                      }
                                                      productController.clear();
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
                                                      color: Color(0xFF8F8F8F),
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                                          right: 0,
                                                          top: 0,
                                                          bottom: 0,
                                                        ),
                                                  ),
                                                  controller: productController,
                                                  inputKey: productKey,
                                                  onTap: () {
                                                    reverseScroll = true;
                                                  },
                                                  onTapItem: (Product product) {
                                                    setState(() {
                                                      reverseScroll = false;
                                                      selectedProduct.add(
                                                        product,
                                                      );
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
                                                right: 0,
                                                child: SizedBox(
                                                  child:
                                                      productController.text ==
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
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 7,
                                                                  right: 2,
                                                                ),
                                                            child: IconButton(
                                                              onPressed: () {
                                                                setState(() {
                                                                  productController
                                                                      .clear();
                                                                });
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
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      height: kIsWeb ? 200 : 100,
                                      child: ListView.builder(
                                        physics: const ClampingScrollPhysics(),
                                        itemCount: selectedProduct.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                              return Card(
                                                color: const Color(0xff2ca9df),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8.0,
                                                            ),
                                                        child: Text(
                                                          selectedProduct[index]
                                                              .ProductName,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          selectedProduct.remove(
                                                            selectedProduct[index],
                                                          );
                                                        });
                                                      },
                                                      icon: const Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "Contact Person Details",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Center(
                                    child: // ignore: sized_box_for_whitespace
                                    Form(
                                      key: formKey,
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 10),
                                          Column(
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  kIsWeb
                                                      ? RawAutocomplete<
                                                          Contacts
                                                        >(
                                                          textEditingController:
                                                              _searchController3,
                                                          focusNode: _focus2,
                                                          optionsBuilder:
                                                              (
                                                                TextEditingValue
                                                                val,
                                                              ) {
                                                                if (val.text ==
                                                                    '') {
                                                                  return const Iterable<
                                                                    Contacts
                                                                  >.empty();
                                                                }
                                                                return contactListWeb.where((
                                                                  Contacts
                                                                  option,
                                                                ) {
                                                                  return option
                                                                          .CustomerName.toLowerCase()
                                                                      .contains(
                                                                        val.text
                                                                            .toLowerCase(),
                                                                      );
                                                                });
                                                              },
                                                          displayStringForOption:
                                                              (
                                                                Contacts option,
                                                              ) => option
                                                                  .CustomerName,
                                                          fieldViewBuilder:
                                                              (
                                                                context,
                                                                textEditingController,
                                                                focusNode,
                                                                onFieldSubmitted,
                                                              ) {
                                                                return TextField(
                                                                  controller:
                                                                      textEditingController,
                                                                  focusNode:
                                                                      focusNode,
                                                                  onSubmitted:
                                                                      (value) =>
                                                                          onFieldSubmitted(),
                                                                  decoration: InputDecoration(
                                                                    labelText:
                                                                        'Contact Person',
                                                                    labelStyle: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400,
                                                                      color: Color(
                                                                        0xFF8F8F8F,
                                                                      ),
                                                                    ),
                                                                    suffixIcon: IconButton(
                                                                      icon:
                                                                          _searchController3.text ==
                                                                              ""
                                                                          ? const Icon(
                                                                              Icons.search,
                                                                              color: Color(
                                                                                0xff2ca9df,
                                                                              ),
                                                                            )
                                                                          : const Icon(
                                                                              Icons.clear,
                                                                            ),
                                                                      onPressed: () {
                                                                        _searchController3
                                                                            .clear();
                                                                      },
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                          onSelected: (Contacts value) {
                                                            setState(() {
                                                              selectedOption = value
                                                                  .CustomerName;
                                                              _searchController3
                                                                  .text = value
                                                                  .CustomerName;
                                                              var customer = contactMasterList.firstWhere(
                                                                (map) =>
                                                                    map['CustContactName'] ==
                                                                    value
                                                                        .CustomerName,
                                                                orElse: () =>
                                                                    <
                                                                      String,
                                                                      dynamic
                                                                    >{
                                                                      'CustContactId':
                                                                          null,
                                                                    },
                                                              );
                                                              selectedLeadContactId =
                                                                  customer['CustContactId']
                                                                      .toString();
                                                              _phoneController
                                                                      .text =
                                                                  customer['CustContactMobileNo']
                                                                      .toString();
                                                              _emailController
                                                                      .text =
                                                                  customer['CustContactEmailId']
                                                                      .toString();
                                                              _designationController
                                                                      .text =
                                                                  customer['DesignationName']
                                                                      .toString();
                                                              _departmentController
                                                                      .text =
                                                                  customer['DepartmentName']
                                                                      .toString();
                                                            });
                                                          },
                                                          optionsViewBuilder:
                                                              (
                                                                BuildContext
                                                                context,
                                                                void Function(
                                                                  Contacts,
                                                                )
                                                                onSelected,
                                                                Iterable<
                                                                  Contacts
                                                                >
                                                                options,
                                                              ) {
                                                                return Material(
                                                                  elevation:
                                                                      4.0,
                                                                  child: Container(
                                                                    constraints:
                                                                        const BoxConstraints(
                                                                          maxHeight:
                                                                              200,
                                                                        ),
                                                                    child: ListView.builder(
                                                                      padding:
                                                                          EdgeInsets
                                                                              .zero,
                                                                      physics:
                                                                          const ClampingScrollPhysics(),
                                                                      shrinkWrap:
                                                                          true,
                                                                      itemCount:
                                                                          options
                                                                              .length,
                                                                      itemBuilder:
                                                                          (
                                                                            BuildContext
                                                                            context,
                                                                            int
                                                                            index,
                                                                          ) {
                                                                            final Contacts
                                                                            option = options.elementAt(
                                                                              index,
                                                                            );
                                                                            return GestureDetector(
                                                                              onTap: () {
                                                                                onSelected(
                                                                                  option,
                                                                                );
                                                                              },
                                                                              child: ListTile(
                                                                                title: Text(
                                                                                  option.CustomerName,
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                        )
                                                      : SizedBox(
                                                          height:
                                                              deviceOrientation ==
                                                                  "Portrait"
                                                              ? containerHeight
                                                              : containerDropDownHeight /
                                                                    1.5,
                                                          child: Stack(
                                                            children: [
                                                              Positioned.fill(
                                                                child: AsyncAutocomplete<Contacts>(
                                                                  focusNode:
                                                                      _focus2,
                                                                  onTap: () {
                                                                    reverseScroll =
                                                                        true;
                                                                  },
                                                                  maxListHeight:
                                                                      deviceOrientation ==
                                                                          "Portrait"
                                                                      ? 370
                                                                      : 200,
                                                                  decoration: InputDecoration(
                                                                    labelText:
                                                                        'Name',
                                                                    labelStyle: const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      color: Color(
                                                                        0xFF8F8F8F,
                                                                      ),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontFamily:
                                                                          "Poppins",
                                                                    ),
                                                                    focusedBorder: UnderlineInputBorder(
                                                                      borderSide: const BorderSide(
                                                                        color: Colors
                                                                            .blue,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            0.0,
                                                                          ),
                                                                    ),
                                                                    contentPadding:
                                                                        const EdgeInsets.only(
                                                                          left:
                                                                              0,
                                                                          right:
                                                                              0,
                                                                          top:
                                                                              0,
                                                                          bottom:
                                                                              0,
                                                                        ),
                                                                  ),
                                                                  controller:
                                                                      _searchController3,
                                                                  inputKey:
                                                                      contactKey,
                                                                  onTapItem:
                                                                      (
                                                                        Contacts
                                                                        contact,
                                                                      ) {
                                                                        setState(() {
                                                                          reverseScroll =
                                                                              false;
                                                                          selectedOption =
                                                                              contact.CustomerName;
                                                                          _searchController3
                                                                              .text = contact
                                                                              .CustomerName;
                                                                          var customer = contactMasterList.firstWhere(
                                                                            (
                                                                              map,
                                                                            ) =>
                                                                                map['CustContactName'] ==
                                                                                contact.CustomerName,
                                                                            orElse: () =>
                                                                                <
                                                                                  String,
                                                                                  dynamic
                                                                                >{
                                                                                  'CustContactId': null,
                                                                                },
                                                                          );
                                                                          selectedLeadContactId =
                                                                              customer['CustContactId'].toString();
                                                                          _phoneController
                                                                              .text = customer['CustContactMobileNo']
                                                                              .toString();
                                                                          _emailController
                                                                              .text = customer['CustContactEmailId']
                                                                              .toString();
                                                                          _designationController
                                                                              .text = customer['DesignationName']
                                                                              .toString();
                                                                          _departmentController
                                                                              .text = customer['DepartmentName']
                                                                              .toString();
                                                                        });
                                                                      },
                                                                  suggestionBuilder: (data) => ListTile(
                                                                    title: Text(
                                                                      data.CustomerName,
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  asyncSuggestions:
                                                                      (
                                                                        searchValue,
                                                                      ) => getContacts(
                                                                        searchValue,
                                                                      ),
                                                                ),
                                                              ),
                                                              Positioned(
                                                                top: 0,
                                                                right: 0,
                                                                child: SizedBox(
                                                                  child: GestureDetector(
                                                                    onTap: () {
                                                                      setState(() {
                                                                        selectedOption =
                                                                            '';
                                                                        _searchController3
                                                                            .clear();
                                                                        _clearContactSummary();
                                                                      });
                                                                    },
                                                                    child:
                                                                        _searchController3.text ==
                                                                            ""
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
                                                                                color: Color(
                                                                                  0xff2ca9df,
                                                                                ),
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
                                                                                  _clearContactSummary();
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
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                ],
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 10,
                                                ),
                                                child: SizedBox(
                                                  height:
                                                      deviceOrientation ==
                                                          "Portrait"
                                                      ? containerHeight
                                                      : containerDropDownHeight /
                                                            1.5,
                                                  child: TextFormField(
                                                    controller:
                                                        _designationController,
                                                    keyboardType:
                                                        TextInputType.name,
                                                    decoration: InputDecoration(
                                                      labelText: 'Designation',
                                                      labelStyle:
                                                          const TextStyle(
                                                            fontSize: 14,
                                                            color: Color(
                                                              0xFF8F8F8F,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontFamily:
                                                                "Poppins",
                                                          ),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Colors
                                                                      .blue,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  0.0,
                                                                ),
                                                          ),
                                                      contentPadding:
                                                          const EdgeInsets.only(
                                                            left: 0,
                                                            right: 0,
                                                            top: 0,
                                                            bottom: 0,
                                                          ),
                                                    ),
                                                    validator: (value) {
                                                      if ((value == null ||
                                                              value.isEmpty) &&
                                                          (_searchController3
                                                                  .text ==
                                                              "")) {
                                                        return 'Please enter your designation.';
                                                      }
                                                      return null;
                                                    },
                                                    textInputAction:
                                                        TextInputAction.next,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 10,
                                                ),
                                                child: SizedBox(
                                                  height:
                                                      deviceOrientation ==
                                                          "Portrait"
                                                      ? containerHeight
                                                      : containerDropDownHeight /
                                                            1.5,
                                                  child: TextFormField(
                                                    controller:
                                                        _departmentController,
                                                    keyboardType:
                                                        TextInputType.text,
                                                    decoration: InputDecoration(
                                                      labelText: 'Department',
                                                      labelStyle:
                                                          const TextStyle(
                                                            fontSize: 14,
                                                            color: Color(
                                                              0xFF8F8F8F,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontFamily:
                                                                "Poppins",
                                                          ),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Colors
                                                                      .blue,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  0.0,
                                                                ),
                                                          ),
                                                      contentPadding:
                                                          const EdgeInsets.only(
                                                            left: 0,
                                                            right: 0,
                                                            top: 0,
                                                            bottom: 0,
                                                          ),
                                                    ),
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'Please enter your department.';
                                                      }
                                                      return null;
                                                    },
                                                    textInputAction:
                                                        TextInputAction.next,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 10,
                                                ),
                                                child: SizedBox(
                                                  height:
                                                      deviceOrientation ==
                                                          "Portrait"
                                                      ? containerHeight
                                                      : containerDropDownHeight /
                                                            1.5,
                                                  child: TextFormField(
                                                    controller:
                                                        _phoneController,
                                                    keyboardType:
                                                        TextInputType.phone,
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'Contact Number',
                                                      labelStyle:
                                                          const TextStyle(
                                                            fontSize: 14,
                                                            color: Color(
                                                              0xFF8F8F8F,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontFamily:
                                                                "Poppins",
                                                          ),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Colors
                                                                      .blue,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  0.0,
                                                                ),
                                                          ),
                                                      contentPadding:
                                                          const EdgeInsets.only(
                                                            left: 0,
                                                            right: 0,
                                                            top: 0,
                                                            bottom: 0,
                                                          ),
                                                    ),
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'Please enter your contact number.';
                                                      } else if (!isValidPhoneNumber(
                                                        value,
                                                      )) {
                                                        return 'Please enter a valid phone number';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 10,
                                                ),
                                                child: SizedBox(
                                                  height:
                                                      deviceOrientation ==
                                                          "Portrait"
                                                      ? containerHeight
                                                      : containerDropDownHeight /
                                                            1.5,
                                                  child: TextFormField(
                                                    controller:
                                                        _emailController,
                                                    keyboardType: TextInputType
                                                        .emailAddress,
                                                    decoration: InputDecoration(
                                                      labelText: 'Email',
                                                      labelStyle:
                                                          const TextStyle(
                                                            fontSize: 14,
                                                            color: Color(
                                                              0xFF8F8F8F,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontFamily:
                                                                "Poppins",
                                                          ),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Colors
                                                                      .blue,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  0.0,
                                                                ),
                                                          ),
                                                      contentPadding:
                                                          const EdgeInsets.only(
                                                            left: 0,
                                                            right: 0,
                                                            top: 0,
                                                            bottom: 0,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Padding(
                                                padding:
                                                    deviceOrientation ==
                                                        "Portrait"
                                                    ? const EdgeInsets.only(
                                                        left: 0.0,
                                                      )
                                                    : const EdgeInsets.only(
                                                        left: 0.0,
                                                        right: 0.0,
                                                      ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Text(
                                                          'Decision Maker :',
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFF8F8F8F,
                                                            ),
                                                            fontFamily:
                                                                "Poppins",
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        Checkbox(
                                                          value: selectedValue,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              selectedValue =
                                                                  value ?? true;
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    // Visibility(
                                                    //   visible:
                                                    //       locationControllerFooter
                                                    //               .text ==
                                                    //           "",
                                                    //  child:
                                                    IconButton(
                                                      onPressed: () {
                                                        if (!kIsWeb) {
                                                          getCurrentLocation();
                                                        } else {
                                                          getCurrentLocationWeb();
                                                        }
                                                      },
                                                      icon:
                                                          (!kIsWeb
                                                              ? locationLoading
                                                              : false)
                                                          ? const CircularProgressIndicator()
                                                          : const Icon(
                                                              Icons.location_on,
                                                              color: Color(
                                                                0xFF2CA9DF,
                                                              ),
                                                            ),
                                                    ),
                                                    // ),
                                                    Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 125,
                                                          child: InkWell(
                                                            onTap: () {
                                                              if (formKey
                                                                  .currentState!
                                                                  .validate()) {
                                                                addDataToList();
                                                                // _clearControls();
                                                              } else {
                                                                const snackBar =
                                                                    SnackBar(
                                                                      content: Text(
                                                                        'Contact details not added to the list',
                                                                      ),
                                                                    );
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  snackBar,
                                                                );
                                                              }
                                                            },
                                                            child: Container(
                                                              width: 0,
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    const Color(
                                                                      0xFF2CA9DF,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      0.0,
                                                                    ),
                                                              ),
                                                              child: const Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                          8.0,
                                                                        ),
                                                                    child: Text(
                                                                      'Add',
                                                                      style: TextStyle(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            14,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  Icon(
                                                                    Icons
                                                                        .add_circle_outline,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 18,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              SizedBox(
                                                height: 200,
                                                child: ListView.builder(
                                                  physics:
                                                      const ClampingScrollPhysics(),
                                                  itemCount: contactList.length,
                                                  itemBuilder: (BuildContext context, int index) {
                                                    return Column(
                                                      children: <Widget>[
                                                        SizedBox(
                                                          width: 350,
                                                          child: Container(
                                                            color: const Color(
                                                              0xFFefefef,
                                                            ),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Expanded(
                                                                  child: ListTile(
                                                                    title: Text(
                                                                      contactList[index]['leadContactName'] ??
                                                                          '',
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color: Color(
                                                                          0xff454545,
                                                                        ),
                                                                        fontFamily:
                                                                            "Poppins",
                                                                      ),
                                                                    ),
                                                                    subtitle: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: Text(
                                                                                contactList[index]['leadContactDepartment'] ??
                                                                                    '',
                                                                                style: const TextStyle(
                                                                                  fontSize: 14,
                                                                                  color: Color(
                                                                                    0xff454545,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            const Text(
                                                                              "/",
                                                                              style: TextStyle(
                                                                                fontSize: 14,
                                                                                color: Color(
                                                                                  0xff454545,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            Expanded(
                                                                              child: Text(
                                                                                contactList[index]['leadContactDesignation'] ??
                                                                                    '',
                                                                                style: const TextStyle(
                                                                                  fontSize: 14,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 70,
                                                                            ),
                                                                            Row(
                                                                              children: [
                                                                                Visibility(
                                                                                  visible:
                                                                                      contactList[index]["leadContactDecisionMaker"].toString() ==
                                                                                      "Yes",
                                                                                  child: const Text(
                                                                                    'DM',
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(
                                                                                  width: 15,
                                                                                ),
                                                                                GestureDetector(
                                                                                  onTap: () {
                                                                                    loadContactDetails(
                                                                                      contactList[index],
                                                                                    );
                                                                                    setState(
                                                                                      () {
                                                                                        contactList.remove(
                                                                                          contactList[index],
                                                                                        );
                                                                                      },
                                                                                    );
                                                                                  },
                                                                                  child: const Icon(
                                                                                    Icons.edit,
                                                                                    size: 16.0,
                                                                                    color: Color(
                                                                                      0xff454545,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 5,
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Meeting Summary",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 150,
                                    width: 400,
                                    child: ParticipantMultiLevelDropDown(),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: summaryController,
                                    keyboardType: TextInputType.multiline,
                                    maxLines: 4,
                                    maxLength: 1000,
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Color(0xFF8F8F8F),
                                        ),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                      labelText: "Summary of Discussion",
                                      labelStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF8F8F8F),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          width: 1,
                                          color: Colors.grey,
                                        ),
                                      ),
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
                                            summaryController,
                                            _isSummaryListening,
                                            (bool isListening) {
                                              _isSummaryListening = isListening;
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Any Input Material submitted ?",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF8F8F8F),
                                        ),
                                      ),
                                      Transform.scale(
                                        scale: .7,
                                        child: Checkbox(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              2.0,
                                            ),
                                          ),
                                          side:
                                              WidgetStateBorderSide.resolveWith(
                                                (states) => const BorderSide(
                                                  width: 1.0,
                                                  color: Color(0xFF8F8F8F),
                                                ),
                                              ),
                                          value: inputMaterialCheck,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              inputMaterialCheck =
                                                  value ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  Visibility(
                                    visible: inputMaterialCheck,
                                    child: Column(
                                      children: [
                                        kIsWeb
                                            ? RawAutocomplete<InputMaterial>(
                                                textEditingController:
                                                    materialController,
                                                focusNode: _focusInputMaterial,
                                                optionsBuilder: (TextEditingValue val) {
                                                  if (val.text == '') {
                                                    return const Iterable<
                                                      InputMaterial
                                                    >.empty();
                                                  }
                                                  return inputMaterialWeb.where((
                                                    InputMaterial option,
                                                  ) {
                                                    return option
                                                            .MaterialName.toLowerCase()
                                                        .contains(
                                                          val.text
                                                              .toLowerCase(),
                                                        );
                                                  });
                                                },
                                                displayStringForOption:
                                                    (InputMaterial option) =>
                                                        option.MaterialName,
                                                fieldViewBuilder:
                                                    (
                                                      context,
                                                      textEditingController,
                                                      focusNode,
                                                      onFieldSubmitted,
                                                    ) {
                                                      return TextField(
                                                        controller:
                                                            textEditingController,
                                                        focusNode: focusNode,
                                                        onSubmitted: (value) {},
                                                        decoration: InputDecoration(
                                                          labelText:
                                                              '   Input Materials',
                                                          labelStyle:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF454545,
                                                                ),
                                                                fontFamily:
                                                                    "Poppins",
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                fontSize: 14,
                                                              ),
                                                          suffixIcon: IconButton(
                                                            icon:
                                                                _searchController
                                                                        .text ==
                                                                    ""
                                                                ? const Icon(
                                                                    Icons
                                                                        .search,
                                                                    color: Color(
                                                                      0xff2ca9df,
                                                                    ),
                                                                  )
                                                                : const Icon(
                                                                    Icons.clear,
                                                                  ),
                                                            onPressed: () {
                                                              _searchController
                                                                  .clear();
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                onSelected: (InputMaterial value) {
                                                  setState(() {
                                                    if (value.MaterialName !=
                                                        "") {
                                                      selectedMaterial.add(
                                                        value,
                                                      );
                                                      inputMaterialController
                                                              .text =
                                                          value.MaterialName;
                                                      materialController
                                                          .clear();
                                                    } else {
                                                      SnackBar
                                                      snackBar = const SnackBar(
                                                        showCloseIcon: true,
                                                        duration: Duration(
                                                          seconds: 1,
                                                        ),
                                                        content: Text(
                                                          "Please Enter Product Name",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(snackBar);
                                                    }
                                                    productController.clear();
                                                  });
                                                },
                                                optionsViewBuilder:
                                                    (
                                                      BuildContext context,
                                                      void Function(
                                                        InputMaterial,
                                                      )
                                                      onSelected,
                                                      Iterable<InputMaterial>
                                                      options,
                                                    ) {
                                                      return Material(
                                                        elevation: 4.0,
                                                        child: Container(
                                                          constraints:
                                                              const BoxConstraints(
                                                                maxHeight: 200,
                                                              ),
                                                          child: ListView.builder(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            physics:
                                                                const ClampingScrollPhysics(),
                                                            shrinkWrap: true,
                                                            itemCount:
                                                                options.length,
                                                            itemBuilder:
                                                                (
                                                                  BuildContext
                                                                  context,
                                                                  int index,
                                                                ) {
                                                                  final InputMaterial
                                                                  option = options
                                                                      .elementAt(
                                                                        index,
                                                                      );
                                                                  return GestureDetector(
                                                                    onTap: () {
                                                                      onSelected(
                                                                        option,
                                                                      );
                                                                    },
                                                                    child: ListTile(
                                                                      title: Text(
                                                                        option
                                                                            .MaterialName,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                          ),
                                                        ),
                                                      );
                                                    },
                                              )
                                            : SizedBox(
                                                height:
                                                    deviceOrientation ==
                                                        "Portrait"
                                                    ? containerHeight
                                                    : containerDropDownHeight /
                                                          1.5,
                                                child: Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: AsyncAutocomplete<InputMaterial>(
                                                        onChanged: (s) {
                                                          setState(() {});
                                                        },
                                                        onSubmitted:
                                                            (material) {
                                                              setState(() {});
                                                            },
                                                        maxListHeight:
                                                            deviceOrientation ==
                                                                "Portrait"
                                                            ? 370
                                                            : 200,
                                                        decoration: InputDecoration(
                                                          labelText:
                                                              'Input Materials',
                                                          labelStyle:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                color: Color(
                                                                  0xFF8F8F8F,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontFamily:
                                                                    "Poppins",
                                                              ),
                                                          focusedBorder: UnderlineInputBorder(
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Colors
                                                                      .blue,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  0.0,
                                                                ),
                                                          ),
                                                          contentPadding:
                                                              const EdgeInsets.only(
                                                                left: 0,
                                                                right: 0,
                                                                top: 0,
                                                                bottom: 0,
                                                              ),
                                                        ),
                                                        controller:
                                                            materialController,
                                                        inputKey: materialKey,
                                                        onTapItem: (InputMaterial mat) {
                                                          setState(() {
                                                            selectedMaterial
                                                                .add(mat);
                                                            inputMaterialController
                                                                .text = mat
                                                                .MaterialName;
                                                            materialController
                                                                .clear();
                                                          });
                                                        },
                                                        suggestionBuilder:
                                                            (data) => ListTile(
                                                              title: Text(
                                                                data.MaterialName,
                                                                style:
                                                                    const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                              ),
                                                            ),
                                                        asyncSuggestions:
                                                            (searchValue) =>
                                                                getInputMaterialData(
                                                                  searchValue,
                                                                ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 0,
                                                      right: 0,
                                                      child: SizedBox(
                                                        child:
                                                            materialController
                                                                    .text ==
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
                                                                        right:
                                                                            2,
                                                                      ),
                                                                  child: Icon(
                                                                    Icons
                                                                        .search,
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
                                                                        right:
                                                                            2,
                                                                      ),
                                                                  child: IconButton(
                                                                    onPressed: () {
                                                                      setState(() {
                                                                        materialController
                                                                            .clear();
                                                                      });
                                                                    },
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .close_rounded,
                                                                      size: 20,
                                                                    ),
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                ),
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: SizedBox(
                                            height: 100,
                                            child: ListView.builder(
                                              physics:
                                                  const ClampingScrollPhysics(),
                                              itemCount:
                                                  selectedMaterial.length,
                                              itemBuilder: (BuildContext context, int index) {
                                                return Card(
                                                  color: const Color(
                                                    0xff2ca9df,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            selectedMaterial[index]
                                                                .MaterialName,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            selectedMaterial.remove(
                                                              selectedMaterial[index],
                                                            );
                                                          });
                                                        },
                                                        icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  SizedBox(
                                    height: 70,
                                    width: 400,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 0),
                                      child: DropdownButtonFormField<String>(
                                        hint: const Text(
                                          'Stages',
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
                                          });
                                        },
                                        items:
                                            <String>[
                                              'Stages',
                                              '1st Meeting',
                                              '2nd Meeting',
                                              'Approved-If sample is approved',
                                              'Rejected - If sample is rejected',
                                              'Quotation',
                                              'Negotiations',
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
                                                    color: Color(0xFF8F8F8F),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 0,
                                              ),
                                              child: DropdownButtonFormField<String>(
                                                hint: const Text(
                                                  'Business Expected within',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w400,
                                                    color: Color(0xFF8F8F8F),
                                                  ),
                                                ),
                                                initialValue:
                                                    businessExpectedWithin,
                                                icon: const Icon(
                                                  Icons.search,
                                                  color: Color(0xff2ca9df),
                                                ),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    businessExpectedWithin =
                                                        newValue!;
                                                  });
                                                },
                                                items:
                                                    <String>[
                                                      '1 Week',
                                                      '2-3 Weeks',
                                                      '1 month',
                                                      '2-3 month',
                                                    ].map<
                                                      DropdownMenuItem<String>
                                                    >((String value) {
                                                      return DropdownMenuItem<
                                                        String
                                                      >(
                                                        value: value,
                                                        child: Text(
                                                          value,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color: Color(
                                                                  0xFF8F8F8F,
                                                                ),
                                                              ),
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 0,
                                              ),
                                              child: DropdownButtonFormField<String>(
                                                hint: const Text(
                                                  'Expected Value',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Color(0xFF8F8F8F),
                                                  ),
                                                ),
                                                initialValue: expectedValue,
                                                icon: const Icon(
                                                  Icons.search,
                                                  color: Color(0xff2ca9df),
                                                ),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    expectedValue = newValue!;
                                                  });
                                                },
                                                items:
                                                    <String>[
                                                      'Deal Value < 50,000',
                                                      '50,001 - 2,00,000',
                                                      '> 2,00,000',
                                                    ].map<
                                                      DropdownMenuItem<String>
                                                    >((String value) {
                                                      return DropdownMenuItem<
                                                        String
                                                      >(
                                                        value: value,
                                                        child: Text(
                                                          value,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color: Color(
                                                                  0xFF8F8F8F,
                                                                ),
                                                              ),
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 0,
                                              ),
                                              child: DropdownButtonFormField<String>(
                                                hint: const Text(
                                                  'Stages',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Color(0xFF8F8F8F),
                                                  ),
                                                ),
                                                initialValue: stageValue,
                                                icon: const Icon(
                                                  Icons.search,
                                                  color: Color(0xff2ca9df),
                                                ),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    stageValue = newValue!;
                                                  });
                                                },
                                                items:
                                                    <String>[
                                                      'Stages',
                                                      '1st Meeting',
                                                      '2nd Meeting',
                                                      'Approved',
                                                      'Rejected',
                                                      'Quotation',
                                                      'Negotiations',
                                                    ].map<
                                                      DropdownMenuItem<String>
                                                    >((String value) {
                                                      return DropdownMenuItem<
                                                        String
                                                      >(
                                                        value: value,
                                                        child: Text(
                                                          value,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color: Color(
                                                                  0xFF8F8F8F,
                                                                ),
                                                              ),
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
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
                                                  padding: EdgeInsets.only(
                                                    left: 20.0,
                                                  ),
                                                  child: Icon(
                                                    Icons.calendar_today,
                                                    color: Color(0xff2ca9df),
                                                    size: 20,
                                                  ),
                                                ),
                                                floatingLabelBehavior:
                                                    FloatingLabelBehavior.never,
                                                labelText: 'On',
                                                contentPadding: EdgeInsets.only(
                                                  bottom: 0,
                                                ),
                                                labelStyle: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xFF8F8F8F),
                                                ),
                                              ),
                                              onTap: () async {
                                                DateTime? selectedDate =
                                                    await showDatePicker(
                                                      context: context,
                                                      initialDate:
                                                          DateTime.now(),
                                                      firstDate: DateTime(2000),
                                                      lastDate: DateTime(2101),
                                                      initialEntryMode:
                                                          DatePickerEntryMode
                                                              .calendar,
                                                    );
                                                TimeOfDay? selectedTime =
                                                    await showTimePicker(
                                                      context: context,
                                                      initialTime:
                                                          TimeOfDay.now(),
                                                    );
                                                if (selectedTime != null) {
                                                  String formattedDateTime =
                                                      DateFormat(
                                                        'dd/MM/yyyy hh:mm a',
                                                      ).format(
                                                        DateTime(
                                                          selectedDate!.year,
                                                          selectedDate.month,
                                                          selectedDate.day,
                                                          selectedTime.hour,
                                                          selectedTime.minute,
                                                        ),
                                                      );
                                                  _dateController.text =
                                                      formattedDateTime;
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      TextField(
                                        showCursor: false,
                                        controller: supportController,
                                        keyboardType: TextInputType.multiline,
                                        maxLines: 4,
                                        maxLength: 500,
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.grey,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                          labelText:
                                              "Any other support required from Head Office?",
                                          labelStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xFF8F8F8F),
                                          ),
                                          focusedBorder:
                                              const OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  width: 1,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                          contentPadding: const EdgeInsets.only(
                                            left: 15,
                                            right: 0,
                                            top: 15,
                                            bottom: 0,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isSupportListening
                                                  ? Icons.mic
                                                  : Icons.mic_none,
                                            ),
                                            onPressed: () {
                                              _listen(
                                                supportController,
                                                _isSupportListening,
                                                (bool isListening) {
                                                  _isSupportListening =
                                                      isListening;
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Center(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xff2ca9df,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                            ),
                                          ),
                                          onPressed:
                                              widget.checkInDetails == null
                                              ? null
                                              : () async {
                                                  if (inputMaterialCheck) {
                                                    validateInputMaterials();
                                                  }
                                                  if (locationControllerFooter
                                                              .text ==
                                                          "" ||
                                                      contactList.isEmpty ||
                                                      validInputMaterial ==
                                                          false) {
                                                    final snackBar = SnackBar(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF2CA9DF,
                                                          ),
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                      content: Text(
                                                        contactList.isEmpty
                                                            ? 'Add contact person.'
                                                            : validInputMaterial ==
                                                                  false
                                                            ? 'Please select a valid Material Name and try again...'
                                                            : 'Location is missing, Please add location and try again...',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
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
                                                                AlwaysStoppedAnimation<
                                                                  Color
                                                                >(Colors.white),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                    try {
                                                      await submitLeads();
                                                      // await submitStageSummary();
                                                      Navigator.of(
                                                        dialogContext!,
                                                      ).pop();
                                                      navigateToHomePage();
                                                    } catch (error) {
                                                      // print('Error: $error');
                                                    }
                                                  }
                                                },
                                          child: const SizedBox(
                                            width: 400,
                                            child: Center(
                                              child: Text(
                                                "Save",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class Job with CustomDropdownListFilter {
  final String name;
  final IconData icon;
  const Job(this.name, this.icon);

  @override
  String toString() {
    return name;
  }

  @override
  bool filter(String query) {
    return name.toLowerCase().contains(query.toLowerCase());
  }
}

class SearchDropdown extends StatelessWidget {
  const SearchDropdown({super.key, TextEditingController? controller});

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<Hospital>.search(
      hintText: 'Select job role',
      items: hspList,
      excludeSelected: false,
      onChanged: (value) {
        // log('changing value to: $value');
      },
    );
  }
}
