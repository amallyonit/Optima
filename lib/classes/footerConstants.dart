// ignore_for_file: file_names

import 'package:flutter/material.dart';

import 'leads.dart';

List<LeadParticipant> selectedParticipantFooter = [];
List<LeadParticipant> availableParticipant = [];
List<LeadParticipant> initialParticipant = [];
TextEditingController summaryControllerFooter = TextEditingController();
TextEditingController followupDateControllerFooter = TextEditingController();
TextEditingController locationControllerFooter = TextEditingController();
String latitudeFooter = "";
String longitudeFooter = "";
String? selectedStatusFooter;
