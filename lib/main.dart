import 'package:drive/home.dart';
import 'package:drive/login.dart';
import 'package:drive/maps/maps.dart';
import 'package:flutter/material.dart';
import 'package:drive/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_background/flutter_background.dart';
// import 'package:background_fetch/background_fetch.dart';
import 'package:connectivity/connectivity.dart';
import 'package:drive/helper/db_helper.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:convert';
// import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'dart:io';

void main() async {
  runApp(const MyApp());
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ApiService apiService = ApiService();
  DBHelper dbHelper = DBHelper();
  bool isLoggedIn = false;
  List runsheetList = [];
  List bookingList = [];
  final bool _isDarkMode = false;
  bool isDatabaseInitialized = false;

  final ThemeData kLightTheme = ThemeData(
    appBarTheme: const AppBarTheme(
      color: Colors.red, // Set the app bar color to blue
    ),
    brightness: Brightness.light,
    // primarySwatch: Colors.blue,
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
    initialization();
    openDatabaseOrInitialize();
    checkLoggedIn();
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
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      final data = await dbHelper.getAll('runsheet');
      final booking = await dbHelper.getAll('booking');
      if (data.isEmpty || booking.isEmpty) {
        exception();
        tasklist();
        runsheet();
      }
    }
    // else {
    //   SharedPreferences prefs = await SharedPreferences.getInstance();
    //   await prefs.clear();
    //   setState(() {
    //     Navigator.pushAndRemoveUntil(
    //       context as BuildContext,
    //       MaterialPageRoute(builder: (context) => LoginPage()),
    //       (Route<dynamic> route) => false,
    //     );
    //   });
    // }
  }

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> runsheet() async {
    var filter = {'plate_no': 'ABC123'};
    final params = {'page': 1, 'filter': jsonEncode(filter)};
    final response = await apiService.getData('runsheet', params: params);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      var data = responseData['data']['data'];
      var book = [];
      runsheetList = data.map((rn) {
        rn['item_details'].forEach((key, value) {
          book.add(value);
        });
        return {
          'id': rn['id'],
          'runsheet_id': rn['id'],
          'cbm': rn['cbm'],
          'charging_type': rn['charging_type'],
          'date_from': rn['date_from'],
          'date_to': rn['date_to'],
          'dr_no': rn['dr_no'],
          'est_tot_cbm': rn['est_tot_cbm'],
          'est_tot_pcs': rn['est_tot_pcs'],
          'est_tot_wt': rn['est_tot_wt'],
          'from_loc': rn['from_loc'],
          'plate_no': rn['plate_no'],
          'reference': rn['reference'],
          'remarks': rn['remarks'],
          'status': rn['status'],
          'task': rn['task'],
          'to_loc': rn['to_loc'],
          'total_pcs': rn['total_pcs'],
          'total_wt': rn['total_wt'],
          'tracking_no': rn['tracking_no'],
          'trucking_id': rn['trucking_id'],
          'updated_at': rn['updated_at'],
          'user_id': rn['user_id'],
          'vehicle_id': rn['vehicle_id'],
          'vehicle_type': rn['vehicle_type']
        };
      }).toList();
      await dbHelper.save('runsheet', runsheetList);
      await dbHelper.save('booking', book);
    } else {
      print('Error: ${response.reasonPhrase}');
    }
  }

  Future<void> tasklist() async {
    await dbHelper.truncateTable('tasks');
    final response = await apiService
        .getData('tasks', params: {'itemsPerPage': -1, 'group_by': 4});
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      var data = responseData['data']['data'];
      List task = data.map((tks) {
        return {
          'id': tks['id'],
          'code': tks['code'],
          'name': tks['name'],
          'sequence_no': tks['sequence_no'],
          'task': tks['task']
        };
      }).toList();
      await dbHelper.save('tasks', task);
    } else {
      print('Error: ${response.reasonPhrase}');
    }
  }

  Future<void> exception() async {
    await dbHelper.truncateTable('exception');
    final response = await apiService.getData('exception_actions');
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      var data = responseData['data'];
      List except = data.map((tks) {
        return {
          'code': tks['code'],
          'name': tks['name'],
          'description': tks['description'],
          'task_id': tks['task_id']
        };
      }).toList();
      await dbHelper.save('exception', except);
    } else {
      print('Error: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: isDarkMode ? kDarkTheme : kLightTheme, home: LoginPage()
        // home: isLoggedIn ? WelcomePage() : LoginPage(),
        );
  }
}
