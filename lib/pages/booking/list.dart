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
import 'package:drive/pages/booking/detail.dart';
import 'package:drive/pages/booking/timeline.dart';
import 'package:drive/pages/exception.dart';
import 'package:drive/services/api_service.dart';
import 'package:phone_call/phone_call.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drive/main_screen.dart';
import 'package:drive/connectivity_service.dart';
import 'package:http/http.dart' as http;

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
  ConnectivityService connectivity = ConnectivityService();
  ApiService apiService = ApiService();
  List<String> attachment = [];
  List<Map<String, dynamic>> attach = [];
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
  List _pickup_items = [];
  List _delivery_items = [];
  String signature = "";
  TextEditingController start_remarks = TextEditingController();
  Map<String, dynamic> driver = {};

  Future<List<dynamic>> pickup_booking() async {
    _isLoading = true;
    bool isTab = _selectedTabIndex == 0;
    var task = "PICKUP";
    final rows = await dbHelper.getAll('booking',
        whereCondition: 'runsheet_id = ? AND task = ?',
        whereArgs: [widget.item['runsheet_id'], task]);
    if (mounted) {
      setState(() {
        _pickup_items = rows.map((data) {
          int sequenceNo = data['sequence_no'] ?? 2;
          String next_status = '';
          int task_id;
          String task_code = '';
          int next_sequence_no;
          String status = data['status'] ?? 'Assigned';
          if (status == 'APA' || status == 'ARRIVE AT PICKUP ADDRESS') {
            next_status = 'START LOADING';
            task_id = 5;
            task_code = 'STL';
            next_sequence_no = sequenceNo + 1;
          } else if (status == 'STL' || status == 'START LOADING') {
            next_status = 'FINISH LOADING';
            task_id = 6;
            task_code = 'FIL';
            next_sequence_no = sequenceNo + 1;
          } else if (status == 'FIL' || status == 'FINISH LOADING') {
            next_status = 'TIME DEPARTURE AT PICKUP ADDR';
            task_id = 7;
            task_code = 'TDP';
            next_sequence_no = sequenceNo + 1;
          } else if (status == 'TDP' ||
              status == 'TIME DEPARTURE AT PICKUP ADDR') {
            next_status = 'ARRIVE AT DELIVERY ADDRESS';
            task_id = 8;
            task_code = 'ADA';
            next_sequence_no = sequenceNo + 1;
          } else {
            next_status = 'ARRIVE AT PICKUP ADDRESS';
            task_id = 4;
            task_code = 'APA';
            next_sequence_no = sequenceNo;
          }
          return {
            ...data,
            'status': status,
            'next_status': next_status,
            'task_id': task_id,
            'task_code': task_code,
            'next_sequence_no': next_sequence_no
          };
        }).toList();
      });
    }
    _isLoading = false;
    return _pickup_items;
  }

  Future<List<dynamic>> delivery_booking() async {
    _isLoading = true;
    var task = "DELIVERY";
    final rows = await dbHelper.getAll('booking',
        whereCondition: 'runsheet_id = ? AND task = ?',
        whereArgs: [widget.item['runsheet_id'], task]);
    if (mounted) {
      setState(() {
        _delivery_items = rows.map((data) {
          int sequenceNo = data['sequence_no'] ?? 6;
          String next_status = '';
          int task_id;
          String task_code = '';
          int next_sequence_no;
          String status = data['status'] ?? 'Assigned';
          if (status == 'ADA' || status == 'ARRIVE AT DELIVERY ADDRESS') {
            next_status = 'START UNLOADING';
            task_id = 9;
            task_code = 'STU';
            next_sequence_no = sequenceNo + 1;
          } else if (status == 'STU' || status == 'START UNLOADING') {
            next_status = 'FINISH UNLOADING';
            task_id = 10;
            task_code = 'FIU';
            next_sequence_no = sequenceNo + 1;
          } else if (status == 'FIU' || status == 'FINISH UNLOADING') {
            next_status = 'TIME DEPARTURE AT DELIVERY ADDR';
            task_id = 11;
            task_code = 'TDD';
            next_sequence_no = sequenceNo + 1;
          } else if (status == 'TDD' ||
              status == 'TIME DEPARTURE AT DELIVERY ADDR') {
            next_status = 'APPROVED TIME OUT';
            task_id = 12;
            task_code = 'ATO';
            next_sequence_no = sequenceNo + 1;
          } else {
            next_status = 'ARRIVE AT DELIVERY ADDRESS';
            task_id = 8;
            task_code = 'ADA';
            next_sequence_no = sequenceNo;
          }
          return {
            ...data,
            'status': status,
            'next_status': next_status,
            'task_id': task_id,
            'task_code': task_code,
            'next_sequence_no': next_sequence_no,
          };
        }).toList();
      });
    }
    _isLoading = false;
    return _delivery_items;
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
    bool _isConnected = await connectivity.isConnected();
    if (!_isConnected) {
      ConnectivityService.noInternetDialog(context);
    } else {
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
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
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
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MainScreen()),
                            (Route<dynamic> route) => false,
                          );
                        },
                      ),
                      TextButton(
                        child: const Text('START'),
                        onPressed: () {
                          startRunsheet();
                          Navigator.of(context).pop();
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
      'plate_no': widget.item['plate_id'],
      'runsheet': widget.item['runsheet_id'],
      'start_remarks': start_remarks.text,
      'approved_time_in': '',
      'approved_time_out': ''
    };
    bool _isConnected = await connectivity.isConnected();
    if (!_isConnected) {
      ConnectivityService.noInternetDialog(context);
    } else {
      try {
        final responseData = await apiService.post(data, 'monitor');
        if (responseData['success'] == true) {
          var monitor = responseData['data'];
          setState(() {
            monitor_id = monitor['id'];
          });
          final itm = {
            'monitor_id': monitor_id,
          };
          await dbHelper
              .update('runsheet', itm, widget.item['runsheet_id'])
              .then((_) {
            start = false;
            Navigator.of(context).pop();
            setState(() {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Runsheet Started Successfully'),
                behavior: SnackBarBehavior.floating,
              ));
            });
          });
        } else {
          setState(() {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Runsheet unable to start'),
              behavior: SnackBarBehavior.floating,
            ));
          });
        }
      } catch (error) {
        print(error);
      }
    }
  }

  Future<void> _openCamera(data) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    final bytes = await image!.readAsBytes();
    final base64Image = base64Encode(bytes);
    final files = {
      'source_id': data['source_id'] ?? '',
      'task_id': data['task_id'] ?? '',
      'attach': base64Image
    };
    setState(() {
      attach.add(files);
      attachment.add(base64Image);
    });
  }

  void _simulateLoading() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != "") {
      driver = json.decode(userdata!);
    }
    setState(() {
      _getRecordById(widget.item['runsheet_id']);
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
    _getRecordById(widget.item['runsheet_id']);
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabSelection);
    pickup_booking();
    delivery_booking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(widget.item['reference'] ?? ''), actions: [
        Builder(builder: (context) {
          return IconButton(
              icon: const Icon(Icons.sync), onPressed: pickup_booking);
        })
      ]),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPickupTab(), _buildDeliveryTab()],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey.shade900,
        child: TabBar(
          onTap: (int) {
            if (int == 0) {
              pickup_booking();
            } else {
              delivery_booking();
            }
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
    );
  }

  Widget _buildPickupTab() {
    return FutureBuilder(
        future: pickup_booking(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: snapshot.data!.length,
                controller: scrollController,
                itemBuilder: (context, int index) {
                  final item = snapshot.data![index];
                  DateTime est_pick =
                      DateTime.parse(item['pickup_expected_date'] ?? '');
                  final pickup_dtime =
                      DateFormat('MMM d,yyyy h:mm a').format(est_pick);
                  DateTime est_dlv =
                      DateTime.parse(item['delivery_expected_date'] ?? '');
                  final deliver_time =
                      DateFormat('MMM d,yyyy h:mm a').format(est_dlv);
                  return Padding(
                      padding: const EdgeInsets.all(4),
                      child: AbsorbPointer(
                        absorbing: false,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        BookingDetailPage(item)));
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
                                                style: TextStyle(
                                                    color: Colors.red.shade900,
                                                    fontSize: 16,
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
                                                                    Timeline(
                                                                        _pickup_items[
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
                                                                        const MapScreen()));
                                                      },
                                                      child: const Icon(
                                                        Icons.map,
                                                        color: Colors.green,
                                                      )),
                                                ],
                                              )),
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
                                                      pickup_dtime,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.red,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                    Text(
                                                      item['pickup_loc'] ?? '',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                    Text(
                                                      item['pickup_other_address'] ??
                                                          '',
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
                                                      deliver_time,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.red,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                    Text(
                                                      item['delivery_loc'] ??
                                                          '',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                    Text(
                                                      item['delivery_other_address'] ??
                                                          '',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                  ])),
                                          ListTile(
                                              // leading: ElevatedButton(
                                              //   style: ElevatedButton.styleFrom(
                                              //       backgroundColor:
                                              //           Colors.red.shade700,
                                              //       shape:
                                              //           RoundedRectangleBorder(
                                              //         borderRadius:
                                              //             BorderRadius.circular(
                                              //                 20),
                                              //       )),
                                              //   onPressed: () {
                                              //     setState(() {
                                              //       _makePhoneCall(
                                              //           '09353330652');
                                              //     });
                                              //   },
                                              //   child: const Icon(Icons.call,
                                              //       color: Colors.white),
                                              // ),
                                              title: (item['status'] == 'TDP' ||
                                                      item['status'] ==
                                                          'TIME DEPARTURE AT PICKUP ADDR')
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
        future: delivery_booking(),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: snapshot.data!.length,
                controller: scrollController,
                itemBuilder: (context, int index) {
                  final item = snapshot.data![index];
                  DateTime est_pick =
                      DateTime.parse(item['pickup_expected_date'] ?? '');
                  final pickup_dtime =
                      DateFormat('MMM d,yyyy h:mm a').format(est_pick);
                  DateTime est_dlv =
                      DateTime.parse(item['delivery_expected_date'] ?? '');
                  final deliver_time =
                      DateFormat('MMM d,yyyy h:mm a').format(est_dlv);
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
                                                style: TextStyle(
                                                    color: Colors.red.shade900,
                                                    fontSize: 16,
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
                                                                    Timeline(
                                                                        _delivery_items[
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
                                                                        const MapScreen()));
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
                                                      pickup_dtime,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.red,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                    Text(
                                                      item['pickup_loc'] ?? '',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                    Text(
                                                      item['pickup_other_address'] ??
                                                          '',
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
                                                      deliver_time,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.red,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                    Text(
                                                      item['delivery_loc'] ??
                                                          '',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                    Text(
                                                      item['delivery_other_address'] ??
                                                          '',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          overflow: TextOverflow
                                                              .ellipsis),
                                                    ),
                                                  ])),
                                          ListTile(
                                              // leading: ElevatedButton(
                                              //   style: ElevatedButton.styleFrom(
                                              //       backgroundColor:
                                              //           Colors.red.shade700,
                                              //       shape:
                                              //           RoundedRectangleBorder(
                                              //         borderRadius:
                                              //             BorderRadius.circular(
                                              //                 20),
                                              //       )),
                                              //   onPressed: () {
                                              //     _makePhoneCall('09353330652');
                                              //   },
                                              //   child: const Icon(Icons.call,
                                              //       color: Colors.white),
                                              // ),
                                              title: (item['status'] == 'TDD' ||
                                                      item['status'] ==
                                                          'TIME DEPARTURE AT DELIVERY ADDR')
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
                                                      onPressed: () async {
                                                        final rows =
                                                            await dbHelper.getAll(
                                                                'booking',
                                                                whereCondition:
                                                                    'source_id = ? AND task = ? AND reference = ?',
                                                                whereArgs: [
                                                                  item[
                                                                      'source_id'],
                                                                  'PICKUP',
                                                                  item[
                                                                      'reference']
                                                                ],
                                                                orderBy:
                                                                    'sequence_no DESC');

                                                        setState(() {
                                                          if (rows.isNotEmpty) {
                                                            final stat = rows[0]
                                                                ['status'];
                                                            if (stat != 'TDP') {
                                                              errorDialog(
                                                                  context,
                                                                  item);
                                                            } else {
                                                              _showDialog(
                                                                  context,
                                                                  item);
                                                            }
                                                          } else {
                                                            _showDialog(
                                                                context, item);
                                                          }
                                                        });
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

  Future<List> loadAssets(data) async {
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
      final attachs = {
        'source_id': data['source_id'] ?? '',
        'task_id': data['task_id'] ?? '',
        'attach': base64Image
      };
      setState(() {
        attach.add(attachs);
        attachment.add(base64Image);
      });
    }
    return images;
  }

  Future<void> _showDialog(BuildContext context, data) async {
    final TextEditingController note = TextEditingController();
    final TextEditingController receive_by = TextEditingController();
    String? _errorMessage;
    attachment = [];
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
                  child: Column(
                children: [
                  Text(data['reference'] ?? '',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(
                    "${"Please confirm status change to \n" + (data['next_status'] ?? '')}.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              )),
              (data['task'] == 'DELIVERY' && data['task_code'] == 'FIU')
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          const SizedBox(height: 8.0),
                          const Text('Add Signature',
                              textAlign: TextAlign.start),
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
                              TextButton(
                                  child: const Text(
                                    'Clear Signature',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () {
                                    _signatureKey.currentState!.clear();
                                  }),
                            ],
                          ),
                          // const SizedBox(height: 8.0),
                          // const Text('Add Attachment:',
                          //     textAlign: TextAlign.start),
                          // const SizedBox(height: 8.0),
                          // Row(
                          //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          //     children: [
                          //       TextButton.icon(
                          //           icon: const Icon(Icons.attach_file,
                          //               color: Colors.grey),
                          //           label: const Text('Attach',
                          //               style: TextStyle(color: Colors.black)),
                          //           onPressed: () {
                          //             loadAssets(data);
                          //           }),
                          //       TextButton.icon(
                          //         onPressed: () {
                          //           _openCamera(data);
                          //         },
                          //         icon: const Icon(Icons.camera_alt,
                          //             color: Colors.grey),
                          //         label: const Text('Camera',
                          //             style: TextStyle(color: Colors.black)),
                          //       ),
                          //     ]),
                          // const SizedBox(height: 8.0),
                          // attachment.isNotEmpty
                          //     ? Container(
                          //         decoration: BoxDecoration(
                          //           border: Border.all(
                          //             color: Colors.grey,
                          //             width: 1.0,
                          //           ),
                          //         ),
                          //         height: 100,
                          //         child: GridView.builder(
                          //           gridDelegate:
                          //               const SliverGridDelegateWithFixedCrossAxisCount(
                          //             crossAxisCount: 3,
                          //             mainAxisSpacing: 8,
                          //             crossAxisSpacing: 8,
                          //             childAspectRatio: 1,
                          //           ),
                          //           itemCount: attachment.length,
                          //           itemBuilder: (context, index) {
                          //             return Stack(
                          //               children: [
                          //                 Image.memory(
                          //                   base64Decode(attachment[index]),
                          //                   width: 300,
                          //                   height: 300,
                          //                   alignment: Alignment.center,
                          //                 ),
                          //                 Positioned(
                          //                   top: 0,
                          //                   right: 0,
                          //                   child: Checkbox(
                          //                     value:
                          //                         true, // Check the box automatically
                          //                     onChanged: (bool? value) {
                          //                       setState(() {
                          //                         if (value == false) {
                          //                           attachment.removeAt(index);
                          //                         }
                          //                       });
                          //                     },
                          //                   ),
                          //                 ),
                          //               ],
                          //             );
                          //           },
                          //         ),
                          //       )
                          //     : const Text(''),
                          const SizedBox(height: 8.0),
                          SizedBox(
                              height: 40.0,
                              child: TextField(
                                controller: receive_by,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Received By',
                                    errorText: _errorMessage),
                              )),
                        ])
                  : Container(),
              const SizedBox(height: 16.0),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                    labelText: 'Remarks', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                      child: const Text('CANCEL',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        setState(() {
                          Navigator.of(context).pop();
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
                    child:
                        const Text('SUBMIT', overflow: TextOverflow.ellipsis),
                    onPressed: () {
                      data['note'] = note.text;
                      data['receive_by'] = receive_by.text;
                      updateStatus(data);
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

  Future<void> errorDialog(BuildContext context, data) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning!', style: TextStyle(color: Colors.red)),
          content: Text(
              "Booking ${data['reference'] ?? ''} is not yet PICK-UP, Unable to change status."),
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
  }

  Future<void> updateStatus(data) async {
    DateTime now = DateTime.now();
    final dateTime = DateFormat('yyyy-MM-dd H:mm:ss').format(now);
    List<Map<String, dynamic>> logs = [];

    final sign = _signatureKey.currentState;
    if (sign != null) {
      final image = await sign.getData();
      var bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final signature = base64.encode(bytes!.buffer.asUint8List());
      String mimeType = 'application/png';
      var signed = 'data:$mimeType;base64,$signature';
      setState(() {
        final files = {
          'source_id': data['source_id'] ?? '',
          'task_id': data['task_id'] ?? '',
          'attach': signed
        };
        attach.add(files);
      });
    }
    final book = {
      'status': data['task_code'] ?? '',
      'sequence_no': data['next_sequence_no'] ?? ''
    };
    dbHelper.update('booking', book, data['id']);
    final task = {
      'task': data['next_status'] ?? '',
      'task_type': data['task'] ?? '',
      'task_code': data['task_code'] ?? '',
      'contact_person': data['receive_by'] ?? '',
      'datetime': dateTime,
      'task_exception': data['task_exception'] ?? '',
      'line_id': data['line_id'] ?? '',
      'location': data['location'] ?? '',
      'source_id': data['source_id'] ?? '',
      'task_id': data['task_id'] ?? '',
      'note': data['note'] ?? '',
      // 'attachment': jsonEncode(attachment),
      // 'signature': signature,
      'monitor_id': monitor_id,
      'flag': 0
    };
    setState(() {
      logs.add(task);
      dbHelper.save('booking_logs', logs);
      if (attach.isNotEmpty) {
        dbHelper.save('attachment', attach);
      }
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
