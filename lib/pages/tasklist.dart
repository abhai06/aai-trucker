import 'package:drive/helper/db_helper.dart';
import 'dart:convert';
import 'package:drive/services/api_service.dart';

class Tasklist {
  final ApiService apiService = ApiService();
  DBHelper dbHelper = DBHelper();

  void tasklist(params) async {
    await dbHelper.truncateTable('tasks');
    final response = await apiService.getData('tasks', params: params);
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      var data = responseData['data']['data'];
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
    } else {
      print('Error: ${response.reasonPhrase}');
    }
  }
}
