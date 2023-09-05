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

  Future<void> runsheet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != null) {
      driver = json.decode(userdata);
    }
    var filter = [
      {
        'field': 'plate_no',
        'condition': '=',
        'value': driver['plate_no'],
        'andor': 'AND',
        'nestedFilters': [],
      },
      {
        'field': null,
        'condition': null,
        'value': null,
        'andor': null,
        'nestedFilters': [
          {
            "field": "status",
            "condition": "=",
            "value": "Active",
            "andor": "OR"
          },
          {
            "field": "status",
            "condition": "=",
            "value": "In-progress",
            "andor": null
          }
        ],
      },
    ];
    final params = {
      'page': '1',
      'filter': filter,
      'itemsPerPage': '999',
      'device': 'mobile'
    };
    await apiService.post(params, 'runsheetList').then((response) {
      if (response['success'] == true) {
        var data = response['data']['data'];
        if (data != null) {
          runsheetList = data.map((rn) {
            if (rn['view_task'].length > 0) {
              List<Map<String, dynamic>> booking = [];
              rn['view_task'].forEach((value) {
                var book = {
                  'runsheet_id': rn['id'] ?? 0,
                  'line_id': value['line_id'] ?? '',
                  'address': value['address'] ?? '',
                  'customer': value['customer'] ?? '',
                  'delivery_expected_date': value['delivery_expected_date'] ?? '',
                  'delivery_loc': value['delivery_loc'] ?? '',
                  'delivery_other_address': value['delivery_other_address'] ?? '',
                  'fixed': value['fixed'] ?? '',
                  'item_cbm': value['item_cbm'] ?? '',
                  'item_height': value['item_height'] ?? '',
                  'item_length': value['item_length'] ?? '',
                  'item_qty': value['item_qty'] ?? '',
                  'item_width': value['item_width'] ?? '',
                  'pickup_expected_date': value['pickup_expected_date'] ?? '',
                  'pickup_loc': value['pickup_loc'] ?? '',
                  'pickup_other_address': value['pickup_other_address'] ?? '',
                  'reference': value['reference'] ?? '',
                  'remarks': value['remarks'] ?? '',
                  'source_id': value['src_id'] ?? '',
                  'status': value['status'] ?? '',
                  'task': value['task'] ?? '',
                };
                booking.add(book);
              });
              dbHelper.saveBooking('booking', booking);
            }
            return {
              'runsheet_id': rn['id'],
              'date_from': rn['date_from'] ?? '',
              'date_to': rn['date_to'] ?? '',
              'ar_no': rn['ar_no'] ?? '',
              'dr_no': rn['dr_no'] ?? '',
              'est_tot_cbm': rn['est_tot_cbm'] ?? '',
              'est_tot_pcs': rn['est_tot_pcs'] ?? '',
              'est_tot_wt': rn['est_tot_wt'] ?? '',
              'est_tot_sqm': rn['est_tot_sqm'] ?? '',
              'plate_no': rn['plate_no'] ?? '',
              'plate_id': driver['plate_id'] ?? '',
              'reference': rn['reference'] ?? '',
              'remarks': rn['remarks'] ?? '',
              'status': rn['status'] ?? ''
            };
          }).toList();
          if (runsheetList.isNotEmpty) {
            dbHelper.save('runsheet', runsheetList, pkey: 'reference');
          }
        } else {
          print('Error: $response');
        }
      } else {
        print('Error: $response');
      }
    }).catchError((error) {
      print(error);
    });
  }
}
