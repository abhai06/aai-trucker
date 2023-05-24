import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'http://192.168.200.116:8000/api/v1';
  postData(data, apiUrl) async {
    var response = await http.post(Uri.parse('$baseUrl/$apiUrl'),
        body: jsonEncode(data), headers: _setHeaders());
    if (response.statusCode == 200) {
      return json.decode(response.body.toString());
    } else {
      return 'Request failed with status: ${response.statusCode}.';
    }
  }

  Future<dynamic> post(data, apiUrl, {int? id}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? bearerToken = prefs.getString('token');
      var head = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $bearerToken',
      };
      var url =
          (id != null && id > 0) ? '$baseUrl/$apiUrl/$id' : '$baseUrl/$apiUrl';
      var response = await http.post(Uri.parse(url),
          body: jsonEncode(data), headers: head);
      if (response.statusCode == 200) {
        return json.decode(response.body.toString());
      } else {
        return 'Request failed with status: ${response.statusCode}.';
      }
    } catch (e) {
      return e;
    }
  }

  getRecordById(apiUrl, id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? bearerToken = prefs.getString('token');

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $bearerToken'
    };
    final url = Uri.parse('$baseUrl/$apiUrl/$id');
    return http.get(url, headers: headers);
  }

  getData(
    apiUrl, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    dynamic body,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? bearerToken = prefs.getString('token');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $bearerToken'
    };

    var url = Uri.parse('$baseUrl/$apiUrl').replace(
        queryParameters: params != null ? _getQueryParams(params) : null);
    return http.get(url, headers: headers);
  }

  Map<String, String> _getQueryParams(Object params) {
    final Map<String, dynamic> map = params as Map<String, dynamic>;
    return Map<String, String>.fromEntries(
      map.entries.map((e) => MapEntry(e.key, e.value.toString())),
    );
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');

    if (userData != null) {
      return jsonDecode(userData);
    } else {
      return null;
    }
  }
}
