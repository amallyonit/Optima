import 'package:flutter/material.dart';
import 'package:optima/pages/schedulerPage/rsvpPage.dart';

class MeetingData {
  String type;
  String title;
  String customer;
  String date;
  MeetingData({
    required this.type,
    required this.title,
    required this.customer,
    required this.date,
  });
}

class MeetingList {
  List<MeetingData> meetingData;
  MeetingList({required this.meetingData});
}

List<MeetingData> meetingData = [
  MeetingData(
    type: "Meeting",
    title: "Test1",
    customer: "Customer1",
    date: "12/12/2024",
  ),
  MeetingData(
    type: "Meeting",
    title: "Test2",
    customer: "Customer2",
    date: "12/12/2024",
  ),
  MeetingData(
    type: "Meeting",
    title: "Test3",
    customer: "Customer3",
    date: "12/12/2024",
  ),
  MeetingData(
    type: "Meeting",
    title: "Test4",
    customer: "Customer4",
    date: "12/12/2024",
  ),
  MeetingData(
    type: "Meeting",
    title: "Test5",
    customer: "Customer5",
    date: "12/12/2024",
  ),
];

MeetingList meetingList = MeetingList(meetingData: meetingData);

class SalesNotificationPage extends StatefulWidget {
  const SalesNotificationPage({super.key});

  @override
  SalesNotificationPageState createState() => SalesNotificationPageState();
}

class SalesNotificationPageState extends State<SalesNotificationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Page ')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 10),
                Text(
                  "Today",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 400,
              child: ListView.separated(
                separatorBuilder: (BuildContext context, int i) {
                  return const SizedBox(height: 10);
                },
                itemCount: meetingList.meetingData.length,
                itemBuilder: (BuildContext context, int i) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 8.0,
                      bottom: 8.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: const Border(
                          left: BorderSide(
                            color: Colors.blue, // Left border color
                            width: 5.0, // Left border thickness
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            spreadRadius: 8,
                            blurRadius: 1,
                            offset: const Offset(
                              0,
                              6,
                            ), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text(meetingList.meetingData[i].type),
                              ),
                              Text(meetingList.meetingData[i].date),
                              const Text("25 min"),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text(meetingList.meetingData[i].title),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text(
                                  meetingList.meetingData[i].customer,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RSVPPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.grey,
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  textStyle: const TextStyle(fontSize: 12.0),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.only(
                                    left: 12.0,
                                    right: 12.0,
                                  ),
                                  child: Text("RSVP"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 10),
                Text(
                  "Yesterday",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 400,
              child: ListView.separated(
                separatorBuilder: (BuildContext context, int i) {
                  return const SizedBox(height: 10);
                },
                itemCount: meetingList.meetingData.length,
                itemBuilder: (BuildContext context, int i) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 8.0,
                      bottom: 8.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: const Border(
                          left: BorderSide(
                            color: Colors.blue, // Left border color
                            width: 5.0, // Left border thickness
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            spreadRadius: 8,
                            blurRadius: 1,
                            offset: const Offset(
                              0,
                              6,
                            ), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text(meetingList.meetingData[i].type),
                              ),
                              Text(meetingList.meetingData[i].date),
                              const Text("25 min"),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text(meetingList.meetingData[i].title),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text(
                                  meetingList.meetingData[i].customer,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RSVPPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.grey,
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  textStyle: const TextStyle(fontSize: 12.0),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.only(
                                    left: 12.0,
                                    right: 12.0,
                                  ),
                                  child: Text("RSVP"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 10),
                Text(
                  "Last Week",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 400,
              child: ListView.separated(
                separatorBuilder: (BuildContext context, int i) {
                  return const SizedBox(height: 10);
                },
                itemCount: meetingList.meetingData.length,
                itemBuilder: (BuildContext context, int i) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 8.0,
                      bottom: 8.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: const Border(
                          left: BorderSide(
                            color: Colors.blue, // Left border color
                            width: 5.0, // Left border thickness
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            spreadRadius: 8,
                            blurRadius: 1,
                            offset: const Offset(
                              0,
                              6,
                            ), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text(meetingList.meetingData[i].type),
                              ),
                              Text(meetingList.meetingData[i].date),
                              const Text("25 min"),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text(meetingList.meetingData[i].title),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Text(
                                  meetingList.meetingData[i].customer,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RSVPPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.grey,
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  textStyle: const TextStyle(fontSize: 12.0),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.only(
                                    left: 12.0,
                                    right: 12.0,
                                  ),
                                  child: Text("RSVP"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
