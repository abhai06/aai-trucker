import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:drive/helper/db_helper.dart';
import 'package:drive/connectivity_service.dart';

class Timeline extends StatefulWidget {
  final item;
  const Timeline(this.item, {Key? key}) : super(key: key);
  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  DBHelper dbHelper = DBHelper();
  ConnectivityService connectivity = ConnectivityService();

  List events = [];
  bool isLoading = false;
  Future<List<dynamic>> logs() async {
    setState(() {
      isLoading = true;
    });
    final log = await dbHelper.getAll('booking_logs',
        whereCondition: 'booking_id = ?',
        whereArgs: [
          widget.item['booking_id']
        ],
        orderBy: 'id DESC');
    events = log;
    setState(() {
      isLoading = false;
    });
    return events;
  }

  @override
  void initState() {
    super.initState();
  }

  void _initConnectivity() async {
    bool isConnected = await connectivity.isConnected();
    if (!isConnected) {
      ConnectivityService.noInternetDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Status Logs"),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  widget.item['reference'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        body: isLoading
            ? Center(
                child: Lottie.asset(
                  "assets/animations/spinner.json",
                  animate: true,
                  alignment: Alignment.center,
                  height: 100,
                  width: 100,
                ),
              )
            : FutureBuilder<List<dynamic>>(
                future: logs(),
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (events.isNotEmpty) {
                    return ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, int index) {
                          final history = events[index];
                          // final signature = history['signature'] ?? '';
                          int flag = history['flag'] ?? 0;
                          return TimelineTile(
                            alignment: TimelineAlign.manual,
                            lineXY: 0.1,
                            endChild: Container(
                              constraints: const BoxConstraints(
                                minHeight: 50,
                              ),
                              // color: Colors.lightGreenAccent,
                              // child: Padding(
                              //   padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text(
                                      history['task_code'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          history['task'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          history['datetime'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          history['note'],
                                          style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
                                        ),
                                        Text(
                                          (history['task_code'] == 'TDD') ? 'Receive By : ${history['contact_person'] ?? ''}' : '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        )
                                      ],
                                    ),
                                    // trailing: GestureDetector(
                                    //     onTap: () {
                                    //       _showSignature(context, signature);
                                    //     },
                                    //     child: (history['task_code'] == 'FIU')
                                    //         ? Icon(Icons.draw,
                                    //             color: Colors.grey)
                                    //         : Text(''))
                                  ),
                                ],
                              ),
                              // ),
                            ),
                            isFirst: false,
                            indicatorStyle: IndicatorStyle(
                              width: 40,
                              color: (flag == 1) ? Colors.green : Colors.blue,
                              padding: const EdgeInsets.all(8),
                              iconStyle: IconStyle(
                                color: Colors.white,
                                iconData: (flag == 1) ? Icons.check : Icons.sync,
                              ),
                            ),
                            beforeLineStyle: const LineStyle(color: Colors.red, thickness: 3),
                            afterLineStyle: const LineStyle(color: Colors.red, thickness: 3),
                          );
                        });
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  } else {
                    return Center(
                        child: Lottie.asset(
                      "assets/animations/noitem.json",
                      animate: true,
                      alignment: Alignment.center,
                      height: 300,
                      width: 300,
                    ));
                  }
                }));
  }

  Future<void> _showSignature(BuildContext context, sign) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
                child: sign != 'null'
                    ? Image.memory(
                        base64Decode(sign),
                        key: UniqueKey(),
                      )
                    : const Text('No Signature')),
          );
        });
  }
}
