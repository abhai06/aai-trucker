import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drive/helper/db_helper.dart';
import 'package:drive/main_screen.dart';
import 'package:drive/services/api_service.dart';
import 'package:drive/plateno.dart';

import 'package:drive/pages/runsheet.dart';
import 'package:drive/pages/tasklist.dart';
import 'package:drive/pages/exceptionlist.dart';
import 'package:drive/connectivity_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

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
  TextEditingController plate = TextEditingController();
  String? selectedPlate;
  String plate_no = "";
  List runsheetList = [];
  List bookingList = [];
  bool _isLoading = true;
  Map<String, dynamic> driver = {};
  Future<void> user_info() async {
    _isLoading = true;
    await Future.delayed(const Duration(seconds: 1));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != "") {
      setState(() {
        driver = json.decode(userdata!);
        plate.text = driver['plate_no'] ?? '';
      });
      final task = {
        'itemsPerPage': '-1',
        'group_by': '4'
      };
      runsheet.runsheet();
      tasklist.tasklist(task);
      setState(() {
        _isLoading = false;
      });
    } else {
      user_info;
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
            : Container(
                decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/maps.jpg'), fit: BoxFit.cover, opacity: 0.3)),
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 50),
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
                    Lottie.asset(
                      "assets/animations/driver.json",
                      animate: true,
                      alignment: Alignment.center,
                      height: 150,
                      width: 150,
                    ),
                    const SizedBox(height: 50),
                    Container(
                        padding: const EdgeInsets.all(16),
                        width: 300,
                        child: OutlinedButton.icon(
                            icon: const Icon(Icons.local_shipping),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                minimumSize: const Size.fromHeight(45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                )),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("PLATE NO : ${driver['plate_no']}"),
                            ),
                            onPressed: () async {
                              _selectDialog();
                            })),
                    Container(
                        padding: const EdgeInsets.all(16),
                        width: 300,
                        child: ElevatedButton.icon(
                            icon: const Icon(Icons.keyboard_double_arrow_right),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade900,
                                minimumSize: const Size.fromHeight(45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                )),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('GO ONLINE'),
                            ),
                            onPressed: () async {
                              bool isConnected = await connectivity.isConnected();
                              if (!isConnected) {
                                ConnectivityService.noInternetDialog(context);
                              } else {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const MainScreen()));
                              }
                            })),
                  ],
                ),
              ));
  }

  void _selectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        plate.text = driver['plate_no'] ?? '';
        return AlertDialog(
          title: Text(driver['trucker']),
          content: Padding(
            padding: const EdgeInsets.all(4.0),
            child: TypeAheadField<PlateNo>(
              textFieldConfiguration: TextFieldConfiguration(
                controller: plate,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(2.0),
                  labelText: 'Plate No',
                  hintText: 'Plate No',
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
                  print(suggestion);
                  plate.text = suggestion.plate_no;
                });
              },
            ),
          ),
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.close),
              label: const Text(
                'CANCEL',
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              icon: const Icon(Icons.published_with_changes),
              label: const Text(
                'CHANGE',
              ),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                final Map<String, dynamic> user = driver;
                user['plate_no'] = plate.text.toString();
                prefs.setString('user', json.encode(user));
                setState(() {
                  driver = user;
                  runsheet.runsheet();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
