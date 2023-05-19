import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:drive/pages/booking/list.dart';
import 'package:drive/services/api_service.dart';
import 'package:drive/helper/db_helper.dart';
import 'package:connectivity/connectivity.dart';
import 'package:lottie/lottie.dart';

class MyTaskPage extends StatefulWidget {
  const MyTaskPage({Key? key}) : super(key: key);

  @override
  State<MyTaskPage> createState() => _MyTaskPageState();
}

class _MyTaskPageState extends State<MyTaskPage> {
  DBHelper dbHelper = DBHelper();
  ApiService apiService = ApiService();
  bool _isLoading = true;
  List _items = [];
  late Map<String, dynamic> monitor;
  // Map<String, String>? responseData;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() async {
    await Future.delayed(
        const Duration(seconds: 2)); // Simulate loading with a delay
    setState(() {
      _loadData();
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final rows = await dbHelper.getAll('runsheet');
    setState(() {
      _items = rows;
    });
    setState(() {
      _isLoading = false;
    });
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

  Future<void> _getRecordById(int id) async {
    bool online = await checkInternetConnection();
    if (online) {
      final responseData = await apiService.getRecordById("monitor", id);
      if (responseData.statusCode == 200) {
        setState(() {
          try {
            monitor = json.decode(responseData.body);
            if (monitor.isNotEmpty) {
              final itm = {
                'monitor_id': monitor['data']['id'],
              };
              dbHelper.update('runsheet', itm, id);
            }
          } catch (e) {
            print('Error parsing JSON: $e');
          }
        });
      } else {
        throw Exception('Failed to retrieve record');
      }
    }
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
            : FutureBuilder(
                future: _loadData(),
                builder: (context, snapshot) {
                  List task = _items;
                  return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: task.length,
                      itemBuilder: (context, index) {
                        final item = task[index];
                        DateTime dateTime = DateTime.parse(item['updated_at']);
                        final formattedDateTime =
                            DateFormat('MMM d,yyyy h:mm a').format(dateTime);
                        return Card(
                            shadowColor: Colors.black,
                            elevation: 4,
                            child: ListTile(
                              onTap: () async {
                                await _getRecordById(item['id']);
                                setState(() {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              BookingListPage(task[index])));
                                });
                              },
                              leading: const Icon(Icons.local_shipping,
                                  color: Colors.red),
                              title: Text(
                                item['reference'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['ar_no'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      item['tracking_no'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      formattedDateTime,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      item['remarks'],
                                      style: const TextStyle(
                                          fontSize: 12,
                                          overflow: TextOverflow.ellipsis,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ]),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(left: 5),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item['status'].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 5),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item['charging_type'].toUpperCase() ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ));
                      });
                }));
  }
}
