// ignore_for_file: use_build_context_synchronously, avoid_print, non_constant_identifier_names, deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:optima/classes/globals.dart';
import 'package:optima/login_screen.dart';
import 'package:optima/pages/footer.dart';
import 'package:optima/pages/header.dart';
import 'package:optima/tabs/tabspage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_helper.dart';
import 'package:optima/classes/leads.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'package:intl/intl.dart';
import '../classes/footerConstants.dart';

String leadId = "";
String deviceOrientation = "";
List<Map<String, String>> contactList = [];
List<Map<String, String>> selectedParticipantList = [];
List<LeadParticipant> selectedParticipantStg1 = [];
String? selectedStatusStg1;
bool summarySave = false;

List<Map<String, dynamic>> customerList = [];

class StageOneLeadEntryPage extends StatefulWidget {
  final String leadsId;
  const StageOneLeadEntryPage({super.key, required this.leadsId});

  static final GlobalKey<StageOneLeadEntryPageState> stageOnePageKey =
      GlobalKey<StageOneLeadEntryPageState>();

  @override
  StageOneLeadEntryPageState createState() => StageOneLeadEntryPageState();
}

class LeadMasterStage1Provider with ChangeNotifier {
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
    leadHospitalName: '',
    leadDistributorCode: '',
    leadDistributorName: '',
    leadAssigneeId: 0,
    leadDealValue: '',
    leadProductName: '',
    leadType: '',
  );

  LeadMaster get leadMaster => _leadMaster;
  void updateLeadMaster(LeadMaster newLeadMaster) {
    _leadMaster = newLeadMaster;
    notifyListeners(); // Notify listeners to rebuild widgets
  }
}

class LeadContactStage1Provider with ChangeNotifier {
  List<LeadContact> _leadContacts = [];
  List<LeadContact> get leadContacts => _leadContacts;
  void updateLeadContacts(List<LeadContact> newLeadContacts) {
    _leadContacts = newLeadContacts;
    notifyListeners();
  }
}

class Hospital {
  String CustomerName;
  String CustomerCode;
  Hospital({required this.CustomerCode, required this.CustomerName});
}

class Distributor {
  String CustomerName;
  String CustomerCode;
  Distributor({required this.CustomerCode, required this.CustomerName});
}

class Contacts {
  String CustomerName;
  String CustomerCode;
  Contacts({required this.CustomerCode, required this.CustomerName});
}

class AssignedList {
  String UserId;
  String UserName;
  AssignedList({required this.UserId, required this.UserName});
}

class StageOneLeadEntryPageState extends State<StageOneLeadEntryPage> {
  late Future<void> loadDataFuture;
  bool _mounted = false;
  bool moveFlag = false;
  List<Map<String, dynamic>> distributorList = [];
  List<Map<String, dynamic>> contactMasterList = [];
  List<Map<String, dynamic>> assigneeList = [];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();

  String selectedHospitalId = "";
  String selectedHospitalName = "";
  String selectedDistributorId = "";
  String selectedDistributorName = "";
  String selectedContactId = "";
  String selectedAssigneeId = "";
  String selectedAssigneeName = "";
  String selectedLeadContactId = "";

  bool selectedValue = true;
  List<String> dealValues = [
    'Select Deal Value',
    'Deal Value < 50,000',
    '50,001 - 2,00,000',
    '> 2,00,000',
    // Add more deal values as needed
  ];
  String selectedDealValue = 'Select Deal Value';
  String defaultAssigneeName = 'Assigned to';
  Map<String, dynamic> defaultAssignee = {
    'UserName': 'Assigned to',
    'UserID': '0',
  };

  bool isDark = false;
  final TextEditingController assignedToController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();
  final TextEditingController _searchController3 = TextEditingController();
  final TextEditingController _searchController4 = TextEditingController();

