import 'package:flutter/material.dart';
import 'package:drive/helper/db_helper.dart';
import 'package:lottie/lottie.dart';

class ExceptionPage extends StatefulWidget {
  const ExceptionPage({Key? key}) : super(key: key);
  @override
  State<ExceptionPage> createState() => _ExceptionPageState();
}

class _ExceptionPageState extends State<ExceptionPage> {
  DBHelper dbHelper = DBHelper();
  List data = [];
  String? selectedValue;
  final TextEditingController note = TextEditingController();

  bool _isLoading = true;

  Future<void> exception() async {
    _isLoading = true;
    final List<Map<String, dynamic>> rows = await dbHelper.getAll('exception');
    setState(() {
      data = rows;
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    exception();
  }

  setSelectedRadioTile(val) {
    setState(() {
      selectedValue = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Irregularities'),
        ),
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
            : SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: data.map((option) {
                          return RadioListTile<String>(
                            title: Text(
                              option['name'].toUpperCase(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(option['description']),
                            value: option['name'],
                            groupValue: selectedValue,
                            activeColor: Colors.red,
                            onChanged: (value) {
                              setState(() {
                                setSelectedRadioTile(value);
                              });
                            },
                            selected: selectedValue == option['name'],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8.0),
                      Padding(
                          padding:
                              const EdgeInsets.only(left: 23.0, right: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              TextField(
                                controller: note,
                                decoration: const InputDecoration(
                                    labelText: 'Remarks',
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter Remarks'),
                              ),
                            ],
                          )),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.red),
                          ),
                          child: const Text('SUBMIT'),
                          onPressed: () {
                            setState(() {});
                          }),
                    ]),
              ));
  }
}
