import 'package:drive/login.dart';
import 'package:drive/pages/feedback.dart';
import 'package:drive/pages/settings.dart';
import 'package:drive/pages/my_task.dart';
import 'package:flutter/material.dart';
import 'package:drive/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:drive/pages/runsheet.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:drive/plateno.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  ApiService apiService = ApiService();
  Runsheet runsheet = Runsheet();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // DBHelper dbHelper = DBHelper();
  bool isDarkMode = false;
  String mode = 'Light';
  int _currentIndex = 0;
  String currentPageTitle = 'My Task';
  Map<String, dynamic> driver = {};
  String _appVersion = '';
  String driver_name = '';
  String helper_name = '';

  final helperName = TextEditingController();
  final driverName = TextEditingController();
  TextEditingController plate = TextEditingController();
  final DateTime duty = DateTime.now();
  String? selectedPlate;
  String plate_no = "";

  final List<Widget> _children = [
    const MyTaskPage(),
    const FeedbackPage(),
    const SettingsPage()
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
        driver_name = (driver['driver_name'] != null) ? driver_name.toUpperCase() : '';
        helper_name = (driver['helper_name'] != null) ? driver_name.toUpperCase() : '';
        _appVersion = packageInfo.version;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    user_info();
  }

  void _clearPlate() {
    setState(() {
      selectedPlate = null;
      plate_no = "";
      plate.clear();
    });
  }

  Future<List<PlateNo>> plateList(String query) async {
    final params = {
      'page': '1',
      'trucker_company': driver['trucker'],
      'itemsPerPage': '999',
      'device': 'mobile'
    };
    print(params);
    return await apiService.getData('fleet', params: params).then((res) {
      var data = json.decode(res.body.toString());
      if (data['success'] == true) {
        List<dynamic> options = List<dynamic>.from(data['data']['data']);
        List<PlateNo> platex = options.map((option) => PlateNo.fromJson(option)).toList();
        List<PlateNo> filteredOptions = platex.where((x) => x.plate_no.toString().toLowerCase().contains(query.toLowerCase())).toList();
        return filteredOptions;
      }
    });
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
            actions: [
              Padding(padding: const EdgeInsets.all(8.0), child: Align(alignment: Alignment.centerRight, child: Text((driver['plate_no']!))))
            ],
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    "Driver : ${driver['driver_name']}",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  accountEmail: Text(
                    "Helper : ${driver['helper_name']}",
                    style: const TextStyle(color: Colors.white, fontSize: 16.0),
                  ),
                  currentAccountPicture: Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Column(children: [
                          CircleAvatar(
                            backgroundImage: AssetImage('assets/images/driver_avatar.png'),
                            radius: 40.0,
                          ),
                        ]),
                        const SizedBox(width: 8.0),
                        Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                          Text(
                            "${driver['plate_no']}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                            ),
                          ),
                          Text(DateFormat('yyyy/MM/dd').format(duty), style: const TextStyle(color: Colors.white))
                        ])
                      ],
                    ),
                  ),
                  otherAccountsPictures: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      color: Colors.white,
                      onPressed: () {
                        // Add your edit button logic here
                        _showDialog(context);
                      },
                    ),
                  ],
                  margin: EdgeInsets.zero,
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
                  leading: const Icon(
                    Icons.settings,
                  ),
                  title: const Text('Settings', style: TextStyle()),
                  onTap: () {
                    setState(() {
                      _currentIndex = 2;
                      currentPageTitle = 'Settings';
                    });
                    Navigator.pop(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
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
                            'Are you sure you want to logout?',
                            style: TextStyle(fontSize: 16),
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Expanded(
                                  child: ElevatedButton(
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
                                            style: TextStyle(color: Colors.black),
                                          )))),
                              const SizedBox(width: 8.0),
                              Expanded(
                                  child: ElevatedButton.icon(
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
                                      label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Logout'))))
                            ]),
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
    String baseUrl = preferences.getString('BASE_URL') ?? '';
    await OneSignal.logout();
    await preferences.clear();
    await preferences.setString('BASE_URL', baseUrl);
  }

  String? customValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }

  _showDialog(BuildContext context) async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          driverName.text = driver['driver_name'];
          helperName.text = driver['helper_name'];
          plate.text = driver['plate_no'];
          return AlertDialog(
            contentPadding: EdgeInsets.all(16.0),
            content: Form(
                key: _formKey,
                child: Container(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TypeAheadField<PlateNo>(
                          hideKeyboard: true,
                          textFieldConfiguration: TextFieldConfiguration(
                            controller: plate,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                              labelText: 'PLATE NO',
                              hintText: 'PLATE NO',
                              labelStyle: const TextStyle(color: Colors.red, fontSize: 13.0),
                              border: const OutlineInputBorder(),
                              suffixIcon: plate.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: _clearPlate,
                                    )
                                  : null,
                            ),
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.black,
                            ),
                          ),
                          suggestionsCallback: (String pattern) async {
                            return await plateList(pattern);
                          },
                          itemBuilder: (context, PlateNo suggestion) {
                            return ListTile(
                              title: Text("${suggestion.plate_no} - ${suggestion.type}"),
                            );
                          },
                          onSuggestionSelected: (PlateNo suggestion) {
                            setState(() {
                              plate.text = suggestion.plate_no;
                            });
                          },
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          style: const TextStyle(height: 0.6),
                          validator: customValidator,
                          controller: driverName,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            labelText: 'DRIVER NAME',
                            labelStyle: const TextStyle(color: Colors.red, fontSize: 13.0),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.red, width: 1.0),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                            style: const TextStyle(height: 0.6),
                            validator: customValidator,
                            controller: helperName,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                labelText: 'HELPER NAME',
                                labelStyle: const TextStyle(color: Colors.red, fontSize: 13.0),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.red, width: 1.0),
                                  borderRadius: BorderRadius.circular(10.0),
                                ))),
                      ],
                    )))),
            actions: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size.fromHeight(40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            )),
                        child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'CANCEL',
                              style: TextStyle(color: Colors.white),
                            )))),
                const SizedBox(width: 4.0),
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && plate.text != '') {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            final Map<String, dynamic> user = driver;
                            user['driver_name'] = driverName.text.toString();
                            user['helper_name'] = helperName.text.toString();
                            user['plate_no'] = plate.text.toString();
                            prefs.setString('user', json.encode(user));
                            setState(() {
                              driver = user;
                              user_info();
                              runsheet.runsheet();
                            });
                            Navigator.of(context).pop();
                          } else if (plate.text == '') {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Validation Error'),
                                    content: const Text('Plate no is required.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('CLOSE'),
                                      ),
                                    ],
                                  );
                                });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size.fromHeight(40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            )),
                        icon: const Icon(Icons.save),
                        label: const FittedBox(fit: BoxFit.scaleDown, child: Text('SAVE')))),
              ])
            ],
          );
        });
  }
}
