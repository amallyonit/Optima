import 'package:flutter/material.dart';
import 'package:optima/sidemenu/sidemenu.dart';
import 'package:optima/pages/notificationpage.dart';
import 'package:optima/pages/searchpage.dart';

import '../pages/addUpateMeeting/leadActivityAnalysis.dart';
import '../pages/dashboardPages/salesDashboardBI/salesAnalysis.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SideMenu(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (BuildContext context) {
            return RotatedBox(
              quarterTurns: 1,
              child: IconButton(
                icon: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF454545),
                ),
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
            onPressed: navigateToSearchPage,
          ),
          IconButton(
            color: const Color(0xFF454545),
            icon: const Icon(Icons.notifications_outlined),
            onPressed: navigateToNotificationPage,
          ),
        ],
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.blue,
            fontFamily: "Poppins",
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            color: Color(0xff454545),
          ),
          tabs: const [
            Tab(text: 'Sales \n Performance'),
            Tab(text: 'Delivery \n Analysis'),
            Tab(text: 'Collection \n Analysis'),
            Tab(text: 'Lead/Activity \n Analysis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SalesPerformancePage(),
          Center(child: Text('Delivery Analysis')),
          Center(child: Text('Collection Analysis')),
          NestedTabBar('Lead/Activity Analysis'),
        ],
      ),
    );
  }

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
}

class NestedTabBar extends StatefulWidget {
  const NestedTabBar(this.outerTab, {super.key});

  final String outerTab;

  @override
  State<NestedTabBar> createState() => _NestedTabBarState();
}

class _NestedTabBarState extends State<NestedTabBar>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'Lead Analysis'),
            Tab(text: 'Activity Analysis'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              const Card(
                margin: EdgeInsets.all(16.0),
                child: LeadActivityAnalysis(),
              ),
              Card(
                margin: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text('${widget.outerTab}:Activity Analysis'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
