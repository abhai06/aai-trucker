import 'package:drive/pages/booking/list.dart';
import 'package:flutter/material.dart';
import 'package:drive/services/api_service.dart';
import 'package:intl/intl.dart';
// import 'package:sqflite/sqflite.dart';
import 'package:drive/helper/db_helper.dart';

class MyTaskPage extends StatefulWidget {
  const MyTaskPage({Key? key}) : super(key: key);

  @override
  State<MyTaskPage> createState() => _MyTaskPageState();
}

class _MyTaskPageState extends State<MyTaskPage> {
  DBHelper dbHelper = DBHelper();
  ApiService apiService = ApiService();
  bool _isLoading = false;
  List _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final rows = await dbHelper.getAll('runsheet');
    setState(() {
      _items = rows;
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
            future: _loadData(),
            builder: (context, snapshot) {
              List task = _items;
              return ListView.builder(
                  itemCount: task.length,
                  itemBuilder: (context, index) {
                    final item = task[index];
                    DateTime dateTime = DateTime.parse(item['updated_at']);
                    final formattedDateTime =
                        DateFormat('MMM d,yyyy h:mm a').format(dateTime);
                    return Card(
                        shadowColor: Colors.black,
                        elevation: 4,
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        BookingListPage(_items[index])));
                          },
                          leading: const Icon(Icons.list_alt),
                          title: Text(
                            item['reference'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDateTime,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  item['remarks'],
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(left: 5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
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
                              ),
                            ],
                          ),
                        ));
                  });
            }));
  }
}
