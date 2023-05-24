import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drive/helper/db_helper.dart';
import 'package:drive/main_screen.dart';
import 'package:drive/services/api_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final ApiService apiService = ApiService();
  DBHelper dbHelper = DBHelper();
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
      final task = await dbHelper.getAll('tasks');
      final except = await dbHelper.getAll('exception');
      if (task.isEmpty || except.isEmpty) {
        exception();
        tasklist();
      }
      runsheet();
    } else {
      user_info;
    }
  }

  Future<void> runsheet() async {
    var filter = {'plate_no': 'ABC123'};
    final params = {'page': 1, 'filter': {}};
    final response = await apiService.getData('runsheet', params: params);
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      var data = responseData['data']['data'];
      var book = [];
      List<Map<String, dynamic>> booking = [];
      runsheetList = data.map((rn) {
        if (rn['task'].length > 0) {
          rn['task'].forEach((key, value) {
            value['runsheet_id'] = rn['id'];
            booking.add(Map<String, dynamic>.from(value));
          });
        }
        return {
          'id': rn['id'],
          'runsheet_id': rn['id'],
          'cbm': rn['cbm'],
          'charging_type': rn['charging_type'],
          'date_from': rn['date_from'],
          'date_to': rn['date_to'],
          'ar_no': rn['ar_no'],
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
      await dbHelper.save('runsheet', runsheetList, pkey: 'runsheet_id');
      if (booking.isNotEmpty) {
        await dbHelper.saveBooking('booking', booking);
      }
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

  void _simulateLoading() async {
    await Future.delayed(
        const Duration(seconds: 2)); // Simulate loading with a delay
    setState(() {
      user_info();
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const MainScreen()));
                            })),
                  ],
                ),
              ));
  }
}
