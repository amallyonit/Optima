// initial_screen.dart
// ignore_for_file: file_names

import 'package:flutter/material.dart';

class LoaderPage extends StatefulWidget {
  const LoaderPage({super.key});

  @override
  LoaderPageState createState() => LoaderPageState();
}

class LoaderPageState extends State<LoaderPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(""),
      ),
    );
  }
}
