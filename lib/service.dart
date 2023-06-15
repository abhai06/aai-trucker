import 'dart:convert';
import 'package:drive/connectivity_service.dart';
import 'package:drive/helper/db_helper.dart';
import 'package:drive/services/api_service.dart';

class Service {
  final ApiService apiService = ApiService();
  ConnectivityService connectivity = ConnectivityService();
  DBHelper dbHelper = DBHelper();
  List addTaskLogs = [];
  Future<void> syncData() async {
    bool _isConnected = await connectivity.isConnected();
    if (_isConnected) {
      final rows = await dbHelper.getAll('booking_logs',
          whereCondition: 'flag = ?',
          whereArgs: [0],
          orderBy: 'source_id ASC, task_id ASC, datetime ASC');
      if (rows.isNotEmpty) {
        rows.forEach((data) async {
          var files = await dbHelper.getAll('attachment',
              whereCondition: 'source_id = ? AND task_id = ?',
              whereArgs: [data['source_id'], data['task_id']]);
          var attach = [];
          if (files.isNotEmpty) {
            attach = files.map((att) {
              return {'attachment': att['attach']};
            }).toList();
          }
          var taskLog = {
            'task': data['task'] ?? '',
            'task_code': data['task_code'] ?? '',
            'contact_person': data['contact_person'] ?? '',
            'datetime': data['datetime'] ?? '',
            'formList': 0,
            'task_exception': data['task_exception'] ?? '',
            'line_id': data['line_id'] ?? 0,
            'location': data['location'] ?? 1,
            'source_id': data['source_id'] ?? '',
            'task_id': data['task_id'] ?? '',
            'note': data['note'] ?? '',
            'task_type': data['task_type'] ?? '',
            'attachment': attach,
            'approved_time_in': '',
            'approved_time_out': ''
          };

          await apiService
              .post(taskLog, 'addTaskLogs', id: data['monitor_id'])
              .then((response) {
            if (response['success'] == true) {
              dbHelper.update('booking_logs', {'flag': 1}, data['id']);
            } else {
              print(
                  'API request failed with status code: ${response['success']}');
            }
          });
        });
      }
    }
  }
}
