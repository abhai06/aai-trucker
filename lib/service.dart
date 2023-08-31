import 'dart:convert';
import 'dart:io';

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
  List addTaskLogs = [];
  Future<void> syncData() async {
    bool isConnected = await connectivity.isConnected();
    if (isConnected) {
      final rows = await dbHelper.getAll('booking_logs',
          whereCondition: 'flag = ?',
          whereArgs: [
            0
          ],
          orderBy: 'source_id ASC, task_id ASC, datetime ASC');
      if (rows.isNotEmpty) {
        rows.forEach((data) async {
          var attachment = await dbHelper.getAll('attachment', whereCondition: 'source_id = ? AND task_id = ?', whereArgs: [
            data['source_id'],
            data['task_id']
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
            'task': data['task'] ?? '',
            'task_code': data['task_code'] ?? '',
            'contact_person': data['contact_person'] ?? '',
            'datetime': data['datetime'] ?? '',
            'formList': 0,
            'task_exception': data['task_exception'] ?? '',
            'ln_id': data['line_id'] ?? 0,
            'location': data['location'] ?? 1,
            'src_id': data['source_id'] ?? '',
            'task_id': data['task_id'] ?? '',
            'note': data['note'] ?? '',
            'task_type': data['task_type'] ?? '',
            'attachment': attach,
            'approved_time_in': '',
            'approved_time_out': ''
          };

          await apiService.post(taskLog, 'addTaskLogs', id: data['monitor_id']).then((response) {
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
