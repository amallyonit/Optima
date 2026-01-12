// ignore_for_file: file_names, use_build_context_synchronously, avoid_print
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
// import 'package:optima/classes/leads.dart';

import 'hospitalMeetingPage.dart';

class StageList {
  final int id;
  final String name;

  StageList({required this.id, required this.name});
}

class StageMultiLevelDropDown extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  StageMultiLevelDropDown({super.key});

  @override
  State<StageMultiLevelDropDown> createState() =>
      _StageMultiLevelDropDownState();
}

class _StageMultiLevelDropDownState extends State<StageMultiLevelDropDown> {
  List<StageList> stages = [
    StageList(id: 1, name: '1st Meeting'),
    StageList(id: 2, name: '2nd Meeting'),
    StageList(id: 3, name: 'Approved-If sample is approved'),
    StageList(id: 4, name: 'Rejected - If sample is rejected'),
    StageList(id: 5, name: 'Quotation'),
    StageList(id: 6, name: 'Negotiations'),
    StageList(id: 7, name: 'Order'),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final items = stages
        .map((stage) => MultiSelectItem<StageList>(stage, stage.name))
        .toList();
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: null,
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 10, left: 0, right: 0),
          child: Column(
            children: <Widget>[
              MultiSelectDialogField(
                searchable: true,
                listType: MultiSelectListType.LIST,
                separateSelectedItems: true,
                items: items,
                title: const Text("Stages"),
                selectedColor: const Color(0xff2ca9df),
                buttonIcon: const Icon(Icons.search, color: Color(0xff2ca9df)),
                buttonText: const Text(
                  "Stages",
                  style: TextStyle(
                    color: Color(0xFF8F8F8F),
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                onConfirm: (results) {
                  setState(() {
                    selectedStages = results;
                  });
                },
                selectedItemsTextStyle: const TextStyle(
                  color: Color(0xFF8F8F8F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // initialParticipant = [];
    super.dispose();
  }
}
