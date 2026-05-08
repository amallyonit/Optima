// ignore_for_file: avoid_print, use_build_context_synchronously, dead_code
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/login_screen.dart';
import 'package:optima/pages/customerdatapage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:optima/classes/leads.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../classes/footerConstants.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

String leadId = "";
String leadStageForEdit = "";
String leadActivityId = "0";
String _leadID = "", _leadStage = "", leadActivityImage = "";
String _selectedImage = "";
bool imageIsSelected = false;
bool locationLoading = false;
bool manualLocationFetchStart = false;

List<Map<String, String>> selectedParticipantList = [];
List<LeadParticipant> selectedParticipant = [];

List<Map<String, dynamic>> participantList = [];

class FooterPage extends StatefulWidget {
  final String leadsId, leadStageForEdit;
  const FooterPage({
    super.key,
    required this.leadsId,
    required this.leadStageForEdit,
  });
  static final GlobalKey<FooterPageState> footerPageKey =
      GlobalKey<FooterPageState>();

  @override
  FooterPageState createState() => FooterPageState();
}

class LeadMasterFooterPageProvider with ChangeNotifier {
  LeadMaster _leadMaster = LeadMaster(
    leadID: 0,
    customerPaymentTerms: 0,
    customerCode: '',
    customerCreditLimit: 0,
    customerMOV: 0,
    customerName: '',
    customerAddress: '',
    leadStageLevel: '',
    leadStage: 0,
    leadStartDate: '',
    leadAging: '',
    leadAssigneeName: '',
    leadHospitalCode: '',
    leadDistributorCode: '',
    leadAssigneeId: 0,
    leadDealValue: '',
    leadHospitalName: '',
    leadDistributorName: '',
    leadProductName: '',
    leadType: '',
  );

  LeadMaster get leadMaster => _leadMaster;
  void updateLeadMaster(LeadMaster newLeadMaster) {
    _leadMaster = newLeadMaster;
    notifyListeners(); // Notify listeners to rebuild widgets
  }
}

class LeadActivityFooterPageProvider with ChangeNotifier {
  List<LeadActivity> _leadActivity = [];
  List<LeadActivity> get leadActivity => _leadActivity;
  void updateLeadActivity(List<LeadActivity> newLeadActivity) {
    _leadActivity = newLeadActivity;
    notifyListeners();
  }
}

class FooterPageState extends State<FooterPage> {
  late Future<void> loadDataFuture;
  LeadMaster leadMaster = LeadMaster(
    leadID: 0,
    customerPaymentTerms: 0,
    customerCreditLimit: 0,
    customerMOV: 0,
    customerCode: '',
    customerName: '',
    customerAddress: '',
    leadStageLevel: '',
    leadStage: 0,
    leadStartDate: '',
    leadAging: '',
    leadAssigneeName: '',
    leadHospitalCode: '',
    leadDistributorCode: '',
    leadAssigneeId: 0,
    leadDealValue: '',
    leadHospitalName: '',
    leadDistributorName: '',
    leadProductName: '',
    leadType: '',
  );
  Timer? _timer;

  late stt.SpeechToText _speech;
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

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    leadId = widget.leadsId;
    leadStageForEdit = widget.leadStageForEdit;
    loadDataFuture = loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userName = prefs.getString('userName') ?? '';
    await _selectLeadsDetails(userId, userJwtToken, userMailID);
    await _selectLeadActivity(userId, userJwtToken, userMailID, userName);
    await _selectLeadActivityImage(userId, userJwtToken, userMailID);
    await _loadparticipant(userId, userJwtToken, userMailID);
    await getCurrentLocation();
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void clearControls() {
    leadMaster = LeadMaster(
      leadID: 0,
      customerPaymentTerms: 0,
      customerCreditLimit: 0,
      customerCode: '',
      customerMOV: 0,
      customerName: '',
      customerAddress: '',
      leadStageLevel: '',
      leadStage: 0,
      leadStartDate: '',
      leadAging: '',
      leadAssigneeName: '',
      leadHospitalCode: '',
      leadDistributorCode: '',
      leadAssigneeId: 0,
      leadDealValue: '',
      leadHospitalName: '',
      leadDistributorName: '',
      leadProductName: '',
      leadType: '',
    );
    leadContacts = [];
    followupDateControllerFooter.text = DateFormat(
      'dd/MM/yyyy hh:mm a',
    ).format(DateTime.now());
    summaryControllerFooter.text = "";
    selectedStatusFooter = 'Next Action';
    selectedParticipantFooter = [];
    selectedParticipantList = [];
    participantList = [];
    availableParticipant = [];
    initialParticipant = [];
    leadActivityId = "0";
    leadStageForEdit = "0";
    _selectedImage = "";
    latitudeFooter = '';
    longitudeFooter = '';
    locationControllerFooter.text = "";
  }

