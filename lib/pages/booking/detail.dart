import 'package:flutter/material.dart';
import 'package:drive/connectivity_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BookingDetailPage extends StatefulWidget {
  final item;
  const BookingDetailPage(this.item, {Key? key}) : super(key: key);
  @override
  _BookingDetailState createState() => _BookingDetailState();
}

class _BookingDetailState extends State<BookingDetailPage> {
  ConnectivityService connectivity = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  void _initConnectivity() async {
    bool isConnected = await connectivity.isConnected();
    if (!isConnected) {
      ConnectivityService.noInternetDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String reference = widget.item['reference'] ?? '';
    final String pickupAddress = widget.item['pickup_other_address'] ?? '';
    final String deliveryAddress = widget.item['delivery_other_address'] ?? '';
    final String task = widget.item['task'] ?? '';
    final String customer = widget.item['customer'] ?? '';
    final String remarks = widget.item['remarks'] ?? '';
    final String address = widget.item['address'] ?? '';
    final String pickupLoc = widget.item['pickup_loc'] ?? '';
    final String deliveryLoc = widget.item['delivery_loc'] ?? '';
    final String serviceType = widget.item['service_type'] ?? '';
    final totalCbm = widget.item['total_cbm'] ?? '';
    final totalQty = widget.item['total_qty'] ?? '';
    final totalWt = widget.item['total_wt'] ?? '';
    final TextEditingController itemHeight = TextEditingController(text: widget.item['item_height'].toString());
    final TextEditingController itemLength = TextEditingController(text: widget.item['item_length'].toString());
    final TextEditingController itemWidth = TextEditingController(text: widget.item['item_width'].toString());
    final itemCbm = widget.item['item_cbm'] ?? '';
    final TextEditingController itemQty = TextEditingController(text: widget.item['item_qty'].toString());
    final itemWeight = widget.item['item_weight'] ?? '';
    final String tripType = widget.item['trip_type'] ?? '';

    final TextEditingController actualQty = TextEditingController(text: widget.item['item_qty'].toString());

    DateTime estPick = DateTime.parse(widget.item['pickup_expected_date'] ?? '');
    final pickupDtime = DateFormat('MMM d,yyyy h:mm a').format(estPick);
    DateTime estDlv = DateTime.parse(widget.item['delivery_expected_date'] ?? '');
    final deliverDtime = DateFormat('MMM d,yyyy h:mm a').format(estDlv);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Booking Details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Card(
                  shadowColor: Colors.black,
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.numbers, size: 35.0, color: Colors.black),
                            title: const Text(
                              'Reference',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(reference, style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.person, size: 35.0, color: Colors.black),
                            title: const Text(
                              'Customer',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            // trailing: Text('May 1, 2023'),
                          ),
                          ListTile(
                              leading: SvgPicture.asset('assets/icons/home_pin.svg', width: 35.0, height: 35.0, color: Colors.black),
                              title: const Text(
                                'Pick Up',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  pickupDtime,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red, overflow: TextOverflow.ellipsis),
                                ),
                                Text(
                                  pickupLoc,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  pickupAddress,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ])),
                          ListTile(
                              leading: SvgPicture.asset('assets/icons/home_location.svg', width: 35.0, height: 35.0, color: Colors.black),
                              title: const Text(
                                'Delivery',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  deliverDtime,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red, overflow: TextOverflow.ellipsis),
                                ),
                                Text(
                                  deliveryLoc,
                                  style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  deliveryAddress,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                )
                              ])),
                          ListTile(
                              leading: SvgPicture.asset('assets/icons/package.svg', width: 35.0, height: 35.0, color: Colors.black),
                              title: const Text(
                                'Item Details',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            TextField(
                                              controller: itemQty,
                                              readOnly: true,
                                              decoration: const InputDecoration(
                                                labelText: 'Qty',
                                              ),
                                              style: const TextStyle(fontSize: 12),
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
                                              controller: actualQty,
                                              keyboardType: TextInputType.text,
                                              decoration: const InputDecoration(
                                                labelText: 'Actual Qty',
                                              ),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: itemHeight,
                                            readOnly: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Length',
                                            ),
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
                                            controller: itemLength,
                                            readOnly: true,
                                            keyboardType: TextInputType.text,
                                            decoration: const InputDecoration(
                                              labelText: 'Width',
                                            ),
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
                                            controller: itemWidth,
                                            readOnly: true,
                                            keyboardType: TextInputType.text,
                                            decoration: const InputDecoration(
                                              labelText: 'Height',
                                            ),
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]),
                                ],
                              )),
                          const Divider(),
                          ListTile(
                              leading: const Icon(Icons.description, size: 35.0, color: Colors.black),
                              title: const Text(
                                'Remarks / Special Instruction',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(remarks, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red))),
                        ],
                      ))
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // floatingActionButton: Container(
      //   padding: const EdgeInsets.all(16.0),
      //   child: Row(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       Expanded(
      //         child: FloatingActionButton.extended(
      //           onPressed: () {
      //             // Add your onPressed logic here
      //           },
      //           label: const Text('Mark as Pick Up'),
      //           icon: const Icon(Icons.east),
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
