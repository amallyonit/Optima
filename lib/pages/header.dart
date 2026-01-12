// ignore_for_file: avoid_print, use_build_context_synchronously, dead_code, unused_element
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/footerConstants.dart';
import 'package:optima/leadstages/finalstage.dart';
import 'package:optima/leadstages/stagefiveentry.dart';
import 'package:optima/leadstages/stagefourentry.dart';
import 'package:optima/leadstages/stageoneentry.dart';
import 'package:optima/leadstages/stagesixentry.dart';
import 'package:optima/leadstages/stagethreeentry.dart';
import 'package:optima/login_screen.dart';
import 'package:optima/pages/customerdatapage.dart';
import 'package:flutter/material.dart';
import 'package:optima/leadstages/stagetwoentry.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:optima/classes/leads.dart';

String leadId = "";
String leadStageForEdit = "";

String? _selectedValue;
Stage? _selectedStage;

bool? hasContactInfo;

class Stage {
  final String name;
  int value;
  final bool selectable;
  Stage(this.name, this.value, this.selectable);
}

List<Stage> stages = [
  Stage('Stages', 0, false),
  Stage('Stage 1 - Lead Details Entry - Contact Details', 1, true),
  Stage('Stage 2 - Sample Data Collection', 2, true),
  Stage('Stage 3 - Sample Submission-Feedback', 3, true),
  Stage('Stage 4 - Quotation', 4, true),
  Stage('Stage 5 - Order', 5, true),
];

class LeadMasterHeaderPageProvider with ChangeNotifier {
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

class LeadContactHeaderPageProvider with ChangeNotifier {
  List<LeadContact> _leadContacts = [];
  List<LeadContact> get leadContacts => _leadContacts;
  void updateLeadContacts(List<LeadContact> newLeadContacts) {
    _leadContacts = newLeadContacts;
    notifyListeners();
  }
}

class HeaderPage extends StatefulWidget {
  final String leadsId, leadStageForEdit;
  const HeaderPage({
    super.key,
    required this.leadsId,
    required this.leadStageForEdit,
  });
  static final GlobalKey<HeaderPageState> headerPageKey =
      GlobalKey<HeaderPageState>();

