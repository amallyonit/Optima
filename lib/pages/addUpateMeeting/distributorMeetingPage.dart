// ignore_for_file: file_names, use_build_context_synchronously, avoid_print, non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:optima/classes/footerConstants.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/login_screen.dart';
import 'package:optima/pages/addUpateMeeting/hospitalMeetingPage.dart';
import 'package:optima/pages/addUpateMeeting/participantMultiDropDown.dart';
import 'dart:async';
import '../../api_helper.dart';
import '../../classes/leads.dart';
import '../../tabs/tabspage.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

String leadId = "";
List<LeadParticipant> selectedParticipantDistri = [];
List<LeadParticipant> initialParticipantDistri = [];
List<Map<String, dynamic>> selectedProductList = [];
List<Map<String, dynamic>> selectedStagesList = [];
String deviceOrientation = "";
String leadActivityId = "0";
bool locationLoading = false;
late stt.SpeechToText _speech;
bool _isSummaryListening = false;
bool _isSupportListening = false;
// String _text = '';
// double _confidence = 1.0;

List<Distributor> distListWeb = [];

class DistributorMeetingPage extends StatefulWidget {
  final CheckinDetails? checkInDetails;
  final bool fromHomePage;
  const DistributorMeetingPage({
    super.key,
    this.checkInDetails,
    required this.fromHomePage,
  });

  @override
  State<DistributorMeetingPage> createState() => _DistributorMeetingPageState();
}

class Distributor {
  String CustomerName;
  String CustomerCode;
  Distributor({required this.CustomerCode, required this.CustomerName});
}

class _DistributorMeetingPageState extends State<DistributorMeetingPage> {
  late Future<void> loadDataFuture;
  List<Map<String, dynamic>> contactMasterList = [];
  final TextEditingController accountController = TextEditingController();
  final TextEditingController summaryController = TextEditingController();
  String? distributorStageValue;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController supportController = TextEditingController();
  TextEditingController locationControllerFooter = TextEditingController();
  var distributorKey = GlobalKey();
  String selectedOption2 = 'Option 1';
  List<Map<String, dynamic>> customerList = [];
  List<Map<String, dynamic>> distributorList = [];
  List<Map<String, dynamic>> participantList = [];
  String selectedDistributorName = "";
  String selectedDistributorId = "";
  bool newBusinessCheck = false;
  bool existingBusinessCheck = false;
  Timer? _timer;
  late FocusNode _focus;

