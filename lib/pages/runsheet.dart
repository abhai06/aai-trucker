import 'package:drive/helper/db_helper.dart';
import 'dart:convert';
import 'package:drive/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Runsheet {
  final ApiService apiService = ApiService();
  DBHelper dbHelper = DBHelper();
  List runsheetList = [];
  List bookingList = [];
  Map<String, dynamic> driver = {};

  Future<void> runsheet(params) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != "") {
      driver = json.decode(userdata!);
    }
    final response = await apiService.getData('runsheet', params: params);
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      var data = responseData['data']['data'];
      List<Map<String, dynamic>> booking = [];
      runsheetList = data.map((rn) {
        if (rn['task'].length > 0) {
          rn['task'].forEach((key, value) {
            value['runsheet_id'] = rn['id'];
            value['line_id'] = key;
            booking.add(Map<String, dynamic>.from(value));
          });
        }
        return {
          'id': rn['id'],
          'runsheet_id': rn['id'],
          'cbm': rn['cbm'],
          'charging_type': rn['charging_type'],
          'date_from': rn['date_from'],
          'date_to': rn['date_to'],
          'ar_no': rn['ar_no'],
          'dr_no': rn['dr_no'],
          'est_tot_cbm': rn['est_tot_cbm'],
          'est_tot_pcs': rn['est_tot_pcs'],
          'est_tot_wt': rn['est_tot_wt'],
          'from_loc': rn['from_loc'],
          'plate_no': rn['plate_no'],
          'plate_id': driver['plate_id'],
          'reference': rn['reference'],
          'remarks': rn['remarks'],
          'status': rn['status'],
          'task': rn['task'],
          'to_loc': rn['to_loc'],
          'total_pcs': rn['total_pcs'],
          'total_wt': rn['total_wt'],
          'tracking_no': rn['tracking_no'],
          'trucking_id': rn['trucking_id'],
          'updated_at': rn['updated_at'],
          'user_id': rn['user_id'],
          'vehicle_id': rn['vehicle_id'],
          'vehicle_type': rn['vehicle_type']
        };
      }).toList();
      if (runsheetList.isNotEmpty) {
        await dbHelper.save('runsheet', runsheetList, pkey: 'runsheet_id');
        if (booking.isNotEmpty) {
          await dbHelper.saveBooking('booking', booking);
        }
      }
    } else {
      print('Error: ${response.reasonPhrase}');
    }
  }
}
