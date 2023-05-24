import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:connectivity/connectivity.dart';
import 'package:drive/maps/maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

import 'package:drive/helper/db_helper.dart';
import 'package:drive/maps/map.dart';
import 'package:drive/pages/booking/detail.dart';
import 'package:drive/pages/booking/timeline.dart';
import 'package:drive/pages/exception.dart';
import 'package:drive/services/api_service.dart';
import 'package:phone_call/phone_call.dart';

class BookingListPage extends StatefulWidget {
  final item;
  const BookingListPage(this.item, {Key? key}) : super(key: key);

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _selectedTabIndex = 0;

  final GlobalKey<SignatureState> _signatureKey = GlobalKey<SignatureState>();
  final scrollController = ScrollController();
  Uint8List? _signatureData;
  DBHelper dbHelper = DBHelper();
  ApiService apiService = ApiService();
  List<String> attachment = [];
  late Map<String, dynamic> monitor;
  List<Asset> images = <Asset>[];
  final String _error = 'No Error Dectected';

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  final List<String> _imageList = [];

  final int _currentPage = 1;
  int monitor_id = 0;
  final int _totalPages = 1;
  bool _isLoading = true;
  bool isSaving = false;
  bool start = false;
  int runsheet_id = 0;
  int page = 1;
  List _items = [];
  List status = [];
  String signature = "";
  TextEditingController start_remarks = TextEditingController();

