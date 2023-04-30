import 'package:flutter/material.dart';
import 'package:drive/helper/db_helper.dart';

class ExceptionPage extends StatefulWidget {
  const ExceptionPage({Key? key}) : super(key: key);
  @override
  State<ExceptionPage> createState() => _ExceptionPageState();
}

class _ExceptionPageState extends State<ExceptionPage> {
  DBHelper dbHelper = DBHelper();
  List data = [];
  Future<void> exception() async {
    final List<Map<String, dynamic>> rows = await dbHelper.getAll('exception');
    setState(() {
      data = rows;
    });
  }

  @override
  void initState() {
    super.initState();
    exception();
  }

  @override
  Widget build(BuildContext context) {
    int selectedValue = 0;
    return Scaffold(
        appBar: AppBar(title: const Text('Exception'), actions: [
          Builder(builder: (context) {
            return IconButton(
              icon: const Icon(
                Icons.map,
                color: Colors.green,
              ),
              onPressed: () {
                // Navigator.push(context,
                //     MaterialPageRoute(builder: (context) => const MapPage()));
              },
            );
          })
        ]),
        body: Column(
          children: data
              .map((option) => RadioListTile<int>(
                    title: Text(
                      option['name'].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(option['description']),
                    value: option['id'],
                    groupValue: selectedValue,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ))
              .toList(),
        ));
  }
}
