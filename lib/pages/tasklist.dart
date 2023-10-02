import 'package:drive/helper/db_helper.dart';
import 'package:drive/services/api_service.dart';
import 'dart:convert';

class Tasklist {
  final ApiService apiService = ApiService();
  DBHelper dbHelper = DBHelper();

  void tasklist(params) async {
    try {
      await dbHelper.truncateTable('tasks');
      await apiService.getData('status', params: params).then((response) async {
        final responseData = json.decode(response.body.toString());
        // if (responseData['success'] == true) {
        var data = responseData['data'];
        List task = data.map((tks) {
          return {
            'id': tks['id'],
            'code': tks['code'],
            'name': tks['name'],
            'sequence_no': tks['sequence_no'],
            'task': tks['task']
          };
        }).toList();
        await dbHelper.save('tasks', task, pkey: 'code');
        // } else {
        //   print('Error: ${response.reasonPhrase}');
        // }
      });
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }
}
