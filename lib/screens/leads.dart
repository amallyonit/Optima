// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:optima/sidemenu/sidemenu.dart';
import 'package:optima/pages/leadpagelist.dart';
import 'package:optima/pages/notificationpage.dart';
import 'package:optima/pages/searchpage.dart';

class Leads extends StatefulWidget {
  const Leads({super.key});
  @override
  LeadsState createState() => LeadsState();
}

class LeadsState extends State<Leads> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void navigateToNotificationPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationPage()));
  }

  void navigateToSearchPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SearchPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      body: const Center(child: LeadPageList()),
    );
  }
}
