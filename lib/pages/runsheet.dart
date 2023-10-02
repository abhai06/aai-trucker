import 'dart:async';

import 'package:drive/helper/db_helper.dart';
import 'dart:convert';
import 'package:drive/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drive/pages/trip.dart';

class Runsheet {
  final ApiService apiService = ApiService();
  DBHelper dbHelper = DBHelper();
  List<Map<String, dynamic>> runsheetList = [];
  List<Map<String, dynamic>> bookingList = [];
  Map<String, dynamic> driver = {};

  Future<void> runsheet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userdata = prefs.getString('user');
    if (userdata != null) {
      driver = json.decode(userdata);
    }
    final params = {
      'page': '1',
      'plate_no': driver['plate_no'],
      'itemsPerPage': '999',
      'device': 'mobile'
    };

    try {
      apiService.getData('runsheet', params: params).then((response) {
        var result = json.decode(response.body);
        print(result['data']);

        if (result['success'] == true) {
          List<dynamic> options = List<Map<String, dynamic>>.from(result['data']);
          List<Trip> list = options.map((option) => Trip.fromJson(option)).toList();
          List<Map<String, dynamic>> runsheet = [];
          List<Map<String, dynamic>> bookingList = [];
          List<int> idsToKeep = [];
          List<int> bookingIds = [];

          for (var ls in list) {
            idsToKeep.add(ls.id);
            var trip = {
              'runsheet_id': ls.id,
              'reference': ls.reference,
              'date_from': ls.scheduleFrom,
              'date_to': ls.scheduleTo,
              'status': ls.status,
              'plate_no': ls.plateNo
            };

            runsheet.add(trip);

            for (var booking in ls.booking) {
              bookingIds.add(booking.bookingId);
              var item = {
                'runsheet_id': booking.runsheetId,
                'booking_id': booking.bookingId,
                'customer': booking.customer,
                'delivery_expected_date': booking.deliveryExpectedDate,
                'delivery_city': booking.deliveryCity,
                "delivery_name": booking.deliveryName,
                'delivery_other_address': booking.deliveryOtherAddress,
                "delivery_contact_no": booking.deliveryContactNo,
                "delivery_contact_person": booking.deliveryContactPerson,
                'item_cbm': booking.totalCbm,
                'item_qty': booking.totalQty,
                'item_sqm': booking.totalSqm,
                'item_weight': booking.totalWt,
                "pickup_city": booking.pickupCity,
                "pickup_contact_no": booking.pickupContactNo,
                "pickup_contact_person": booking.pickupContactPerson,
                "pickup_expected_date": booking.pickupExpectedDate,
                "pickup_name": booking.pickupName,
                "pickup_other_address": booking.pickupOtherAddress,
                'reference': booking.reference,
                'remarks': booking.remarks,
                'status': booking.status,
                'status_name': booking.statusName,
                'task': booking.task,
              };
              bookingList.add(item);
            }
          }
          // print(runsheet);
          // print(bookingIds);

          if (runsheet.isNotEmpty) {
            dbHelper.save('runsheet', runsheet, pkey: 'runsheet_id');
            dbHelper.save('booking', bookingList, pkey: 'booking_id');
            dbHelper.deleteDataNotIn('runsheet', 'runsheet_id', idsToKeep);
            dbHelper.deleteDataNotIn('booking', 'booking_id', bookingIds);
          } else {
            dbHelper.truncateTable('runsheet');
          }
        }
      });
    } catch (e) {
      throw Exception('Failed to fetch trip: $e');
    }
  }
}