  Future<void> _selectLeadsDetails(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadId': leadId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectleadsdetails';
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
          if (data.isNotEmpty) {
            var masDataArray = data[0];
            if (masDataArray is List && masDataArray.isNotEmpty) {
              var masData = masDataArray[0];
              if (masData is Map) {
                setState(() {
                  context.read<LeadMasterFooterPageProvider>().updateLeadMaster(
                    LeadMaster.fromJson(masData as Map<String, dynamic>),
                  );
                });
              }
            }
          } else {}
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
          content: Text('Lead details not found for Lead ID: $widget.leadsId'),
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

  Future<void> _selectLeadActivity(
    String userId,
    String userJwtToken,
    String userMailID,
    String userName,
  ) async {
    selectedParticipantFooter = [];
    if (leadStageForEdit != "0") {
      final data = {
        'UserID': userId,
        'UserJwtToken': userJwtToken,
        'UsermailID': userMailID,
        'LoadFullCustomerData': 0,
        'LeadId': leadId,
        'LeadStage': leadStageForEdit,
        'LeadDate': "",
        'ShowScheduledOnly': 0,
      };

      const apiUrl = '${ApiHelper.baseUrl}selectleadsactivity';
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
            if (data.isNotEmpty) {
              if (data[0] is List && (data[0] as List).isNotEmpty) {
                List<LeadActivity> newLeadActivity = (data[0] as List)
                    .map((item) => LeadActivity.fromJson(item))
                    .toList();
                setState(() {
                  context
                      .read<LeadActivityFooterPageProvider>()
                      .updateLeadActivity(newLeadActivity);
                  summaryControllerFooter.text =
                      data[0][0]["LeadActivitySummary"].toString();
                  followupDateControllerFooter.text =
                      data[0][0]["LeadActivityFollowupDate"].toString();
                  latitudeFooter = data[0][0]["LeadActivityLatitude"]
                      .toString();
                  longitudeFooter = data[0][0]["LeadActivityLongitude"]
                      .toString();
                  locationControllerFooter.text =
                      data[0][0]["LeadActivityLocation"].toString();
                  selectedStatusFooter = data[0][0]["LeadActivityStatus"]
                      .toString();
                  selectedStatusFooter = selectedStatusFooter == ""
                      ? 'Next Action'
                      : selectedStatusFooter;
                  _leadStage = data[0][0]["LeadActivityStageLevel"].toString();
                  leadActivityId = data[0][0]["LeadActivityId"].toString();
                  List<dynamic> dataList = data[1];
                  if (dataList.isNotEmpty) {
                    List<Map<String, dynamic>> newParticipantList = [];
                    for (var item in data[1]) {
                      final participant = {
                        "ParticipantId": item["ParticipantId"].toString(),
                        "ParticipantName": item["ParticipantName"].toString(),
                      };
                      newParticipantList.add(participant);
                    }
                    setState(() {
                      participantList = newParticipantList;
                      initialParticipant = convertToList(participantList);
                    });
                  } else {
                    if (initialParticipant.isEmpty) {
                      List<Map<String, dynamic>> newParticipantList = [];
                      final participant = {
                        "ParticipantId": userId.toString(),
                        "ParticipantName": userName,
                      };
                      newParticipantList.add(participant);
                      setState(() {
                        participantList = newParticipantList;
                        initialParticipant = convertToList(participantList);
                      });
                    }
                  }
                });
              } else {
                clearControls();
              }
            } else {}
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
            content: Text('Leads activity details not found.'),
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
    } else {
      leadActivityId = "0";
      if (selectedParticipantFooter.isEmpty) {
        List<Map<String, dynamic>> newParticipantList = [];
        final participant = {
          "ParticipantId": userId.toString(),
          "ParticipantName": userName,
        };
        newParticipantList.add(participant);
        setState(() {
          participantList = newParticipantList;
          initialParticipant = convertToList(participantList);
        });
      }
    }
  }

  Future<void> _selectLeadActivityImage(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    imageIsSelected = false;
    if (leadStageForEdit != "0") {
      final data = {
        'UserID': userId,
        'UserJwtToken': userJwtToken,
        'UsermailID': userMailID,
        'LoadFullCustomerData': 0,
        'LeadId': leadId,
        'LeadStage': leadStageForEdit,
        'LeadDate': "",
      };

      const apiUrl = '${ApiHelper.baseUrl}selectleadsactivityimage';
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
            if (data.isNotEmpty) {
              if (data[0] is List && (data[0] as List).isNotEmpty) {
                setState(() {
                  _selectedImage = data[0][0]["LeadActivityImage"].toString();
                });
                if (_selectedImage != "null" && _selectedImage != "") {
                  imageIsSelected = true;
                }
              }
            } else {
              const snackBar = SnackBar(
                content: Text('Leads activity image not found...'),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
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
            content: Text('Leads activity image not found...'),
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
    } else {
      _selectedImage = "";
      leadActivityId = "0";
    }
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
      _updateLocation(locationSettings);
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error getting location: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _updateLocation(LocationSettings locationSettings) {
    // ignore: unused_local_variable
    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
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
          },
          onError: (e) {
            final snackBar = SnackBar(
              content: Text('Error in positionStream: $e'),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          },
        );
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

  Future<void> _loadparticipant(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
    };
    const apiUrl = '${ApiHelper.baseUrl}loadparticipant';
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
          List<Map<String, dynamic>> newParticipantList = [];
          for (var item in data[0]) {
            final participant = {
              "ParticipantId": item["ParticipantId"].toString(),
              "ParticipantName": item["ParticipantName"].toString(),
            };
            newParticipantList.add(participant);
          }
          setState(() {
            participantList = newParticipantList;
            availableParticipant = convertToList(participantList);
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
        const snackBar = SnackBar(
          content: Text('Participants details not found.'),
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
      // Choose platform-specific settings or use general LocationSettings
      final locationSettings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
              forceLocationManager: false,
            )
          : Platform.isIOS
          ? AppleSettings(accuracy: LocationAccuracy.high, distanceFilter: 0)
          : const LocationSettings(accuracy: LocationAccuracy.high);

      Position? position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
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
      if (mounted) {
        final snackBar = SnackBar(content: Text('Error getting location: $e'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> submitStageSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJwtToken = prefs.getString('userJwtToken') ?? '';
      final userMailID = prefs.getString('userMailID') ?? '';
      List<Map<String, Object>> selectedParticipantList =
          selectedParticipantFooter
              .whereType<LeadParticipant>()
              .map(
                (LeadParticipant item) => {
                  'ParticipantName': item.leadParticipantUserName,
                  'LeadParticipantId': '0',
                  'ParticipantId': item.leadParticipantUserId,
                },
              )
              .toList();

      if (selectedParticipantList.isEmpty) {
        selectedParticipantList = initialParticipant
            .whereType<LeadParticipant>()
            .map(
              (LeadParticipant item) => {
                'ParticipantName': item.leadParticipantUserName,
                'LeadParticipantId': '0',
                'ParticipantId': item.leadParticipantUserId,
              },
            )
            .toList();
      }
      final leadactivity = {
        'UserJwtToken': userJwtToken,
        'UsermailID': userMailID,
        'LeadID': _leadID,
        'LeadActivityId': leadActivityId,
        'LeadActivityStageLevel': _leadStage,
        'LeadActivitySummary': summaryControllerFooter.text,
        'LeadActivityFollowupDate': followupDateControllerFooter.text == ""
            ? DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())
            : followupDateControllerFooter.text,
        'LeadActivityLatitude': latitudeFooter,
        'LeadActivityLongitude': longitudeFooter,
        'LeadActivityLocation': locationControllerFooter.text,
        'LeadActivityStatus': selectedStatusFooter,
        'LeadActivityImage': _selectedImage,
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
            _leadID = "";
            _leadStage = "";
            _selectedImage = "";
            // _selectedImageFile = "";
            imageIsSelected = false;
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
            content: Text('Lead activity save failed.'),
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

  // void displayImage(BuildContext context, String selectedImage) {
  //   try {
  //     showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           content: SizedBox(
  //             height: selectedImage.isNotEmpty
  //                 ? (MediaQuery.of(context).size.height) * 0.68
  //                 : 200,
  //             child: SingleChildScrollView(
  //               physics: const AlwaysScrollableScrollPhysics(),
  //               child: Column(
  //                 children: [
  //                   Align(
  //                     alignment: Alignment.topRight,
  //                     child: IconButton(
  //                       icon: const Icon(Icons.cancel_presentation_rounded),
  //                       onPressed: () {
  //                         Navigator.of(context).pop(); // Close the image popup
  //                       },
  //                     ),
  //                   ),
  //                   Image(
  //                     image: MemoryImage(base64Decode(selectedImage)),
  //                     fit: BoxFit.cover,
  //                     filterQuality: FilterQuality.high,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     print('Error decoding base64 image: $e');
  //   }
  // }

  // Future<void> openGallery(BuildContext context) async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  //   if (pickedFile != null) {
  //     List<int> imageBytes = await pickedFile.readAsBytes();
  //     String base64Image = base64Encode(imageBytes);
  //     setState(() {
  //       _selectedImage = base64Image;
  //       // _selectedImageFile = pickedFile.name;
  //     });
  //     displayImage(context, _selectedImage);
  //     Navigator.of(context).pop();
  //   }
  // }

  // Future<void> openCamera(BuildContext context) async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(source: ImageSource.camera);

  //   if (pickedFile != null) {
  //     List<int> imageBytes = await pickedFile.readAsBytes();
  //     String base64Image = base64Encode(imageBytes);
  //     setState(() {
  //       _selectedImage = base64Image;
  //       // _selectedImageFile = pickedFile.name;
  //     });
  //     displayImage(context, _selectedImage);
  //     Navigator.of(context).pop();
  //   }
  // }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      if (mounted) {
        leadMaster = LeadMaster(
          leadID: 0,
          customerPaymentTerms: 0,
          customerCreditLimit: 0,
          customerCode: '',
          customerMOV: 0,
          customerName: '',
          customerAddress: '',
          leadStageLevel: '',
          leadStage: 0,
          leadStartDate: '',
          leadAging: '',
          leadAssigneeName: '',
          leadHospitalCode: '',
          leadDistributorCode: '',
          leadAssigneeId: 0,
          leadDealValue: '',
          leadHospitalName: '',
          leadDistributorName: '',
          leadProductName: '',
          leadType: '',
        );
        leadContacts = [];
        followupDateControllerFooter.text = DateFormat(
          'dd/MM/yyyy hh:mm a',
        ).format(DateTime.now());
        summaryControllerFooter.text = "";
        selectedStatusFooter = 'Next Action';
        selectedParticipantFooter = [];
        selectedParticipantList = [];
        participantList = [];
        availableParticipant = [];
        initialParticipant = [];
        leadActivityId = "0";
        leadStageForEdit = "0";
        _selectedImage = "";
      }
      super.dispose();
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<void>(
          future: loadDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else {
              return footerHome(leadId);
            }
          },
        ),
      ),
    );
  }

  Widget footerHome(String leadsId) {
    LeadMaster leadMaster = context
        .watch<LeadMasterFooterPageProvider>()
        .leadMaster;
    _leadID = leadMaster.leadID.toString();
    _leadStage = leadMaster.leadStage.toString();
    final screenWidth = MediaQuery.of(context).size.width;
    final textFieldDropDownWidth = screenWidth * 0.92;
    final textFieldWidth = screenWidth * 0.9;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0, bottom: 0),
        child: Column(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          Visibility(
                            visible: locationControllerFooter.text == "",
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  manualLocationFetchStart = true;
                                });
                                getCurrentLocation();
                              },
                              icon: locationLoading && manualLocationFetchStart
                                  ? const CircularProgressIndicator()
                                  : const Icon(
                                      Icons.location_on,
                                      color: Color(0xFF2CA9DF),
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
                          stageNumber: widget.leadStageForEdit,
                          selectedParticipantFooter: selectedParticipantFooter,
                          availableParticipant: availableParticipant,
                          initialParticipant: initialParticipant,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
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
                            _isSummaryListening ? Icons.mic : Icons.mic_none,
                          ),
                          onPressed: () {
                            _listen(
                              summaryControllerFooter,
                              _isSummaryListening,
                              (bool isListening) {
                                _isSummaryListening = isListening;
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
                  padding: const EdgeInsets.only(left: 10.0, right: 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Container(
                                    width: textFieldDropDownWidth / 3.18,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey,
                                        ), // Add bottom border
                                      ),
                                    ),
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: selectedStatusFooter,
                                      hint: const Text(
                                        "Next Action ",
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
                                          selectedStatusFooter = newValue;
                                        });
                                      },
                                      underline:
                                          Container(), // Remove the default underline
                                      icon: const Icon(Icons.search, size: 20),
                                      items:
                                          <String>[
                                            'Next Action',
                                            'Sampling',
                                            'Re Sampling',
                                            'Approved',
                                            'Rejected',
                                          ].map<DropdownMenuItem<String>>((
                                            String value,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: textFieldWidth / 1.6,
                                  padding: const EdgeInsets.only(
                                    left: 10.0,
                                    right: 0.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "On",
                                        style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xff454545),
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              followupDateControllerFooter,
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            hintText: DateFormat(
                                              'dd/MM/yyyy hh:mm a',
                                            ).format(DateTime.now()),
                                            border:
                                                const UnderlineInputBorder(),
                                            hintStyle: const TextStyle(
                                              fontFamily: "Poppins",
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xff454545),
                                              height: 12 / 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 10.0,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.calendar_month_outlined,
                                          ),
                                          onPressed: () async {
                                            DateTime?
                                            selectedDate = await showDatePicker(
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
    );
  }
}

class MultiLevelDropDown extends StatefulWidget {
  final List<LeadParticipant> selectedParticipantFooter;
  final List<LeadParticipant> availableParticipant;
  final List<LeadParticipant> initialParticipant;
  final String stageNumber;
  // ignore: prefer_const_constructors_in_immutables
  MultiLevelDropDown({
    super.key,
    required this.selectedParticipantFooter,
    required this.availableParticipant,
    required this.initialParticipant,
    required this.stageNumber,
  });

  @override
  State<MultiLevelDropDown> createState() => _MultiLevelDropDownState();
}

class _MultiLevelDropDownState extends State<MultiLevelDropDown> {
  final _participant = availableParticipant
      .map(
        (participant) => MultiSelectItem<LeadParticipant>(
          participant,
          participant.leadParticipantUserName,
        ),
      )
      .toList();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 240, 240),
      body: SingleChildScrollView(
        child: Container(
          height: null,
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
          child: Column(
            children: <Widget>[
              MultiSelectDialogField(
                listType: MultiSelectListType.CHIP,
                initialValue: availableParticipant.where((element) {
                  return initialParticipant.any(
                    (selected) =>
                        selected.leadParticipantUserId ==
                        element.leadParticipantUserId,
                  );
                }).toList(),
                separateSelectedItems: true,
                items: _participant,
                title: const Text("Participants"),
                selectedColor: const Color(0xff2ca9df),
                decoration: BoxDecoration(
                  color: const Color(0xffCFCFCF).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(0)),
                  border: Border.all(color: const Color(0xffCFCFCF), width: 2),
                ),
                buttonIcon: const Icon(
                  Icons.people_alt_outlined,
                  color: Color(0xff454545),
                ),
                buttonText: const Text(
                  "Select Participant",
                  style: TextStyle(
                    color: Color(0xFF454545),
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                onConfirm: (results) {
                  setState(() {
                    selectedParticipantFooter = results;
                    selectedParticipant = results;
                    initialParticipant = selectedParticipant;
                  });
                },
                selectedItemsTextStyle: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    initialParticipant = [];
    super.dispose();
  }
}
