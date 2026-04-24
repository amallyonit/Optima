// ignore_for_file: file_names, use_build_context_synchronously, avoid_print, unused_local_variable

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:optima/classes/globals.dart';
import 'package:optima/login_screen.dart';

import 'package:optima/pages/addUpateMeeting/participantMultiDropDown.dart';
import 'package:optima/pages/footer.dart';
import '../../api_helper.dart';
import '../../classes/leads.dart';
import '../../tabs/tabspage.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

List<LeadParticipant> selectedParticipantOther = [];
List<LeadParticipant> initialParticipantOther = [];
List<Map<String, dynamic>> selectedProductList = [];
List<Map<String, String>> contactList = [];
List<Map<String, dynamic>> participantListOther = [];
String? deviceOrientation;
bool locationLoading = false;
bool summarySave = false;
TextEditingController locationControllerFooter = TextEditingController();
String latitudeFooter = "";
String longitudeFooter = "";
late stt.SpeechToText _speech;
bool _isListening = false;
String _text = '';
// double _confidence = 1.0;

class OtherMeetingPage extends StatefulWidget {
  final CheckinDetails? checkInDetails;
  final bool fromHomePage;
  const OtherMeetingPage({
    super.key,
    this.checkInDetails,
    required this.fromHomePage,
  });

  @override
  State<OtherMeetingPage> createState() => _OtherMeetingPageState();
}

class _OtherMeetingPageState extends State<OtherMeetingPage> {
  late Future<void> loadDataFuture;
  final TextEditingController placeOfVisitController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController supportController = TextEditingController();
  var othersKey = GlobalKey();
  bool value1 = false;
  bool value2 = false;
  Timer? _timer;

  void navigateToHomePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TabsPage(selectedIndex: 0, selectedRoleCode: ""),
      ),
    );
  }

  Future<void> submitStageSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    List<Map<String, Object>> selectedParticipantList = selectedParticipantOther
        .whereType<LeadParticipant>()
        .map(
          (LeadParticipant item) => {
            'ParticipantName': item.leadParticipantUserName,
            'LeadParticipantId': 0,
            'ParticipantId': item.leadParticipantUserId,
          },
        )
        .toList();
    summarySave = false;
    final leadactivity = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadID': leadId,
      'LeadActivityId': leadActivityId,
      'LeadActivityStageLevel': "1",
      'LeadActivitySummary': reasonController.text,
      'LeadActivityFollowupDate':
          "", //DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()),
      'LeadActivityLatitude': latitudeFooter,
      'LeadActivityLongitude': longitudeFooter,
      'LeadActivityLocation': locationControllerFooter.text,
      'LeadActivityStatus': "",
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
          reasonController.clear();
          setState(() {
            selectedParticipantList.clear();
            selectedParticipantList = [];
            participantList.clear();
            participantList = [];
            summarySave = true;
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
            navigateToHomePage();
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

  Future<void> submitLeads() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userId = prefs.getString('userId') ?? '';

    participantListOther = selectedParticipantOther
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
      'LeadDistributorCode': "",
      'LeadDistributorName': "",
      'LeadAssigneeId': "0",
      'LeadDealValue': "0",
      'LeadStatus': 'A',
      'LeadType': "A",
      'LeadCategory': 'O',
      'LeadBusinessType': 'O',
      'LeadPromotionType': 'O',
      'LeadSummary':
          " ${placeOfVisitController.text}, ${reasonController.text} ",
      'LeadStages': "",
      'LeadExpectedWithin': "",
      'LeadNextAction': "0",
      'LeadNextActionDate': "",
      'LeadHelpRequired': supportController.text,
      'LeadCheckinId': widget.checkInDetails?.checkinId ?? 0,
      'contactList': contactList,
      'participantList': participantListOther,
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
        if (status && responseJson["Data"].toString().isNotEmpty) {
          setState(() {
            leadId = responseJson["Data"]["LeadID"].toString();
          });
          await submitStageSummary();
          setState(() {
            contactList.clear();
            placeOfVisitController.clear();
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
            navigateToHomePage();
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
    if (!kIsWeb) {
      await getCurrentLocation();
    } else {
      await getCurrentLocationWeb();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    manualLocationFetchStart = false;
    placeOfVisitController.dispose();
    super.dispose();
  }

  void _listen(TextEditingController txtController) async {
    if (!_isListening) {
      _checkMicPermissions();
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            txtController.text = _text;
            if (val.hasConfidenceRating && val.confidence > 0) {
              // _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
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
      final checkin = {
        'UserJwtToken': userJwtToken,
        'UsermailID': userMailID,
        'CheckinId': widget.checkInDetails?.checkinId ?? 0,
        'CheckinUserId': userId,
        'CheckinCustomerType': 'O',
        'CheckinCustomerCode': "",
        'CheckinLatitude': latitudeFooter,
        'CheckinLongitude': longitudeFooter,
        'CheckinLocation': locationControllerFooter.text,
        'CheckoutLatitude': "",
        'CheckoutLongitude': "",
        'CheckoutLocation': "",
        'CheckinPlaceOfVisit': placeOfVisitController.text,
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
    if (!kIsWeb) {
      await getCurrentLocation();
    } else {
      await getCurrentLocationWeb();
    }
    final checkin = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'CheckinId': widget.checkInDetails?.checkinId ?? 0,
      'CheckinUserId': userId,
      'CheckinCustomerType': 'O',
      'CheckinCustomerCode': "",
      'CheckinLatitude': "",
      'CheckinLongitude': "",
      'CheckinLocation': "",
      'CheckoutLatitude': latitudeFooter,
      'CheckoutLongitude': longitudeFooter,
      'CheckoutLocation': locationControllerFooter.text,
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

  @override
  void initState() {
    super.initState();
    if (widget.fromHomePage == true) {
      placeOfVisitController.text =
          widget.checkInDetails?.checkinPlaceOfVisit ?? "";
    }
    manualLocationFetchStart = false;
    if (isUserLoggedIn) {
      loadDataFuture = loadData();
    }
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      deviceOrientation = "Portrait";
    } else {
      deviceOrientation = "Landscape";
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
                      'Others Meeting',
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
        padding: const EdgeInsets.all(16.0),
        child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: placeOfVisitController,
                  decoration: const InputDecoration(
                    hintText: "Place of Visit",
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8F8F8F),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                AbsorbPointer(
                  absorbing: widget.checkInDetails != null,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (placeOfVisitController.text == "") {
                        const snackBar = SnackBar(
                          backgroundColor: Color(0xFF2CA9DF),
                          duration: Duration(seconds: 2),
                          content: Text(
                            'Please enter place of visit and try again...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
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
                          await submitCheckin();
                          Navigator.of(dialogContext!).pop();
                          navigateToHomePage();
                        } catch (error) {
                          // print('Error: $error');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.checkInDetails == null
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Visit Summary",
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
                        setState(() {
                          manualLocationFetchStart = true;
                        });
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
                  controller: reasonController,
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    labelText: "Reason of Visit",
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8F8F8F),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(width: 1, color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.only(
                      left: 15,
                      right: 0,
                      top: 15,
                      bottom: 0,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      onPressed: () {
                        _listen(reasonController);
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
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
    );
  }
}
