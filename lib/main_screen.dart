import 'package:drive/login.dart';
import 'package:drive/pages/feedback.dart';
import 'package:drive/pages/my_task.dart';
import 'package:flutter/material.dart';
import 'package:drive/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:drive/pages/runsheet.dart';
import 'package:package_info/package_info.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  ApiService apiService = ApiService();
  Runsheet runsheet = Runsheet();
  // DBHelper dbHelper = DBHelper();
  bool isDarkMode = false;
  String mode = 'Light';
  int _currentIndex = 0;
  String currentPageTitle = 'My Task';
  Map<String, dynamic> driver = {};
  String _appVersion = '';

  final List<Widget> _children = [
    const MyTaskPage(),
    const FeedbackPage()
  ];

  final ThemeData kLightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.red,
  );

  final ThemeData kDarkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.red,
  );

  void _toggleTheme() {
    setState(() {
      if (isDarkMode == true) {
        mode = 'Dark';
      } else {
        mode = 'Light';
      }
    });
  }

  Future<void> user_info() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (userdata != null) {
      setState(() {
        driver = json.decode(userdata);
        _appVersion = packageInfo.version;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    user_info();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return Theme(
        data: isDarkMode ? kDarkTheme : kLightTheme,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text(currentPageTitle),
            // actions: [
            //   Padding(
            //       padding: const EdgeInsets.all(8.0),
            //       child: Align(
            //           alignment: Alignment.centerRight,
            //           child: TextButton.icon(
            //               onPressed: () async {
            //                 await runsheet.runsheet();
            //                 // _handleRefresh(context);
            //               },
            //               icon: const Icon(Icons.refresh, color: Colors.white),
            //               label: const Text(
            //                 'Refresh',
            //                 style: TextStyle(color: Colors.white),
            //               ))))
            // ],
          ),
          drawer: Drawer(
            child: ListView(
              children: <Widget>[
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    // image: DecorationImage(
                    //     image: AssetImage("assets/images/profile.png"),
                    //     alignment: Alignment.topCenter,
                    //     fit: BoxFit.contain)
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      const CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage('assets/images/profile.png'),
                      ),
                      const SizedBox(height: 5),
                      // Text(
                      //   "${driver['trucker']}",
                      //   style: const TextStyle(color: Colors.white),
                      // ),
                      Text(
                        "DRIVER : ${driver['name']}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        "PLATE # : ${driver['plate_no']}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'DUTY DATE : ${now.month}/${now.day}/${now.year}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.assignment_add,
                  ),
                  title: const Text('My Task', style: TextStyle()),
                  onTap: () {
                    setState(() {
                      _currentIndex = 0;
                      currentPageTitle = 'My Task';
                    });
                    Navigator.pop(context, MaterialPageRoute(builder: (context) => const MyTaskPage()));
                  },
                ),
                ListTile(
                  leading: (isDarkMode ? const Icon(Icons.dark_mode) : const Icon(Icons.light_mode)),
                  title: Text('$mode Mode', style: const TextStyle()),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        _toggleTheme();
                        isDarkMode = value;
                      });
                    },
                  ),
                ),
                ListTile(
                    leading: const Icon(
                      Icons.comment,
                    ),
                    title: const Text('Feedback', style: TextStyle()),
                    onTap: () {
                      setState(() {
                        _currentIndex = 1;
                        currentPageTitle = 'Feedback';
                      });
                      Navigator.pop(context, MaterialPageRoute(builder: (context) => const FeedbackPage()));
                    }),
                ListTile(
                  leading: const Icon(
                    Icons.build,
                  ),
                  title: const Text('Version', style: TextStyle()),
                  trailing: Text(_appVersion),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout', style: TextStyle()),
                  onTap: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text(
                            'Are you sure you want to end the shift?',
                            style: TextStyle(fontSize: 16),
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    )),
                                child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.red),
                                    ))),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                                onPressed: () {
                                  resetPreferences();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade900,
                                    minimumSize: const Size.fromHeight(40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    )),
                                icon: const Icon(Icons.logout),
                                label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Logout'))),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          body: _children[_currentIndex],
        ));
  }

  Future<void> resetPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }
}
