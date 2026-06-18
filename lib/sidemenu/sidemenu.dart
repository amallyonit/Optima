// ignore_for_file: use_build_context_synchronously, strict_top_level_inference
import 'package:optima/excel_helper.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:optima/api_helper.dart';
import 'package:optima/classes/dashBoard.dart';
import 'package:optima/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/approvedManPowerInput.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/MISreports/manpowerCostingInput.dart';
import 'package:optima/pages/dashboardPages/productionDashboardBI/salaryInput.dart';
import 'package:optima/pages/monthlyScheduler/approvalPage.dart';
import 'package:optima/pages/monthlyScheduler/monthlyScheduler.dart';
import 'package:optima/tabs/tabspage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' as xl;

import 'package:optima/pages/dashboardPages/excel_helper_web.dart';

import '../notificationService.dart';
import '../pages/dashboardPages/productionDashboardBI/MISreports/scrapDataInput.dart';
import '../pages/dashboardPages/productionDashboardBI/MISreports/sterilizationExpenses.dart';
import '../pages/dashboardPages/productionDashboardBI/MISreports/wrapsheetCalculationEntry.dart';

AttendanceList attendanceList = AttendanceList(attendanceData: []);
CheckinsDataList checkinsDataList = CheckinsDataList(checkinData: []);
LoginlogDataList loginLogDataList = LoginlogDataList(loginLogData: []);

bool attendanceData = false;
bool checkinData = false;
bool loginLogData = false;
String checkStatus = "Check In";
bool generateAttendance = false;
bool generateCheckins = false;
bool generateLoginlog = false;
String userRoleCode = "";

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});
  @override
  SideMenuState createState() => SideMenuState();
}

class SideMenuState extends State<SideMenu> {
  String userName = "";
  String userEmailId = "";
  String fromDt = "";
  String toDt = "";
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  TextEditingController locationControllerFooter = TextEditingController();
  String latitudeFooter = "";
  String longitudeFooter = "";
  bool loading = true;
  bool locationLoading = false;
  Timer? _timer;
  String? hoveredTitle; // track which tile is being hovered
  bool isHeaderHovered = false;

  void navigateToLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userJwtToken', '');
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  void initState() {
    super.initState();
    checkinData = false;
    attendanceData = false;
    loginLogData = false;
    generateAttendance = false;
    generateCheckins = false;
    generateLoginlog = false;
    checkStatus == "" ? checkStatus = "Check In" : checkStatus;
    getUserData();
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _timer?.cancel();
    attendanceData = false;
    checkinData = false;
    loginLogData = false;
    generateAttendance = false;
    generateCheckins = false;
    generateLoginlog = false;
    super.dispose();
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userJwtToken');
    prefs.remove('userMailID');
    prefs.remove('userName');
    prefs.remove('isUserLoggedIn');
    prefs.remove('userRoleCode');
    navigateToLoginPage();
  }

