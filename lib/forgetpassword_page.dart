// ignore_for_file: avoid_print, use_build_context_synchronously
import 'api_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:optima/resetpassword_page.dart';
import 'package:http/http.dart' as http;

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});
  @override
  OTPScreenState createState() => OTPScreenState();
}

class OTPScreenState extends State<OTPScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otp1Controller = TextEditingController();
  final TextEditingController otp2Controller = TextEditingController();
  final TextEditingController otp3Controller = TextEditingController();
  final TextEditingController otp4Controller = TextEditingController();

  FocusNode otp1FocusNode = FocusNode();
  FocusNode otp2FocusNode = FocusNode();
  FocusNode otp3FocusNode = FocusNode();
  FocusNode otp4FocusNode = FocusNode();
  FocusNode otpNextFocusNode = FocusNode();
  String generatedOTP = "";
  String email = "";
  Future<String> _getOtp() async {
    final random = Random();
    final otp = 1000 + random.nextInt(9000);
    return otp.toString();
  }

  void _buttonClick() {
    String otp1 = otp1Controller.text.trim();
    String otp2 = otp2Controller.text.trim();
    String otp3 = otp3Controller.text.trim();
    String otp4 = otp4Controller.text.trim();
    if (otp1.isNotEmpty &&
        otp2.isNotEmpty &&
        otp3.isNotEmpty &&
        otp4.isNotEmpty) {
      _validateOtp(otp1 + otp2 + otp3 + otp4);
    } else {
      _sendOtp();
    }
  }

  void _validateOtp(String otp) {
    if (generatedOTP == otp) {
      navigateToResetPassword(email);
    } else {
      const snackBar = SnackBar(content: Text('Invalid OTP'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _sendOtp() async {
    email = emailController.text;
    _showEmailDialog(email);
    generatedOTP = await _getOtp();
    final data = {'email': email, 'message': generatedOTP};
    const apiUrl = '${ApiHelper.baseUrl}sendforgotpasswordotp';
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
        if (status) {
        } else {
          const snackBar = SnackBar(content: Text('Failed'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text('Error: $e'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _showEmailDialog(String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert'),
          content: Text('OTP sent to email id: $email'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void navigateToResetPassword(String email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetpasswordScreen(email: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Align(
          alignment: Alignment.topLeft,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: const Icon(
                  Icons.keyboard_arrow_left,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Forgot Password',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF2CA9DF),
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
                      "Forgot Password",
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Align the OTP fields with the left side
                children: [
                  SizedBox(
                    height: 50,
                    width: 350,
                    child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            10.0,
                          ), // Add border radius
                        ),
                        labelText: 'Email Id',
                        // hintText: 'Enter your email id here.',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 5.0),
                    child: Text(
                      'Enter Your OTP',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF454545),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ), // Decrease the space between phone number and OTP fields
                  Row(
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Align the OTP fields vertically with the phone field
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.0,
                        ), // Add equal spacing between OTP fields
                        child: SizedBox(
                          width: 60, // Adjust the width as needed
                          height: 50,
                          child: TextField(
                            controller: otp1Controller,
                            focusNode: otp1FocusNode,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  10.0,
                                ), // Add border radius
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                otp1FocusNode.unfocus();
                                FocusScope.of(
                                  context,
                                ).requestFocus(otp2FocusNode);
                              }
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.0,
                        ), // Add equal spacing between OTP fields
                        child: SizedBox(
                          width: 60, // Adjust the width as needed
                          height: 50,
                          child: TextField(
                            controller: otp2Controller,
                            focusNode: otp2FocusNode,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  10.0,
                                ), // Add border radius
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                otp2FocusNode.unfocus();
                                FocusScope.of(
                                  context,
                                ).requestFocus(otp3FocusNode);
                              }
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.0,
                        ), // Add equal spacing between OTP fields
                        child: SizedBox(
                          width: 60, // Adjust the width as needed
                          height: 50,
                          child: TextField(
                            controller: otp3Controller,
                            focusNode: otp3FocusNode,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  10.0,
                                ), // Add border radius
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                otp3FocusNode.unfocus();
                                FocusScope.of(
                                  context,
                                ).requestFocus(otp4FocusNode);
                              }
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.0,
                        ), // Add equal spacing between OTP fields
                        child: SizedBox(
                          width: 60,
                          height: 50,
                          child: TextField(
                            controller: otp4Controller,
                            focusNode: otp4FocusNode,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  8.0,
                                ), // Add border radius
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                otp4FocusNode.unfocus();
                                FocusScope.of(
                                  context,
                                ).requestFocus(otpNextFocusNode);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 90,
                  ), // Add spacing between OTP fields and "Next" button
                  Container(
                    height: 50,
                    width: 350, // Increase the width here
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(
                        10.0,
                      ), // Add border radius
                    ),
                    child: TextButton(
                      focusNode: otpNextFocusNode,
                      onPressed: () => _buttonClick(),
                      child: const Text(
                        'Next',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
