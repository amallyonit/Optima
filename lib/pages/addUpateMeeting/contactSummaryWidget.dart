// ignore_for_file: use_build_context_synchronously, avoid_print, non_constant_identifier_names, file_names

import 'package:optima/login_screen.dart';
import 'package:optima/tabs/tabspage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/classes/leads.dart';
import 'package:flutter_async_autocomplete/flutter_async_autocomplete.dart';
import 'hospitalMeetingPage.dart';

String leadId = "";
String deviceOrientation = "";
List<Map<String, dynamic>> contactMasterList = [];

class ContactSummaryWidget extends StatefulWidget {
  final List<Map<String, dynamic>> contactMasterList;
  const ContactSummaryWidget({super.key, required this.contactMasterList});

  static final GlobalKey<ContactSummaryWidgetState> stageOnePageKey =
      GlobalKey<ContactSummaryWidgetState>();

  @override
  ContactSummaryWidgetState createState() => ContactSummaryWidgetState();
}

class Hospital {
  String CustomerName;
  String CustomerCode;
  Hospital({required this.CustomerCode, required this.CustomerName});
}

class Contacts {
  String CustomerName;
  String CustomerCode;
  Contacts({required this.CustomerCode, required this.CustomerName});
}

class ContactSummaryWidgetState extends State<ContactSummaryWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  String selectedContactId = "";
  String selectedLeadContactId = "";

  bool selectedValue = true;
  bool isDark = false;
  final TextEditingController _searchController3 = TextEditingController();

  bool isEditMode = false;
  String selectedOption = 'Option 1';
  bool isDropdownOpen = false;

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
      leadType: '');

  @override
  void dispose() {
    _searchController3.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    isEditMode = false;
    leadId = "";
    contactMasterList = widget.contactMasterList;
  }

  void _clearControls() {
    setState(() {
      _emailController.clear();
      _phoneController.clear();
      _departmentController.clear();
      _designationController.clear();
    });
  }

  bool isValidPhoneNumber(String phoneNumber) {
    RegExp regex = RegExp(r'^(\+91[\-\s]?)?\s*?[6-9]\d{9}$');

    return regex.hasMatch(phoneNumber);
  }

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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
        "leadContactParentId":
            selectedLeadContactId == '' ? '0' : selectedLeadContactId,
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

  void navigateToHomePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => TabsPage(selectedIndex: 0, selectedRoleCode: "")),
    );
  }

  var contactKey = GlobalKey();
  List<Contacts> convertContact(List<Map<String, dynamic>> contList) {
    return contList
        .map((map) => Contacts(
              CustomerCode: map['CustContactId']?.toString() ?? '',
              CustomerName: map['CustContactName']?.toString() ?? '',
            ))
        .toList();
  }

  Future<List<Contacts>> getContacts(String search) async {
    List<Contacts> contList = convertContact(contactMasterList);
    List<Contacts> filteredList = contList
        .where((element) =>
            element.CustomerName.toLowerCase().contains(search.toLowerCase()))
        .toList();

    return filteredList;
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
    contactMasterList = widget.contactMasterList;
    if (deviceOrientation == "Portrait") {
      containerDropDownHeight = screenHeight * 0.06;
      containerHeight = screenHeight * 0.06;
    } else {
      containerDropDownHeight = screenHeight * 0.12;
    }

    return Center(
      child: // ignore: sized_box_for_whitespace
          Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: deviceOrientation == "Portrait"
                          ? containerHeight
                          : containerDropDownHeight / 1.5,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: AsyncAutocomplete<Contacts>(
                              maxListHeight:
                                  deviceOrientation == "Portrait" ? 370 : 200,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                labelStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8F8F8F),
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "Poppins",
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                  ),
                                  borderRadius: BorderRadius.circular(0.0),
                                ),
                                contentPadding: const EdgeInsets.only(
                                    left: 0, right: 0, top: 0, bottom: 0),
                              ),
                              controller: _searchController3,
                              inputKey: contactKey,
                              onTapItem: (Contacts contact) {
                                setState(() {
                                  selectedOption = contact.CustomerName;
                                  _searchController3.text =
                                      contact.CustomerName;
                                  var customer = contactMasterList.firstWhere(
                                    (map) =>
                                        map['CustContactName'] ==
                                        contact.CustomerName,
                                    orElse: () => <String, dynamic>{
                                      'CustContactId': null
                                    },
                                  );
                                  selectedLeadContactId =
                                      customer['CustContactId'].toString();
                                  _phoneController.text =
                                      customer['CustContactMobileNo']
                                          .toString();
                                  _emailController.text =
                                      customer['CustContactEmailId'].toString();
                                  _designationController.text =
                                      customer['DesignationName'].toString();
                                  _departmentController.text =
                                      customer['DepartmentName'].toString();
                                });
                              },
                              suggestionBuilder: (data) => ListTile(
                                title: Text(data.CustomerName),
                              ),
                              asyncSuggestions: (searchValue) =>
                                  getContacts(searchValue),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: SizedBox(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedOption = '';
                                    _searchController3.clear();
                                    _clearControls();
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.only(top: 14, right: 2),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.grey,
                                      size: 20,
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
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: deviceOrientation == "Portrait"
                        ? containerHeight
                        : containerDropDownHeight / 1.5,
                    child: TextFormField(
                      controller: _designationController,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        hintText: 'Designation',
                        hintStyle: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: Color(0xFF8F8F8F)),
                        // contentPadding: EdgeInsets.only(
                        //     left: 0, right: 30, top: 0, bottom: 0),
                      ),
                      validator: (value) {
                        if ((value == null || value.isEmpty) &&
                            (_searchController3.text == "")) {
                          return 'Please enter your designation.';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: deviceOrientation == "Portrait"
                        ? containerHeight
                        : containerDropDownHeight / 1.5,
                    child: TextFormField(
                      controller: _departmentController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        hintText: 'Department',
                        hintStyle: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: Color(0xFF8F8F8F)),
                        // contentPadding: EdgeInsets.only(
                        //     left: 0, right: 30, top: 0, bottom: 0),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your department.';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: deviceOrientation == "Portrait"
                        ? containerHeight
                        : containerDropDownHeight / 1.5,
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        hintText: 'Contact Number',
                        hintStyle: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: Color(0xFF8F8F8F)),
                        // contentPadding: EdgeInsets.only(
                        //     left: 0, right: 30, top: 0, bottom: 0),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your contact number.';
                        } else if (!isValidPhoneNumber(value)) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: deviceOrientation == "Portrait"
                        ? containerHeight
                        : containerDropDownHeight / 1.5,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        hintText: 'Email',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8F8F8F),
                          fontFamily: 'Poppins',
                        ),
                        contentPadding: EdgeInsets.only(
                            left: 0, right: 30, top: 0, bottom: 0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: deviceOrientation == "Portrait"
                      ? const EdgeInsets.only(left: 0.0)
                      : const EdgeInsets.only(left: 0.0, right: 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Decision Maker :',
                            style: TextStyle(
                                color: Color(0xFF8F8F8F),
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w500,
                                fontSize: 14),
                          ),
                          Checkbox(
                            value: selectedValue,
                            onChanged: (value) {
                              setState(() {
                                selectedValue = value ?? true;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: 125,
                            child: InkWell(
                              onTap: () {
                                if (_formKey.currentState!.validate()) {
                                  addDataToList();
                                  _clearControls();
                                } else {
                                  const snackBar = SnackBar(
                                    content: Text(
                                        'Contact details are missing. Please fill in the contact details.'),
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                }
                              },
                              child: Container(
                                width: 0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2CA9DF),
                                  borderRadius: BorderRadius.circular(0.0),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Add',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.add_circle_outline,
                                        color: Colors.white, size: 18),
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
                const SizedBox(
                  height: 5,
                ),
                SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      for (var item in contactList)
                        SizedBox(
                          width: 350,
                          height: 65,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 1),
                            color: contactList.indexOf(item) % 2 == 0
                                ? const Color(0xFFefefef)
                                : const Color(0xFFefefef),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ListTile(
                                    title: Text(item['leadContactName'] ?? '',
                                        style: const TextStyle(
                                            color: Color(0xff454545),
                                            fontFamily: "Poppins")),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                                item['leadContactDepartment'] ??
                                                    '',
                                                style: const TextStyle(
                                                    color: Color(0xff454545))),
                                            const SizedBox(width: 10),
                                            const Text("/",
                                                style: TextStyle(
                                                    color: Color(0xff454545))),
                                            const SizedBox(width: 10),
                                            Text(item[
                                                    'leadContactDesignation'] ??
                                                ''),
                                            const SizedBox(width: 70),
                                            Visibility(
                                                visible:
                                                    item["leadContactDecisionMaker"]
                                                            .toString() ==
                                                        "Yes",
                                                child: const Text('DM'))
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    loadContactDetails(item);
                                    setState(() {
                                      contactList.remove(item);
                                    });
                                  },
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.only(right: 16.0, top: 15),
                                    child: SizedBox(
                                      height: 90,
                                      child: Icon(Icons.edit,
                                          size: 16.0, color: Color(0xff454545)),
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
              ],
            ),
          ],
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
  }) =>
      InputDecoration(
          enabledBorder: enabledBorder ??
              const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueGrey, width: 2.0)),
          border:
              border ?? const UnderlineInputBorder(borderSide: BorderSide()),
          fillColor: fillColor ?? Colors.white,
          filled: filled ?? true,
          prefixIcon: prefixIcon,
          hintText: hintText,
          labelText: labelText);
}
