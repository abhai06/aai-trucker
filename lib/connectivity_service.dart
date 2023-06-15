import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConnectivityService extends ChangeNotifier {
  static final Connectivity _connectivity = Connectivity();
  static Stream<ConnectivityResult>? _connectivityStream;

  static Future<void> initialize() async {
    _connectivityStream = _connectivity.onConnectivityChanged;
  }

  Future<bool> isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      await pushUpdatesToServer();
      return true;
    } else {
      return false;
    }
    notifyListeners();
  }

  static Future<void> noInternetDialog(context) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Internet Connection'),
          content: const Text('Please check your internet connection.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> pushUpdatesToServer() async {}
}
