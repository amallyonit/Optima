// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:optima/classes/dataManager.dart';
import 'package:optima/classes/globals.dart';
import 'api_helper.dart';
import 'package:flutter/material.dart';
import 'package:optima/tabs/tabspage.dart';
import 'package:optima/forgetpassword_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

String sapToken = "";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  bool _isLoading = true;
  String currentVersion = "";
  bool biometricEnabled = false;

  final LocalAuthentication auth = LocalAuthentication();
  FlutterSecureStorage? secureStorage;
  @override
  void initState() {
    super.initState();
    getVersionNumber();
    if (!kIsWeb) {
      secureStorage = const FlutterSecureStorage();
    }
    loadData();
  }

  @override
  void dispose() {
    try {
      if (mounted) {
        emailController.dispose();
        passwordController.dispose();
      }
      super.dispose();
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? '';
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    final userMailID = prefs.getString('userMailID') ?? '';
    await _sapApiToken();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final enabled = await secureStorage?.read(key: 'biometric_enabled');

      biometricEnabled = enabled == 'true';
      if (!mounted) return;
      setState(() {});
    }

    await checkUserTokenAndNavigate(
      userJwtToken,
      userName,
      sapToken,
      userMailID,
    );
  }

  Future<void> setLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isUserLoggedIn', false);
  }

  Future<void> checkUserTokenAndNavigate(
    String userJwtToken,
    String userName,
    String sapToken,
    String userMailId,
  ) async {
    bool validToken = false;

    final data = {'UserJwtToken': userJwtToken, 'UsermailID': userMailId};
    const apiUrl = '${ApiHelper.baseUrl}isvalidtoken';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        validToken = responseJson["Status"];
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    if (validToken) {
      DataManager.saveSapToken(sapToken);
      isUserLoggedIn = await DataManager.readLoginStatus();
      if (isUserLoggedIn) {
        setSelectedDate();
        navigateToHomePage();
      } else {
        // Token is valid but user is not logged in; stop showing the loading indicator
        if (!mounted) return;
        setState(() {
          setLoginStatus();
          _isLoading = false;
        });
      }
    } else {
      // User not logged in; stop showing the loading indicator
      if (!mounted) return;
      setState(() {
        setLoginStatus();
        _isLoading = false;
      });
    }
  }

  Future<void> selectCheckinStatus(
    String userJwtToken,
    String userName,
    String sapToken,
    String userMailId,
  ) async {
    final data = {'UserJwtToken': userJwtToken, 'UsermailID': userMailId};
    const apiUrl = '${ApiHelper.baseUrl}selectcheckinstatus';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson["Data"].toString().isNotEmpty) {
          List<dynamic> data = responseJson['Data'];
          if (data.isNotEmpty && data[0] is Map<String, dynamic>) {
            DataManager.saveCheckinStatus(data[0]["CheckinStatus"].toString());
          }
        }
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  bool _isLoginLoading = false;
  bool _isLoginpasswordVisible = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _login() async {
    if (!mounted) return;
    setState(() {
      _isLoginLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    String email = emailController.text;
    String password = passwordController.text;
    final data = {'UsermailID': email, 'Password': password};
    const apiUrl = '${ApiHelper.baseUrl}login';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: headerss,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        bool status = responseJson["Status"];
        String? token = DataManager.readSapToken();
        if (token == null || sapToken.isEmpty) {
          await _sapApiToken();
          DataManager.saveSapToken(sapToken);
        }

        await prefs.setBool('isUserLoggedIn', false);
        if (status && responseJson["Data"].toString().isNotEmpty) {
          await _showBiometricDialog(email, password);

          final userJwtToken = responseJson["Data"][0]["UserJwtToken"];
          final userName = responseJson["Data"][0]["UserName"];
          final userId = responseJson["Data"][0]["UserID"].toString();
          final userLevel = responseJson["Data"][0]["UserLevel"].toString();
          final userRoleCode = responseJson["Data"][0]["UserRoleCode"]
              .toString();

          await selectCheckinStatus(userJwtToken, userName, sapToken, email);
          await prefs.setString('userJwtToken', userJwtToken);
          await prefs.setString('userMailID', email);
          await prefs.setString('userName', userName);
          await prefs.setString('userId', userId);
          await prefs.setString('userLevel', userLevel);
          await prefs.setString('userRoleCode', userRoleCode);
          await prefs.setBool('isUserLoggedIn', true);
          await _saveLoginLog(email, userJwtToken, password, "");
          DataManager.saveCheckinStatus(
            responseJson["Data"][0]["UserCheckinStatus"].toString(),
          );
          setSelectedDate();
          navigateToHomePage();
        } else {
          if (!mounted) return;
          setState(() {
            _isLoginLoading = false;
          });
          await prefs.setBool('isUserLoggedIn', false);
          const snackBar = SnackBar(content: Text('Login failed'));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      } else {
        if (!mounted) return;
        setState(() {
          _isLoginLoading = false;
        });
        await prefs.setBool('isUserLoggedIn', false);
        const snackBar = SnackBar(content: Text('Login failed'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoginLoading = false;
      });
      await prefs.setBool('isUserLoggedIn', false);
      const snackBar = SnackBar(content: Text('Login failed.'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> _showBiometricDialog(String email, String password) async {
    final biometrics = await auth.getAvailableBiometrics();
    if (biometrics.isEmpty) {
      return;
    }

    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    final enabled = await secureStorage?.read(key: 'biometric_enabled');

    // Already configured once
    if (enabled != null) {
      return;
    }

    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enable Fingerprint Login'),
          content: const Text(
            'Do you want to enable biometric login on this device?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (!mounted) return;
      setState(() {
        biometricEnabled = true;
      });
      await secureStorage?.write(key: 'email', value: email);
      await secureStorage?.write(key: 'password', value: password);
      await secureStorage?.write(key: 'biometric_enabled', value: 'true');
    } else {
      if (!mounted) return;
      setState(() {
        biometricEnabled = false;
      });
      await secureStorage?.write(key: 'biometric_enabled', value: 'false');
    }
  }

  Future<void> biometricLogin() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Biometric authentication not available"),
          ),
        );
        return;
      }

      bool authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: false,
        ),
      );

      if (authenticated) {
        String? savedEmail = await secureStorage?.read(key: 'email');
        String? savedPassword = await secureStorage?.read(key: 'password');

        if (savedEmail != null && savedPassword != null) {
          emailController.text = savedEmail;
          passwordController.text = savedPassword;

          _login();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No saved credentials found")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Biometric Error: $e")));
    }
  }

  Future<void> _saveLoginLog(
    String userMailId,
    String userJwtToken,
    String userPassword,
    String userRemarks,
  ) async {
    String userDeviceIp = await _getDeviceIp();
    String userDeviceType = await _getDeviceType();
    String sessionID = const Uuid().v4();

    final payload = {
      'UserJwtToken': userJwtToken,
      'UsermailID': userMailId,
      "UserPassword": userPassword,
      "UserDeviceIp": userDeviceIp,
      "UserDeviceType": userDeviceType,
      "UserRemarks": userRemarks,
      "SessionID": sessionID,
    };

    const apiUrl = '${ApiHelper.baseUrl}insertloginlog';
    var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(payload),
        headers: headerss,
      );

      if (response.statusCode == 200) {
      } else {}
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save: $e")));
    }
  }

  Future<String> _getDeviceType() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        return "Web Browser";
      } else if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return 'Android - ${info.model}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return 'iOS - ${info.utsname.machine}';
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        return 'Windows - ${info.computerName}';
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        return 'macOS - ${info.model}';
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        return 'Linux - ${info.prettyName}';
      } else {
        return "Unknown Platform";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String> _getDeviceIp() async {
    try {
      if (kIsWeb) {
        // Use external API for public IP (since local IP is restricted in browsers)
        final response = await http.get(
          Uri.parse('https://api.ipify.org?format=json'),
        );
        if (response.statusCode == 200) {
          return jsonDecode(response.body)['ip'];
        } else {
          return 'Unknown';
        }
      } else {
        // Local IP for Android/iOS/Desktop
        final interfaces = await NetworkInterface.list();
        for (var interface in interfaces) {
          for (var addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
              return addr.address;
            }
          }
        }
        return 'Unknown';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> _sapApiToken() async {
    const apiUrl = '${ApiHelper.baseUrl}sapToken';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        sapToken = responseData['token'];
      } else {
        final snackBar = SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(
            'Failed to fetch SAP Token. Status code: ${response.statusCode}',
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Error: $e'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void setSelectedDate() async {
    DateTime selectedDate = DateTime.now();
    DataManager.saveSelectedDate(selectedDate);
  }

  void getVersionNumber() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    currentVersion = packageInfo.version;
  }

  void navigateToHomePage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TabsPage(selectedIndex: 0, selectedRoleCode: ""),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  SizedBox(height: screenHeight / 10),
                  const Center(
                    child: Image(
                      image: AssetImage(
                        'assets/images/${ApiHelper.projectName}/companyName.png',
                      ),
                      width: 300,
                      height: 100,
                    ),
                  ),
                  SizedBox(height: screenHeight / 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF454545),
                            ),
                          ),
                        ),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: UnderlineInputBorder(),
                            labelText: 'Email',
                            hintStyle: TextStyle(fontSize: 14),
                          ),
                        ),
                        TextField(
                          controller: passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText:
                              !_isLoginpasswordVisible, // Toggle visibility
                          decoration: InputDecoration(
                            isDense: true,
                            border: UnderlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            labelText: 'Password',
                            labelStyle: const TextStyle(
                              color: Color(0xFF454545),
                            ),
                            // hintText: 'Enter secure password',
                            hintStyle: const TextStyle(fontSize: 16),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isLoginpasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                // Change the icon based on the _isResetpasswordVisible state
                              ),
                              onPressed: () {
                                setState(() {
                                  _isLoginpasswordVisible =
                                      !_isLoginpasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OTPScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot Password',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF454545),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 50,
                          width: 370, // Increase the width here
                          decoration: BoxDecoration(
                            color: const Color(0xFF2CA9DF),
                            borderRadius: BorderRadius.circular(
                              6,
                            ), // Increase the border radius here
                          ),
                          child: TextButton(
                            onPressed: _isLoginLoading ? null : () => _login(),
                            child: _isLoginLoading
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                        ),
                        !kIsWeb && biometricEnabled
                            ? const SizedBox(height: 15)
                            : const SizedBox.shrink(),

                        !kIsWeb && biometricEnabled
                            ? IconButton(
                                icon: const Icon(
                                  Icons.fingerprint,
                                  size: 35,
                                  color: Color(0xFF2CA9DF),
                                ),
                                onPressed: biometricLogin,
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight / 10),
                  Column(
                    children: [
                      const Center(
                        child: Image(
                          image: AssetImage(
                            'assets/images/${ApiHelper.projectName}/optima.png',
                          ),
                          width: 150,
                          height: 50,
                        ),
                      ),
                      Text(
                        'v $currentVersion',
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF878787),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
