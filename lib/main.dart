import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
// import 'package:workmanager/workmanager.dart';
// import 'package:background_fetch/background_fetch.dart';
import 'package:drive/connectivity_service.dart';
import 'package:drive/helper/db_helper.dart';
import 'package:drive/login.dart';
import 'package:drive/main_screen.dart';
import 'package:drive/pages/exceptionlist.dart';
import 'package:drive/pages/runsheet.dart';
import 'package:drive/pages/tasklist.dart';
import 'package:drive/services/api_service.dart';
import 'package:drive/service.dart';
// import 'package:drive/sync_background.dart';
// import 'package:drive/sync_worker.dart';
// import 'package:package_info/package_info.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  await dotenv.load();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
  ConnectivityService.initialize();
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Service service = Service();
  late BuildContext dialogContext;
  Timer? _timer;
  final ApiService apiService = ApiService();
  ConnectivityService connectivity = ConnectivityService();
  DBHelper dbHelper = DBHelper();
  Runsheet runsheet = Runsheet();
  Tasklist tasklist = Tasklist();
  Exceptionlist exceptionlist = Exceptionlist();
  bool isLoggedIn = false;
  List runsheetList = [];
  List bookingList = [];
  bool isDatabaseInitialized = false;
  Map<String, dynamic> driver = {};

  String currentVersion = '';

  bool _enabled = true;
  int _status = 0;
  List<DateTime> _events = [];

  final ThemeData kLightTheme = ThemeData(
    appBarTheme: const AppBarTheme(
      color: Colors.red, // Set the app bar color to blue
    ),
    brightness: Brightness.light,
  );

  final ThemeData kDarkTheme = ThemeData(
    appBarTheme: const AppBarTheme(
      color: Colors.red, // Set the app bar color to blue
    ),
    brightness: Brightness.dark,
    // primarySwatch: Colors.blue,
  );
  bool isDarkMode = false;
  @override
  void initState() {
    super.initState();
    _initConnectivity();
    Timer.periodic(Duration(seconds: 20), (timer) {
      service.syncData();
    });
    initialization();
    openDatabaseOrInitialize();
    checkLoggedIn();
  }

  @override
  void dispose() {
    _timer!.cancel();
    super.dispose();
  }

  void _initConnectivity() async {
    bool _isConnected = await connectivity.isConnected();
    if (_isConnected) {
      final params = {
        'page': 1,
        'filter': jsonEncode({'plate_no': driver['plate_id']}),
        'itemsPerPage': '999',
        'device': 'mobile'
      };
      await runsheet.runsheet(params);
    }
  }

  void openDatabaseOrInitialize() async {
    String databasePath = await getDatabasesPath();
    String databaseName = 'trams.db';
    String path = join(databasePath, databaseName);

    bool isdbexists = await databaseExists(path);
    if (isdbexists == false) {
      await dbHelper.initDB();
    }
  }

  Future<bool> databaseExists(String path) async {
    return File(path).exists();
  }

  void initialization() async {
    FlutterNativeSplash.remove();
  }

  void checkLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('token');
    final userdata = prefs.getString('user');
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      setState(() {
        driver = json.decode(userdata!);
      });
      final task = await dbHelper.getAll('tasks');
      final except = await dbHelper.getAll('exception');
      if (task.isEmpty) {
        tasklist.tasklist({'itemsPerPage': -1, 'group_by': 4});
      }
      if (except.isEmpty) {
        exceptionlist.exception();
      }
      final params = {
        'page': 1,
        'filter': jsonEncode({'plate_no': driver['plate_id']}),
        'itemsPerPage': '999'
      };
      runsheet.runsheet(params);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: isDarkMode ? kDarkTheme : kLightTheme,
        home: isLoggedIn ? const MainScreen() : const LoginPage());
  }
}
