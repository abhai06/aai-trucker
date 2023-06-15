import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drive/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drive/welcome.dart';
import 'services/api_service.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  ApiService apiService = ApiService();
  ConnectivityService connectivity = ConnectivityService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  FocusNode textFieldFocusNode = FocusNode();
  bool _obscured = true;
  bool _showClearIcon = false;
  String _appVersion = '';
  String latestVersion = '';
  String url = '';

  @override
  void initState() {
    super.initState();
    textFieldFocusNode.requestFocus();
    _usernameController.addListener(() {
      setState(() {
        _showClearIcon = _usernameController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    textFieldFocusNode.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _clearText() {
    setState(() {
      _usernameController.clear();
      _showClearIcon = false;
    });
  }

  _login() async {
    bool _isConnected = await connectivity.isConnected();
    if (!_isConnected) {
      ConnectivityService.noInternetDialog(context);
    } else {
      var data = {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'device': 'mobile'
      };
      var res = await apiService.postData(data, 'login');
      if (res['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        res['data']['plate_no'] = res['data']['record']['assigned_vehicle'];
        res['data']['plate_id'] =
            res['data']['record']['assigned_vehicle_value'];
        res['data']['trucker'] = res['data']['record']['trucker'];
        res['data']['driver_contact'] = res['data']['record']['driver_contact'];
        prefs.setString('token', res['data']['api_token']);
        prefs.setBool('isLoggedIn', true);
        prefs.setString('user', json.encode(res['data']));

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        setState(() {
          _appVersion = packageInfo.version;
        });

        final response = await apiService.getData('app-version');
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          var data = responseData['data'];
          latestVersion = data['version'];
          url = data['url_link'];

          setState(() {
            if (_appVersion.toString() != latestVersion.toString()) {
              appUpdate(context, url);
            } else {
              _usernameController.clear();
              _passwordController.clear();
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Login Successfully'),
                behavior: SnackBarBehavior.floating,
              ));
            }
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(res['message']),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> appUpdate(BuildContext context, url) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Required'),
          content: Text(
              'A new version of the app is available. Please update to continue using the app.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Update Now'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                setState(() {
                  launchUrl(Uri.parse(url));
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false,
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleObscured() {
    setState(() {
      _obscured = !_obscured;
      if (textFieldFocusNode.hasPrimaryFocus) {
        return;
      }
      textFieldFocusNode.canRequestFocus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
              image: AssetImage('assets/images/maps.jpg'),
              fit: BoxFit.cover,
            )),
            child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Image(
                      image: AssetImage('assets/images/aai.png'),
                      height: 70,
                      width: 70,
                    ),
                    const SizedBox(height: 60.0),
                    TextField(
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(90.0),
                        ),
                        // filled: true,
                        // fillColor: Colors.grey.shade300,
                        labelText: 'Username',
                        labelStyle: const TextStyle(color: Colors.black),
                        prefixIcon: const Icon(Icons.person, size: 24),
                        prefixIconColor: Colors.black,
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.black, width: 2.0),
                          borderRadius: BorderRadius.circular(70.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.red, width: 2.0),
                          borderRadius: BorderRadius.circular(70.0),
                        ),
                        suffixIcon: _showClearIcon
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearText,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: _passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                      obscureText: _obscured,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(90.0),
                        ),
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.black),
                        prefixIcon: const Icon(Icons.lock_rounded, size: 24),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                          child: GestureDetector(
                            onTap: _toggleObscured,
                            child: Icon(
                                _obscured
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 24,
                                color: Colors.black),
                          ),
                        ),
                        prefixIconColor: Colors.black,
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.black, width: 2.0),
                          borderRadius: BorderRadius.circular(70.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Colors.red, width: 2.0),
                          borderRadius: BorderRadius.circular(70.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 222, 8, 8),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            )),
                        onPressed: _login,
                        child: const Text('SIGN IN'))
                  ],
                ))));
  }
}
