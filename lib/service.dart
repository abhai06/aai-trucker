import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drive/connectivity_service.dart';
import 'package:drive/helper/db_helper.dart';
import 'package:drive/services/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:drive/pages/runsheet.dart';

class Service {
  final ApiService apiService = ApiService();
  Runsheet runsheet = Runsheet();
  ConnectivityService connectivity = ConnectivityService();
  DBHelper dbHelper = DBHelper();
  String driver_name = "";
  String helper_name = "";
  dynamic driver = {};

  List addTaskLogs = [];
  Future<void> syncData() async {
    bool isConnected = await connectivity.isConnected();
    if (isConnected) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final userdata = prefs.getString('user');
      if (userdata != "") {
        driver = json.decode(userdata!);
        driver_name = driver['driver_name']!;
        helper_name = driver['helper_name']!;
      }
      final rows = await dbHelper.getAll('booking_logs',
          whereCondition: 'flag = ?',
          whereArgs: [
            0
          ],
          orderBy: 'booking_id ASC, datetime ASC');
      if (rows.isNotEmpty) {
        rows.forEach((data) async {
          var attachment = await dbHelper.getAll('attachment', whereCondition: 'booking_id = ? AND task_code = ?', whereArgs: [
            data['booking_id'],
            data['task_code']
          ]);

          List<Map<String, dynamic>> attach = await Future.wait(attachment.map((att) async {
            final directory = await getApplicationDocumentsDirectory();
            final filePath = path.join(directory.path, att['attach']);
            final file = File(filePath);

            String imageExtension = path.extension(filePath).replaceAll('.', '');
            final bytes = await file.readAsBytes();
            final base64Image = base64Encode(bytes);
            String mimeType = 'application/$imageExtension';
            var base64 = 'data:$mimeType;base64,$base64Image';
            return {
              'attachment': base64
            };
          }).toList());

          var taskLog = {
            'attachment': attach,
            'booking': data['booking_id'],
            'datetime': data['datetime'],
            'notes': data['note'],
            'runsheet': data['runsheet_id'],
            'status': data['task_code'],
            'transact_with': data['contact_person'],
            'skip_status': true,
            'driver': driver_name,
            'helper': helper_name
          };
          print(taskLog);
          apiService.post(taskLog, 'bookingStatusLogs').then((response) {
            if (response['success'] == true) {
              dbHelper.update(
                  'booking_logs',
                  {
                    'flag': 1
                  },
                  data['id']);
            } else {
              print('API request failed with status code: $response');
            }
          });
        });
      }
    }
  }
}
