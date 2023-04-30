import 'package:drive/login.dart';
import 'package:drive/pages/exception_task.dart';
import 'package:drive/pages/my_task.dart';
import 'package:drive/pages/pending_task.dart';
import 'package:drive/pages/done_task.dart';
import 'package:flutter/material.dart';
import 'package:drive/services/api_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  ApiService apiService = ApiService();
  // DBHelper dbHelper = DBHelper();

  int _currentIndex = 0;
  String currentPageTitle = 'My Task';
  final List<Widget> _children = [
    const MyTaskPage(),
    const PendingTaskPage(),
    const DoneTaskPage(),
    const ExceptionTaskPage()
  ];

  // List runsheetList = [];
  // List bookingList = [];

  // Future<void> runsheet() async {
  //   var filter = {'plate_no': 'ABC123'};
  //   final params = {'page': 1, 'filter': jsonEncode(filter)};
  //   final response = await apiService.getData('runsheet', params: params);

  //   if (response.statusCode == 200) {
  //     final responseData = json.decode(response.body);
  //     var data = responseData['data']['data'];
  //     var book = [];
  //     runsheetList = data.map((rn) {
  //       rn['item_details'].forEach((key, value) {
  //         book.add(value);
  //       });
  //       return {
  //         'id': rn['id'],
  //         'cbm': rn['cbm'],
  //         'charging_type': rn['charging_type'],
  //         'date_from': rn['date_from'],
  //         'date_to': rn['date_to'],
  //         'dr_no': rn['dr_no'],
  //         'est_tot_cbm': rn['est_tot_cbm'],
  //         'est_tot_pcs': rn['est_tot_pcs'],
  //         'est_tot_wt': rn['est_tot_wt'],
  //         'from_loc': rn['from_loc'],
  //         'plate_no': rn['plate_no'],
  //         'reference': rn['reference'],
  //         'remarks': rn['remarks'],
  //         'status': rn['status'],
  //         'task': rn['task'],
  //         'to_loc': rn['to_loc'],
  //         'total_pcs': rn['total_pcs'],
  //         'total_wt': rn['total_wt'],
  //         'tracking_no': rn['tracking_no'],
  //         'trucking_id': rn['trucking_id'],
  //         'updated_at': rn['updated_at'],
  //         'user_id': rn['user_id'],
  //         'vehicle_id': rn['vehicle_id'],
  //         'vehicle_type': rn['vehicle_type']
  //       };
  //     }).toList();
  //     await dbHelper.save('runsheet', runsheetList);
  //     await dbHelper.save('booking', book);
  //   } else {
  //     print('Error: ${response.reasonPhrase}');
  //   }
  // }

  // Future<void> tasklist() async {
  //   await dbHelper.truncateTable('tasks');
  //   final response = await apiService
  //       .getData('tasks', params: {'itemsPerPage': -1, 'group_by': 4});
  //   if (response.statusCode == 200) {
  //     final responseData = json.decode(response.body);
  //     var data = responseData['data']['data'];
  //     List task = data.map((tks) {
  //       return {
  //         'id': tks['id'],
  //         'code': tks['code'],
  //         'name': tks['name'],
  //         'sequence_no': tks['sequence_no'],
  //         'task': tks['task']
  //       };
  //     }).toList();
  //     await dbHelper.save('tasks', task);
  //   } else {
  //     print('Error: ${response.reasonPhrase}');
  //   }
  // }

  // Future<void> exception() async {
  //   await dbHelper.truncateTable('exception');
  //   final response = await apiService.getData('exception_actions');
  //   if (response.statusCode == 200) {
  //     final responseData = json.decode(response.body);
  //     var data = responseData['data'];
  //     List except = data.map((tks) {
  //       return {
  //         'code': tks['code'],
  //         'name': tks['name'],
  //         'description': tks['description'],
  //         'task_id': tks['task_id']
  //       };
  //     }).toList();
  //     await dbHelper.save('exception', except);
  //   } else {
  //     print('Error: ${response.reasonPhrase}');
  //   }
  // }

  @override
  void initState() {
    super.initState();
    // exception();
    // tasklist();
    // runsheet();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(currentPageTitle), actions: [
        Builder(builder: (context) {
          if (_currentIndex == 0) {
            return IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () async {
                // await runsheet();
                // await tasklist();
                // await exception();
                // final res = await dbHelper.getAll('exception');
                // print(res);
              },
            );
          } else {
            return Container();
          }
        })
      ]),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.red,
                // image: DecorationImage(
                //     image: AssetImage("assets/images/profile.png"),
                //     alignment: Alignment.topCenter,
                //     fit: BoxFit.contain)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/images/profile.png'),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'TRUCKER : NILO BESINGGA',
                    style: TextStyle(color: Colors.white),
                  ),
                  const Text(
                    'PLATE # : 002896',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'DUTY DATE : ${now.month}/${now.day}/${now.year}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.add_task,
                color: Colors.indigo,
              ),
              title: const Text('My Task',
                  style: TextStyle(
                    color: Colors.black,
                  )),
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                  currentPageTitle = 'My Task';
                });
                Navigator.pop(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyTaskPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.pending, color: Colors.blue[900]),
              title: const Text('In Progress',
                  style: TextStyle(
                    color: Colors.black,
                  )),
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                  currentPageTitle = 'In Progress';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.done,
                color: Colors.green,
              ),
              title: const Text('Done',
                  style: TextStyle(
                    color: Colors.black,
                  )),
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                  currentPageTitle = 'Completed';
                });
                Navigator.pop(context);
              },
            ),
            // ListTile(
            //   leading: Icon(
            //     Icons.sync,
            //     color: Colors.yellow,
            //   ),
            //   title: Text('Request Task',
            //       style: TextStyle(
            //         color: Colors.white,
            //       )),
            //   onTap: () {
            //     // Handle item tap here
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.red),
              title: const Text('Exception',
                  style: TextStyle(
                    color: Colors.black,
                  )),
              onTap: () {
                setState(() {
                  _currentIndex = 3;
                  currentPageTitle = 'Exception';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text('Logout',
                  style: TextStyle(
                    color: Colors.black,
                  )),
              onTap: () {
                Navigator.pop(context,
                    MaterialPageRoute(builder: (context) => const LoginPage()));
                // Handle item tap here
              },
            ),
          ],
        ),
      ),
      body: _children[_currentIndex],
    );
  }
}
