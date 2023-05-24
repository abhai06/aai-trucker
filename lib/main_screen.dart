import 'package:drive/login.dart';
import 'package:drive/pages/exception_task.dart';
import 'package:drive/pages/my_task.dart';
import 'package:drive/pages/pending_task.dart';
import 'package:drive/pages/done_task.dart';
import 'package:flutter/material.dart';
import 'package:drive/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  ApiService apiService = ApiService();
  // DBHelper dbHelper = DBHelper();
  bool isDarkMode = false;
  String mode = 'Light';
  int _currentIndex = 0;
  String currentPageTitle = 'My Task';
  Map<String, dynamic> driver = {};

  final List<Widget> _children = [
    const MyTaskPage(),
    const PendingTaskPage(),
    const DoneTaskPage(),
    const ExceptionTaskPage()
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
    if (userdata != "") {
      setState(() {
        driver = json.decode(userdata!);
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
          appBar: AppBar(
            title: Text(currentPageTitle),
            // actions: [
            //   Builder(builder: (context) {
            //     if (_currentIndex == 0) {
            //       return IconButton(
            //         icon: const Icon(Icons.sync),
            //         onPressed: () async {
            // await runsheet();
            // await tasklist();
            // await exception();
            // final res = await dbHelper.getAll('exception');
            // print(res);
            //         },
            //       );
            //     } else {
            //       return Container();
            //     }
            //   })
            // ]
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
                        backgroundImage:
                            AssetImage('assets/images/profile.png'),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "DRIVER : ${driver['name']}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Text(
                        'PLATE # : 002896',
                        style: TextStyle(color: Colors.white),
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
                    color: Colors.indigo,
                  ),
                  title: const Text('My Task', style: TextStyle()),
                  onTap: () {
                    setState(() {
                      _currentIndex = 0;
                      currentPageTitle = 'My Task';
                    });
                    Navigator.pop(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyTaskPage()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.pending, color: Colors.blue[900]),
                  title: const Text('In Progress', style: TextStyle()),
                  onTap: () {
                    setState(() {
                      _currentIndex = 1;
                      currentPageTitle = 'In Progress';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.done,
                    color: Colors.green,
                  ),
                  title: const Text('Done', style: TextStyle()),
                  onTap: () {
                    setState(() {
                      _currentIndex = 2;
                      currentPageTitle = 'Completed';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: (isDarkMode
                      ? const Icon(Icons.dark_mode)
                      : const Icon(Icons.light_mode)),
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
                  leading: const Icon(Icons.logout, color: Colors.orange),
                  title: const Text('Logout', style: TextStyle()),
                  onTap: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.clear();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
          body: _children[_currentIndex],
        ));
  }
}
