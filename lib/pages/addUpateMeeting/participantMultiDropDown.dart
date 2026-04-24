// ignore_for_file: file_names, use_build_context_synchronously
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:optima/api_helper.dart';
import 'package:http/http.dart' as http;
import 'package:optima/pages/addUpateMeeting/distributorMeetingPage.dart';
import 'package:optima/pages/addUpateMeeting/otherMeetingPage.dart';
import '../../classes/leads.dart';
import '../../login_screen.dart';
import 'package:optima/pages/addUpateMeeting/hospitalMeetingPage.dart';

class ParticipantMultiLevelDropDown extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  ParticipantMultiLevelDropDown({super.key});

  @override
  State<ParticipantMultiLevelDropDown> createState() =>
      _ParticipantMultiLevelDropDownState();
}

class _ParticipantMultiLevelDropDownState
    extends State<ParticipantMultiLevelDropDown> {
  late Future<void> loadDataFuture;
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

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
            const snackBar = SnackBar(
              content: Text('Participant loading failed'),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } else {
        const snackBar = SnackBar(content: Text('Participant loading failed'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('$e'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loadparticipant(userId, userJwtToken, userMailID);
  }

  @override
  void initState() {
    super.initState();
    selectedParticipantHospital = [];
    selectedParticipantDistri = [];
    selectedParticipantOther = [];
    initialParticipantHospital = [];
    initialParticipantDistri = [];
    initialParticipantOther = [];
    loadDataFuture = loadData();
  }

  @override
  Widget build(BuildContext context) {
    final participant = availableParticipant
        .map(
          (participant) => MultiSelectItem<LeadParticipant>(
            participant,
            participant.leadParticipantUserName,
          ),
        )
        .toList();
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
                checkColor: Colors.white,
                chipDisplay: MultiSelectChipDisplay<LeadParticipant>(
                  chipColor: const Color(0xff2ca9df),
                  textStyle: const TextStyle(color: Colors.white),
                  onTap: (selected) {
                    setState(() {
                      selectedParticipantHospital.remove(selected);
                      selectedParticipantDistri.remove(selected);
                      selectedParticipantOther.remove(selected);
                      initialParticipantHospital = selectedParticipantHospital;
                      initialParticipantDistri = selectedParticipantDistri;
                      initialParticipantOther = selectedParticipantOther;
                    });
                  },
                ),
                searchable: true,
                listType: MultiSelectListType.LIST,
                initialValue: availableParticipant.where((element) {
                  return initialParticipantHospital.any(
                    (selected) =>
                        selected.leadParticipantUserId ==
                        element.leadParticipantUserId,
                  );
                }).toList(),
                separateSelectedItems: false,
                items: participant,
                title: const Text("Participants"),
                selectedColor: const Color(0xff2ca9df),
                buttonIcon: const Icon(Icons.search, color: Color(0xff2ca9df)),
                buttonText: const Text(
                  "Participants",
                  style: TextStyle(
                    color: Color(0xFF454545),
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                onConfirm: (results) {
                  setState(() {
                    selectedParticipantHospital = results;
                    selectedParticipantDistri = results;
                    selectedParticipantOther = results;
                    initialParticipantHospital = selectedParticipantHospital;
                    initialParticipantDistri = selectedParticipantHospital;
                    initialParticipantOther = selectedParticipantHospital;
                  });
                },
                selectedItemsTextStyle: const TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    initialParticipantHospital = [];
    initialParticipantDistri = [];
    initialParticipantOther = [];
    super.dispose();
  }
}
