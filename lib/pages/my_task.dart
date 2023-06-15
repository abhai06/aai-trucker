import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:drive/pages/booking/list.dart';
import 'package:drive/services/api_service.dart';
import 'package:drive/helper/db_helper.dart';
import 'package:drive/connectivity_service.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyTaskPage extends StatefulWidget {
  const MyTaskPage({Key? key}) : super(key: key);

  @override
  State<MyTaskPage> createState() => _MyTaskPageState();
}

class _MyTaskPageState extends State<MyTaskPage> {
  DBHelper dbHelper = DBHelper();
  ApiService apiService = ApiService();
  ConnectivityService connectivity = ConnectivityService();
  bool _isLoading = true;
  List _items = [];
  late Map<String, dynamic> monitor;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getRecordById(int id) async {
    bool _isConnected = await connectivity.isConnected();
    if (!_isConnected) {
      ConnectivityService.noInternetDialog(context);
    } else {
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

  Future<List<Map<String, dynamic>>> fetchData() async {
    _isLoading = true;
    await Future.delayed(Duration(seconds: 2));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    String? plateNo;
    if (userdata != "") {
      setState(() {
        var user = json.decode(userdata!);
        plateNo = user['plate_no'];
      });
    }
    List<Map<String, dynamic>> dataList = await dbHelper.getAll('runsheet',
        whereCondition: '(status = ? OR status = ?) AND plate_no = ?',
        whereArgs: ['Active', 'In-Progress', plateNo]);
    setState(() {
      _isLoading = false;
    });
    return dataList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: FutureBuilder<List<dynamic>>(
            future: fetchData(),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              // List task = _items;
              if (snapshot.hasData) {
                // if (task.isNotEmpty) {
                return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final item = snapshot.data![index];
                      DateTime dateFrom =
                          DateTime.parse(item['date_from'] ?? '');
                      final from =
                          DateFormat('MMM d,yyyy h:mm a').format(dateFrom);
                      DateTime dateTo = DateTime.parse(item['date_to'] ?? '');
                      final to = DateFormat('MMM d,yyyy h:mm a').format(dateTo);
                      final TextEditingController est_tot_wt =
                          TextEditingController(
                              text: item['est_tot_wt'].toString());
                      final TextEditingController est_tot_sqm =
                          TextEditingController(
                              text: item['est_tot_sqm'].toString());
                      final TextEditingController est_tot_pcs =
                          TextEditingController(
                              text: item['est_tot_pcs'].toString());
                      final TextEditingController est_tot_cbm =
                          TextEditingController(
                              text: item['est_tot_cbm'].toString());
                      return Card(
                          shadowColor: Colors.black,
                          elevation: 4,
                          child: ListTile(
                            onTap: () async {
                              // await _getRecordById(item['id'] ?? 0);
                              setState(() {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => BookingListPage(
                                            snapshot.data![index])));
                              });
                            },
                            leading: const Icon(Icons.local_shipping,
                                color: Colors.red),
                            title: Text(
                              item['reference'] ?? '',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FROM :  ' + from,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'TO : ' + to,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Row(children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: est_tot_cbm,
                                            readOnly: true,
                                            decoration: const InputDecoration(
                                                labelText: 'Est. CBM',
                                                labelStyle: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                      height: 10.0,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: est_tot_sqm,
                                            readOnly: true,
                                            keyboardType: TextInputType.text,
                                            decoration: const InputDecoration(
                                                labelText: 'Est. SQM',
                                                labelStyle: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                      height: 10.0,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: est_tot_pcs,
                                            readOnly: true,
                                            keyboardType: TextInputType.text,
                                            decoration: const InputDecoration(
                                                labelText: 'Est. PCS',
                                                labelStyle: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                      height: 10.0,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: est_tot_wt,
                                            readOnly: true,
                                            keyboardType: TextInputType.text,
                                            decoration: const InputDecoration(
                                                labelText: 'Est. Wt',
                                                labelStyle: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]),
                                  Text(
                                    item['remarks'] ?? '',
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
                                )
                              ],
                            ),
                          ));
                    });
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Lottie.asset(
                    "assets/animations/loading.json",
                    animate: true,
                    alignment: Alignment.center,
                    height: 100,
                    width: 100,
                  ),
                );
              } else {
                return Center(
                  child: Lottie.asset(
                    "assets/animations/nodata.json",
                    animate: true,
                    alignment: Alignment.center,
                    height: 300,
                    width: 300,
                  ),
                );
              }
            }));
  }
}
