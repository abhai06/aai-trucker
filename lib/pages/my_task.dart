import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drive/connectivity_service.dart';
import 'package:drive/helper/db_helper.dart';
import 'package:drive/pages/booking/list.dart';
import 'package:drive/pages/runsheet.dart';
import 'package:drive/services/api_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class MyTaskPage extends StatefulWidget {
  const MyTaskPage({Key? key}) : super(key: key);

  @override
  _MyTaskPageState createState() => _MyTaskPageState();
}

class _MyTaskPageState extends State<MyTaskPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _selectedTabIndex = 1;
  Runsheet runsheet = Runsheet();
  DBHelper dbHelper = DBHelper();
  ApiService apiService = ApiService();
  ConnectivityService connectivity = ConnectivityService();
  bool _isLoading = false;
  List<Map<String, dynamic>> my_task = [];
  late Map<String, dynamic> monitor;
  TextEditingController search = TextEditingController();
  String searchQuery = '';
  String plateNo = '';

  @override
  void initState() {
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _selectedTabIndex,
    );
    _tabController!.addListener(_handleTabSelection);
    super.initState();
  }

  @override
  void dispose() {
    _tabController!.removeListener(_handleTabSelection);
    _tabController?.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      _selectedTabIndex = _tabController!.index;
    });
  }

  Future<List<dynamic>> getTrips() async {
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != null) {
      var user = json.decode(userdata);
      plateNo = user['plate_no'] ?? '';
    }
    final res = await apiService.getData('getTrip', params: {
      'plate_no': plateNo,
      'type': _selectedTabIndex
    });
    if (res.statusCode == 200) {
      var data = jsonDecode(res.body);
      List<dynamic> trip = List<dynamic>.from(data['data']);
      return trip;
    } else {
      throw Exception('Failed to load trips');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/maps.jpg'), fit: BoxFit.cover, opacity: 0.3)),
            padding: const EdgeInsets.all(8.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              Expanded(
                  child: TabBarView(controller: _tabController, children: [
                previousTab(),
                todayTab()
              ]))
            ])),
        bottomNavigationBar: BottomAppBar(
          color: Colors.grey.shade900,
          child: TabBar(
            onTap: (int) {
              setState(() {
                _selectedTabIndex = int;
                _isLoading = false;
                getTrips();
              });
            },
            indicator: BoxDecoration(
              color: Colors.red.shade900,
            ),
            indicatorColor: Colors.white,
            indicatorWeight: 4.0,
            controller: _tabController,
            labelColor: Colors.white,
            dividerColor: Colors.white,
            tabs: const [
              Tab(text: "PREVIOUS", icon: Icon(Icons.event_repeat)),
              Tab(text: "TODAY", icon: Icon(Icons.today)),
            ],
          ),
        ));
  }

  Widget previousTab() {
    return FutureBuilder<List<dynamic>>(
        future: getTrips(),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          // final previousList = my_task.where((itm) => itm['reference'].toLowerCase().contains(searchQuery)).toList();
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: SpinKitFadingCircle(
              color: Colors.red.shade900,
              size: 50.0,
            ));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  DateTime dateFrom = DateTime.parse(item['schedule_from'] ?? '');
                  final from = DateFormat('MMM d,yyyy').format(dateFrom);
                  final TextEditingController estTotWt = TextEditingController(text: "");
                  final TextEditingController estTotSqm = TextEditingController(text: "");
                  final TextEditingController estTotPcs = TextEditingController(text: "");
                  final TextEditingController estTotCbm = TextEditingController(text: "");
                  return Card(
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      shadowColor: Colors.black,
                      elevation: 4,
                      child: ListTile(
                        selectedTileColor: Colors.red.shade100,
                        onTap: () {
                          setState(() {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => BookingListPage(item)));
                          });
                        },
                        leading: const Icon(Icons.local_shipping, color: Colors.grey),
                        title: Text(
                          item['reference'] ?? '',
                          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 18.0),
                        ),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            from,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: estTotCbm,
                                    readOnly: true,
                                    decoration: const InputDecoration(labelText: 'CBM', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                                    style: const TextStyle(fontSize: 11),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: estTotSqm,
                                    readOnly: true,
                                    keyboardType: TextInputType.text,
                                    decoration: const InputDecoration(labelText: 'SQM', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                                    style: const TextStyle(fontSize: 11),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: estTotPcs,
                                    readOnly: true,
                                    keyboardType: TextInputType.text,
                                    decoration: const InputDecoration(labelText: 'PCS', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                                    style: const TextStyle(fontSize: 11),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: estTotWt,
                                    readOnly: true,
                                    keyboardType: TextInputType.text,
                                    decoration: const InputDecoration(labelText: 'WT', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                          Text(
                            item['remarks'] ?? '',
                            style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.bold),
                          ),
                        ]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          } else {
            return Center(
              child: Lottie.asset(
                "assets/animations/noitem.json",
                animate: true,
                alignment: Alignment.center,
                height: 300,
                width: 300,
              ),
            );
          }
        });
  }

  Widget todayTab() {
    return FutureBuilder<List<dynamic>>(
        future: getTrips(),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: SpinKitFadingCircle(
              color: Colors.red.shade900,
              size: 50.0,
            ));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  DateTime dateFrom = DateTime.parse(item['schedule_from'] ?? '');
                  final from = DateFormat('MMM d,yyyy').format(dateFrom);
                  final TextEditingController estTotWt = TextEditingController(text: "");
                  final TextEditingController estTotSqm = TextEditingController(text: "");
                  final TextEditingController estTotPcs = TextEditingController(text: "");
                  final TextEditingController estTotCbm = TextEditingController(text: "");
                  return Card(
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      shadowColor: Colors.black,
                      elevation: 4,
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => BookingListPage(item)));
                          });
                        },
                        leading: const Icon(Icons.local_shipping, color: Colors.blue),
                        title: Text(
                          item['reference'] ?? '',
                          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            from,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: estTotCbm,
                                    readOnly: true,
                                    decoration: const InputDecoration(labelText: 'CBM', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                                    style: const TextStyle(fontSize: 11),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: estTotSqm,
                                    readOnly: true,
                                    keyboardType: TextInputType.text,
                                    decoration: const InputDecoration(labelText: 'SQM', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                                    style: const TextStyle(fontSize: 11),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: estTotPcs,
                                    readOnly: true,
                                    keyboardType: TextInputType.text,
                                    decoration: const InputDecoration(labelText: 'PCS', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                                    style: const TextStyle(fontSize: 11),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: estTotWt,
                                    readOnly: true,
                                    keyboardType: TextInputType.text,
                                    decoration: const InputDecoration(labelText: 'Wt', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                          Text(
                            item['remarks'] ?? '',
                            style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.bold),
                          ),
                        ]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(left: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          } else {
            return Center(
              child: Lottie.asset(
                "assets/animations/noitem.json",
                animate: true,
                alignment: Alignment.center,
                height: 300,
                width: 300,
              ),
            );
          }
        });
  }
}
