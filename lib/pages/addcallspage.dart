import 'package:flutter/material.dart';

class AddCallsPage extends StatefulWidget {
  const AddCallsPage({super.key});

  @override
  AddCallsPageState createState() => AddCallsPageState();
}

class AddCallsPageState extends State<AddCallsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AddCallsPage  '),
      ),
      body: const Center(
        child: Text('This is the AddCallsPage  .'),
      ),
    );
  }
}
