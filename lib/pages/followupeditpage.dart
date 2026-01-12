// ignore_for_file: avoid_print, use_build_context_synchronously, dead_code
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/leadstages/finalstage.dart';
import 'package:optima/leadstages/stagefiveentry.dart';
import 'package:optima/leadstages/stagefourentry.dart';
import 'package:optima/leadstages/stageoneentry.dart';
import 'package:optima/leadstages/stagesixentry.dart';
import 'package:optima/leadstages/stagethreeentry.dart';
import 'package:optima/login_screen.dart';
import 'package:optima/pages/customerdatapage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optima/leadstages/stagetwoentry.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:optima/classes/leads.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

String leadId = "";
String leadStageForEdit = "";
String leadActivityId = "0";
String _leadID = "", _leadStage = "", leadActivityImage = "";
String? _selectedValue;
String? _selectedStatus;
Stage? _selectedStage;
String _selectedImage = "";
String _latitude = "";
String _longitude = "";
// String _selectedImageFile = "";
bool imageIsSelected = false;

List<Map<String, String>> selectedParticipantList = [];
List<LeadParticipant> selectedParticipant = [];

List<Map<String, dynamic>> participantList = [];
List<LeadParticipant> availableParticipant = [];
List<LeadParticipant> initialParticipant = [];

final TextEditingController _summaryController = TextEditingController();
final TextEditingController _followupDateController = TextEditingController();
final TextEditingController _locationController = TextEditingController();

class FollowUpPage extends StatefulWidget {
  final String leadsId, leadStageForEdit;
  const FollowUpPage({
    super.key,
    required this.leadsId,
    required this.leadStageForEdit,
  });
  static final GlobalKey<FollowUpPageState> followUpPageKey =
      GlobalKey<FollowUpPageState>();

  @override
  FollowUpPageState createState() => FollowUpPageState();
}

class Stage {
  final String name;
  final int value;
  final bool selectable;
  Stage(this.name, this.value, this.selectable);
}

List<Stage> stages = [
  Stage('Stages', 0, false),
  Stage('Stage 1 - Lead Details Entry - Contact Details', 1, true),
  Stage('Stage 2 - Sample Data Collection', 2, true),
  Stage('Stage 3 - Sample Submission', 3, true),
  Stage('Stage 4 - Sample Feedback', 4, true),
  Stage('Stage 5 - Quotation', 5, true),
  Stage('Stage 6 - Order', 6, true),
  Stage('Final Stage', 7, true),
];

