import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:path/path.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:drive/connectivity_service.dart';
import 'package:drive/helper/db_helper.dart';
import 'package:drive/login.dart';
import 'package:drive/main_screen.dart';
import 'package:drive/pages/exceptionlist.dart';
import 'package:drive/pages/runsheet.dart';
import 'package:drive/pages/tasklist.dart';
import 'package:drive/service.dart';
import 'package:drive/services/api_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await dotenv.load();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@drawable/ic_notification');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
  ConnectivityService.initialize();
}

void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  if (notificationResponse.payload != null) {
    await navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (context) => const MainScreen()),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
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
    _initConnectivity();
    Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) {
        service.syncData();
      }
    });
    initialization();
    openDatabaseOrInitialize();
    checkLoggedIn();
    initPusher();
  }

  void initPusher() async {
    await pusher.init(
      apiKey: dotenv.env['PUSHER_APP_KEY'].toString(),
      cluster: dotenv.env['PUSHER_APP_CLUSTER'].toString(),
      onConnectionStateChange: onConnectionStateChange,
      onError: onError,
      onSubscriptionSucceeded: onSubscriptionSucceeded,
      onEvent: onEvent,
      onSubscriptionError: onSubscriptionError,
      onDecryptionFailure: onDecryptionFailure,
      onMemberAdded: onMemberAdded,
      onMemberRemoved: onMemberRemoved,
    );
    await pusher.subscribe(channelName: "mobile");
    await pusher.connect();
  }

  void onEvent(PusherEvent event) {
    if (event.eventName == driver['plate_no']) {
      Map<String, dynamic> data = jsonDecode(event.data);
      if (data.isNotEmpty) {
        showNotification(data['data']);
      }
    }
  }

  void onError(String message, int? code, dynamic e) {
    print("onError: $message code: $code exception: $e");
  }

  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    print("Connection: $currentState");
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print("onSubscriptionSucceeded: $channelName data: $data");
    final me = pusher.getChannel(channelName)?.me;
    print("Me: $me");
  }

  void onDecryptionFailure(String event, String reason) {
    print("onDecryptionFailure: $event reason: $reason");
  }

  void onSubscriptionError(String message, dynamic e) {
    print("onSubscriptionError: $message Exception: $e");
  }

  void onMemberAdded(String channelName, PusherMember member) {
    print("onMemberAdded: $channelName member: $member");
  }

  void onMemberRemoved(String channelName, PusherMember member) {
    print("onMemberRemoved: $channelName member: $member");
  }

  Future<void> showNotification(data) async {
    AndroidNotificationDetails androidNotificationDetails = const AndroidNotificationDetails('mobile', 'runsheet', importance: Importance.max, priority: Priority.high, ticker: 'ticker');
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      data['title'],
      data['description']['reference'],
      platformChannelSpecifics,
      payload: 'item_x',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initConnectivity() async {
    bool isConnected = await connectivity.isConnected();
    if (isConnected) {
      runsheet.runsheet();
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
    final userdata = prefs.getString('user');
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      setState(() {
        driver = json.decode(userdata!);
      });
      final task = await dbHelper.getAll('tasks');
      final except = await dbHelper.getAll('exception');
      if (task.isEmpty) {
        tasklist.tasklist({
          'itemsPerPage': -1,
          'group_by': 4
        });
      }
      if (except.isEmpty) {
        exceptionlist.exception();
      }
      runsheet.runsheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(navigatorKey: navigatorKey, theme: isDarkMode ? kDarkTheme : kLightTheme, home: isLoggedIn ? const MainScreen() : const LoginPage());
  }
}
