import 'package:flutter/material.dart';
import 'package:optima/sidemenu/sidemenu.dart';
import 'package:optima/pages/notificationpage.dart';
import 'package:optima/pages/searchpage.dart';

class Expense extends StatefulWidget {
  const Expense({super.key});
  @override
  ExpenseState createState() => ExpenseState();
}

class ExpenseState extends State<Expense> {
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
      drawer: const SideMenu(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return SizedBox(
              child: IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF454545)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        actions: [
          IconButton(
            color: const Color(0xFF454545),
            icon: const Icon(Icons.search),
            onPressed: () {
              navigateToSearchPage();
            },
          ),
          IconButton(
            color: const Color(0xFF454545),
            icon: const Icon(
              Icons.notifications_outlined,
            ), // Icon for notifications
            onPressed: () {
              navigateToNotificationPage();
            },
          ),
        ],
        title: const Text(
          "Expense", // Replace with your desired title text
          style: TextStyle(
            color: Colors.blue,
            fontSize: 14, // Customize the title text color here
          ),
        ),
      ),
      body: const Center(child: Text('Expense Page')),
    );
  }
}
