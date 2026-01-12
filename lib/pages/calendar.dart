import 'package:optima/tabs/tabspage.dart';
import 'package:flutter/material.dart';
import '../classes/dataManager.dart';

class TableEventsExample extends StatefulWidget {
  const TableEventsExample({super.key});
  @override
  TableEventsExampleState createState() => TableEventsExampleState();
}

class TableEventsExampleState extends State<TableEventsExample> {
  DateTime selectedDate = DateTime.now(); // To track the selected date
  final scrollDuration = const Duration(seconds: 2);
  int currentDateSelectedIndex = 0; // For Horizontal Date
  ScrollController scrollController =
      ScrollController(); // To Track Scroll of ListView

  List<String> listOfMonths = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  List<String> listOfDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  String? receivedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DataManager.readSelectedDate() ?? DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (scrollController.hasClients) {
        if (selectedDate.day <= 7) {
          scrollController.jumpTo(scrollController.position.minScrollExtent);
        } else if (1 <= selectedDate.day && selectedDate.day <= 13) {
          scrollController.jumpTo(360);
        } else if (14 <= selectedDate.day && selectedDate.day <= 19) {
          scrollController.jumpTo(770);
        } else if (20 <= selectedDate.day && selectedDate.day <= 25) {
          scrollController.jumpTo(1130);
        } else if (26 <= selectedDate.day && selectedDate.day <= 31) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        // final daysDifference = picked.difference(DateTime.now()).inDays;
        currentDateSelectedIndex = picked.day;
        // scrollController.jumpTo(currentDateSelectedIndex *
        //     30.0);
        setSelectedDate(selectedDate);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TabsPage(selectedIndex: 0, selectedRoleCode: ""),
          ),
        );
        if (currentDateSelectedIndex <= 7) {
          scrollController.jumpTo(scrollController.position.minScrollExtent);
        } else if (1 <= currentDateSelectedIndex &&
            currentDateSelectedIndex <= 13) {
          scrollController.jumpTo(360);
        } else if (14 <= currentDateSelectedIndex &&
            currentDateSelectedIndex <= 20) {
          scrollController.jumpTo(770);
        } else if (21 <= currentDateSelectedIndex &&
            currentDateSelectedIndex <= 25) {
          scrollController.jumpTo(1130);
        } else if (26 <= currentDateSelectedIndex &&
            currentDateSelectedIndex <= 31) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  void setSelectedDate(DateTime selectedDate) async {
    DataManager.saveSelectedDate(selectedDate);
  }

  static int getDaysInMonth(int year, int month) {
    if (month == DateTime.february) {
      final bool isLeapYear =
          (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const List<int> daysInMonth = <int>[
      31,
      -1,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];
    return daysInMonth[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          centerTitle: true,
          elevation: 0.0,
          title: Text(
            "${listOfMonths[selectedDate.month - 1]} ${selectedDate.year}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color.fromRGBO(54, 45, 45, 1.0),
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.map_outlined),
              color: const Color(0xFF454545),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              color: const Color(0xFF454545),
              onPressed: () {
                selectDate(context);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              height: 0,
              margin: const EdgeInsets.only(left: 10),
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.separated(
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(width: 10);
                },
                itemCount: getDaysInMonth(
                  selectedDate.year,
                  selectedDate.month,
                ),
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                itemBuilder: (BuildContext context, int index) {
                  final currentDate = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    1,
                  ).add(Duration(days: index));
                  final isSelected = currentDate.day == selectedDate.day;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        currentDateSelectedIndex = index;
                        selectedDate = currentDate;
                        setSelectedDate(selectedDate);
                      });
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TabsPage(selectedIndex: 0, selectedRoleCode: ""),
                        ),
                      );
                    },
                    child: Container(
                      height: 20,
                      width: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isSelected
                            ? const Color(0xFFEAEAEA)
                            : const Color(0xFFEAEAEA),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            listOfDays[currentDate.weekday - 1],
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected
                                  ? const Color(0xFF2CA9DF)
                                  : const Color(0xFF858585),
                            ),
                          ),
                          Text(
                            currentDate.day.toString(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.blue
                                  : const Color(0xFF858585),
                            ),
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // const Expanded(
            //   child: MultipleGridView(),
            // ),
          ],
        ),
      ),
    );
  }
}
