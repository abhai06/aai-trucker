import 'package:drive/helper/db_helper.dart';
import 'package:drive/services/api_service.dart';

class Exceptionlist {
  final ApiService apiService = ApiService();
  DBHelper dbHelper = DBHelper();

  void exception() async {
    // await dbHelper.truncateTable('exception');
    // final response =
    //     await apiService.getData('exception_actions', params: {'page': '0'});
    // if (response.statusCode == 200) {
    //   final responseData = json.decode(response.body);
    //   var data = responseData['data'];
    //   List except = data.map((tks) {
    //     return {
    //       'code': tks['code'],
    //       'name': tks['name'],
    //       'description': tks['description'],
    //       'task_id': tks['task_id']
    //     };
    //   }).toList();
    //   await dbHelper.save('exception', except, pkey: 'code');
    // } else {
    //   print('Error: ${response.reasonPhrase}');
    // }
  }
}