class LeadMasterFollowUpProvider with ChangeNotifier {
  LeadMaster _leadMaster = LeadMaster(
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

  LeadMaster get leadMaster => _leadMaster;
  void updateLeadMaster(LeadMaster newLeadMaster) {
    _leadMaster = newLeadMaster;
    notifyListeners(); // Notify listeners to rebuild widgets
  }
}

class LeadContactFollowUpProvider with ChangeNotifier {
  List<LeadContact> _leadContacts = [];
  List<LeadContact> get leadContacts => _leadContacts;
  void updateLeadContacts(List<LeadContact> newLeadContacts) {
    _leadContacts = newLeadContacts;
    notifyListeners();
  }
}

class FollowUpPageState extends State<FollowUpPage> {
  late Future<void> loadDataFuture;
  List<LeadContact> leadContacts = [];
  LeadMaster leadMaster = LeadMaster(
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
  @override
  void initState() {
    super.initState();
    loadDataFuture = loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userName = prefs.getString('userName') ?? '';
    await _loadparticipant(userId, userJwtToken, userMailID);
    await _assignStageSelectable(userId, userJwtToken, userMailID);
    await _selectLeadsDetails(userId, userJwtToken, userMailID);
    await _selectLeadActivity(userId, userJwtToken, userMailID, userName);
    await _selectLeadActivityImage(userId, userJwtToken, userMailID);
    await getLocation();
  }

  Future<void> _assignStageSelectable(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    leadId = widget.leadsId;
    leadStageForEdit = widget.leadStageForEdit;
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadId': widget.leadsId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectselectablestages';
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
          List<dynamic> data = responseJson['Data'];
          bool stage1Selectable = true,
              stage2Selectable = true,
              stage3Selectable = true,
              stage4Selectable = true,
              stage5Selectable = true,
              stage6Selectable = true,
              stage7Selectable = true;
          for (var item in data) {
            stage1Selectable = item[0]["Stage1Selectable"] == 1;
            stage2Selectable = item[0]["Stage2Selectable"] == 1;
            stage3Selectable = item[0]["Stage3Selectable"] == 1;
            stage4Selectable = item[0]["Stage4Selectable"] == 1;
            stage5Selectable = item[0]["Stage5Selectable"] == 1;
            stage6Selectable = item[0]["Stage6Selectable"] == 1;
            stage7Selectable = item[0]["Stage7Selectable"] == 1;
          }
          setState(() {
            stages = [
              Stage('Stages', 0, false),
              Stage(
                'Stage 1 - Lead Details Entry - Contact Details',
                1,
                stage1Selectable,
              ),
              Stage('Stage 2 - Sample Data Collection', 2, stage2Selectable),
              Stage('Stage 3 - Sample Submission', 3, stage3Selectable),
              Stage('Stage 4 - Sample Feedback', 4, stage4Selectable),
              Stage('Stage 5 - Quotation', 5, stage5Selectable),
              Stage('Stage 6 - Order', 6, stage6Selectable),
              Stage('Final Stage', 7, stage7Selectable),
            ];
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
        final snackBar = SnackBar(
          content: Text('HTTP Error: ${response.statusCode}'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('$e'));
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

  Future<void> _selectLeadsDetails(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    leadId = widget.leadsId;
    final data = {
      'UserID': userId,
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadId': widget.leadsId,
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
                  context.read<LeadMasterFollowUpProvider>().updateLeadMaster(
                    LeadMaster.fromJson(masData as Map<String, dynamic>),
                  );
                });
              }
            }
            if (data.length > 1 && data[1] is List) {
              List<LeadContact> newLeadContacts = (data[1] as List)
                  .map((item) => LeadContact.fromJson(item))
                  .toList();
              setState(() {
                context.read<LeadContactFollowUpProvider>().updateLeadContacts(
                  newLeadContacts,
                );
              });
            }
          } else {
            const snackBar = SnackBar(
              content: Text('Leads details not found.'),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
        final snackBar = SnackBar(
          content: Text('HTTP Error: ${response.statusCode}'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('$e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _selectLeadActivity(
    String userId,
    String userJwtToken,
    String userMailID,
    String userName,
  ) async {
    selectedParticipant = [];
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
              if (data[0] is List) {
                List<LeadActivity> newLeadActivity = (data[0] as List)
                    .map((item) => LeadActivity.fromJson(item))
                    .toList();
                setState(() {
                  context
                      .read<LeadActivityFollowupProvider>()
                      .updateLeadActivity(newLeadActivity);
                  _summaryController.text = data[0][0]["LeadActivitySummary"]
                      .toString();
                  _followupDateController.text =
                      data[0][0]["LeadActivityFollowupDate"].toString();
                  _latitude = data[0][0]["LeadActivityLatitude"].toString();
                  _longitude = data[0][0]["LeadActivityLongitude"].toString();
                  _locationController.text = data[0][0]["LeadActivityLocation"]
                      .toString();
                  _selectedStatus = data[0][0]["LeadActivityStatus"].toString();
                  _selectedStatus = _selectedStatus == ""
                      ? 'Next Action'
                      : _selectedStatus;
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
              }
            } else {
              const snackBar = SnackBar(
                content: Text('Leads activity details not found.'),
              );
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
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              navigateToLoginScreen();
            } else {
              final snackBar = SnackBar(
                content: Text(responseJson["Error"].toString()),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          }
        }
      } catch (e) {
        final snackBar = SnackBar(content: Text('$e'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      leadActivityId = "0";
      if (selectedParticipant.isEmpty) {
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
              if (data[0] is List) {
                setState(() {
                  _selectedImage = data[0][0]["LeadActivityImage"].toString();
                });
                if (_selectedImage != "null" && _selectedImage != "") {
                  imageIsSelected = true;
                }
              }
            } else {
              const snackBar = SnackBar(content: Text('No image found...'));
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
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              navigateToLoginScreen();
            } else {
              final snackBar = SnackBar(
                content: Text(responseJson["Error"].toString()),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          }
        }
      } catch (e) {
        final snackBar = SnackBar(content: Text('$e'));
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

      // ignore: unused_local_variable
      StreamSubscription<Position> positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) async {
            _latitude = position.latitude.toString();
            _longitude = position.longitude.toString();
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
              _locationController.text = location;
              //location;
            } else {
              _locationController.clear();
            }
          });
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error getting location: $e'));
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
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('$e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  void dispose() {
    try {
      if (mounted) {
        leadMaster = LeadMaster(
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
        leadContacts = [];
        _followupDateController.text = DateFormat(
          'dd/MM/yyyy hh:mm a',
        ).format(DateTime.now());
        _summaryController.text = "";
        _selectedStatus = 'Next Action';
        selectedParticipant = [];
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
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return followUpHome(widget.leadsId);
            }
          },
        ),
      ),
    );
  }

  Widget followUpHome(String leadsId) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CustomerData(leadsId: leadsId)),
            );
          },
        ),
        backgroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        child: Center(
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(children: <Widget>[Header(), Footer()]),
          ),
        ),
      ),
    );
  }
}