  bool isEditMode = false;
  String selectedOption = 'Option 1';
  String selectedAssignee = "";
  bool isDropdownOpen = false;
  List<ProductList> selectedProducts = [];
  List<LeadContact> leadContacts = [];
  LeadMaster leadMaster = LeadMaster(
    leadID: 0,
    customerCode: '',
    customerPaymentTerms: 0,
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

  final ScrollController scrollController = ScrollController();
  final ScrollController stageController = ScrollController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey hospitalKey = GlobalKey();
  final GlobalKey distributorKey = GlobalKey();
  final GlobalKey contactKey = GlobalKey();
  final GlobalKey assignedToKey = GlobalKey();
  final GlobalKey saveKey = GlobalKey();
  final GlobalKey footerKey = GlobalKey();

  static final FocusNode _focusHospital = FocusNode();
  static final FocusNode _focusAssignedTo = FocusNode();
  static final FocusNode _focusDistributor = FocusNode();
  static final FocusNode _focusContact = FocusNode();

  @override
  void dispose() {
    searchController.dispose();
    _searchController2.dispose();
    _searchController3.dispose();
    _searchController4.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    scrollController.dispose();
    stageController.dispose();
    contactList.clear();
    contactList = [];
    _mounted = false;
    selectedParticipantFooter = [];
    summaryControllerFooter.clear();
    followupDateControllerFooter.text = DateFormat(
      'dd/MM/yyyy hh:mm a',
    ).format(DateTime.now());
    selectedStatusFooter = 'Next Action';
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    contactList.clear();
    contactList = [];
    isEditMode = false;
    leadId = widget.leadsId;
    if (isUserLoggedIn) {
      loadDataFuture = loadData();
    }
    _focusHospital.addListener(_handleFocusChange);
    _focusDistributor.addListener(_handleFocusChange);
    _focusContact.addListener(_handleFocusChange);
    _focusAssignedTo.addListener(_handleFocusChange);
    _mounted = true;
  }

  void _handleFocusChange() {
    if (_focusHospital.hasFocus != _focusedHospital) {
      setState(() {
        _focusedHospital = _focusHospital.hasFocus;
      });
    }
    if (_focusDistributor.hasFocus != _focusedDistributor) {
      setState(() {
        _focusedDistributor = _focusDistributor.hasFocus;
      });
    }
    if (_focusContact.hasFocus != _focusedContact) {
      setState(() {
        _focusedContact = _focusContact.hasFocus;
      });
    }
    if (_focusAssignedTo.hasFocus != _focusedAssignedTo) {
      setState(() {
        _focusedAssignedTo = _focusAssignedTo.hasFocus;
      });
    }
  }

  bool _focusedHospital = false;
  bool _focusedDistributor = false;
  bool _focusedContact = false;
  bool _focusedAssignedTo = false;

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';

    await _loadcustomer(userId, userJwtToken, userMailID);
    await _loaddistributor(userId, userJwtToken, userMailID);
    await _loadleadassignees(userId, userJwtToken, userMailID);
    await _selectLeadsDetails(userId, userJwtToken, userMailID);
  }

