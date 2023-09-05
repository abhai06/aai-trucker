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

  @override
  void initState() {
    runsheet.runsheet();
    fetchData();
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

  Future<List<Map<String, dynamic>>> fetchData() async {
    _isLoading = true;
    await Future.delayed(const Duration(seconds: 2));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    String? plateNo;
    if (userdata != null) {
      setState(() {
        var user = json.decode(userdata);
        plateNo = user['plate_no'];
      });
    }
    DateTime currentDate = DateTime.now();
    DateTime now = DateTime(currentDate.year, currentDate.month, currentDate.day);
    String today = DateFormat('yyyy-MM-dd').format(now);
    var operation = _selectedTabIndex == 1 ? "=" : "<";
    var dataList = await dbHelper.getAll('runsheet',
        whereCondition: '(status = ? OR status = ?) AND plate_no = ? AND date_from $operation ?',
        whereArgs: [
          'Active',
          'In-Progress',
          plateNo,
          today
        ],
        orderBy: 'date_from DESC');
    setState(() {
      my_task = dataList;
    });
    _isLoading = false;
    return my_task;
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/maps.jpg'), fit: BoxFit.cover, opacity: 0.3)),
          padding: const EdgeInsets.all(8.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              controller: search,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(4.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(70.0),
                ),
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          _clearSearch();
                        })
                    : null,
              ),
            ),
            const SizedBox(height: 2.0),
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
              fetchData();
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
      ),
      floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 10.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
            FloatingActionButton(
                hoverColor: Colors.green,
                backgroundColor: Colors.blue,
                onPressed: () {
                  runsheet.runsheet();
                },
                child: const Icon(Icons.refresh, size: 30.0))
          ])),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget previousTab() {
    return FutureBuilder<List<dynamic>>(
        future: fetchData(),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          final previousList = my_task.where((itm) => itm['reference'].toLowerCase().contains(searchQuery)).toList();
          if (previousList.isNotEmpty) {
            return ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: previousList.length,
                itemBuilder: (context, index) {
                  final item = previousList[index];
                  DateTime dateFrom = DateTime.parse(item['date_from'] ?? '');
                  final from = DateFormat('MMM d,yyyy h:mm a').format(dateFrom);
                  DateTime dateTo = DateTime.parse(item['date_to'] ?? '');
                  final to = DateFormat('MMM d,yyyy h:mm a').format(dateTo);
                  final TextEditingController estTotWt = TextEditingController(text: item['est_tot_wt'].toString());
                  final TextEditingController estTotSqm = TextEditingController(text: item['est_tot_sqm'].toString());
                  final TextEditingController estTotPcs = TextEditingController(text: item['est_tot_pcs'].toString());
                  final TextEditingController estTotCbm = TextEditingController(text: item['est_tot_cbm'].toString());
                  return Card(
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      shadowColor: Colors.black,
                      elevation: 4,
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => BookingListPage(my_task[index])));
                          });
                        },
                        // leading: const Icon(Icons.local_shipping, color: Colors.red),
                        title: Text(
                          item['reference'] ?? '',
                          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            'FROM :  $from',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'TO : $to',
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
                                    decoration: const InputDecoration(labelText: 'Est. CBM', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
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
                                    decoration: const InputDecoration(labelText: 'Est. SQM', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
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
                                    decoration: const InputDecoration(labelText: 'Est. PCS', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
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
                                    decoration: const InputDecoration(labelText: 'Est. Wt', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
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
                                color: Colors.red.shade900,
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
        future: fetchData(),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          final todayList = my_task.where((itm) => itm['reference'].toLowerCase().contains(searchQuery)).toList();
          if (todayList.isNotEmpty) {
            return ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: todayList.length,
                itemBuilder: (context, index) {
                  final item = todayList[index];
                  DateTime dateFrom = DateTime.parse(item['date_from'] ?? '');
                  final from = DateFormat('MMM d,yyyy h:mm a').format(dateFrom);
                  DateTime dateTo = DateTime.parse(item['date_to'] ?? '');
                  final to = DateFormat('MMM d,yyyy h:mm a').format(dateTo);
                  final TextEditingController estTotWt = TextEditingController(text: item['est_tot_wt'].toString());
                  final TextEditingController estTotSqm = TextEditingController(text: item['est_tot_sqm'].toString());
                  final TextEditingController estTotPcs = TextEditingController(text: item['est_tot_pcs'].toString());
                  final TextEditingController estTotCbm = TextEditingController(text: item['est_tot_cbm'].toString());
                  return Card(
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      shadowColor: Colors.black,
                      elevation: 4,
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => BookingListPage(my_task[index])));
                          });
                        },
                        // leading: const Icon(Icons.local_shipping, color: Colors.red),
                        title: Text(
                          item['reference'] ?? '',
                          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            'FROM :  $from',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'TO : $to',
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
                                    decoration: const InputDecoration(labelText: 'Est. CBM', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
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
                                    decoration: const InputDecoration(labelText: 'Est. SQM', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
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
                                    decoration: const InputDecoration(labelText: 'Est. PCS', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
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
                                    decoration: const InputDecoration(labelText: 'Est. Wt', labelStyle: TextStyle(fontWeight: FontWeight.bold)),
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
                                color: Colors.red.shade900,
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
