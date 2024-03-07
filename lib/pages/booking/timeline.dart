import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:drive/helper/db_helper.dart';
import 'package:drive/connectivity_service.dart';
import 'package:drive/services/api_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class Timeline extends StatefulWidget {
  final item;
  const Timeline(this.item, {Key? key}) : super(key: key);
  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  DBHelper dbHelper = DBHelper();
  ConnectivityService connectivity = ConnectivityService();
  ApiService apiService = ApiService();

  List events = [];
  bool isLoading = false;
  Future<List<dynamic>> logs() async {
    try {
      final res = await apiService.getData('getStatus', params: {
        'booking_id': widget.item['booking_id'] ?? '',
        'runsheet_id': widget.item['runsheet_id'] ?? ''
      });
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        return List<dynamic>.from(data['data']);
      } else {
        throw Exception('Failed to load logs');
      }
    } catch (e) {
      print(e);
      return events;
    }
  }

  @override
  void initState() {
    logs();
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
        body: FutureBuilder<List<dynamic>>(
            future: logs(),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: SpinKitFadingCircle(
                  color: Colors.red.shade900,
                ));
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, int index) {
                      final history = snapshot.data![index];
                      DateTime stat = DateTime.parse(history['datetime'] ?? '');
                      final statusDate = DateFormat('MMM d,yyyy HH:mm').format(stat);
                      return TimelineTile(
                        alignment: TimelineAlign.manual,
                        lineXY: 0.1,
                        endChild: Container(
                          constraints: const BoxConstraints(
                            minHeight: 50,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(
                                  history['status'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(history['status_name'] ?? '', style: const TextStyle(fontSize: 12)),
                                    Text(statusDate, style: const TextStyle(fontSize: 15, color: Colors.red, fontWeight: FontWeight.bold)),
                                    Text((history['status'] == 'TDD') ? 'Receive By : ${history['transact_with'] ?? ''}' : '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text(history['notes'] ?? '', style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis))
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(left: 5),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (history['task'] == 'DELIVERY') ? Colors.green : Colors.blue,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        history['task'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // ),
                        ),
                        isFirst: false,
                        indicatorStyle: IndicatorStyle(
                          width: 40,
                          color: Colors.green,
                          padding: const EdgeInsets.all(8),
                          iconStyle: IconStyle(
                            color: Colors.white,
                            iconData: Icons.check,
                          ),
                        ),
                        beforeLineStyle: const LineStyle(color: Colors.green, thickness: 2),
                        afterLineStyle: const LineStyle(color: Colors.green, thickness: 2),
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
