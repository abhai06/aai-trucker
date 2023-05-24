import 'package:flutter/material.dart';
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
        title: Text('Home'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, User!',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DashboardStat(
                  label: 'Total Orders',
                  value: '120',
                ),
                DashboardStat(
                  label: 'Pending Orders',
                  value: '5',
                ),
                DashboardStat(
                  label: 'Completed Orders',
                  value: '115',
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 5,
                        itemBuilder: (BuildContext context, int index) {
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 20.0,
                              backgroundColor: Colors.blue,
                              // Replace with the order icon or image
                              // child: Icon(Icons.shopping_bag, color: Colors.white),
                            ),
                            title: Text('Order ${index + 1}'),
                            subtitle: Text('Delivery Address'),
                            trailing: Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // Implement order details screen navigation
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardStat extends StatelessWidget {
  final String label;
  final String value;

  const DashboardStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}
