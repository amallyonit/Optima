// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optima/pages/addUpateMeeting/participantMultiDropDown.dart';
import 'package:optima/tabs/tabspage.dart';

class RSVPPage extends StatefulWidget {
  const RSVPPage({super.key});

  @override
  State<RSVPPage> createState() => _RSVPPageState();
}

class _RSVPPageState extends State<RSVPPage> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  String fromDt = "";
  String toDt = "";
  String? scheduleType;
  int _selectedPriority = 1;

  void navigateToHomePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TabsPage(selectedIndex: 0, selectedRoleCode: ""),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Navigator.of(context).pop();
                },
                child: const Icon(
                  Icons.keyboard_arrow_left,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'RSVP',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Text(
                "jhon@lyonit.com",
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 8,
                      blurRadius: 1,
                      offset: const Offset(0, 6), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: DropdownButtonFormField<String>(
                                hint: const Text(
                                  'Type',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF8F8F8F),
                                  ),
                                ),
                                initialValue: scheduleType,
                                icon: const Icon(
                                  Icons.search,
                                  color: Color(0xff2ca9df),
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    scheduleType = newValue!;
                                  });
                                },
                                items:
                                    <String>[
                                      'Call',
                                      'Meeting',
                                      'Travel Plan',
                                      'Others',
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
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      child: TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          hintText: "Title",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8F8F8F),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      child: TextField(
                        controller: customerController,
                        decoration: const InputDecoration(
                          hintText: "Customer",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8F8F8F),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 175,
                      width: 400,
                      child: ParticipantMultiLevelDropDown(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              canRequestFocus: false,
                              style: const TextStyle(color: Color(0xFF8F8F8F)),
                              keyboardType: TextInputType.none,
                              controller: _fromDateController,
                              decoration: const InputDecoration(
                                suffixIcon: Padding(
                                  padding: EdgeInsets.only(left: 20.0),
                                  child: Icon(
                                    Icons.calendar_today,
                                    color: Color(0xff2ca9df),
                                    size: 20,
                                  ),
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                labelText: 'Start',
                                contentPadding: EdgeInsets.only(bottom: 0),
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF8F8F8F),
                                ),
                              ),
                              onTap: () async {
                                DateTime? selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                  initialEntryMode:
                                      DatePickerEntryMode.calendar,
                                );
                                if (selectedDate != null) {
                                  String formattedDateTime =
                                      DateFormat('dd/MM/yyyy').format(
                                        DateTime(
                                          selectedDate.year,
                                          selectedDate.month,
                                          selectedDate.day,
                                        ),
                                      );
                                  fromDt = DateFormat('yyyy-MM-dd').format(
                                    DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                    ),
                                  );
                                  _fromDateController.text = formattedDateTime;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 25),
                          Expanded(
                            child: TextField(
                              canRequestFocus: false,
                              style: const TextStyle(color: Color(0xFF8F8F8F)),
                              keyboardType: TextInputType.none,
                              controller: _toDateController,
                              decoration: const InputDecoration(
                                suffixIcon: Padding(
                                  padding: EdgeInsets.only(left: 20.0),
                                  child: Icon(
                                    Icons.calendar_today,
                                    color: Color(0xff2ca9df),
                                    size: 20,
                                  ),
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                labelText: 'End',
                                contentPadding: EdgeInsets.only(bottom: 0),
                                labelStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF8F8F8F),
                                ),
                              ),
                              onTap: () async {
                                DateTime? selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                  initialEntryMode:
                                      DatePickerEntryMode.calendar,
                                );

                                if (selectedDate != null) {
                                  String formattedDateTime =
                                      DateFormat('dd/MM/yyyy').format(
                                        DateTime(
                                          selectedDate.year,
                                          selectedDate.month,
                                          selectedDate.day,
                                        ),
                                      );
                                  toDt = DateFormat('yyyy-MM-dd').format(
                                    DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                    ),
                                  );
                                  _toDateController.text = formattedDateTime;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      child: TextField(
                        controller: remarksController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          labelText: "Remarks",
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
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text("Priority:"),
                              Radio<int>(
                                value: 1,
                                groupValue: _selectedPriority,
                                activeColor: Colors.red,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedPriority = value!;
                                  });
                                },
                              ),
                              const Text('High'),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(width: 2, color: Colors.grey),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(3.0),
                              child: Row(
                                children: [
                                  Text("Approved"),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.check_circle_outline_outlined,
                                    color: Colors.green,
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
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: TextField(
                controller: remarksController,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  labelText: "Add a Message",
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
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text("Yes"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text("Maybe"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey, width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text("No"),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