class ContacteeList extends StatelessWidget {
  const ContacteeList({super.key});

  @override
  Widget build(BuildContext context) {
    LeadContactProvider leadContactProvider = context
        .watch<LeadContactProvider>();
    List<LeadContact> leadContacts = leadContactProvider.leadContacts;
    final screenWidth = MediaQuery.of(context).size.width;
    final textFieldWidth = screenWidth;
    return InkWell(
      onTap: () {
        // Handle the tap event
      },
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (var item in leadContacts)
              SizedBox(
                width: textFieldWidth,
                height: 35,
                child: Container(
                  padding: const EdgeInsets.only(
                    bottom: 0,
                    top: 0,
                    left: 0,
                    right: 0,
                  ),
                  decoration: const BoxDecoration(color: Color(0xFFCCF0FF)),
                  child: ListTile(
                    title: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Row(
                        children: [
                          const Icon(Icons.person_4_outlined, size: 16.0),
                          Expanded(
                            child: Text(
                              item.leadContactName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Color(0xFF454545),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.add_moderator_outlined, size: 16.0),
                          Expanded(
                            child: Text(
                              item.leadContactDepartment,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Color(0xFF454545),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.add_moderator_outlined, size: 16.0),
                          Expanded(
                            child: Text(
                              item.leadContactDesignation,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Color(0xFF454545),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    LeadMaster leadMaster = context
        .watch<LeadMasterFollowUpProvider>()
        .leadMaster;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFCCF0FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 15.0,
                right: 0,
                top: 10,
                bottom: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "${leadMaster.leadID} ",
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Color(0xFF454545),
                              ),
                            ),
                            const WidgetSpan(
                              child: SizedBox(
                                width: 30,
                              ), // Adjust the width as needed
                            ),
                            TextSpan(
                              text:
                                  "${leadMaster.leadStartDate.substring(0, 10)} ",
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Color(0xFF454545),
                              ),
                            ),
                            const WidgetSpan(
                              child: SizedBox(
                                width: 30,
                              ), // Adjust the width as needed
                            ),
                            TextSpan(
                              text: leadMaster.leadAging,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Color(0xFF454545),
                              ),
                            ),
                            const WidgetSpan(
                              child: SizedBox(
                                width: 30,
                              ), // Adjust the width as needed
                            ),
                            const TextSpan(
                              text: "Lead Value",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Color(0xFF454545),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
          const SizedBox(height: 1),
          const SizedBox(height: 85, child: ContacteeList()),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}

class LeadActivityFollowupProvider with ChangeNotifier {
  List<LeadActivity> _leadActivity = [];
  List<LeadActivity> get leadActivity => _leadActivity;
  void updateLeadActivity(List<LeadActivity> newLeadActivity) {
    _leadActivity = newLeadActivity;
    notifyListeners();
  }
}

class Footer extends StatefulWidget {
  const Footer({super.key});

  @override
  FooterState createState() => FooterState();
}

class FooterState extends State<Footer> {
  @override
  void initState() {
    super.initState();
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
            _latitude = position.latitude.toString();
            _longitude = position.longitude.toString();
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
              _locationController.text = location;
            } else {
              _locationController.clear();
            }
          });
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error getting location: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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
      _latitude = position.latitude.toString();
      _longitude = position.longitude.toString();
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
        _locationController.text = location;
      } else {
        _locationController.clear();
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error getting location: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void navigateToStagePage(int selectedStage) {
    switch (selectedStage) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageOneLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageTwoLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageThreeLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageFourLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageFiveLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 6:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StageSixLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
      case 7:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FinalLeadEntryPage(leadsId: leadId),
          ),
        );
        break;
    }
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> submitStageSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    List<Map<String, Object>> selectedParticipantList = selectedParticipant
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
      'LeadActivitySummary': _summaryController.text,
      'LeadActivityFollowupDate': _followupDateController.text == ""
          ? DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now())
          : _followupDateController.text,
      'LeadActivityLatitude': _latitude,
      'LeadActivityLongitude': _longitude,
      'LeadActivityLocation': _locationController.text,
      'LeadActivityStatus': _selectedStatus,
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
          _summaryController.clear();
          _followupDateController.text = DateFormat(
            'dd/MM/yyyy hh:mm a',
          ).format(DateTime.now());
          _selectedStatus = 'Next Action';
          _leadID = "";
          _leadStage = "";
          _selectedImage = "";
          // _selectedImageFile = "";
          imageIsSelected = false;
          setState(() {
            selectedParticipantList.clear();
            selectedParticipantList = [];
            selectedParticipant.clear();
            selectedParticipant = [];
          });
          const snackBar = SnackBar(
            duration: Duration(seconds: 1),
            content: Text(
              'Saved Successfully...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
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
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            navigateToLoginScreen();
          } else {
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 1),
        content: Text('$e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    LeadMaster leadMaster = context
        .watch<LeadMasterFollowUpProvider>()
        .leadMaster;
    _leadID = leadMaster.leadID.toString();
    _leadStage = leadMaster.leadStage.toString();
    final screenWidth = MediaQuery.of(context).size.width;
    final textFieldDropDownWidth = screenWidth * 0.92;
    final textFieldWidth = screenWidth * 0.9;

    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 0.0),
            child: Container(
              width: textFieldDropDownWidth,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedValue,
                  hint: const Text('Stages'),
                  onChanged: (String? newValue) {
                    if (stages
                        .firstWhere(
                          (stage) => stage.name == newValue,
                          orElse: () => Stage('Stages', 0, false),
                        )
                        .selectable) {
                      setState(() {
                        _selectedValue = newValue;
                        _selectedStage = stages.firstWhere(
                          (stage) => stage.name == newValue,
                          orElse: () => Stage('Stages', 0, false),
                        );
                        if (newValue != null) {
                          navigateToStagePage(_selectedStage!.value);
                        }
                      });
                    }
                  },
                  underline: Container(),
                  items: stages.map<DropdownMenuItem<String>>((Stage stage) {
                    final isSelectable = stage.selectable;
                    return DropdownMenuItem<String>(
                      value: stage.name,
                      onTap: isSelectable ? () {} : null,
                      child: Text(
                        stage.name,
                        style: isSelectable
                            ? const TextStyle(color: Colors.black)
                            : const TextStyle(color: Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Participant',
                      style: TextStyle(color: Color(0xFF454545)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      width: textFieldDropDownWidth,
                      child: MultiLevelDropDown(
                        selectedParticipant: selectedParticipant,
                        availableParticipant: availableParticipant,
                        initialParticipant: initialParticipant,
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: SizedBox(
                  width: textFieldDropDownWidth,
                  height: 80,
                  child: TextField(
                    controller: _summaryController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Summary of Discussion.',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.only(left: 10.0, top: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: textFieldDropDownWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _locationController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Enter Location',
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.location_on_outlined),
                                  color: Colors.grey,
                                  onPressed: getCurrentLocation,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          child: Row(
                            children: [
                              Container(
                                width: textFieldDropDownWidth / 2.97,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey,
                                    ), // Add bottom border
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10.0),
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _selectedStatus,
                                    hint: const Text(
                                      'Next Action',
                                    ), // Placeholder
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedStatus = newValue;
                                      });
                                    },
                                    underline:
                                        Container(), // Remove the default underline
                                    icon: const Icon(Icons.search),
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
                                width: textFieldWidth / 1.4,
                                padding: const EdgeInsets.only(
                                  left: 20.0,
                                  right: 0.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'On ',
                                      style: TextStyle(fontSize: 14.0),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _followupDateController,
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          hintText: DateFormat(
                                            'dd/MM/yyyy hh:mm a',
                                          ).format(DateTime.now()),
                                          border: const UnderlineInputBorder(),
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
                                          _followupDateController.text =
                                              formattedDateTime;
                                        }
                                      },
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (_locationController.text == "") {
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
                            await submitStageSummary();
                            Navigator.of(dialogContext!).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomerData(leadsId: leadId),
                              ),
                            );
                          } catch (error) {
                            // print('Error: $error');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2CA9DF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(15.0),
                        textStyle: const TextStyle(fontSize: 16),
                        minimumSize: Size(textFieldDropDownWidth, 50.0),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class MultiLevelDropDown extends StatefulWidget {
  final List<LeadParticipant> selectedParticipant;
  final List<LeadParticipant> availableParticipant;
  final List<LeadParticipant> initialParticipant;
  // ignore: prefer_const_constructors_in_immutables
  MultiLevelDropDown({
    super.key,
    required this.selectedParticipant,
    required this.availableParticipant,
    required this.initialParticipant,
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
      backgroundColor: Colors.grey.shade300,
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
                selectedColor: Colors.blue,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(40)),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                buttonIcon: const Icon(
                  Icons.people_alt_outlined,
                  color: Colors.blue,
                ),
                buttonText: const Text(
                  "Select Participant",
                  style: TextStyle(color: Color(0xFF454545), fontSize: 16),
                ),
                onConfirm: (results) {
                  setState(() {
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
