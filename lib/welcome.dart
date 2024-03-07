import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drive/main_screen.dart';
import 'package:drive/services/api_service.dart';
import 'package:drive/plateno.dart';
import 'package:drive/connectivity_service.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final ApiService apiService = ApiService();
  ConnectivityService connectivity = ConnectivityService();
  TextEditingController plate = TextEditingController();
  final helper = TextEditingController();
  final driverName = TextEditingController();
  bool _showClearIcon = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
        driverName.text = (driver['type'] == 'Driver') ? driver['name'] : "";
        helper.text = (driver['type'] == 'Helper') ? driver['name'] : "";
        plate.text = driver['plate_no'] ?? '';
      });
      plateList(driver['plate_no']);
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

  void _clearText() {
    setState(() {
      helper.clear();
      _showClearIcon = false;
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
        resizeToAvoidBottomInset: true,
        body: _isLoading
            ? Center(
                child: SpinKitFadingCircle(
                color: Colors.red.shade900,
                size: 50.0,
              ))
            : SingleChildScrollView(
                child: Container(
                    child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 80),
                    Text(
                      "${driver['trucker']?.toUpperCase()}! \n",
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
                    const SizedBox(height: 30),
                    Lottie.asset(
                      "assets/animations/driver.json",
                      animate: true,
                      alignment: Alignment.center,
                      height: 150,
                      width: 150,
                    ),
                    const SizedBox(height: 30),
                    Container(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 4.0,
                          bottom: 16.0,
                        ),
                        width: 300,
                        child: TypeAheadField<PlateNo>(
                          hideKeyboard: true,
                          textFieldConfiguration: TextFieldConfiguration(
                              controller: plate,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                                labelText: 'PLATE NO',
                                hintText: 'PLATE NO',
                                labelStyle: const TextStyle(color: Colors.red),
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
                              )),
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
                        )),
                    Container(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 4.0,
                          bottom: 0.0,
                        ),
                        width: 300,
                        child: TextFormField(
                          style: const TextStyle(height: 0.6),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Driver is required';
                            }
                            return null;
                          },
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
                            suffixIcon: _showClearIcon
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.red),
                                    onPressed: _clearText,
                                  )
                                : null,
                          ),
                        )),
                    Container(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 8.0,
                          bottom: 4.0,
                        ),
                        width: 300,
                        child: TextFormField(
                          style: const TextStyle(height: 0.6),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Helper is required';
                            }
                            return null;
                          },
                          controller: helper,
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
                            ),
                            suffixIcon: _showClearIcon
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.red),
                                    onPressed: _clearText,
                                  )
                                : null,
                          ),
                        )),
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
                                if (_formKey.currentState!.validate() && plate.text != '') {
                                  SharedPreferences prefs = await SharedPreferences.getInstance();
                                  final Map<String, dynamic> user = driver;
                                  user['driver_name'] = (driverName.text == '') ? driver['driver_name'] : driverName.text.toString();
                                  user['helper_name'] = (helper.text == '') ? driver['driver_name'] : helper.text.toString();
                                  user['plate_no'] = plate.text.toString();
                                  prefs.setString('user', json.encode(user));
                                  OneSignal.login(plate.text.toString());
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MainScreen()));
                                } else if (plate.text == '') {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text('Plate No is required'),
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              }
                            })),
                  ],
                ),
              ))));
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
                  // print(suggestion);
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
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String? customValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }
}
