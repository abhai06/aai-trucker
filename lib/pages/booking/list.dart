import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';

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
import 'package:drive/connectivity_service.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reactive_date_time_picker/reactive_date_time_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';

class BookingListPage extends StatefulWidget {
  final item;
  const BookingListPage(this.item, {Key? key}) : super(key: key);

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _selectedTabIndex = 0;

  final GlobalKey<SignatureState> _signatureKey = GlobalKey<SignatureState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final scrollController = ScrollController();
  DBHelper dbHelper = DBHelper();
  ConnectivityService connectivity = ConnectivityService();
  ApiService apiService = ApiService();
  List<String> attachment = [];
  List<Map<String, dynamic>> attach = [];
  late Map<String, dynamic> monitor;
  List<Asset> images = <Asset>[];

  final ImagePicker _picker = ImagePicker();
  File? imageFile;
  List<File>? selectedImages = [];

  int monitor_id = 0;
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
    // bool isTab = _selectedTabIndex == 0;
    // var task = "PICKUP";
    final rows = await dbHelper.getAll('booking', whereCondition: 'runsheet_id = ?', whereArgs: [
      widget.item['runsheet_id']
    ]);
    // print(rows);
    if (mounted) {
      setState(() {
        _pickup_items = rows.map((data) {
          int sequenceNo = data['sequence_no'] ?? 2;
          String nextStatus = '';
          int taskId;
          String taskCode = '';
          String task = 'PICKUP';
          int nextSequenceNo;
          String status = data['status'] ?? 'Assigned';
          if (status == 'ACPT' || status == 'ACCEPT BOOKING') {
            nextStatus = 'ARRIVE AT PICKUP ADDRESS';
            taskId = 4;
            taskCode = 'APA';
            nextSequenceNo = 4;
            task = 'PICKUP';
          } else if (status == 'APA' || status == 'ARRIVE AT PICKUP ADDRESS') {
            nextStatus = 'START LOADING';
            taskId = 5;
            taskCode = 'STL';
            nextSequenceNo = sequenceNo + 1;
            task = 'PICKUP';
          } else if (status == 'STL' || status == 'START LOADING') {
            nextStatus = 'FINISH LOADING';
            taskId = 6;
            taskCode = 'FIL';
            nextSequenceNo = sequenceNo + 1;
            task = 'PICKUP';
          } else if (status == 'FIL' || status == 'FINISH LOADING') {
            nextStatus = 'TIME DEPARTURE AT PICKUP ADDR';
            taskId = 7;
            taskCode = 'TDP';
            nextSequenceNo = sequenceNo + 1;
            task = 'PICKUP';
          } else if (status == 'TDP' || status == 'TIME DEPARTURE AT PICKUP ADDR') {
            nextStatus = 'ARRIVE AT DELIVERY ADDRESS';
            taskId = 8;
            taskCode = 'ADA';
            nextSequenceNo = sequenceNo + 1;
            task = 'DELIVERY';
          } else if (status == 'ADA' || status == 'ARRIVE AT DELIVERY ADDRESS') {
            nextStatus = 'START UNLOADING';
            taskId = 9;
            taskCode = 'STU';
            nextSequenceNo = sequenceNo + 1;
            task = 'DELIVERY';
          } else if (status == 'STU' || status == 'START UNLOADING') {
            nextStatus = 'FINISH UNLOADING';
            taskId = 10;
            taskCode = 'FIU';
            nextSequenceNo = sequenceNo + 1;
            task = 'DELIVERY';
          } else if (status == 'FIU' || status == 'FINISH UNLOADING') {
            nextStatus = 'TIME DEPARTURE AT DELIVERY ADDR';
            taskId = 11;
            taskCode = 'TDD';
            nextSequenceNo = sequenceNo + 1;
            task = 'DELIVERY';
          } else if (status == 'TDD' || status == 'TIME DEPARTURE AT DELIVERY ADDR') {
            nextStatus = 'APPROVED TIME OUT';
            taskId = 12;
            taskCode = 'ATO';
            nextSequenceNo = sequenceNo + 1;
            task = 'DELIVERY';
          } else {
            nextStatus = data['status_name'];
            taskId = 2;
            taskCode = 'PAT';
            nextSequenceNo = 4;
          }
          return {
            ...data,
            'task': task,
            'status': status,
            'next_status': nextStatus,
            'task_id': taskId,
            'task_code': taskCode,
            'next_sequence_no': nextSequenceNo
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
    final rows = await dbHelper.getDelivery('booking', whereCondition: 'runsheet_id = ? AND task = ?', whereArgs: [
      widget.item['runsheet_id'],
      task
    ]);
    if (mounted) {
      setState(() {
        _delivery_items = rows.map((data) {
          int sequenceNo = data['sequence_no'] ?? 6;
          String nextStatus = '';
          int taskId;
          String taskCode = '';
          int nextSequenceNo;
          String status = data['status'] ?? 'Assigned';
          if (status == 'ADA' || status == 'ARRIVE AT DELIVERY ADDRESS') {
            nextStatus = 'START UNLOADING';
            taskId = 9;
            taskCode = 'STU';
            nextSequenceNo = sequenceNo + 1;
          } else if (status == 'STU' || status == 'START UNLOADING') {
            nextStatus = 'FINISH UNLOADING';
            taskId = 10;
            taskCode = 'FIU';
            nextSequenceNo = sequenceNo + 1;
          } else if (status == 'FIU' || status == 'FINISH UNLOADING') {
            nextStatus = 'TIME DEPARTURE AT DELIVERY ADDR';
            taskId = 11;
            taskCode = 'TDD';
            nextSequenceNo = sequenceNo + 1;
          } else if (status == 'TDD' || status == 'TIME DEPARTURE AT DELIVERY ADDR') {
            nextStatus = 'APPROVED TIME OUT';
            taskId = 12;
            taskCode = 'ATO';
            nextSequenceNo = sequenceNo + 1;
          } else {
            nextStatus = 'ARRIVE AT DELIVERY ADDRESS';
            taskId = 8;
            taskCode = 'ADA';
            nextSequenceNo = sequenceNo;
          }
          return {
            ...data,
            'status': status,
            'next_status': nextStatus,
            'task_id': taskId,
            'task_code': taskCode,
            'next_sequence_no': nextSequenceNo,
          };
        }).toList();
      });
    }
    _isLoading = false;
    return _delivery_items;
  }

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> _getRecordById(int id) async {
    bool isConnected = await connectivity.isConnected();
    if (!isConnected) {
      ConnectivityService.noInternetDialog(context);
    } else {
      if (widget.item['monitor_id'] == null) {
        await apiService.getRecordById("monitor", id).then((res) {
          if (res.statusCode == 200) {
            monitor = json.decode(res.body);
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
        });
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
    bool isConnected = await connectivity.isConnected();
    if (!isConnected) {
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
          await dbHelper.update('runsheet', itm, widget.item['runsheet_id']).then((_) {
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

  void _simulateLoading() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != "") {
      driver = json.decode(userdata!);
    }
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
    // print(widget.item);
    // Intl.defaultLocale = 'pt_BR';
    _simulateLoading();
    // _getRecordById(widget.item['runsheet_id']);
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabSelection);
    pickup_booking();
    // delivery_booking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(widget.item['reference'] ?? '')),
      body: _buildPickupTab(),
      // TabBarView(
      //   controller: _tabController,
      //   children: [
      //     _buildPickupTab(),
      //     _buildDeliveryTab()
      //   ],
      // ),
      // bottomNavigationBar: BottomAppBar(
      //   color: Colors.grey.shade900,
      //   child: TabBar(
      //     onTap: (int) {
      //       if (int == 0) {
      //         pickup_booking();
      //       } else {
      //         delivery_booking();
      //       }
      //     },
      //     indicator: BoxDecoration(
      //       color: Colors.red.shade900,
      //     ),
      //     indicatorColor: Colors.white,
      //     indicatorWeight: 4.0,
      //     controller: _tabController,
      //     labelColor: Colors.white,
      //     dividerColor: Colors.white,
      //     tabs: const [
      //       Tab(text: 'PICK-UP'),
      //       Tab(text: 'DELIVERY'),
      //     ],
      //   ),
      // ),
      // floatingActionButton: Container(
      //     margin: const EdgeInsets.only(bottom: 8.0),
      //     child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
      //       (monitor_id == 0)
      //           ? FloatingActionButton(
      //               backgroundColor: Colors.green,
      //               onPressed: () {
      //                 showDialog(
      //                   context: context,
      //                   barrierDismissible: false,
      //                   builder: (BuildContext dialogContext) {
      //                     return AlertDialog(
      //                       title: const Text('Start Runsheet'),
      //                       content: TextField(
      //                         keyboardType: TextInputType.text,
      //                         controller: start_remarks,
      //                         decoration: const InputDecoration(
      //                           labelText: 'Remarks',
      //                         ),
      //                       ),
      //                       actions: [
      //                         TextButton(
      //                           child: const Text(
      //                             'CANCEL',
      //                             style: TextStyle(color: Colors.red),
      //                           ),
      //                           onPressed: () {
      //                             Navigator.of(context).pop();
      //                           },
      //                         ),
      //                         TextButton(
      //                           child: const Text('START'),
      //                           onPressed: () {
      //                             startRunsheet();
      //                           },
      //                         ),
      //                       ],
      //                     );
      //                   },
      //                 );
      //               },
      //               child: const Text('START'))
      //           : Container(),
      //     ])),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
                  DateTime estPick = DateTime.parse(item['pickup_expected_date'] ?? '');
                  final pickupDtime = DateFormat('MMM d,yyyy h:mm a').format(estPick);
                  DateTime estDlv = DateTime.parse(item['delivery_expected_date'] ?? '');
                  final deliverTime = DateFormat('MMM d,yyyy h:mm a').format(estDlv);
                  return Padding(
                      padding: const EdgeInsets.all(4),
                      child: AbsorbPointer(
                        absorbing: false,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => BookingDetailPage(item)));
                          },
                          child: Card(
                            shadowColor: Colors.black,
                            elevation: 8,
                            child: Stack(
                              children: [
                                Container(
                                    padding: EdgeInsets.zero,
                                    child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                                      ListTile(
                                          title: Text(
                                            item['reference'] ?? '',
                                            style: TextStyle(color: Colors.red.shade900, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['customer'] ?? '',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                "Status : " + (item['status_name'] ?? ''),
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
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
                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => Timeline(_pickup_items[index])));
                                                  },
                                                  child: const Icon(
                                                    Icons.timeline,
                                                    color: Colors.blue,
                                                  )),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ExceptionPage(_pickup_items[index])));
                                                  },
                                                  child: const Icon(
                                                    Icons.info,
                                                    color: Colors.red,
                                                  )),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen(_pickup_items[index])));
                                                  },
                                                  child: const Icon(
                                                    Icons.map,
                                                    color: Colors.green,
                                                  )),
                                            ],
                                          )),
                                      const Divider(color: Colors.black, thickness: 1.0),
                                      ListTile(
                                          leading: SvgPicture.asset(
                                            'assets/icons/home_pin.svg',
                                            width: 35.0,
                                            height: 35.0,
                                            color: Colors.blue,
                                          ),
                                          title: const Text(
                                            'PICK UP',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          // trailing: Container(
                                          //   margin: const EdgeInsets.only(left: 5),
                                          //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          //   decoration: BoxDecoration(
                                          //     color: Colors.blue,
                                          //     borderRadius: BorderRadius.circular(20),
                                          //   ),
                                          //   child: Text(
                                          //     item['task'] ?? '',
                                          //     style: const TextStyle(
                                          //       fontSize: 12,
                                          //       fontWeight: FontWeight.bold,
                                          //       color: Colors.white,
                                          //     ),
                                          //   ),
                                          // ),
                                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(
                                              pickupDtime,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red, overflow: TextOverflow.ellipsis),
                                            ),
                                            Text(
                                              item['pickup_name'] ?? '',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                                            ),
                                            Text(
                                              item['pickup_other_address'] ?? '',
                                              style: const TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis),
                                            ),
                                          ])),
                                      ListTile(
                                          leading: SvgPicture.asset(
                                            'assets/icons/home_location.svg',
                                            width: 35.0,
                                            height: 35.0,
                                            color: Colors.red,
                                          ),
                                          title: const Text(
                                            'DELIVERY',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(
                                              deliverTime,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red, overflow: TextOverflow.ellipsis),
                                            ),
                                            Text(
                                              item['delivery_name'] ?? '',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                                            ),
                                            Text(
                                              item['delivery_other_address'] ?? '',
                                              style: const TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis),
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
                                          title: (item['status'] == 'TDD' || item['status'] == 'EOT' || item['status'] == 'FTD' || item['status'] == 'FTP')
                                              ? ((item['status'] == 'TDD')
                                                  ? const Center(
                                                      child: Text(
                                                      '*** DELIVERED SUCCESSFULLY ***',
                                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                                                    ))
                                                  : Center(
                                                      child: Text("*** ${item['status_name']} ***",
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.red,
                                                          ))))
                                              : (item['status'] == 'Assigned' || item['status'] == 'PAT' || item['status'] == 'BTT' || item['status'] == 'ATI')
                                                  ? Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      children: [
                                                        Expanded(
                                                            child: ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color.fromARGB(255, 222, 8, 8),
                                                              minimumSize: const Size.fromHeight(40),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(20),
                                                              )),
                                                          onPressed: () {
                                                            showDialog(
                                                                context: context,
                                                                barrierDismissible: false,
                                                                builder: (BuildContext context) {
                                                                  String reason = 'Mechanical error/ problem / Vehicle breakdown';
                                                                  List<String> options = <String>[
                                                                    "Mechanical error/ problem / Vehicle breakdown",
                                                                    "Trucker's and Contractor Negligence ( ex. Unreachable via cellphone , Late reporting to duty of trucker, Late provision of trips from the coordinator, Budget related concerns)",
                                                                    "Expired permits / Peza / Manila ",
                                                                    "No Available Driver / Helper (due to an Emergency situation that has to attend / Sicked Trucker / Cannot report to work)",
                                                                    "Coding Scheme",
                                                                    "Non Peza Registered ",
                                                                    "No Available truck based on the actual requirement.",
                                                                    "Not updated registration / Insurance policies",
                                                                    "With existing trips / Engaged to other customers",
                                                                    "With current reservations.",
                                                                  ];

                                                                  return AlertDialog(
                                                                    title: Text(item['reference'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                                                                    content: SizedBox(
                                                                        height: 95,
                                                                        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                                                                          const Text("Are you sure to decline this booking?", textAlign: TextAlign.center, style: TextStyle(color: Colors.black)),
                                                                          const SizedBox(height: 10),
                                                                          DropdownButtonFormField<String>(
                                                                            isExpanded: true,
                                                                            style: const TextStyle(overflow: TextOverflow.clip),
                                                                            value: reason,
                                                                            items: options.map((String value) {
                                                                              return DropdownMenuItem<String>(
                                                                                value: value,
                                                                                child: Text(value, style: const TextStyle(overflow: TextOverflow.clip, color: Colors.black)),
                                                                              );
                                                                            }).toList(),
                                                                            onChanged: (String? newValue) {
                                                                              setState(() {
                                                                                reason = newValue as String;
                                                                              });
                                                                            },
                                                                            decoration: const InputDecoration(
                                                                              labelText: 'Reason',
                                                                              border: OutlineInputBorder(),
                                                                            ),
                                                                          ),
                                                                        ])),
                                                                    actions: [
                                                                      FilledButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: const Color.fromARGB(255, 222, 8, 8),
                                                                        ),
                                                                        child: const Text('CANCEL'),
                                                                        onPressed: () {
                                                                          Navigator.of(context).pop();
                                                                        },
                                                                      ),
                                                                      FilledButton(
                                                                        child: const Text('CONFIRM'),
                                                                        onPressed: () {
                                                                          updateStatus({
                                                                            ...item,
                                                                            'task_code': 'DCLN',
                                                                            'next_status': 'DECLINED BOOKING',
                                                                            'note': reason
                                                                          });
                                                                        },
                                                                      ),
                                                                    ],
                                                                  );
                                                                });
                                                          },
                                                          icon: const Icon(Icons.close),
                                                          label: const Text('DECLINE'),
                                                        )),
                                                        const SizedBox(width: 3),
                                                        Expanded(
                                                            child: ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.green.shade800,
                                                              minimumSize: const Size.fromHeight(40),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(20),
                                                              )),
                                                          onPressed: () {
                                                            showDialog(
                                                                context: context,
                                                                barrierDismissible: false,
                                                                builder: (BuildContext context) {
                                                                  return AlertDialog(
                                                                    title: Text(item['reference'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                                                                    content: const Text("Are you sure to accept this booking?", textAlign: TextAlign.center, style: TextStyle(color: Colors.black)),
                                                                    actions: [
                                                                      FilledButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                          backgroundColor: const Color.fromARGB(255, 222, 8, 8),
                                                                        ),
                                                                        child: const Text('CANCEL'),
                                                                        onPressed: () {
                                                                          Navigator.of(context).pop();
                                                                        },
                                                                      ),
                                                                      FilledButton(
                                                                        child: const Text('CONFIRM'),
                                                                        onPressed: () {
                                                                          updateStatus({
                                                                            ...item,
                                                                            'task_code': 'ACPT',
                                                                            'next_status': 'ACCEPT BOOKING'
                                                                          });
                                                                        },
                                                                      ),
                                                                    ],
                                                                  );
                                                                });
                                                          },
                                                          icon: const Icon(Icons.check),
                                                          label: const Text('ACCEPT'),
                                                        )),
                                                      ],
                                                    )
                                                  : item['status'] == 'DCLN'
                                                      ? const Center(
                                                          child: Text(
                                                          '*** BOOKING DECLINED ***',
                                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                                                        ))
                                                      : ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                              backgroundColor: (item['task'] == 'DELIVERY') ? Colors.green.shade700 : Colors.blue.shade700,
                                                              minimumSize: const Size.fromHeight(35),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(20),
                                                              )),
                                                          child: FittedBox(
                                                            fit: BoxFit.scaleDown,
                                                            child: Row(mainAxisSize: MainAxisSize.max, children: [
                                                              Text(item['next_status'] ?? ''),
                                                              const SizedBox(width: 8.0),
                                                            ]),
                                                          ),
                                                          onPressed: () {
                                                            _showDialog(context, item);
                                                          }))
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

  Widget _buildDeliveryTab() {
    return FutureBuilder(
        future: delivery_booking(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                padding: const EdgeInsets.all(4),
                itemCount: snapshot.data!.length,
                controller: scrollController,
                itemBuilder: (context, int index) {
                  final item = snapshot.data![index];
                  DateTime estPick = DateTime.parse(item['pickup_expected_date'] ?? '');
                  final pickupDtime = DateFormat('MMM d,yyyy h:mm a').format(estPick);
                  DateTime estDlv = DateTime.parse(item['delivery_expected_date'] ?? '');
                  final deliverTime = DateFormat('MMM d,yyyy h:mm a').format(estDlv);
                  return Padding(
                      padding: const EdgeInsets.all(4),
                      child: AbsorbPointer(
                        absorbing: false,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => BookingDetailPage(snapshot.data![index])));
                          },
                          child: Card(
                            shadowColor: Colors.black,
                            elevation: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    padding: EdgeInsets.zero,
                                    child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                                      ListTile(
                                          title: Text(
                                            item['reference'] ?? '',
                                            style: TextStyle(color: Colors.red.shade900, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['customer'] ?? '',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                "Status : " + (item['status'] ?? ''),
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
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
                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => Timeline(_delivery_items[index])));
                                                  },
                                                  child: const Icon(
                                                    Icons.timeline,
                                                    color: Colors.blue,
                                                  )),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ExceptionPage(_delivery_items[index])));
                                                  },
                                                  child: const Icon(
                                                    Icons.info,
                                                    color: Colors.red,
                                                  )),
                                              const SizedBox(width: 10),
                                              GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen(item)));
                                                  },
                                                  child: const Icon(
                                                    Icons.map,
                                                    color: Colors.green,
                                                  )),
                                            ],
                                          )),
                                      const Divider(color: Colors.black, thickness: 1.0),
                                      ListTile(
                                          leading: SvgPicture.asset(
                                            'assets/icons/home_pin.svg',
                                            width: 35.0,
                                            height: 35.0,
                                            color: Colors.blue,
                                          ),
                                          title: const Text(
                                            'Pick Up',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          trailing: Container(
                                            margin: const EdgeInsets.only(left: 5),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(20),
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
                                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(
                                              pickupDtime,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red, overflow: TextOverflow.ellipsis),
                                            ),
                                            Text(
                                              item['pickup_city'] ?? '',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                                            ),
                                            Text(
                                              item['pickup_other_address'] ?? '',
                                              style: const TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis),
                                            ),
                                          ])),
                                      ListTile(
                                          leading: SvgPicture.asset(
                                            'assets/icons/home_location.svg',
                                            width: 35.0,
                                            height: 35.0,
                                            color: Colors.red,
                                          ),
                                          title: const Text(
                                            'Delivery',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text(
                                              deliverTime,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red, overflow: TextOverflow.ellipsis),
                                            ),
                                            Text(
                                              item['delivery_city'] ?? '',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                                            ),
                                            Text(
                                              item['delivery_other_address'] ?? '',
                                              style: const TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis),
                                            ),
                                          ])),
                                      (monitor_id > 0 && item['pick_stat'] == 'TDP')
                                          ? ListTile(
                                              title: (item['status'] == 'TDD' || item['status'] == 'TIME DEPARTURE AT DELIVERY ADDR')
                                                  ? Container(
                                                      margin: const EdgeInsets.only(left: 5),
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey,
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: const Center(
                                                          child: Text(
                                                        'Delivered Successfully',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      )),
                                                    )
                                                  : ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.green.shade700,
                                                          minimumSize: const Size.fromHeight(35),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(20),
                                                          )),
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Row(mainAxisSize: MainAxisSize.max, children: [
                                                          Text(item['next_status'] ?? ''),
                                                          const SizedBox(width: 8.0),
                                                          // const Icon(
                                                          //     Icons.east),
                                                        ]),
                                                      ),
                                                      onPressed: () async {
                                                        setState(() {
                                                          _showDialog(context, item);
                                                        });
                                                      }))
                                          : Container()
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

  FormGroup buildForm() => fb.group({
        'dateTime': FormControl<DateTime>(value: DateTime.now(), validators: [
          Validators.required
        ])
      });
  String? customValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }

  _showDialog(BuildContext context, data) async {
    final TextEditingController note = TextEditingController();
    final TextEditingController receiveBy = TextEditingController();

    DateTime datetime = DateTime.now();
    selectedImages = [];
    attach = [];
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                    return ReactiveFormBuilder(
                        form: buildForm,
                        builder: (context, form, child) {
                          final datetime = form.control('dateTime');
                          return Form(
                              key: _formKey,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
                                const SizedBox(height: 8.0),
                                Container(
                                    child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(data['reference'] ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    const Divider(),
                                    const Text(
                                      "Please confirm status change to",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      data['next_status'] ?? '',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                    ),
                                  ],
                                )),
                                const SizedBox(height: 16.0),
                                ReactiveDateTimePicker(
                                    formControlName: 'dateTime',
                                    type: ReactiveDatePickerFieldType.dateTime,
                                    decoration: const InputDecoration(
                                      labelText: 'Date & Time',
                                      hintText: 'hintText',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    selectableDayPredicate: (DateTime date) {
                                      final currentDate = DateTime.now();
                                      final twoDaysBefore = currentDate.subtract(const Duration(days: 2));
                                      return date.isAfter(twoDaysBefore) || date.isAtSameMomentAs(currentDate);
                                    }),
                                const SizedBox(height: 4.0),
                                (data['task'] == 'DELIVERY' && data['task_code'] == 'TDD')
                                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                                        const SizedBox(height: 2.0),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                          const Text('Add Attachment:', textAlign: TextAlign.start),
                                          // const SizedBox(width: 70.0),
                                          IconButton(
                                              icon: SvgPicture.asset(
                                                'assets/icons/gallery_thumbnail.svg',
                                                width: 35.0,
                                                height: 35.0,
                                                color: Colors.green.shade900,
                                              ),
                                              onPressed: () async {
                                                final image = await _picker.pickImage(source: ImageSource.gallery);
                                                if (image != null) {
                                                  final directory = await getApplicationDocumentsDirectory();
                                                  String imagePath = image.path;
                                                  String filename = path.basename(imagePath);
                                                  final tempPath = path.join(directory.path, filename);
                                                  final imageFile = File(image.path);
                                                  await imageFile.copy(tempPath);

                                                  final files = {
                                                    'booking_id': data['booking_id'] ?? '',
                                                    'runsheet_id': data['runsheet_id'] ?? '',
                                                    'task_code': data['task_code'] ?? '',
                                                    'attach': filename
                                                  };
                                                  setState(() {
                                                    attach.add(files);
                                                    selectedImages!.add(File(imagePath));
                                                  });
                                                }
                                              }),
                                          IconButton(
                                              onPressed: () async {
                                                final image = await _picker.pickImage(source: ImageSource.camera);
                                                if (image != null) {
                                                  final directory = await getApplicationDocumentsDirectory();
                                                  var imagePath = File(image.path);
                                                  String filename = path.basename(image.path);
                                                  final tempPath = path.join(directory.path, filename);
                                                  await imagePath.copy(tempPath);
                                                  final files = {
                                                    'booking_id': data['booking_id'] ?? '',
                                                    'runsheet_id': data['runsheet_id'] ?? '',
                                                    'task_code': data['task_code'] ?? '',
                                                    'attach': filename
                                                  };
                                                  setState(() {
                                                    attach.add(files);
                                                    selectedImages!.add(imagePath);
                                                  });
                                                }
                                              },
                                              icon: Icon(Icons.camera_alt, color: Colors.red.shade900),
                                              iconSize: 28.0),
                                        ]),
                                        const SizedBox(height: 8.0),
                                        selectedImages!.isNotEmpty
                                            ? SizedBox(
                                                height: 100,
                                                child: GridView.builder(
                                                  shrinkWrap: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 3,
                                                    mainAxisSpacing: 8,
                                                    crossAxisSpacing: 8,
                                                    childAspectRatio: 1,
                                                  ),
                                                  itemCount: selectedImages!.length,
                                                  itemBuilder: (context, index) {
                                                    return Stack(
                                                      children: [
                                                        Image.file(selectedImages![index], fit: BoxFit.cover, width: 300, height: 300, alignment: Alignment.center),
                                                        Positioned(
                                                          top: 0,
                                                          right: 0,
                                                          child: Checkbox(
                                                            value: true,
                                                            onChanged: (bool? value) {
                                                              setState(() {
                                                                if (value == false) {
                                                                  selectedImages!.removeAt(index);
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
                                            : const Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(color: Colors.red),
                                                )),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: receiveBy,
                                          validator: customValidator,
                                          keyboardType: TextInputType.text,
                                          decoration: InputDecoration(
                                            border: const OutlineInputBorder(),
                                            labelText: 'Received By',
                                            suffixIcon: receiveBy.text != ''
                                                ? IconButton(
                                                    icon: const Icon(Icons.clear),
                                                    onPressed: () {
                                                      receiveBy.clear();
                                                    },
                                                  )
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 8.0),
                                        TextFormField(
                                          controller: note,
                                          validator: customValidator,
                                          decoration: const InputDecoration(labelText: 'Remarks', border: OutlineInputBorder()),
                                        ),
                                        const SizedBox(height: 16.0)
                                      ])
                                    : Container(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    FilledButton.icon(
                                        icon: const Icon(Icons.close),
                                        style: ButtonStyle(
                                          backgroundColor: MaterialStateProperty.all<Color>(Colors.orange.shade300),
                                        ),
                                        label: const Text('CANCEL', style: TextStyle(color: Colors.white)),
                                        onPressed: () {
                                          setState(() {
                                            Navigator.of(context).pop();
                                          });
                                        }),
                                    const SizedBox(
                                      width: 2,
                                    ),
                                    FilledButton.icon(
                                      icon: const Icon(Icons.save),
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all<Color>(Colors.red.shade900),
                                      ),
                                      label: const Text('SAVE', overflow: TextOverflow.ellipsis),
                                      onPressed: () {
                                        if (_formKey.currentState!.validate() && form.valid) {
                                          final DateTime date = datetime.value;
                                          final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
                                          data['note'] = note.text;
                                          data['receive_by'] = receiveBy.text;
                                          data['datetime'] = dateFormat.format(date);
                                          updateStatus(data);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ]));
                        });
                  })));
        });
  }

  Future<void> errorDialog(BuildContext context, data) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning!', style: TextStyle(color: Colors.red)),
          content: Text("Booking ${data['reference'] ?? ''} is not yet PICK-UP, Unable to change status."),
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
      final imageBytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = await getApplicationDocumentsDirectory();
      final dateTimex = DateTime.now();
      final filename = '${dateTimex.microsecondsSinceEpoch}.png';
      final imagePath = path.join(directory.path, filename);
      final buffer = imageBytes!.buffer;
      final file = await File(imagePath).writeAsBytes(buffer.asUint8List(imageBytes.offsetInBytes, imageBytes.lengthInBytes));

      final tempDirectory = await getTemporaryDirectory();
      final tempPath = path.join(tempDirectory.path, filename);
      await file.copy(tempPath);

      setState(() {
        final files = {
          'booking_id': data['booking_id'] ?? '',
          'task_code': data['task_code'] ?? '',
          'attach': filename
        };
        attach.add(files);
      });
    }
    final book = {
      'status': data['task_code'] ?? '',
      'status_name': data['next_status'] ?? '',
      'sequence_no': data['next_sequence_no'] ?? '',
      'task': data[''] ?? ''
    };
    setState(() {
      dbHelper.update('booking', book, data['id']);
    });
    final task = {
      'task': data['next_status'] ?? '',
      'task_type': data['task'] ?? '',
      'task_code': data['task_code'] ?? '',
      'contact_person': data['receive_by'] ?? '',
      'datetime': data['datetime'] ?? dateTime,
      'task_exception': data['task_exception'] ?? '',
      'booking_id': data['booking_id'] ?? '',
      'note': data['note'] ?? '',
      'runsheet_id': widget.item['runsheet_id'],
      'flag': 0
    };
    setState(() {
      logs.add(task);
      dbHelper.save('booking_logs', logs);
      if (attach.isNotEmpty) {
        dbHelper.save('attachment', attach);
      }
      pickup_booking();
    });
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Status Successfully Updated.'),
        behavior: SnackBarBehavior.fixed,
      ));
    });
    setState(() {
      Navigator.of(context).pop();
    });
  }
}