  void _clearControls() {
    setState(() {
      _searchController4.clear();
      _emailController.clear();
      _phoneController.clear();
      _departmentController.clear();
      _designationController.clear();
      selectedValue = true;
      selectedDealValue = 'Select Deal Value';
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

  bool isValidPhoneNumber(String phoneNumber) {
    RegExp regex = RegExp(r'^(\+91[\-\s]?)?\s*?[6-9]\d{9}$');

    return regex.hasMatch(phoneNumber);
  }

  Future<void> _selectLeadsDetails(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    if (widget.leadsId != "0") {
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
              if (masDataArray.isNotEmpty && masDataArray is List) {
                var masData = masDataArray[0];
                if (masData is Map) {
                  setState(() {
                    context.read<LeadMasterStage1Provider>().updateLeadMaster(
                      LeadMaster.fromJson(masData as Map<String, dynamic>),
                    );
                    searchController.text = masData['CustomerName'].toString();
                    assignedToController.text = masData['UserName'].toString();
                    selectedHospitalId = masData['LeadHospitalCode'].toString();
                    _searchController2.text = masData['DistributorName']
                        .toString();
                    selectedDistributorId = masData['LeadDistributorCode']
                        .toString();
                    _searchController4.text = masData['UserName'].toString();
                    selectedAssigneeName = masData['UserName'].toString();
                    selectedAssigneeId = masData['LeadAssigneeId'].toString();
                    selectedDealValue = masData['LeadDealValue'].toString();
                    isEditMode = true;
                  });
                }
              }
              if (data.isNotEmpty && data[1] is List) {
                List<LeadContact> newLeadContacts = (data[1] as List)
                    .map((item) => LeadContact.fromJson(item))
                    .toList();
                setState(() {
                  context.read<LeadContactStage1Provider>().updateLeadContacts(
                    newLeadContacts,
                  );
                  contactList = convertLeadContactsToMapList(newLeadContacts);
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
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
            : selectedContactId, //Id from CustomerContactPerson table
        "leadContactParentId": selectedLeadContactId == ''
            ? '0'
            : selectedLeadContactId,
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
    } else {
      const snackBar = SnackBar(
        content: Text(
          'Contact details are missing. Please fill in the contact details.',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _loadcustomer(
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
        // int dataLength = data.length;
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
        // int dataLength = data.length;
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

  Future<void> _loadleadassignees(
    String userId,
    String userJwtToken,
    String userMailID,
  ) async {
    final data = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'UserID': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectleadassignees';
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
          List<Map<String, dynamic>> newAssigneeList = [];
          for (var item in data) {
            final cont = {
              "UserID": item["UserID"],
              "UserName": item["UserName"],
            };
            newAssigneeList.add(cont);
          }
          setState(() {
            assigneeList = newAssigneeList;
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

  Future<void> submitLeads() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    final userId = prefs.getString('userId') ?? '';

    final leadmaster = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadID': leadId,
      'LeadUserId': userId,
      'LeadHospitalCode': selectedHospitalId,
      'LeadHospitalName': searchController.text,
      'LeadDistributorCode': selectedDistributorId,
      'LeadDistributorName': _searchController2.text,
      'LeadAssigneeId': selectedAssigneeId,
      'LeadDealValue': selectedDealValue,
      'LeadStatus': 'A',
      'LeadType': 'L',
      'contactList': contactList,
      'participantList': selectedParticipantList,
      'productList': selectedProducts,
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
          if (_mounted) {
            searchController.clear();
            _searchController2.clear();
            _searchController4.clear();
            selectedDealValue = 'Select Deal Value';
            isEditMode = false;
            summarySave = false;
            setState(() {
              contactList.clear();
              contactList = [];
              selectedParticipantFooter = [];
            });
          }
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
      final snackBar = SnackBar(content: Text('$e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> submitStageSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    summarySave = false;
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

    if (selectedParticipantList.isEmpty) {
      selectedParticipantList = initialParticipant
          .whereType<LeadParticipant>()
          .map(
            (LeadParticipant item) => {
              'ParticipantName': item.leadParticipantUserName,
              'LeadParticipantId': 0,
              'ParticipantId': item.leadParticipantUserId,
            },
          )
          .toList();
    }
    final leadactivity = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'LeadID': leadId,
      'LeadActivityId': leadActivityId,
      'LeadActivityStageLevel': "1",
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
          summarySave = true;
          summaryControllerFooter.clear();
          followupDateControllerFooter.text = DateFormat(
            'dd/MM/yyyy hh:mm a',
          ).format(DateTime.now());
          selectedStatusFooter = 'Next Action';
          leadId = "";
          imageIsSelected = false;
          setState(() {
            selectedParticipantList.clear();
            selectedParticipantList = [];
            selectedParticipantFooter.clear();
            selectedParticipantFooter = [];
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
      final snackBar = SnackBar(
        duration: const Duration(seconds: 1),
        content: Text('$e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  List<Map<String, String>> convertLeadContactsToMapList(
    List<LeadContact> leadContacts,
  ) {
    return leadContacts.map((leadContact) {
      return {
        'leadContactId': leadContact.leadContactId.toString(),
        'leadContactParentId': leadContact.leadContactParentId.toString(),
        'leadContactMasterId': leadContact.leadContactMasterId.toString(),
        'leadContactName': leadContact.leadContactName,
        'leadContactDesignation': leadContact.leadContactDesignation,
        'leadContactDepartment': leadContact.leadContactDepartment,
        'leadContactContactNo': leadContact.leadContactContactNo,
        'leadContactEmailId': leadContact.leadContactEmailId,
        'leadContactDecisionMaker': leadContact.leadContactDecisionMaker,
      };
    }).toList();
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

  void navigateToHomePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TabsPage(selectedIndex: 0, selectedRoleCode: ""),
      ),
    );
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

  List<AssignedList> convertAssignedList(
    List<Map<String, dynamic>> assignedList,
  ) {
    return assignedList
        .map(
          (map) => AssignedList(
            UserId: map['UserID']?.toString() ?? '',
            UserName: map['UserName']?.toString() ?? '',
          ),
        )
        .toList();
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

  Future<List<AssignedList>> getAssignedList(String search) async {
    List<AssignedList> assignedList = convertAssignedList(assigneeList);
    List<AssignedList> filteredList = assignedList
        .where(
          (element) =>
              element.UserName.toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
    filteredList.removeWhere((element) => element.UserName == "");

    return filteredList;
  }

  void goUp() {
    stageController.jumpTo(stageController.position.pixels + 30);
  }

  void accountNameEmptyChecker() {
    if (searchController.text == "") {
      SnackBar snackBar = const SnackBar(
        showCloseIcon: true,
        duration: Duration(seconds: 1),
        content: Text(
          "Please Enter Hospital Name",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Size size = const Size(0, 0);
  Offset? offset;
  double? y = 0.0;

  Future<void> ensureVisibleOnTextArea({
    required GlobalKey textfieldKey,
  }) async {
    final keyContext = textfieldKey.currentContext;
    if (keyContext != null) {
      await Future.delayed(const Duration(milliseconds: 0)).then(
        (value) => Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 0),
          curve: Curves.decelerate,
        ),
      );
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
              // Display a loading indicator while waiting for data
              return const CircularProgressIndicator();
            } else {
              // Data loaded successfully, build your widgets here
              return stageOneHome(context);
            }
          },
        ),
      ),
    );
  }

  // @override
  Widget stageOneHome(BuildContext context) {
    // Widget build(BuildContext context) {
    return Scaffold(
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
                'Stage 1 - Lead Details Entry - Contact Details',
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
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 600) {
            deviceOrientation = "Landscape";
          } else {
            deviceOrientation = "Portrait";
          }
          return PopScope(
            canPop: false,
            onPopInvoked: (onPop) => navigateToHomePage(),
            child: _buildContainer(),
          );
        },
      ),
    );
  }

  Widget _buildContainer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // const screenWidth = 392.72727272727275;
    // const screenHeight = 803.6363636363636;
    double textFieldDropDownWidth = 0;
    double containerDropDownHeight = 0;
    double textFieldWidth = 0;
    double containerHeight = 0;

    if (deviceOrientation == "Portrait") {
      textFieldDropDownWidth = screenWidth * 0.82;
      containerDropDownHeight = screenHeight * 0.06;
      textFieldWidth = screenWidth * 0.9;
      containerHeight = screenHeight * 0.06;
    } else {
      textFieldDropDownWidth = screenWidth * 0.82;
      containerDropDownHeight = screenHeight * 0.12;
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Center(
        child:
            // ignore: sized_box_for_whitespace
            NotificationListener(
              onNotification: (notificationInfo) {
                if (notificationInfo is ScrollUpdateNotification) {}
                return true;
              },
              child: SingleChildScrollView(
                reverse: moveFlag,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                controller: stageController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160, // Set a fixed height or adjust as needed
                      child: HeaderPage(leadsId: leadId, leadStageForEdit: "1"),
                    ),
                    Padding(
                      padding: deviceOrientation == "Portrait"
                          ? const EdgeInsets.only(top: 20.0, bottom: 0, left: 0)
                          : const EdgeInsets.only(right: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          kIsWeb
                              ? RawAutocomplete<Hospital>(
                                  textEditingController: searchController,
                                  optionsBuilder: (TextEditingValue val) {
                                    if (val.text == '') {
                                      return const Iterable<Hospital>.empty();
                                    }
                                    return customerList
                                        .map(
                                          (item) => Hospital(
                                            CustomerName:
                                                item['CustomerName'] ?? '',
                                            CustomerCode: item['CustomerCode'],
                                          ),
                                        )
                                        .where((Hospital option) {
                                          return option
                                                  .CustomerName.toLowerCase()
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
                                            labelText: 'Hospital',
                                            labelStyle: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF8F8F8F),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: searchController.text == ""
                                                  ? const Icon(
                                                      Icons.search,
                                                      color: Color(0xff2ca9df),
                                                    )
                                                  : const Icon(Icons.clear),
                                              onPressed: () {
                                                searchController.clear();
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                  onSelected: (Hospital value) {
                                    searchController.text = value.CustomerName;
                                    // setState(() {
                                    //   selectedOption = value.CustomerName;
                                    //   searchController.text =
                                    //       value.CustomerName;
                                    //   var customer = customerList.firstWhere(
                                    //         (map) =>
                                    //     map['CustomerName'] ==
                                    //         value.CustomerName,
                                    //   );
                                    //   selectedHospitalId =
                                    //       customer['CustomerCode'].toString();
                                    //   selectedHospitalName = value.CustomerName;
                                    // });
                                    setState(() {
                                      selectedOption = value.CustomerName;
                                      searchController.text =
                                          value.CustomerName;
                                      var customer = customerList.firstWhere(
                                        (map) =>
                                            map['CustomerName'] ==
                                            value.CustomerName,
                                        orElse: () => <String, dynamic>{
                                          'CustomerCode': null,
                                        },
                                      );
                                      selectedHospitalId =
                                          customer['CustomerCode'].toString();
                                      selectedHospitalName = value.CustomerName;
                                    });
                                    /*await*/
                                    loadContacs();
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
                                      : containerDropDownHeight + 2,
                                  width: textFieldDropDownWidth,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: AsyncAutocomplete<Hospital>(
                                          onTap: () {},
                                          maxListHeight:
                                              deviceOrientation == "Portrait"
                                              ? 370
                                              : 220,
                                          decoration: const InputDecoration(
                                            labelText: 'Hospital',
                                            labelStyle: TextStyle(
                                              color: Color(0xff454545),
                                              fontWeight: FontWeight.w400,
                                              fontFamily: "Poppins",
                                              fontSize: 14.0,
                                            ),
                                            focusedBorder:
                                                UnderlineInputBorder(),
                                            contentPadding: EdgeInsets.only(
                                              left: 0,
                                              right: 30,
                                              top: 2,
                                              bottom: 0,
                                            ),
                                          ),
                                          controller: searchController,
                                          inputKey: hospitalKey,
                                          onTapItem: (Hospital hospital) async {
                                            setState(() {
                                              selectedOption =
                                                  hospital.CustomerName;
                                              searchController.text =
                                                  hospital.CustomerName;
                                              var customer = customerList
                                                  .firstWhere(
                                                    (map) =>
                                                        map['CustomerName'] ==
                                                        hospital.CustomerName,
                                                    orElse: () =>
                                                        <String, dynamic>{
                                                          'CustomerCode': null,
                                                        },
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
                                                color: Color(0xff454545),
                                                fontSize: 14.0,
                                                fontFamily: "Poppins",
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          asyncSuggestions: (searchValue) =>
                                              getCustomer(searchValue),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 0.0,
                                          bottom: 20,
                                        ),
                                        child: Align(
                                          alignment: Alignment.bottomRight,
                                          child: Visibility(
                                            child: SizedBox(
                                              width: 20.0,
                                              child: GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedOption = '';
                                                    selectedHospitalId = "";
                                                    selectedDistributorId = "";
                                                    searchController.clear();
                                                    _searchController2.clear();
                                                    _searchController3.clear();
                                                    _clearControls();
                                                    contactMasterList.clear();
                                                  });
                                                  // loadContacs();
                                                },
                                                child:
                                                    searchController.text == ""
                                                    ? Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                              color: Colors
                                                                  .transparent,
                                                            ),
                                                        child: const Icon(
                                                          Icons.search,
                                                          color: Colors.grey,
                                                          size: 20,
                                                        ),
                                                      )
                                                    : Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                              color: Colors
                                                                  .transparent,
                                                            ),
                                                        child: const Icon(
                                                          Icons.close_rounded,
                                                          color: Colors.grey,
                                                          size: 20,
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
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        accountNameEmptyChecker();
                      },
                      child: AbsorbPointer(
                        absorbing: searchController.text == "",
                        child: Column(
                          children: [
                            Padding(
                              padding: deviceOrientation == "Portrait"
                                  ? const EdgeInsets.only(
                                      top: 10.0,
                                      bottom: 0,
                                      left: 0,
                                    )
                                  : const EdgeInsets.only(right: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  kIsWeb
                                      ? RawAutocomplete<Distributor>(
                                          textEditingController:
                                              _searchController2,
                                          optionsBuilder: (TextEditingValue val) {
                                            if (val.text == '') {
                                              return const Iterable<
                                                Distributor
                                              >.empty();
                                            }
                                            return distributorList
                                                .map(
                                                  (item) => Distributor(
                                                    CustomerName:
                                                        item['CustomerName'] ??
                                                        '',
                                                    CustomerCode:
                                                        item['CustomerCode'],
                                                  ),
                                                )
                                                .where((Distributor option) {
                                                  return option
                                                          .CustomerName.toLowerCase()
                                                      .contains(
                                                        val.text.toLowerCase(),
                                                      );
                                                });
                                          },
                                          displayStringForOption:
                                              (Distributor option) =>
                                                  option.CustomerName,
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
                                                  onSubmitted: (value) =>
                                                      onFieldSubmitted(),
                                                  decoration: InputDecoration(
                                                    labelText: 'Distributor',
                                                    labelStyle: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Color(0xFF8F8F8F),
                                                    ),
                                                    suffixIcon: IconButton(
                                                      icon:
                                                          _searchController2
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
                                                        _searchController2
                                                            .clear();
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                          onSelected: (Distributor value) {
                                            _searchController2.text =
                                                value.CustomerName;
                                            // setState(() {
                                            //   selectedOption = value.CustomerName;
                                            //   searchController.text =
                                            //       value.CustomerName;
                                            //   var customer = customerList.firstWhere(
                                            //         (map) =>
                                            //     map['CustomerName'] ==
                                            //         value.CustomerName,
                                            //   );
                                            //   selectedHospitalId =
                                            //       customer['CustomerCode'].toString();
                                            //   selectedHospitalName = value.CustomerName;
                                            // });
                                            setState(() {
                                              selectedOption =
                                                  value.CustomerName;
                                              _searchController2.text =
                                                  value.CustomerName;
                                              var customer = customerList
                                                  .firstWhere(
                                                    (map) =>
                                                        map['CustomerName'] ==
                                                        value.CustomerName,
                                                    orElse: () =>
                                                        <String, dynamic>{
                                                          'CustomerCode': null,
                                                        },
                                                  );
                                              selectedDistributorId =
                                                  customer['CustomerCode']
                                                      .toString();
                                              selectedDistributorName =
                                                  value.CustomerName;
                                            });
                                            /*await*/
                                            loadContacs();
                                          },
                                          optionsViewBuilder:
                                              (
                                                BuildContext context,
                                                void Function(Distributor)
                                                onSelected,
                                                Iterable<Distributor> options,
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
                                                            final Distributor
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
                                                                      .CustomerName,
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
                                              : containerDropDownHeight + 2,
                                          width: textFieldDropDownWidth,
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: AsyncAutocomplete<Distributor>(
                                                  maxListHeight:
                                                      deviceOrientation ==
                                                          "Portrait"
                                                      ? 370
                                                      : 220,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Distributor',
                                                        labelStyle: TextStyle(
                                                          color: Color(
                                                            0xff454545,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontFamily: "Poppins",
                                                          fontSize: 14.0,
                                                        ),
                                                        focusedBorder:
                                                            UnderlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                    color: Colors
                                                                        .blue,
                                                                  ),
                                                            ),
                                                        contentPadding:
                                                            EdgeInsets.only(
                                                              left: 0,
                                                              right: 30,
                                                              top: 2,
                                                              bottom: 0,
                                                            ),
                                                      ),
                                                  controller:
                                                      _searchController2,
                                                  inputKey: distributorKey,
                                                  onTapItem: (Distributor distributor) async {
                                                    setState(() {
                                                      selectedOption =
                                                          distributor
                                                              .CustomerName;
                                                      _searchController2.text =
                                                          distributor
                                                              .CustomerName;
                                                      var customer = customerList
                                                          .firstWhere(
                                                            (map) =>
                                                                map['CustomerName'] ==
                                                                distributor
                                                                    .CustomerName,
                                                            orElse: () =>
                                                                <
                                                                  String,
                                                                  dynamic
                                                                >{
                                                                  'CustomerCode':
                                                                      null,
                                                                },
                                                          );
                                                      selectedDistributorId =
                                                          customer['CustomerCode']
                                                              .toString();
                                                      selectedDistributorName =
                                                          distributor
                                                              .CustomerName;
                                                    });
                                                  },
                                                  suggestionBuilder: (data) =>
                                                      ListTile(
                                                        title: Text(
                                                          data.CustomerName,
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xff454545,
                                                                ),
                                                                fontSize: 14.0,
                                                                fontFamily:
                                                                    "Poppins",
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      ),
                                                  asyncSuggestions:
                                                      (searchValue) =>
                                                          getDistributor(
                                                            searchValue,
                                                          ),
                                                ),
                                              ),
                                              Align(
                                                alignment:
                                                    Alignment.bottomRight,
                                                child: Visibility(
                                                  child: SizedBox(
                                                    width: 20.0,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          selectedOption = '';
                                                          selectedDistributorId =
                                                              "";
                                                          _searchController2
                                                              .clear();
                                                        });
                                                      },
                                                      child:
                                                          searchController
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
                                                                      top: 5,
                                                                      right: 4,
                                                                      bottom:
                                                                          20,
                                                                    ),
                                                                child: Icon(
                                                                  Icons.search,
                                                                  color: Colors
                                                                      .grey,
                                                                  size: 20,
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
                                                                      top: 5,
                                                                      right: 4,
                                                                      bottom:
                                                                          20,
                                                                    ),
                                                                child: Icon(
                                                                  Icons
                                                                      .close_rounded,
                                                                  color: Colors
                                                                      .grey,
                                                                  size: 20,
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
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Transform.translate(
                              offset: deviceOrientation == "Portrait"
                                  ? const Offset(14, 0)
                                  : const Offset(50, 0),
                              child: const Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Contact Person Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xff454545),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: "Poppins",
                                  ),
                                ),
                              ),
                            ),
                            Form(
                              key: _formKey,
                              child: Container(
                                margin: const EdgeInsets.all(5),
                                color: const Color(0xffEFEFEF),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: deviceOrientation == "Portrait"
                                          ? const EdgeInsets.only(
                                              top: 10.0,
                                              bottom: 0,
                                              left: 0,
                                            )
                                          : const EdgeInsets.only(right: 0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height:
                                                deviceOrientation == "Portrait"
                                                ? containerHeight
                                                : containerDropDownHeight + 2,
                                            width: textFieldDropDownWidth,
                                            child: Stack(
                                              children: [
                                                Align(
                                                  alignment: Alignment
                                                      .center, //previously postion.fill was given
                                                  child: AsyncAutocomplete<Contacts>(
                                                    maxListHeight:
                                                        deviceOrientation ==
                                                            "Portrait"
                                                        ? 370
                                                        : 200,
                                                    decoration: InputDecoration(
                                                      labelText: 'Name',
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
                                                            right: 30,
                                                            top: 0,
                                                            bottom: 0,
                                                          ),
                                                    ),
                                                    controller:
                                                        _searchController3,
                                                    inputKey: contactKey,
                                                    onTapItem: (Contacts contact) {
                                                      setState(() {
                                                        selectedOption = contact
                                                            .CustomerName;
                                                        _searchController3
                                                            .text = contact
                                                            .CustomerName;
                                                        var customer = contactMasterList.firstWhere(
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
                                                        selectedLeadContactId =
                                                            customer['CustContactId']
                                                                .toString();
                                                        _phoneController.text =
                                                            customer['CustContactMobileNo']
                                                                .toString();
                                                        _emailController.text =
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
                                                    suggestionBuilder: (data) =>
                                                        ListTile(
                                                          title: Text(
                                                            data.CustomerName,
                                                          ),
                                                        ),
                                                    asyncSuggestions:
                                                        (searchValue) =>
                                                            getContacts(
                                                              searchValue,
                                                            ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 15,
                                                  right: 0,
                                                  child: Visibility(
                                                    child: SizedBox(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            selectedOption = '';
                                                            _clearContactSummary();
                                                          });
                                                        },
                                                        child:
                                                            _searchController3
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
                                                                        top: 5,
                                                                        right:
                                                                            4,
                                                                        bottom:
                                                                            5,
                                                                      ),
                                                                  child: Icon(
                                                                    Icons
                                                                        .search,
                                                                    color: Colors
                                                                        .grey,
                                                                    size: 20,
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
                                                                        top: 5,
                                                                        right:
                                                                            4,
                                                                        bottom:
                                                                            5,
                                                                      ),
                                                                  child: Icon(
                                                                    Icons
                                                                        .close_rounded,
                                                                    color: Colors
                                                                        .grey,
                                                                    size: 20,
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
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: SizedBox(
                                        width: deviceOrientation == "Portrait"
                                            ? textFieldWidth
                                            : textFieldDropDownWidth,
                                        height: deviceOrientation == "Portrait"
                                            ? containerHeight
                                            : containerDropDownHeight,
                                        child: TextFormField(
                                          controller: _designationController,
                                          keyboardType: TextInputType.name,
                                          decoration: const InputDecoration(
                                            border: UnderlineInputBorder(),
                                            labelText: 'Designation',
                                            labelStyle: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              color: Color(0xff454545),
                                            ),
                                            contentPadding: EdgeInsets.only(
                                              left: 0,
                                              right: 30,
                                              top: 0,
                                              bottom: 12,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your designation.';
                                            }
                                            return null;
                                          },
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 15),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: SizedBox(
                                        width: deviceOrientation == "Portrait"
                                            ? textFieldWidth
                                            : textFieldDropDownWidth,
                                        height: deviceOrientation == "Portrait"
                                            ? containerHeight
                                            : containerDropDownHeight,
                                        child: TextFormField(
                                          controller: _departmentController,
                                          keyboardType: TextInputType.text,
                                          decoration: const InputDecoration(
                                            border: UnderlineInputBorder(),
                                            labelText: 'Department',
                                            labelStyle: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              color: Color(0xff454545),
                                            ),
                                            contentPadding: EdgeInsets.only(
                                              left: 0,
                                              right: 30,
                                              top: 0,
                                              bottom: 12,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your department.';
                                            }
                                            return null;
                                          },
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 15),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: SizedBox(
                                        width: deviceOrientation == "Portrait"
                                            ? textFieldWidth
                                            : textFieldDropDownWidth,
                                        height: deviceOrientation == "Portrait"
                                            ? containerHeight
                                            : containerDropDownHeight,
                                        child: TextFormField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          decoration: const InputDecoration(
                                            border: UnderlineInputBorder(),
                                            labelText: 'Contact Number',
                                            labelStyle: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              color: Color(0xff454545),
                                            ),
                                            contentPadding: EdgeInsets.only(
                                              left: 0,
                                              right: 30,
                                              top: 0,
                                              bottom: 12,
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

                                    const SizedBox(height: 15),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: SizedBox(
                                        width: deviceOrientation == "Portrait"
                                            ? textFieldWidth
                                            : textFieldDropDownWidth,
                                        height: deviceOrientation == "Portrait"
                                            ? containerHeight
                                            : containerDropDownHeight,
                                        child: TextFormField(
                                          scrollPadding: const EdgeInsets.all(
                                            50,
                                          ),
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: const InputDecoration(
                                            border: UnderlineInputBorder(),
                                            labelText: 'Email',
                                            labelStyle: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xff454545),
                                              fontFamily: 'Poppins',
                                            ),
                                            contentPadding: EdgeInsets.only(
                                              left: 0,
                                              right: 30,
                                              top: 0,
                                              bottom: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: deviceOrientation == "Portrait"
                                          ? const EdgeInsets.only(left: 0.0)
                                          : const EdgeInsets.only(left: 50.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                'Decision Maker :',
                                                style: TextStyle(
                                                  color: Color(0xff454545),
                                                  fontFamily: "Poppins",
                                                  fontWeight: FontWeight.w500,
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
                                          SizedBox(
                                            width: 100,
                                            child: InkWell(
                                              onTap: () {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  addDataToList();
                                                } else {
                                                  const snackBar = SnackBar(
                                                    content: Text(
                                                      'Contact details are missing. Please fill in the contact details.',
                                                    ),
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(snackBar);
                                                }
                                              },
                                              child: Container(
                                                width: 0,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF2CA9DF,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        0.0,
                                                      ),
                                                ),
                                                child: const Row(
                                                  // mainAxisAlignment:
                                                  // MainAxisAlignment.center,
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.all(
                                                        8.0,
                                                      ),
                                                      child: Text(
                                                        'Add',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Icon(
                                                      Icons.add_circle_outline,
                                                      color: Colors.white,
                                                      size: 18,
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

                                    //  *************************************************************************************************
                                    Visibility(
                                      visible: contactList.isNotEmpty,
                                      child: SizedBox(
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
                                                    color: Colors.white,
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
                                                                fontSize: 14,
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
                                                                          fontSize:
                                                                              14,
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
                                                                        fontSize:
                                                                            14,
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
                                                                          fontSize:
                                                                              14,
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
                                                                          width:
                                                                              15,
                                                                        ),
                                                                        GestureDetector(
                                                                          onTap: () {
                                                                            loadContactDetails(
                                                                              contactList[index],
                                                                            );
                                                                            setState(() {
                                                                              contactList.remove(
                                                                                contactList[index],
                                                                              );
                                                                            });
                                                                          },
                                                                          child: const Icon(
                                                                            Icons.edit,
                                                                            size:
                                                                                16.0,
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
                                                const SizedBox(height: 5),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Padding(
                              padding: deviceOrientation == "Portrait"
                                  ? const EdgeInsets.only(
                                      top: 0.0,
                                      bottom: 0.0,
                                      left: 10,
                                      right: 10,
                                    )
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
                                        GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: () {},
                                          child: Container(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: AsyncAutocomplete<AssignedList>(
                                            onTap: () {
                                              moveFlag = true;
                                            },
                                            onChanged: (s) {
                                              setState(() {});
                                            },
                                            focusNode: _focusAssignedTo,
                                            maxListHeight:
                                                deviceOrientation == "Portrait"
                                                ? 370
                                                : 220,
                                            decoration: const InputDecoration(
                                              labelText: 'Assigned To',
                                              labelStyle: TextStyle(
                                                color: Color(0xff454545),
                                                fontWeight: FontWeight.w400,
                                                fontFamily: "Poppins",
                                                fontSize: 14.0,
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(),
                                              contentPadding: EdgeInsets.only(
                                                left: 0,
                                                right: 30,
                                                top: 2,
                                                bottom: 0,
                                              ),
                                            ),
                                            controller: assignedToController,
                                            inputKey: assignedToKey,
                                            onTapItem:
                                                (
                                                  AssignedList assignedList,
                                                ) async {
                                                  setState(() {
                                                    moveFlag = false;
                                                    selectedAssignee =
                                                        assignedList.UserName;
                                                    assignedToController.text =
                                                        assignedList.UserName;
                                                    selectedAssigneeId =
                                                        assignedList.UserId;
                                                    selectedAssigneeName =
                                                        assignedList.UserName;
                                                  });
                                                },
                                            suggestionBuilder: (data) =>
                                                ListTile(
                                                  dense: true,
                                                  title: Text(
                                                    data.UserName,
                                                    style: const TextStyle(
                                                      color: Color(0xff454545),
                                                      fontSize: 14.0,
                                                      fontFamily: "Poppins",
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                            asyncSuggestions: (searchValue) =>
                                                getAssignedList(searchValue),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 0.0,
                                            bottom: 20,
                                            right: 10,
                                          ),
                                          child: Align(
                                            alignment: Alignment.bottomRight,
                                            child: Visibility(
                                              child: SizedBox(
                                                width: 20.0,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      assignedToController
                                                          .clear();
                                                    });
                                                  },
                                                  child:
                                                      assignedToController
                                                              .text ==
                                                          ""
                                                      ? Container(
                                                          decoration:
                                                              const BoxDecoration(
                                                                color: Colors
                                                                    .transparent,
                                                              ),
                                                          child: const Icon(
                                                            Icons.search,
                                                            color: Colors.grey,
                                                            size: 20,
                                                          ),
                                                        )
                                                      : Container(
                                                          decoration:
                                                              const BoxDecoration(
                                                                color: Colors
                                                                    .transparent,
                                                              ),
                                                          child: const Icon(
                                                            Icons.close_rounded,
                                                            color: Colors.grey,
                                                            size: 20,
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
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: textFieldDropDownWidth,
                              height: containerDropDownHeight,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedDealValue,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedDealValue = newValue!;
                                    });
                                  },
                                  // underline: const SizedBox(),
                                  style: const TextStyle(
                                    color: Color(0xFF454545),
                                    fontSize: 14,
                                    fontFamily: "Poppins",
                                    fontWeight: FontWeight.w400,
                                  ),
                                  items: dealValues.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height:
                                  460, // Set a fixed height or adjust as needed
                              child: FooterPage(
                                key: footerKey,
                                leadsId: leadId,
                                leadStageForEdit: "1",
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: textFieldDropDownWidth,
                              child: GestureDetector(
                                onTap: () async {
                                  if (locationControllerFooter.text == "" ||
                                      contactList.isEmpty) {
                                    final snackBar = SnackBar(
                                      backgroundColor: const Color(0xFF2CA9DF),
                                      duration: const Duration(seconds: 2),
                                      content: Text(
                                        contactList.isEmpty
                                            ? 'Add contact person.'
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
                                      await submitLeads();
                                      // await submitStageSummary();
                                      Navigator.of(dialogContext!).pop();
                                      navigateToHomePage();
                                    } catch (e) {
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

mixin ProductList {}
