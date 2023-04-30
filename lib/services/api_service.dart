import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'http://192.168.252.247:8000/api/v1';
  postData(data, apiUrl) async {
    var fullUrl = baseUrl + apiUrl;
    var response = await http.post(Uri.parse('$baseUrl/$apiUrl'),
        body: jsonEncode(data), headers: _setHeaders());
    if (response.statusCode == 200) {
      return json.decode(response.body.toString());
    } else {
      return 'Request failed with status: ${response.statusCode}.';
    }
  }

  getData(
    apiUrl, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    dynamic body,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
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
