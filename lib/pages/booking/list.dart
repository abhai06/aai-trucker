import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

import 'package:drive/helper/db_helper.dart';
import 'package:drive/maps/map.dart';
import 'package:drive/pages/booking/detail.dart';
import 'package:drive/pages/exception.dart';
import 'package:drive/services/api_service.dart';

class BookingListPage extends StatefulWidget {
  final item;
  const BookingListPage(this.item, {Key? key}) : super(key: key);

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  final scrollController = ScrollController();
  DBHelper dbHelper = DBHelper();
  ApiService apiService = ApiService();
  List<Asset> images = [];
  List<String> attachment = [];

  final int _currentPage = 1;
  final int _totalPages = 1;
  final bool _isLoading = true;
  int page = 1;
  List _items = [];

  Future<List<dynamic>> _fetchData() async {
    final rows = await dbHelper.getAll('booking',
        whereCondition: 'item_details = ?', whereArgs: [widget.item['id']]);
    // await Future.delayed(const Duration(seconds: 1));
    List status = await dbHelper.getAll('tasks');
    setState(() {
      _items = rows.map((data) {
        var stat = {};
        int sequenceNo;
        if (data['status'] == 'Assigned' || data['status'] == null) {
          sequenceNo = 2;
        } else {
          sequenceNo = (data['sequence_no'] != null && data['sequence_no'] < 9)
              ? data['sequence_no'] + 1
              : 9;
        }
        if (status.isNotEmpty) {
          stat = status.firstWhere((row) => (row['sequence_no'] == sequenceNo));
          return {
            ...data,
            'next_status': stat['name'],
            'task_id': stat['id'] ?? '',
            'task_code': stat['code'] ?? '',
            'sequence_no': stat['sequence_no'] ?? ''
          };
        }
      }).toList();
    });
    return _items;
  }

  Future<void> logs() async {
    List logs = await dbHelper
        .getAll('booking_logs', whereCondition: 'source_id=?', whereArgs: [2]);
    print(logs);
  }

  @override
  void initState() {
    super.initState();
    // scrollController.addListener(_scrollListener);
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController searchQueryController = TextEditingController();
    return Scaffold(
        appBar: AppBar(title: Text(widget.item['reference']), actions: [
          Builder(builder: (context) {
            return IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () async {
                // await _fetchData();
                await logs();
              },
            );
          })
        ]),
        body: FutureBuilder<List<dynamic>>(
            future: _fetchData(),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: snapshot.data!.length,
                    controller: scrollController,
                    itemBuilder: (context, int index) {
                      final item = snapshot.data![index];
                      DateTime dateTime =
                          DateTime.parse(widget.item['updated_at']);
                      final formattedDateTime =
                          DateFormat('MMM d,yyyy h:mm a').format(dateTime);
                      return Padding(
                          padding: const EdgeInsets.all(4),
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
                              elevation: 4,
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
                                                subtitle: Text(
                                                  "Status : " +
                                                      (item['status'] ?? ''),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
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
                                                                          const MapPage()));
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
                                                  Icons.mode_standby,
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
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    item['trip_type'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item['pickup_contact_person'] ??
                                                            '',
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Text(
                                                        item['pickup_loc'] ??
                                                            '',
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            overflow:
                                                                TextOverflow
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
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item['delivery_contact_person'] ??
                                                            '',
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Text(
                                                          item['delivery_loc'] ??
                                                              '',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      11)),
                                                    ])),
                                            ListTile(
                                                leading: TextButton(
                                                  child: const Icon(Icons.west),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                ),
                                                title: item['sequence_no'] == 10
                                                    ? Container(
                                                        margin: const EdgeInsets
                                                            .only(left: 5),
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                horizontal: 8,
                                                                vertical: 8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.green,
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
                                                                    Colors.red,
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
                                                                const Icon(
                                                                    Icons.east),
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
                          ));
                    });
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              } else {
                return Center(
                  child: Lottie.asset(
                    "assets/animations/loading.json",
                    animate: true,
                    alignment: Alignment.center,
                    height: 100,
                    width: 100,
                  ),
                );
              }
            }));
  }

  Future<void> _pickImages() async {
    List<Asset> pickedImages = [];
    try {
      pickedImages = await MultiImagePicker.pickImages(
        maxImages: 3,
        enableCamera: true,
        selectedAssets: images,
        cupertinoOptions: const CupertinoOptions(
            takePhotoIcon: "chat", autoCloseOnSelectionLimit: true),
        materialOptions: const MaterialOptions(
            actionBarColor: "#FA0707",
            actionBarTitle: "Select images",
            allViewTitle: "All Photos",
            useDetailsView: true,
            startInAllView: true,
            selectCircleStrokeColor: "#000000",
            autoCloseOnSelectionLimit: true),
      );
    } on Exception catch (e) {
      print(e.toString());
    }

    setState(() {
      images = pickedImages;
    });

    for (var i = 0; i < pickedImages.length; i++) {
      ByteData byteData = await pickedImages[i].getByteData();
      List<int> imageData = byteData.buffer.asUint8List();
      String base64Image = base64Encode(imageData);
      attachment.add(base64Image);
    }
  }

  void _showDialog(BuildContext context, data) {
    final TextEditingController note = TextEditingController();
    DateTime now = DateTime.now();
    final dateTime = DateFormat('yyyy-MM-dd h:mm:ss').format(now);
    List<Map<String, dynamic>> logs = [];
    final book = {
      'status': data['next_status'],
      'sequence_no': data['sequence_no']
    };
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                child: Text(
                  "${"Please confirm status change to \n" + (data['next_status'] ?? '')}.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextField(
                keyboardType: TextInputType.text,
                controller: note,
                decoration: const InputDecoration(
                  labelText: 'Note',
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                      onPressed: _pickImages,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.attach_file),
                          SizedBox(width: 5),
                          Text('Attachment'),
                        ],
                      ))
                ],
              ),
              Expanded(
                  child: GridView.count(
                      crossAxisCount: 3,
                      children: List.generate(images.length, (index) {
                        Asset asset = images[index];
                        return Stack(
                          children: [
                            AssetThumb(
                              asset: asset,
                              width: 100,
                              height: 100,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Checkbox(
                                value: true, // Check the box automatically
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value != null && value) {
                                      images.add(asset);
                                    } else {
                                      images.remove(asset);
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      }, growable: false))),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextButton(
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
                      backgroundColor: MaterialStateProperty.all<Color>(Colors
                          .blue), // Set the background color of the button
                    ),
                    child: const Text('SAVE'),
                    onPressed: () {
                      dbHelper.update('booking', book, data['id']);
                      setState(() {
                        logs.add({
                          'task': data['next_status'],
                          'task_code': data['task_code'],
                          'datetime': dateTime,
                          'source_id': data['id'],
                          'task_id': data['task_id'],
                          'note': note.text,
                          'attachment': jsonEncode(attachment)
                        });
                      });
                      dbHelper.save('booking_logs', logs);
                      Future.delayed(const Duration(seconds: 1));
                      setState(() {
                        _fetchData();
                      });
                      setState(() {
                        Navigator.pop(context);
                      });
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
}