  void navigateToLoginPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? '';
      userEmailId = prefs.getString('userMailID') ?? '';
      userRoleCode = prefs.getString('userRoleCode') ?? '';
    });
  }

  Future<void> generateAttendaanceExcel(String fromDt, String toDt) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loadAttendanceData(
      userId,
      userJwtToken,
      userMailID,
      fromDt.toString(),
      toDt.toString(),
    );
    int numberOfRows = attendanceList.attendanceData.length;

    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    List<String> headers = [
      'EmployeeId',
      'EmployeeName',
      'ReportingEmployeeName',
    ];
    Set<String> uniqueDates = {};
    for (var attendanceData in attendanceList.attendanceData) {
      uniqueDates.addAll(attendanceData.days.keys);
    }
    headers.addAll(uniqueDates);
    sheet.appendRow(toCellRow(headers));
    int numberOfColumns = 3 + uniqueDates.length;
    for (int column = 0; column < numberOfColumns; column++) {
      var cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
      );
      cell.cellStyle = xl.CellStyle(bold: true, fontSize: 10);
    }

    for (var attendanceData in attendanceList.attendanceData) {
      List<String> row = [
        attendanceData.employeeId.toString(),
        attendanceData.employeeName,
        attendanceData.reportingEmployeeName,
      ];
      for (String date in uniqueDates) {
        row.add(attendanceData.days[date] ?? '');
      }
      sheet.appendRow(toCellRow(row));
    }

    xl.CellStyle centerCellStyle = xl.CellStyle(
      verticalAlign: xl.VerticalAlign.Center,
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    for (int rowIndex = 0; rowIndex <= numberOfRows; rowIndex++) {
      for (int colIndex = 0; colIndex < numberOfColumns; colIndex++) {
        var cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex,
          ),
        );
        if (rowIndex != 0) {
          cell.cellStyle = centerCellStyle;
        }
      }
    }

    setState(() {
      attendanceData = true;
    });

    if (kIsWeb) {
      final excelBytes = excel.encode()!;
      saveAndOpenExcel('Attendance_Report.xlsx', excelBytes);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/Attendance_Report.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<void> generateCheckinsExcel(String fromDt, String toDt) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loadCheckinsData(
      userId,
      userJwtToken,
      userMailID,
      fromDt.toString(),
      toDt.toString(),
    );
    int numberOfRows = checkinsDataList.checkinData.length;

    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    // sheet.getColAutoFits;
    sheet.appendRow(
      toCellRow([
        'Checkin Date',
        'Employee Name',
        'Checkin Time',
        'Checkout Time',
        'Duration',
      ]),
    );

    for (int column = 0; column < 5; column++) {
      var cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
      );
      cell.cellStyle = xl.CellStyle(bold: true, fontSize: 10);
    }

    for (var checkinData in checkinsDataList.checkinData) {
      sheet.appendRow(
        toCellRow([
          checkinData.checkinDate,
          checkinData.checkinUserName,
          checkinData.checkinTime,
          checkinData.checkoutTime,
          checkinData.checkinDuration,
        ]),
      );
    }

    xl.CellStyle centerCellStyle = xl.CellStyle(
      verticalAlign: xl.VerticalAlign.Center,
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    for (int rowIndex = 0; rowIndex <= numberOfRows; rowIndex++) {
      for (int colIndex = 0; colIndex < 5; colIndex++) {
        var cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex,
          ),
        );
        if (rowIndex != 0) {
          cell.cellStyle = centerCellStyle;
        }
      }
    }

    setState(() {
      checkinData = true;
    });

    if (kIsWeb) {
      final excelBytes = excel.encode()!;
      saveAndOpenExcel('Checkin_Report.xlsx', excelBytes);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/Checkin_Report.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<void> generateUsagelogExcel(String fromDt, String toDt) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _loadLoginLogData(
      userId,
      userJwtToken,
      userMailID,
      fromDt.toString(),
      toDt.toString(),
    );
    int numberOfRows = loginLogDataList.loginLogData.length;

    final excel = xl.Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow(
      toCellRow([
        'Log Date',
        'Log Mailid',
        'Log Device Ip',
        'Log Device Type',
        'Remarks',
      ]),
    );

    for (int column = 0; column < 5; column++) {
      var cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
      );
      cell.cellStyle = xl.CellStyle(bold: true, fontSize: 10);
    }

    for (var loginData in loginLogDataList.loginLogData) {
      sheet.appendRow(
        toCellRow([
          loginData.logDate,
          loginData.logUserMailId,
          loginData.logUserDeviceIp,
          loginData.logDeviceType,
          loginData.logRemarks,
        ]),
      );
    }

    xl.CellStyle centerCellStyle = xl.CellStyle(
      verticalAlign: xl.VerticalAlign.Center,
      horizontalAlign: xl.HorizontalAlign.Center,
    );

    for (int rowIndex = 0; rowIndex <= numberOfRows; rowIndex++) {
      for (int colIndex = 0; colIndex < 5; colIndex++) {
        var cell = sheet.cell(
          xl.CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex,
          ),
        );
        if (rowIndex != 0) {
          cell.cellStyle = centerCellStyle;
        }
      }
    }

    setState(() {
      loginLogData = true;
    });

    if (kIsWeb) {
      final excelBytes = excel.encode()!;
      saveAndOpenExcel('LoginLog_Report.xlsx', excelBytes);
    } else {
      String storageDir = await getStorageDirectory();
      final file = File('$storageDir/LoginLog_Report.xlsx');
      await file.writeAsBytes(excel.encode()!);
      OpenFile.open(file.path);
    }
  }

  Future<String> getStorageDirectory() async {
    String? externalDir = (await getExternalStorageDirectory())?.path;
    if (externalDir != null) {
      return externalDir;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  Future<void> _loadAttendanceData(
    String userId,
    String userJwtToken,
    String userMailID,
    String fromDt,
    String toDt,
  ) async {
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'FromDt': fromDt,
      'ToDt': toDt,
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectdailyattendance';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            List<AttendanceData> attendanceDataList = [];
            for (var visit in data) {
              Map<String, String> days = {};
              visit.forEach((key, value) {
                if (RegExp(r'^\d{2}/\d{2}/\d{4}(_Visit)?$').hasMatch(key)) {
                  days[key] = value;
                }
              });
              AttendanceData attendanceData = AttendanceData(
                employeeId: visit['EmployeeId'],
                employeeName: visit['EmployeeName'],
                reportingEmployeeName: visit['ReportingEmployeeName'],
                days: days,
              );
              attendanceDataList.add(attendanceData);
            }
            setState(() {
              attendanceList = AttendanceList(
                attendanceData: attendanceDataList,
              );
              attendanceData = true;
            });
          }
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            if (!mounted) return;
            NotificationService.warning(
              title: "Security Alert",
              message: "Invalid or Expired Token.",
            );
            navigateToLoginPage();
          } else {
            if (!mounted) return;
            NotificationService.error(
              title: "Error",
              message: responseJson["Error"].toString(),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(title: "Error", message: e.toString());
    }
  }

  Future<void> _loadCheckinsData(
    String userId,
    String userJwtToken,
    String userMailID,
    String fromDt,
    String toDt,
  ) async {
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'FromDt': fromDt,
      'ToDt': toDt,
      'UserId': userId,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectcheckins';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            List<CheckinData> checkinDataList = [];
            for (var checkin in data) {
              CheckinData checkinData = CheckinData(
                checkinDate: checkin['CheckinDate'],
                checkinUserName: checkin['CheckinUserName'],
                checkinTime: checkin['CheckinTime'],
                checkoutTime: checkin['CheckoutTime'],
                checkinDuration: checkin['CheckinDuration'],
              );
              checkinDataList.add(checkinData);
            }
            setState(() {
              checkinsDataList = CheckinsDataList(checkinData: checkinDataList);
            });
          }
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            if (!mounted) return;
            NotificationService.warning(
              title: "Security Alert",
              message: "Invalid or Expired Token.",
            );

            navigateToLoginScreen();
          } else {
            if (!mounted) return;
            NotificationService.error(
              title: "Error",
              message: responseJson["Error"].toString(),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(title: "Error", message: e.toString());
    }
  }

  Future<void> _loadLoginLogData(
    String userId,
    String userJwtToken,
    String userMailID,
    String fromDt,
    String toDt,
  ) async {
    final body = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailID,
      'FromDt': fromDt,
      'ToDt': toDt,
    };
    const apiUrl = '${ApiHelper.baseUrl}selectloginlog';
    var headers = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(body),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        if (status && responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty) {
            List<LoginlogData> loginDataList = [];
            for (var login in data) {
              LoginlogData loginLogData = LoginlogData(
                logDate: login['LogDate'],
                logUserMailId: login['LogUserMailId'],
                logUserDeviceIp: login['LogUserDeviceIp'],
                logDeviceType: login['LogDeviceType'],
                logRemarks: login['LogRemarks'],
              );
              loginDataList.add(loginLogData);
            }
            setState(() {
              loginLogDataList = LoginlogDataList(loginLogData: loginDataList);
            });
          }
        } else {
          if (responseJson.containsKey("Error") &&
              responseJson["Error"].toString() == "Invalid or Expired Token") {
            if (!mounted) return;
            NotificationService.warning(
              title: "Security Alert",
              message: "Invalid or Expired Token.",
            );
            navigateToLoginScreen();
          } else {
            if (!mounted) return;
            NotificationService.error(
              title: "Error",
              message: responseJson["Error"].toString(),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(title: "Error", message: e.toString());
    }
  }

  Widget buildHoverTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    bool isHovered = hoveredTitle == title;
    return MouseRegion(
      onEnter: (_) => setState(() => hoveredTitle = title),
      onExit: (_) => setState(() => hoveredTitle = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 30),
        color: isHovered ? Colors.blue.shade100 : Colors.transparent,
        child: ListTile(
          leading: Icon(
            icon,
            color: isHovered ? Colors.blue.shade500 : Colors.grey[800],
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isHovered ? Colors.blue.shade500 : Colors.black,
              fontWeight: isHovered ? FontWeight.w300 : FontWeight.normal,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue, // Customize the background color
            ),
            padding: const EdgeInsets.only(top: 0, left: 16, bottom: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(
                    'assets/images/${ApiHelper.projectName}/ph_user-circle-thin.png',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  userName,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  userEmailId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          buildHoverTile(
            icon: Icons.home,
            title: 'Home',
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TabsPage(selectedIndex: 0, selectedRoleCode: ""),
                ),
              );
            },
          ),
          if (userRoleCode == "R1" || userRoleCode == "R2")
            buildHoverTile(
              icon: Icons.calendar_month,
              title: 'Monthly Scheduler',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MonthlyScheduler(),
                  ),
                );
              },
            ),
          if (userRoleCode == "R1" || userRoleCode == "R2")
            buildHoverTile(
              icon: Icons.calendar_month,
              title: 'Schedule Approval',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SchedulerApproval(),
                  ),
                );
              },
            ),
          if (userRoleCode == "R1" || userRoleCode == "R2")
            buildHoverTile(
              icon: Icons.people_alt_outlined,
              title: 'Leads',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TabsPage(selectedIndex: 1, selectedRoleCode: ""),
                  ),
                );
              },
            ),
          ExpansionTile(
            leading: const Icon(Icons.dashboard_customize_outlined),
            title: const Text('BI Dashboard'),
            children: [
              if (userRoleCode == "R1" || userRoleCode == "R2")
                buildHoverTile(
                  icon: Icons.show_chart_outlined,
                  title: 'Sales',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TabsPage(selectedIndex: 2, selectedRoleCode: "R2"),
                      ),
                    );
                  },
                ),
              if (userRoleCode == "R1" || userRoleCode == "R3")
                buildHoverTile(
                  icon: Icons.price_change_outlined,
                  title: 'Finance',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TabsPage(selectedIndex: 2, selectedRoleCode: "R3"),
                      ),
                    );
                  },
                ),
              if (userRoleCode == "R1" || userRoleCode == "R4")
                buildHoverTile(
                  icon: Icons.cases_outlined,
                  title: 'Purchase',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TabsPage(selectedIndex: 2, selectedRoleCode: "R4"),
                      ),
                    );
                  },
                ),
              if (userRoleCode == "R1" || userRoleCode == "R5")
                buildHoverTile(
                  icon: Icons.factory_outlined,
                  title: 'Production',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TabsPage(selectedIndex: 2, selectedRoleCode: "R5"),
                      ),
                    );
                  },
                ),
              if (userRoleCode == "R1" || userRoleCode == "R6")
                buildHoverTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TabsPage(selectedIndex: 2, selectedRoleCode: "R6"),
                      ),
                    );
                  },
                ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.calculate),
            title: const Text('Dashboard Data Inputs'),
            children: [
              if (userRoleCode == "R1" || userRoleCode == "R5")
                buildHoverTile(
                  icon: Icons.analytics_outlined,
                  title: 'CTC Entry - Production',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SalaryInputTable(),
                      ),
                    );
                  },
                ),
              if (userRoleCode == "R1" || userRoleCode == "R5")
                buildHoverTile(
                  icon: Icons.analytics_outlined,
                  title: 'Manpower Costing Input',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManpowerCostingInputTable(),
                      ),
                    );
                  },
                ),
              if (userRoleCode == "R1" || userRoleCode == "R5")
                buildHoverTile(
                  icon: Icons.analytics_outlined,
                  title: 'Attendance Input',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AttendancePage()),
                    );
                  },
                ),
              if (userRoleCode == "R1" || userRoleCode == "R5")
                buildHoverTile(
                  icon: Icons.analytics_outlined,
                  title: 'Scrap Details Input',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ScrapInputPage()),
                    );
                  },
                ),
              if (userRoleCode == "R1" || userRoleCode == "R5")
                buildHoverTile(
                  icon: Icons.analytics_outlined,
                  title: 'Sterilization Expenses',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SterilizationExpensesPage(),
                      ),
                    );
                  },
                ),
              if (userRoleCode == "R1" || userRoleCode == "R5")
                buildHoverTile(
                  icon: Icons.analytics_outlined,
                  title: 'Wrapsheep Calculation',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WrapsheetCalculationPage(),
                      ),
                    );
                  },
                ),
            ],
          ),
          if (userRoleCode == "R1" ||
              userRoleCode == "R2" ||
              userRoleCode == "R3")
            buildHoverTile(
              icon: Icons.pie_chart_outline_outlined,
              title: 'Customer Data',
              onTap: () => {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TabsPage(selectedIndex: 3, selectedRoleCode: ""),
                  ),
                ).then((onValue) {
                  setState(() {});
                }),
              },
            ),
          if (userRoleCode == "R1")
            buildHoverTile(
              icon: Icons.person_2_outlined,
              title: 'Download Attendance',
              onTap: () {
                generateAttendance = true;
                generateCheckins = false;
                generateLoginlog = false;
                setDatePopup(context);
              },
            ),
          if (userRoleCode == "R1")
            buildHoverTile(
              icon: Icons.person_2_outlined,
              title: 'Download Checkins',
              onTap: () {
                generateAttendance = false;
                generateCheckins = true;
                generateLoginlog = false;
                setDatePopup(context);
              },
            ),
          if (userRoleCode == "R1")
            buildHoverTile(
              icon: Icons.person_2_outlined,
              title: 'Download Usage Log',
              onTap: () {
                generateAttendance = false;
                generateCheckins = false;
                generateLoginlog = true;
                setDatePopup(context);
              },
            ),
          const Divider(), // Add a horizontal line as a section break
          // ListTile(
          //   leading: const Icon(Icons.logout),
          //   title: const Text('Logout'),
          //   onTap: () {
          //     logout();
          //   },
          // ),
          buildHoverTile(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              logout();
            },
          ),
        ],
      ),
    );
  }

  Future<bool?> setDatePopup(context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            height: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Set Date"),
                const SizedBox(height: 20),
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
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      labelText: 'From Date',
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
                        initialDate: DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          1,
                        ),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                        initialEntryMode: DatePickerEntryMode.calendar,
                      );
                      if (selectedDate != null) {
                        String formattedDateTime = DateFormat('dd/MM/yyyy')
                            .format(
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
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      labelText: 'To Date',
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
                        initialEntryMode: DatePickerEntryMode.calendar,
                      );

                      if (selectedDate != null) {
                        String formattedDateTime = DateFormat('dd/MM/yyyy')
                            .format(
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
                const SizedBox(height: 70),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (generateAttendance == true) {
                            generateAttendaanceExcel(fromDt, toDt);
                          }
                          if (generateCheckins == true) {
                            generateCheckinsExcel(fromDt, toDt);
                          }
                          if (generateLoginlog == true) {
                            generateUsagelogExcel(fromDt, toDt);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2ca9df),
                        ),
                        child: const Text("Download"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