  void _clearControls() {
    setState(() {
      accountController.clear();
    });
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
      final snackBar = SnackBar(content: Text('Error getting location: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> getCurrentLocationWeb() async {
    try {
      setState(() {
        locationLoading = true;
      });
      // Request location permission
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

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loaddistributor(userId, userJwtToken, userMailID);
    if (!kIsWeb) {
      await getCurrentLocation();
    } else {
      await getCurrentLocationWeb();
    }
  }

  List<Distributor> convertDist(List<Map<String, dynamic>> distributorList) {
    return distributorList
        .map(
          (map) => Distributor(
            CustomerCode: map['CustomerCode']?.toString() ?? '',
            CustomerName: map['CustomerName']?.toString() ?? '',
          ),
        )
        .toList();
  }

  Future<List<Distributor>> getDistributor(String search) async {
    List<Distributor> distList = convertDist(distributorList);
    List<Distributor> filteredList = distList
        .where(
          (element) => element.CustomerName.toLowerCase().startsWith(
            search.toLowerCase(),
          ),
        )
        .toList();

    return filteredList;
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
            distListWeb = convertDist(distributorList);
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
      final snackBar = SnackBar(content: Text('$e'));
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

  void navigateToHomePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TabsPage(selectedIndex: 0, selectedRoleCode: ""),
      ),
    );
  }

  void accountNameEmptyChecker() {
    if (accountController.text == "") {
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

  Future<void> submitLeads() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userId = prefs.getString('userId') ?? '';

    participantList = selectedParticipantDistri
        .whereType<LeadParticipant>()
        .map(
          (LeadParticipant item) => {
            'LeadParticipantId': item.leadParticipantId,
            'ParticipantId': item.leadParticipantUserId,
          },
        )
        .toList();

    final leadmaster = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadID': leadId,
      'LeadUserId': userId,
      'LeadHospitalCode': "",
      'LeadHospitalName': "",
      'LeadDistributorCode': selectedDistributorId,
      'LeadDistributorName': accountController.text,
      'LeadAssigneeId': "0",
      'LeadDealValue': '',
      'LeadStatus': 'A',
      'LeadType': "A",
      'LeadCategory': 'D',
      'LeadBusinessType': newBusinessCheck && existingBusinessCheck == true
          ? 'O'
          : newBusinessCheck == true
          ? 'N'
          : 'E',
      'LeadPromotionType': 'O',
      'LeadSummary': summaryController.text,
      'LeadStages': selectedStagesList,
      'LeadExpectedWithin': '',
      'LeadNextAction': distributorStageValue,
      'LeadNextActionDate': _dateController.text,
      'LeadHelpRequired': supportController.text,
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
        if (status &&
            summarySave &&
            responseJson["Data"].toString().isNotEmpty) {
          setState(() {
            accountController.clear();
            contactList.clear();
            selectedDistributorId = "";
            leadId = responseJson["Data"]["LeadID"].toString();
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
        'CheckinCustomerType': 'D',
        'CheckinCustomerCode': selectedDistributorId,
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
      'CheckinCustomerType': 'D',
      'CheckinCustomerCode': selectedDistributorId,
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
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    summarySave = false;
    List<Map<String, Object>> selectedParticipantList =
        selectedParticipantDistri
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
      'LeadActivityStatus': distributorStageValue,
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
          _dateController.text = DateFormat(
            'dd/MM/yyyy hh:mm a',
          ).format(DateTime.now());
          leadId = "";
          setState(() {
            selectedParticipantList.clear();
            selectedParticipantList = [];
            participantList.clear();
            participantList = [];
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
        'LeadHospitalCode': "",
        'LeadHospitalName': "",
        'LeadDistributorCode': selectedDistributorId,
        'LeadDistributorName': accountController.text,
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
              selectedDistributorId = responseJson["AccountCode"].toString();
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

  @override
  void dispose() {
    _timer?.cancel();
    accountController.dispose();
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
    _focus = FocusNode();
    _speech = stt.SpeechToText();
    leadId = "";
    if (isUserLoggedIn) {
      loadDataFuture = loadData();
    }
    if (widget.fromHomePage == true) {
      selectedDistributorId = widget.checkInDetails?.checkinCustomerCode ?? "";
      selectedDistributorName =
          widget.checkInDetails?.checkinCustomerName ?? "";
      accountController.text = widget.checkInDetails?.checkinCustomerName ?? "";
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
                      'Distributor Meeting',
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
        padding: const EdgeInsets.all(12.0),
        child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AbsorbPointer(
                  absorbing: widget.checkInDetails != null,
                  child: kIsWeb
                      ? RawAutocomplete<Distributor>(
                          textEditingController: accountController,
                          focusNode: _focus,
                          optionsBuilder: (TextEditingValue val) {
                            if (val.text == '') {
                              return const Iterable<Distributor>.empty();
                            }
                            return distListWeb.where((Distributor option) {
                              return option.CustomerName.toLowerCase().contains(
                                val.text.toLowerCase(),
                              );
                            });
                          },
                          displayStringForOption: (Distributor option) =>
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
                                  onSubmitted: (value) {
                                    accountController.text = value;
                                    setState(() {
                                      selectedOption2 = value;
                                      accountController.text = value;
                                      selectedDistributorName = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Enter Account Name',
                                    labelStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF8F8F8F),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: accountController.text == ""
                                          ? const Icon(
                                              Icons.search,
                                              color: Color(0xff2ca9df),
                                            )
                                          : const Icon(Icons.clear),
                                      onPressed: () {
                                        accountController.clear();
                                      },
                                    ),
                                  ),
                                );
                              },
                          onSelected: (Distributor value) {
                            accountController.text = value.CustomerName;
                            setState(() {
                              selectedOption2 = value.CustomerName;
                              accountController.text = value.CustomerName;
                              var customer = distributorList.firstWhere(
                                (map) =>
                                    map['CustomerName'] == value.CustomerName,
                                // orElse: () =>
                                //     <String, dynamic>{'CustomerCode': null},
                              );
                              selectedDistributorId = customer['CustomerCode']
                                  .toString();
                              selectedDistributorName = value.CustomerName;
                            });
                          },
                          optionsViewBuilder:
                              (
                                BuildContext context,
                                void Function(Distributor) onSelected,
                                Iterable<Distributor> options,
                              ) {
                                return Material(
                                  elevation: 4.0,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 200,
                                    ),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      physics: const ClampingScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                            final Distributor option = options
                                                .elementAt(index);
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
                                child: AsyncAutocomplete<Distributor>(
                                  onChanged: (s) {
                                    setState(() {
                                      accountController.text == s;
                                    });
                                  },
                                  onSaved: (s) {
                                    setState(() {
                                      accountController.text == s;
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
                                    hintText: 'Enter Account Name',
                                    hintStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF8F8F8F),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: const BorderSide(
                                        color: Colors
                                            .blue, // Set your desired focus color
                                      ),
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                  ),
                                  controller: accountController,
                                  inputKey: distributorKey,
                                  onTapItem: (Distributor distributor) async {
                                    setState(() {
                                      selectedOption2 =
                                          distributor.CustomerName;
                                      accountController.text =
                                          distributor.CustomerName;
                                      var customer = distributorList.firstWhere(
                                        (map) =>
                                            map['CustomerName'] ==
                                            distributor.CustomerName,
                                        // orElse: () =>
                                        //     <String, dynamic>{'CustomerCode': null},
                                      );
                                      selectedDistributorId =
                                          customer['CustomerCode'].toString();
                                      selectedDistributorName =
                                          distributor.CustomerName;
                                    });
                                  },
                                  suggestionBuilder: (data) =>
                                      ListTile(title: Text(data.CustomerName)),
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
                                          selectedOption2 = '';
                                          selectedDistributorId = "";
                                          selectedDistributorName = "";
                                          accountController.clear();
                                          _clearControls();
                                        });
                                      },
                                      child: accountController.text == ""
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
                GestureDetector(
                  onTap: () {
                    accountNameEmptyChecker();
                  },
                  child: AbsorbPointer(
                    absorbing: accountController.text == "",
                    child: SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Transform.scale(
                                      scale: .7,
                                      child: Checkbox(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            2.0,
                                          ),
                                        ),
                                        side: WidgetStateBorderSide.resolveWith(
                                          (states) => const BorderSide(
                                            width: 1.0,
                                            color: Color(0xFF8F8F8F),
                                          ),
                                        ),
                                        value: newBusinessCheck,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            newBusinessCheck = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Transform.scale(
                                      scale: .7,
                                      child: Checkbox(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            2.0,
                                          ),
                                        ),
                                        side: WidgetStateBorderSide.resolveWith(
                                          (states) => const BorderSide(
                                            width: 1.0,
                                            color: Color(0xFF8F8F8F),
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
                                  absorbing: widget.checkInDetails != null,
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
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          );
                                        },
                                      );
                                      try {
                                        await submitCheckin();
                                        Navigator.of(dialogContext!).pop();
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
                                      shape: const RoundedRectangleBorder(),
                                    ),
                                    child: const Text(
                                      "Check In",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Meeting Summary",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              // Visibility(
                              //   visible: locationControllerFooter.text == "",
                              //   child:
                              IconButton(
                                onPressed: () {
                                  if (!kIsWeb) {
                                    getCurrentLocation();
                                  } else {
                                    getCurrentLocationWeb();
                                  }
                                },
                                icon: (!kIsWeb ? locationLoading : false)
                                    ? const CircularProgressIndicator()
                                    : const Icon(
                                        Icons.location_on,
                                        color: Color(0xFF2CA9DF),
                                      ),
                              ),
                              // ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 150,
                            width: 400,
                            child: ParticipantMultiLevelDropDown(),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: summaryController,
                            keyboardType: TextInputType.multiline,
                            maxLines: 4,
                            maxLength: 1000,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(2),
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
                                top: 0,
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
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
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
                                    initialValue: distributorStageValue,
                                    icon: const Icon(
                                      Icons.search,
                                      color: Color(0xff2ca9df),
                                    ),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        distributorStageValue = newValue!;
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
                              const SizedBox(width: 20),
                              Flexible(
                                child: TextField(
                                  showCursor: false,
                                  canRequestFocus: false,
                                  style: const TextStyle(
                                    color: Color(0xFF8F8F8F),
                                  ),
                                  keyboardType: TextInputType.none,
                                  controller: _dateController,
                                  decoration: const InputDecoration(
                                    suffixIcon: Icon(
                                      Icons.calendar_today,
                                      color: Color(0xff2ca9df),
                                      size: 20,
                                    ),
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    labelText: 'On',
                                    contentPadding: EdgeInsets.only(bottom: 0),
                                    labelStyle: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF8F8F8F),
                                    ),
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
                                  _dateController.text =
                                      DateFormat.yMMMd().format(_selectedDate);
                                });
                              }
                            }*/ async {
                                        DateTime? selectedDate =
                                            await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2101),
                                              initialEntryMode:
                                                  DatePickerEntryMode.calendar,
                                            );
                                        TimeOfDay? selectedTime =
                                            await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
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
                            controller: supportController,
                            keyboardType: TextInputType.multiline,
                            maxLines: 4,
                            maxLength: 500,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              labelText:
                                  "Any other support required from Head Office?",
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
                                top: 0,
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
                                      _isSupportListening = isListening;
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
                                backgroundColor: const Color(0xff2ca9df),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              onPressed: widget.checkInDetails == null
                                  ? null
                                  : () async {
                                      if (locationControllerFooter.text == "") {
                                        const snackBar = SnackBar(
                                          backgroundColor: Color(0xFF2CA9DF),
                                          duration: Duration(seconds: 2),
                                          content: Text(
                                            'Location is missing, Please add location and try again...',
                                            style: TextStyle(
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
                                          Navigator.of(dialogContext!).pop();
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
                                    style: TextStyle(color: Colors.white),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
