import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drive/helper/db_helper.dart';
import 'package:drive/main_screen.dart';
import 'package:drive/services/api_service.dart';

import 'package:drive/pages/runsheet.dart';
import 'package:drive/pages/tasklist.dart';
import 'package:drive/pages/exceptionlist.dart';
import 'package:drive/connectivity_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final ApiService apiService = ApiService();
  ConnectivityService connectivity = ConnectivityService();
  DBHelper dbHelper = DBHelper();
  Runsheet runsheet = Runsheet();
  Tasklist tasklist = Tasklist();
  Exceptionlist exceptionlist = Exceptionlist();

  List runsheetList = [];
  List bookingList = [];
  bool _isLoading = true;
  Map<String, dynamic> driver = {};
  Future<void> user_info() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != "") {
      setState(() {
        driver = json.decode(userdata!);
      });
      final task = {'itemsPerPage': '-1', 'group_by': '4'};
      tasklist.tasklist(task);
      exceptionlist.exception();
      final params = {
        'page': '1',
        'filter': jsonEncode({'plate_no': driver['plate_id']}),
        'itemsPerPage': '999',
        'device': 'mobile'
      };
      runsheet.runsheet(params);
    } else {
      user_info;
    }
  }

  void _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      user_info();
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _simulateLoading();
  }

  void _initConnectivity() async {
    bool _isConnected = await connectivity.isConnected();
    if (!_isConnected) {
      ConnectivityService.noInternetDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: _isLoading
            ? Center(
                child: Lottie.asset(
                  "assets/animations/loading.json",
                  animate: true,
                  alignment: Alignment.center,
                  height: 100,
                  width: 100,
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 150),
                    Text(
                      "Welcome ${driver['name']?.toUpperCase()}! \n",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Ready to head out?',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),
                    const Image(
                      image: AssetImage("assets/images/driver.png"),
                      height: 150,
                      width: 150,
                    ),
                    const SizedBox(height: 100),
                    Container(
                        padding: const EdgeInsets.all(16),
                        width: 300,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                minimumSize: const Size.fromHeight(40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                )),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('GO ONLINE'),
                            ),
                            onPressed: () async {
                              bool _isConnected =
                                  await connectivity.isConnected();
                              if (!_isConnected) {
                                ConnectivityService.noInternetDialog(context);
                              } else {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const MainScreen()));
                              }
                            })),
                  ],
                ),
              ));
  }
}