  Future<List<dynamic>> booking() async {
    _isLoading = true;
    bool isTab = _selectedTabIndex == 0;
    var task = "PICKUP";
    if (isTab) {
      task = "PICKUP";
    } else {
      task = "DELIVERY";
    }
    final rows = await dbHelper.getAll('booking',
        whereCondition: 'runsheet_id = ? AND task = ?',
        whereArgs: [widget.item['runsheet_id'], task]);
    // print(rows);
    status = await dbHelper.getAll('tasks');
    if (mounted) {
      setState(() {
        _items = rows.map((data) {
          var stat = {};
          int sequenceNo = isTab ? 2 : 6;
          if (data['status'] == null || data['status'] == 'Assigned') {
            sequenceNo = isTab ? 2 : 6;
          } else {
            var seq = isTab ? 5 : 9;
            sequenceNo =
                (data['sequence_no'] != null && data['sequence_no'] < seq)
                    ? data['sequence_no'] + 1
                    : seq;
          }
          stat = status.firstWhere((row) => ((row['sequence_no'] != null &&
              row['sequence_no'] == sequenceNo &&
              row['task'] == task)));
          if (stat.isNotEmpty) {
            return {
              ...data,
              'status': data['status'] ?? 'Assigned',
              'next_status': (sequenceNo <= 9) ? stat['name'] : 'Completed',
              'task_id': stat['id'] ?? '',
              'task_code': stat['code'] ?? '',
              'next_sequence_no': stat['sequence_no'] ?? sequenceNo,
              'sequence_no': (data['sequence_no'] != null)
                  ? data['sequence_no']
                  : (isTab == true)
                      ? 2
                      : 6
            };
          }
        }).toList();
      });
    }
    _isLoading = false;
    return _items;
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
      if (widget.item['monitor_id'] == null) {
        final responseData = await apiService.getRecordById("monitor", id);
        if (responseData.statusCode == 200) {
          monitor = json.decode(responseData.body);
          setState(() {
            if (monitor['data'].isNotEmpty) {
              monitor_id = monitor['data']['id'];
              final itm = {
                'monitor_id': monitor_id,
              };
              dbHelper.update('runsheet', itm, id);
              start = false;
            } else {
              start = true;
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Start Runsheet'),
                    content: TextField(
                      keyboardType: TextInputType.text,
                      controller: start_remarks,
                      decoration: const InputDecoration(
                        labelText: 'Remarks',
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('START'),
                        onPressed: () {
                          startRunsheet();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          });
        } else {
          throw Exception('Failed to retrieve record');
        }
      } else {
        monitor_id = widget.item['monitor_id'];
      }
    }
  }

  startRunsheet() async {
    DateTime now = DateTime.now();
    final startDate = DateFormat('yyyy-MM-dd h:mm:ss').format(now);
    final data = {
      'start_date': startDate,
      'end_date': null,
      'end_remarks': null,
      'formList': 0,
      'logs': null,
      'plate_no': 1,
      'runsheet': widget.item['runsheet_id'],
      'start_remarks': start_remarks.text
    };
    bool online = await checkInternetConnection();
    if (online) {
      try {
        final responseData = await apiService.post(data, 'monitor');
        if (responseData.statusCode == 200) {
          var monitor = json.decode(responseData.body);
          print(monitor);
          setState(() {
            final itm = {
              'monitor_id': monitor['data']['id'],
            };
            dbHelper.update('runsheet', itm, widget.item['runsheet_id']);
          });
          start = false;
          Navigator.of(context).pop();
        }
      } catch (error) {
        print(error);
      }
    }
  }

  Future<void> _openCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    final bytes = await image!.readAsBytes();
    final base64String = base64Encode(bytes);
    setState(() {
      attachment.add(base64String);
    });
  }

  void _simulateLoading() async {
    await Future.delayed(
        const Duration(seconds: 2)); // Simulate loading with a delay
    setState(() {
      _getRecordById(widget.item['runsheet_id']);
      _isLoading = false;
    });
  }

  void _makePhoneCall(String phoneNumber) async {
    await PhoneCall.calling(phoneNumber);
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

  @override
  void initState() {
    super.initState();
    _simulateLoading();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabSelection);
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController searchQueryController = TextEditingController();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(widget.item['reference'] ?? ''), actions: [
        Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await booking();
            },
          );
        })
      ]),
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
          : Column(children: [
              Expanded(
                  child: TabBarView(
                controller: _tabController,
                children: [_buildPickupTab(), _buildDeliveryTab()],
              ))
            ]),
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey.shade900,
        child: TabBar(
          onTap: (int) {
            _isLoading = true;
            setState(() {
              booking();
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
            Tab(text: 'PICK-UP'),
            Tab(text: 'DELIVERY'),
          ],
        ),
      ),
      floatingActionButton: Visibility(
          visible: start,
          child: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Start Runsheet'),
                    content: TextField(
                      keyboardType: TextInputType.text,
                      controller: start_remarks,
                      decoration: const InputDecoration(
                        labelText: 'Remarks',
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('START'),
                        onPressed: () {
                          startRunsheet();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            backgroundColor: Colors.black,
            child: const Text(
              'START',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildPickupTab() {
    return FutureBuilder<List<dynamic>>(
        future: booking(),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: snapshot.data!.length,
                controller: scrollController,
                itemBuilder: (context, int index) {
                  final item = snapshot.data![index];
                  DateTime dateTime =
                      DateTime.parse(widget.item['updated_at'] ?? '');
                  final formattedDateTime =
                      DateFormat('MMM d,yyyy h:mm a').format(dateTime);
                  return Padding(
                      padding: const EdgeInsets.all(4),
                      child: AbsorbPointer(
                        absorbing: false,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => BookingDetailPage(
                                        snapshot.data![index])));
                          },
                          child: Card(
                            shadowColor: Colors.black,
                            elevation: 8,
                            child: Stack(
                              children: [
                                Container(
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          ListTile(
                                              title: Text(
                                                item['reference'] ?? '',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['customer'] ?? '',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Status : " +
                                                        (item['status'] ?? ''),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) =>
                                                                    Timeline(_items[
                                                                        index])));
                                                      },
                                                      child: const Icon(
                                                        Icons.timeline,
                                                        color: Colors.blue,
                                                      )),
                                                  const SizedBox(width: 10),
                                                  GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const ExceptionPage()));
                                                      },
                                                      child: const Icon(
                                                        Icons.info,
                                                        color: Colors.red,
                                                      )),
                                                  const SizedBox(width: 10),
                                                  GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        MapScreen()));
                                                      },
                                                      child: const Icon(
                                                        Icons.map,
                                                        color: Colors.green,
                                                      )),
                                                ],
                                              )),
                                          const Divider(),
                                          ListTile(
                                              leading: const Icon(
                                                Icons.place,
                                                color: Colors.black87,
                                              ),
                                              title: const Text(
                                                'Pick Up',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              trailing: Container(
                                                margin: const EdgeInsets.only(
                                                    left: 5),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  item['task'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['pickup_contact_person'] ??
                                                          '',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                      item['pickup_loc'] ?? '',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                  ])),
                                          ListTile(
                                              leading: const Icon(
                                                Icons.pin_drop,
                                                color: Colors.red,
                                              ),
                                              title: const Text(
                                                'Delivery',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['delivery_contact_person'] ??
                                                          '',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                        item['delivery_loc'] ??
                                                            '',
                                                        style: const TextStyle(
                                                            fontSize: 11)),
                                                  ])),
                                          ListTile(
                                              leading: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red.shade700,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    )),
                                                onPressed: () {
                                                  setState(() {
                                                    _makePhoneCall(
                                                        '09353330652');
                                                  });
                                                },
                                                child: const Icon(Icons.call,
                                                    color: Colors.white),
                                              ),
                                              title: item['sequence_no'] == 5
                                                  ? Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 5),
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 8,
                                                          vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: const Center(
                                                          child: Text(
                                                        'Pick-Up Successfully',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      )),
                                                    )
                                                  : ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  Colors.blue
                                                                      .shade700,
                                                              minimumSize:
                                                                  const Size
                                                                          .fromHeight(
                                                                      35),
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20),
                                                              )),
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              Text(item[
                                                                      'next_status'] ??
                                                                  ''),
                                                              const SizedBox(
                                                                  width: 8.0),
                                                              // const Icon(
                                                              //     Icons.east),
                                                            ]),
                                                      ),
                                                      onPressed: () {
                                                        _showDialog(
                                                            context, item);
                                                      })),
                                        ])),
                              ],
                            ),
                          ),
                        ),
                      ));
                });
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
        });
  }

  Widget _buildDeliveryTab() {
    return FutureBuilder<List<dynamic>>(
        future: booking(),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: snapshot.data!.length,
                controller: scrollController,
                itemBuilder: (context, int index) {
                  final item = snapshot.data![index];
                  DateTime dateTime =
                      DateTime.parse(widget.item['updated_at'] ?? '');
                  final formattedDateTime =
                      DateFormat('MMM d,yyyy h:mm a').format(dateTime);
                  return Padding(
                      padding: const EdgeInsets.all(4),
                      child: AbsorbPointer(
                        absorbing: false,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => BookingDetailPage(
                                        snapshot.data![index])));
                          },
                          child: Card(
                            shadowColor: Colors.black,
                            elevation: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    padding: EdgeInsets.zero,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          ListTile(
                                              title: Text(
                                                item['reference'] ?? '',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['customer'] ?? '',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Status : " +
                                                        (item['status'] ?? ''),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) =>
                                                                    Timeline(_items[
                                                                        index])));
                                                      },
                                                      child: const Icon(
                                                        Icons.timeline,
                                                        color: Colors.blue,
                                                      )),
                                                  const SizedBox(width: 10),
                                                  GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const ExceptionPage()));
                                                      },
                                                      child: const Icon(
                                                        Icons.info,
                                                        color: Colors.red,
                                                      )),
                                                  const SizedBox(width: 10),
                                                  GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        MapScreen()));
                                                      },
                                                      child: const Icon(
                                                        Icons.map,
                                                        color: Colors.green,
                                                      )),
                                                ],
                                              )),
                                          const Divider(),
                                          ListTile(
                                              leading: const Icon(
                                                Icons.place,
                                                color: Colors.black87,
                                              ),
                                              title: const Text(
                                                'Pick Up',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              trailing: Container(
                                                margin: const EdgeInsets.only(
                                                    left: 5),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  item['task'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['pickup_contact_person'] ??
                                                          '',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                      item['pickup_loc'] ?? '',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                  ])),
                                          ListTile(
                                              leading: const Icon(
                                                Icons.pin_drop,
                                                color: Colors.red,
                                              ),
                                              title: const Text(
                                                'Delivery',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['delivery_contact_person'] ??
                                                          '',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                        item['delivery_loc'] ??
                                                            '',
                                                        style: const TextStyle(
                                                            fontSize: 11)),
                                                  ])),
                                          ListTile(
                                              leading: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red.shade700,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    )),
                                                onPressed: () {
                                                  _makePhoneCall('09353330652');
                                                },
                                                child: const Icon(Icons.call,
                                                    color: Colors.white),
                                              ),
                                              title: item['sequence_no'] == 9
                                                  ? Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 5),
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 8,
                                                          vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: const Center(
                                                          child: Text(
                                                        'Delivered Successfully',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      )),
                                                    )
                                                  : ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  Colors.green
                                                                      .shade700,
                                                              minimumSize:
                                                                  const Size
                                                                          .fromHeight(
                                                                      35),
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20),
                                                              )),
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            children: [
                                                              Text(item[
                                                                      'next_status'] ??
                                                                  ''),
                                                              const SizedBox(
                                                                  width: 8.0),
                                                              // const Icon(
                                                              //     Icons.east),
                                                            ]),
                                                      ),
                                                      onPressed: () {
                                                        _showDialog(
                                                            context, item);
                                                      })),
                                        ]))
                              ],
                            ),
                          ),
                        ),
                      ));
                });
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
        });
  }

  Future<List> loadAssets() async {
    List<Asset> resultList = <Asset>[];
    String error = 'No Error Detected';

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 3,
        enableCamera: true,
        selectedAssets: images,
        cupertinoOptions: const CupertinoOptions(takePhotoIcon: "chat"),
        materialOptions: const MaterialOptions(
          actionBarColor: "#FF4136",
          actionBarTitle: "Attachment",
          allViewTitle: "All Photos",
          useDetailsView: false,
          selectCircleStrokeColor: "#000000",
        ),
      );
    } on Exception catch (e) {
      error = e.toString();
    }
    if (!mounted) return [];
    setState(() {
      images = resultList;
    });

    for (var i = 0; i < images.length; i++) {
      ByteData byteData = await images[i].getByteData();
      List<int> imageData = byteData.buffer.asUint8List();
      String base64Image = base64Encode(imageData);
      attachment.add(base64Image);
    }
    return images;
  }

  Future<void> pushData(data) async {
    bool online = await checkInternetConnection();
    if (online) {
      var taskLog = {
        'task': data['next_status'] ?? '',
        'task_code': data['task_code'] ?? '',
        'contact_person': data['contact_person'] ?? 'nilo besingga',
        'datetime': data['datetime'],
        'formList': 0,
        'task_exception': data['task_exception'] ?? '',
        'line_id': data['line_id'] ?? 1,
        'location': data['location'] ?? 1,
        'source_id': data['source_id'] ?? '',
        'task_id': data['task_id'] ?? '',
        'note': data['note'] ?? '',
        'task_type': data['task'] ?? '',
        // 'signature': signature,
        'attachment': [] //jsonEncode(attachment)
      };
      final res = await apiService.post(taskLog, 'addTaskLogs', id: monitor_id);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Status Successfully Sync to server.'),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Column(children: [
            Text(res['message']),
            Text(json.encode(res['data'])),
          ]),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _showDialog(BuildContext context, data) async {
    final TextEditingController note = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8.0),
              Container(
                child: Text(
                  "${"Please confirm status change to \n" + (data['next_status'] ?? '')}.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8.0),
              const Text('Add Signature', textAlign: TextAlign.start),
              const SizedBox(height: 8.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                ),
                height: 100.0,
                child: Signature(
                  key: _signatureKey,
                  color: Colors.black,
                  strokeWidth: 2.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.yellow),
                      ),
                      child: const Text(
                        'Clear Signature',
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: () {
                        _signatureKey.currentState!.clear();
                      }),
                ],
              ),
              const SizedBox(height: 8.0),
              const Text('Add Attachment:', textAlign: TextAlign.start),
              const SizedBox(height: 8.0),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                TextButton.icon(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    label: const Text('Attach',
                        style: TextStyle(color: Colors.black)),
                    onPressed: loadAssets),
                TextButton.icon(
                  onPressed: _openCamera,
                  icon: const Icon(Icons.camera_alt, color: Colors.grey),
                  label: const Text('Camera',
                      style: TextStyle(color: Colors.black)),
                ),
              ]),
              const SizedBox(height: 8.0),
              attachment.isNotEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                          width: 1.0,
                        ),
                      ),
                      height: 100,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: attachment.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Image.memory(
                                base64Decode(attachment[index]),
                                width: 300,
                                height: 300,
                                alignment: Alignment.center,
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Checkbox(
                                  value: true, // Check the box automatically
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == false) {
                                        attachment.removeAt(index);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  : const Text(''),
              const SizedBox(height: 8.0),
              const Text('Remarks:', textAlign: TextAlign.start),
              const SizedBox(height: 8.0),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Enter Remarks'),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.red),
                      ),
                      child: const Text('CANCEL'),
                      onPressed: () {
                        setState(() {
                          Navigator.pop(context);
                        });
                      }),
                  const SizedBox(
                    width: 2,
                  ),
                  FilledButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    child: const Text('MARK STATUS'),
                    onPressed: () async {
                      data['note'] = note.text;
                      await updateStatus(data);
                    },
                  ),
                ],
              ),
            ],
          ),
        ));
      },
    );
  }

  Future<void> updateStatus(data) async {
    DateTime now = DateTime.now();
    final dateTime = DateFormat('yyyy-MM-dd H:mm:ss').format(now);
    List<Map<String, dynamic>> logs = [];
    bool valid = true;
    if (data['task'] == 'DELIVERY') {
      final rows = await dbHelper.getAll('booking',
          whereCondition: 'source_id = ? AND task = ? AND reference = ?',
          whereArgs: [data['source_id'], 'PICKUP', data['reference']]);
      if (rows.isNotEmpty &&
          rows[0]['status'] != 'TIME DEPARTURE AT PICKUP ADDR') {
        setState(() {
          valid = false;
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title:
                    const Text('Warning!', style: TextStyle(color: Colors.red)),
                content: Text(
                    "Booking ${data['reference']} is not yet PICK-UP, Unable to change status."),
                actions: [
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        });
      } else {
        valid = true;
      }
    }

    if (valid) {
      final sign = _signatureKey.currentState;
      final image = await sign?.getData();
      var bytes = await image!.toByteData(format: ui.ImageByteFormat.png);
      final signature = base64.encode(bytes!.buffer.asUint8List());
      final book = {
        'status': data['next_status'] ?? '',
        'sequence_no': data['next_sequence_no'] ?? ''
      };
      await dbHelper.update('booking', book, data['id']);
      final task = {
        'task': data['next_status'] ?? '',
        'task_code': data['task_code'] ?? '',
        'contact_person': data['contact_person'] ?? '',
        'datetime': dateTime,
        'task_exception': data['task_exception'] ?? '',
        'line_id': data['line_id'] ?? '',
        'location': data['location'] ?? '',
        'source_id': data['source_id'] ?? '',
        'task_id': data['task_id'] ?? '',
        'note': data['note'] ?? '',
        'attachment': jsonEncode(attachment),
        'signature': signature
      };
      setState(() {
        logs.add(task);
        dbHelper.save('booking_logs', logs);
      });

      setState(() {
        data['datetime'] = dateTime;
        pushData(data);
      });

      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Status Successfully Updated.'),
          behavior: SnackBarBehavior.floating,
        ));
      });
      setState(() {
        Navigator.of(context).pop();
      });
    }
  }

  errorAlertDialog() {
    context:
    context;
    builder:
    (BuildContext context) {
      return AlertDialog(
        title: const Text('Alert'),
        content: const Text('This is an alert dialog.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      );
    };
  }
}