  @override
  HeaderPageState createState() => HeaderPageState();
}

class HeaderPageState extends State<HeaderPage> {
  late Future<void> loadDataFuture;
  List<LeadContact> leadContacts = [];
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
  @override
  void initState() {
    super.initState();
    loadDataFuture = loadData();
    leadId = widget.leadsId;
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _assignStageSelectable(userId, userJwtToken, userMailID);
    await _selectLeadsDetails(userId, userJwtToken, userMailID);
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
              stage5Selectable = true;
          for (var item in data) {
            stage1Selectable = item[0]["Stage1Selectable"] == 1;
            stage2Selectable = item[0]["Stage2Selectable"] == 1;
            stage3Selectable = item[0]["Stage3Selectable"] == 1;
            stage4Selectable = item[0]["Stage4Selectable"] == 1;
            stage5Selectable = item[0]["Stage5Selectable"] == 1;
            // stage1Selectable = item[0]["Stage1Selectable"] == 1;
            // stage2Selectable = item[0]["Stage2Selectable"] == 1;
            // stage3Selectable = item[0]["Stage3Selectable"] == 1 &&
            //     item[0]["Stage4Selectable"] == 1;
            // stage4Selectable = item[0]["Stage5Selectable"] == 1;
            // stage5Selectable = item[0]["Stage6Selectable"] == 1;
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
              Stage(
                'Stage 3 - Sample Submission-Feedback',
                3,
                stage3Selectable,
              ),
              Stage('Stage 4 - Quotation', 4, stage4Selectable),
              Stage('Stage 5 - Order', 5, stage5Selectable),
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
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
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
    const apiUrl = '${ApiHelper.baseUrl}selectleadsdetailsbyid';
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
                  context.read<LeadMasterHeaderPageProvider>().updateLeadMaster(
                    LeadMaster.fromJson(masData as Map<String, dynamic>),
                  );
                });
              }
            }
            if (data.length > 1 &&
                data[1] is List &&
                (data[1] as List).isNotEmpty) {
              hasContactInfo = true;
              List<LeadContact> newLeadContacts = (data[1] as List)
                  .map((item) => LeadContact.fromJson(item))
                  .toList();
              setState(() {
                context
                    .read<LeadContactHeaderPageProvider>()
                    .updateLeadContacts(newLeadContacts);
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
          content: Text('Lead details not found for Lead ID: $widget.leadsId'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
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
        leadContacts = [];
        leadStageForEdit = "0";
        leadId = "0";
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
            } else {
              return headerHome(leadId);
            }
          },
        ),
      ),
    );
  }

  Widget headerHome(String leadsId) {
    return Header(leadsId: leadsId);
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
    // if(leadContacts.isNotEmpty) {
    //   hasContactInfo = true;
    // }
    // else {
    //   hasContactInfo = false;
    // }

    return InkWell(
      onTap: () {},
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (var item in leadContacts)
              SizedBox(
                width: textFieldWidth,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xffC0E4F3)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 5, top: 0),
                              child: Icon(Icons.person_4_outlined, size: 16.0),
                            ),
                            Flexible(
                              child: SizedBox(
                                width: 150,
                                child: Text(
                                  item.leadContactName,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    color: Color(0xFF454545),
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(
                                left: 25.0,
                                right: 5,
                                top: 1,
                              ),
                              child: Icon(
                                Icons.add_moderator_outlined,
                                size: 16.0,
                              ),
                            ),
                            Flexible(
                              child: SizedBox(
                                width: 100,
                                child: Text(
                                  item.leadContactDepartment,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    color: Color(0xFF454545),
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(
                                left: 25.0,
                                right: 5,
                                top: 1,
                              ),
                              child: Icon(
                                Icons.work_outline_rounded,
                                size: 16.0,
                              ),
                            ),
                            Flexible(
                              child: SizedBox(
                                width: 100,
                                child: Text(
                                  item.leadContactDesignation,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    color: Color(0xFF454545),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        color: const Color(0xffC0E4F3),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 14.0,
                            right: 8,
                            top: 4,
                            bottom: 4,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.phone,
                                size: 14.0,
                                color: Color(0xff454545),
                              ),
                              Text(
                                item.leadContactContactNo,
                                style: const TextStyle(
                                  fontFamily: "Roboto",
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff454545),
                                ),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(width: 22),
                              const Icon(
                                Icons.mail_outlined,
                                size: 14.0,
                                color: Color(0xff454545),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.leadContactEmailId,
                                  overflow: TextOverflow.clip,
                                  style: const TextStyle(
                                    fontFamily: "Roboto",
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff454545),
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(height: 1, color: const Color(0xfffdfdfd)),
                    ],
                  ),
                ),
              ),
            Container(height: 1, color: const Color(0xfffdfdfd)),
          ],
        ),
      ),
    );
  }
}

class Header extends StatefulWidget {
  final String? leadsId;
  const Header({this.leadsId, super.key});

  @override
  HeaderState createState() => HeaderState();
}

class HeaderState extends State<Header> {
  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    LeadMaster leadMaster = context
        .watch<LeadMasterHeaderPageProvider>()
        .leadMaster;

    return Column(
      children: <Widget>[
        Container(
          decoration: const BoxDecoration(color: Color(0xffC0E4F3)),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            widget.leadsId != "0"
                                ? Text(leadMaster.leadID.toString())
                                : const Text(""),
                            widget.leadsId != "0"
                                ? Text(
                                    leadMaster.leadStartDate != ""
                                        ? leadMaster.leadStartDate.substring(
                                            0,
                                            10,
                                          )
                                        : "",
                                  )
                                : const Text(""),
                            widget.leadsId != "0"
                                ? Text(leadMaster.leadAging)
                                : const Text(""),
                            widget.leadsId != "0"
                                ? const Text("Value")
                                : const Text(""),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(height: 1, color: const Color(0xfffdfdfd)),
        Visibility(
          // visible: hasContactInfo == true ? true : false,
          visible: widget.leadsId != "0",
          child: const Expanded(child: ContacteeList()),
        ),
        Container(
          color: const Color(0xffC0E4F3),
          child: DropdownButton<String>(
            isExpanded: true,
            value: stages[int.parse(leadStageForEdit)].name,
            hint: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Stages',
                style: TextStyle(
                  color: Color(0xff454545),
                  fontSize: 14,
                  fontFamily: "Roboto",
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            onChanged: (String? newValue) {
              selectedParticipantFooter.clear();
              summaryControllerFooter.clear();
              followupDateControllerFooter.clear();
              availableParticipant.clear();
              initialParticipant.clear();
              latitudeFooter = '';
              longitudeFooter = '';
              locationControllerFooter.text = "";
              selectedStatusFooter = "Next Action";
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
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    stage.name,
                    style: isSelectable
                        ? const TextStyle(
                            color: Color(0xff454545),
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          )
                        : const TextStyle(
                            color: Colors.grey,
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
