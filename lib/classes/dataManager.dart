// ignore_for_file: file_names

import 'package:shared_preferences/shared_preferences.dart';

class DataManager {
  static DateTime? _selectedDate;
  static void saveSelectedDate(DateTime date) {
    _selectedDate = date;
  }

  static DateTime? readSelectedDate() {
    return _selectedDate;
  }

  static void saveSelectedDateCalendar(DateTime date) {
    _selectedDate = date;
  }

  static DateTime? readSelectedDateCalendar() {
    return _selectedDate;
  }

  static String? _sapToken;
  static void saveSapToken(String token) {
    _sapToken = token;
  }

  static String? readSapToken() {
    return _sapToken;
  }

  static Future<bool> readLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isUserLoggedIn') ?? false;
  }

  static int? _checkinId;
  static void saveCheckinId(int id) {
    _checkinId = id;
  }

  static int? readCheckinId() {
    return _checkinId;
  }

  static String? _saveStatus;
  static void saveCheckinStatus(String status) {
    _saveStatus = status;
  }

  static String? readCheckinStatus() {
    return _saveStatus;
  }
}
