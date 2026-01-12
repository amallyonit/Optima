// ignore_for_file: avoid_print, use_build_context_synchronously
import 'package:shared_preferences/shared_preferences.dart';
import 'api_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:optima/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetpasswordScreen extends StatefulWidget {
  // const ResetpasswordScreen({super.key});
  final String email;
  const ResetpasswordScreen({super.key, required this.email});
  @override
  ResetpasswordScreenstate createState() => ResetpasswordScreenstate();
}

class ResetpasswordScreenstate extends State<ResetpasswordScreen> {
  bool _isPasswordVisible = false;
  bool _isResetpasswordVisible = false;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController newpasswordController = TextEditingController();

  void _changePassword() async {
    String password = passwordController.text;
    String newpassword = newpasswordController.text;
    final prefs = await SharedPreferences.getInstance();
    final userJwtToken = prefs.getString('userJwtToken') ?? '';
    prefs.remove('userJwtToken');
    prefs.remove('userMailID');
    final data = {
      'UsermailID': widget.email,
      'Password': password,
      'NewPassword': newpassword,
      'UserJwtToken': userJwtToken,
    };
    if (password == newpassword) {
      const apiUrl = '${ApiHelper.baseUrl}changepassword';
      var headerss = {HttpHeaders.contentTypeHeader: 'application/json'};
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          body: jsonEncode(data),
          headers: headerss,
        );
        if (response.statusCode == 200) {
          if (response.body == '"1"') {
            navigateToLoginPage();
          } else {
            final Map<String, dynamic> responseJson = jsonDecode(response.body);
            final snackBar = SnackBar(
              content: Text(responseJson["Error"].toString()),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      } catch (e) {
        final snackBar = SnackBar(content: Text('Error: $e'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      const snackBar = SnackBar(content: Text('Password mismatch'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void navigateToLoginPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 255, 255, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 99, 97, 97),
        title: const Text(
          "Optima",
          style: TextStyle(
            fontSize: 18,
            color: Color.fromARGB(255, 204, 198, 198),
            // color: Color(0xFF454545),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(top: 150.0, bottom: 20.0),
              child: Center(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20.0),
                    child: Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF454545),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: SizedBox(
                height: 50,
                width: 350,
                child: TextField(
                  controller: passwordController,
                  obscureText: !_isPasswordVisible, // Toggle visibility
                  decoration: InputDecoration(
                    border: const UnderlineInputBorder(),
                    labelText: 'Enter password',
                    hintText: 'New password',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: SizedBox(
                height: 50,
                width: 380,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    controller: newpasswordController,
                    obscureText: !_isResetpasswordVisible,
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      labelText: 'Re-enter password',
                      labelStyle: const TextStyle(color: Color(0xFF454545)),
                      hintText: 'Re-entered password',
                      hintStyle: const TextStyle(fontSize: 16),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isResetpasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isResetpasswordVisible = !_isResetpasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 30.0, right: 20, top: 10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 60.0),
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Use at least 8 characters with 1 number, and one special character.',
                      style: TextStyle(color: Color(0xFF8F8F8F), fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 50,
              width: 350,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextButton(
                onPressed: () => _changePassword(),
                child: const Text(
                  'Reset Password',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
