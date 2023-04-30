import 'package:flutter/material.dart';
import 'current_order.dart';
import 'package:drive/pages/my_task.dart';
// import 'services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // final ApiService apiService = ApiService();
  // late Map<String, dynamic> _userData;
  @override
  void initState() {
    super.initState();
    // apiService.getUserData().then((userData) {
    //   setState(() {
    //     _userData = userData!;
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return Scaffold(
        appBar: AppBar(
            backgroundColor: const Color.fromRGBO(158, 146, 146, 1),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                  start: 10, top: 35, end: 10, bottom: 10),
              centerTitle: true,
              collapseMode: CollapseMode.pin,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png', // Replace with your own logo image asset
                    height: 40,
                    alignment:
                        Alignment.center, // Customize the logo height as needed
                  ),
                  const SizedBox(
                      width:
                          8), // Add some spacing between the logo and the text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'TRUCKER : NILO BESINGGA', // Replace with your app name
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'DUTY DATE : ${now.month}/${now.day}/${now.year}',
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 71), // A
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'PLATE # : 002896', // Replace with your app name
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
        drawer: Drawer(
          backgroundColor: Colors.black,
          child: ListView(
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.red[900],
                  // image: DecorationImage(
                  //     image: AssetImage("assets/images/logo.png"),
                  //     fit: BoxFit.none)
                ),
                child: const Text(
                  'TRUCKER : NILO BESINGGA',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.add_task,
                  color: Colors.indigo,
                ),
                title: const Text('My Task',
                    style: TextStyle(
                      color: Colors.white,
                    )),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CurrentOrderPage()));
                },
              ),
              ListTile(
                leading: Icon(Icons.pending, color: Colors.blue[900]),
                title: const Text('In Progress',
                    style: TextStyle(
                      color: Colors.white,
                    )),
                onTap: () {
                  // Handle item tap here
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.done,
                  color: Colors.green,
                ),
                title: const Text('Completed',
                    style: TextStyle(
                      color: Colors.white,
                    )),
                onTap: () {
                  // Handle item tap here
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.sync,
                  color: Colors.yellow,
                ),
                title: const Text('Request Task',
                    style: TextStyle(
                      color: Colors.white,
                    )),
                onTap: () {
                  // Handle item tap here
                },
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.red),
                title: const Text('Exception',
                    style: TextStyle(
                      color: Colors.white,
                    )),
                onTap: () {
                  // Handle item tap here
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text('Logout',
                    style: TextStyle(
                      color: Colors.white,
                    )),
                onTap: () {
                  // Handle item tap here
                },
              ),
            ],
          ),
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            if (index == 0) {
              return GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyTaskPage()));
                    // Handle the tap event
                  },
                  child: Card(
                    color: Colors.indigo,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_task,
                          size: 50,
                          color: Colors.white,
                        ),
                        SizedBox(height: 5),
                        Text('My Task',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                      ],
                    ),
                  ));
            } else if (index == 1) {
              return GestureDetector(
                  onTap: () {
                    // Handle the tap event
                  },
                  child: Card(
                    color: Colors.blue[900],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.pending,
                          size: 50,
                          color: Colors.white,
                        ),
                        SizedBox(height: 5),
                        Text('In Progress',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                      ],
                    ),
                  ));
            } else if (index == 2) {
              return GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CurrentOrderPage()));
                    // Handle the tap event
                  },
                  child: Card(
                    color: Colors.green[900],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.done,
                          size: 50,
                          color: Colors.white,
                        ),
                        SizedBox(height: 10),
                        Text('Done Task',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                      ],
                    ),
                  ));
            } else if (index == 3) {
              return GestureDetector(
                  onTap: () {
                    // Handle the tap event
                  },
                  child: Card(
                    color: Colors.red[900],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.info,
                          size: 50,
                          color: Colors.white,
                        ),
                        SizedBox(height: 10),
                        Text('Exception',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                      ],
                    ),
                  ));
            } else if (index == 4) {
              return GestureDetector(
                  onTap: () {
                    // Handle the tap event
                  },
                  child: Card(
                    color: Colors.black54,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.sync,
                          size: 50,
                          color: Colors.white,
                        ),
                        SizedBox(height: 10),
                        Text('Task Request',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                      ],
                    ),
                  ));
            } else if (index == 5) {
              return GestureDetector(
                  onTap: () {
                    // Handle the tap event
                  },
                  child: Card(
                    color: Colors.orange[900],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.logout,
                          size: 50,
                          color: Colors.white,
                        ),
                        SizedBox(height: 10),
                        Text('Logout',
                            style:
                                TextStyle(fontSize: 20, color: Colors.white)),
                      ],
                    ),
                  ));
            }
            return null;
          },
        ));
  }
}
