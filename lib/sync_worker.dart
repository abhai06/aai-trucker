import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'syncTask':
        // Add your data synchronization logic here
        await synchronizeData();
        break;
    }

    return Future.value(true);
  });
}

Future<void> synchronizeData() async {
  print('its successfully running');
  // Retrieve data from SQLite and prepare it for synchronization

  // Make an HTTP request to the server API
  // final response = await http.post('', body: {
  // Serialize and send the data as required by your server's API
  // ...
  // });

  // if (response.statusCode == 200) {
  // Data synchronization successful, update local database or perform any other required tasks
  // } else {
  // Handle synchronization error
  // }
}

void registerSyncTask() {
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  Workmanager().registerPeriodicTask(
    'syncTask', // Task ID
    'syncDataTask', // Task Name
    inputData: {}, // Optional input data for the task
    frequency: const Duration(minutes: 1),
  );
}
