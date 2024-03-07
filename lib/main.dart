import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drive/connectivity_service.dart';
import 'package:drive/helper/db_helper.dart';
import 'package:drive/login.dart';
import 'package:drive/main_screen.dart';
import 'package:drive/service.dart';
import 'package:drive/services/api_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  await dotenv.load();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  try {
    OneSignal.initialize(
      dotenv.env['ONE_SIGNAL_APP_ID'] ?? '',
    );
    OneSignal.Notifications.requestPermission(true);
  } catch (e) {
    print(e);
  }
  ConnectivityService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Service service = Service();
  late BuildContext dialogContext;
  ConnectivityService connectivity = ConnectivityService();
  ApiService api = ApiService();
  DBHelper dbHelper = DBHelper();
  bool isLoggedIn = false;
  Map<String, dynamic> driver = {};
  String? baseUrl;
  String currentVersion = '';

  final ThemeData kLightTheme = ThemeData(
    appBarTheme: const AppBarTheme(
      color: Colors.red,
    ),
    brightness: Brightness.light,
  );

  final ThemeData kDarkTheme = ThemeData(
    appBarTheme: const AppBarTheme(color: Colors.red),
    brightness: Brightness.dark,
  );
  bool isDarkMode = false;
  @override
  void initState() {
    super.initState();
    initialization();
    checkLoggedIn();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initialization() async {
    FlutterNativeSplash.remove();
  }

  void checkLoggedIn() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      baseUrl = dotenv.env['APP_SETTINGS'];
      var response = await http.get(Uri.parse('$baseUrl/appSettings'));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          baseUrl = data['data'];
        });
      } else {
        throw Exception('Failed to fetch API settings');
      }
      prefs.setString('BASE_URL', baseUrl!);
      final userdata = prefs.getString('user');
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        setState(() {
          driver = json.decode(userdata!);
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, navigatorKey: navigatorKey, theme: isDarkMode ? kDarkTheme : kLightTheme, home: isLoggedIn ? const MainScreen() : const LoginPage());
  }
}
