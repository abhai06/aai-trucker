import 'package:drive/maps/map.dart';
import 'package:flutter/material.dart';

class BookingDetailPage extends StatefulWidget {
  final item;
  const BookingDetailPage(this.item, {Key? key}) : super(key: key);
  @override
  _BookingDetailState createState() => _BookingDetailState();
}

class _BookingDetailState extends State<BookingDetailPage> {
  @override
  void initState() {
    super.initState();
    print(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final String reference = widget.item['reference'] ?? '';
    final String customer = widget.item['customer'] ?? '';
    final String remarks = widget.item['remarks'] ?? '';
    final String pickupLoc = widget.item['pickup_loc'] ?? '';
    final String deliveryLoc = widget.item['delivery_loc'] ?? '';
    final String serviceType = widget.item['service_type'] ?? '';
    final totalCbm = widget.item['total_cbm'] ?? '';
    final totalQty = widget.item['total_qty'] ?? '';
    final totalWt = widget.item['total_wt'] ?? '';
    final TextEditingController item_height =
        TextEditingController(text: widget.item['item_height'].toString());
    final TextEditingController item_length =
        TextEditingController(text: widget.item['item_length'].toString());
    final TextEditingController item_width =
        TextEditingController(text: widget.item['item_width'].toString());
    final item_cbm = widget.item['item_cbm'] ?? '';
    final TextEditingController item_qty =
        TextEditingController(text: widget.item['item_qty'].toString());
    final item_weight = widget.item['item_weight'] ?? '';
    final String tripType = widget.item['trip_type'] ?? '';

    final TextEditingController actualQty =
        TextEditingController(text: widget.item['item_qty'].toString());
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Booking Details'), actions: [
        Builder(builder: (context) {
          return IconButton(
            icon: const Icon(
              Icons.map,
              color: Colors.green,
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const MapPage()));
            },
          );
        })
      ]),
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
                      Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(4),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Ref# : $reference',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text('April 19, 2023',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold))
                              ])),
                      const Divider(),
                      Expanded(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text(
                              'Customer',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                const Text('DR #: 09867896242',
                                    style: TextStyle(fontSize: 11)),
                                const Text('Invoice #: 09867896242',
                                    style: TextStyle(fontSize: 11)),
                                Text('Service : $serviceType',
                                    style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                            // trailing: Text('May 1, 2023'),
                          ),
                          const Divider(),
                          ListTile(
                            leading: Icon(Icons.location_on),
                            title: const Text(
                              'Pick Up',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nilo Besingga',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'May 1, 2023 11:24 AM',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Text('09353330652',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    pickupLoc,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextField(
                                              controller: item_qty,
                                              readOnly: true,
                                              decoration: const InputDecoration(
                                                labelText: 'Qty',
                                              ),
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
                                              CrossAxisAlignment.end,
                                          children: [
                                            TextField(
                                              controller: actualQty,
                                              keyboardType: TextInputType.text,
                                              decoration: const InputDecoration(
                                                labelText: 'Actual Qty',
                                              ),
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ]),
                            // trailing: const Text(
                            //   'May 1, 2023 11:24 AM',
                            //   style: TextStyle(
                            //       fontSize: 9, fontWeight: FontWeight.bold),
                            // ),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(
                              Icons.pin_drop,
                            ),
                            title: const Text(
                              'Delivery',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nilo Besingga',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'May 1, 2023 11:24 AM',
                                  style: TextStyle(
                                      fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                                const Text('09353330652',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  deliveryLoc,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: item_qty,
                                            readOnly: true,
                                            decoration: const InputDecoration(
                                              labelText: 'Qty',
                                            ),
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
                                            controller: actualQty,
                                            keyboardType: TextInputType.text,
                                            decoration: const InputDecoration(
                                              labelText: 'Actual Qty',
                                            ),
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // trailing: const Text(
                            //   'May 1, 2023 11:26 AM',
                            //   style: TextStyle(
                            //       fontSize: 9, fontWeight: FontWeight.bold),
                            // ),
                          ),
                          const Divider(),
                          ListTile(
                              leading: const Icon(
                                Icons.view_in_ar,
                              ),
                              title: const Text(
                                'Item Details',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          controller: item_height,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          controller: item_length,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          controller: item_width,
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
                                ],
                              )),
                          const Divider(),
                          ListTile(
                              leading: const Icon(
                                Icons.text_snippet,
                              ),
                              title: const Text(
                                'Remarks / Special Instruction',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(remarks)),
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
