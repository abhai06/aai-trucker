import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drive/welcome.dart';

import 'services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  ApiService apiService = ApiService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  FocusNode textFieldFocusNode = FocusNode();
  bool _obscured = true;
  final bool _isLoading = false;
  final bool _loginSuccess = false;
  late AnimationController _animationController;
  bool _showClearIcon = false;

  @override
  void initState() {
    super.initState();
    textFieldFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkConnectivity(context);
    });

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

  _showMsg(msg) {
    final snackBar = SnackBar(
      backgroundColor: const Color(0xFF363f93),
      content: Text(msg),
      action: SnackBarAction(
        label: 'Close',
        onPressed: () {
          // Some code to undo the change!
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  _login() async {
    bool connected = await checkInternetConnection();
    if (connected) {
      var data = {
        'username': _usernameController.text,
        'password': _passwordController.text,
      };
      var res = await apiService.postData(data, 'login');
      if (res['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('token', res['data']['api_token']);
        prefs.setBool('isLoggedIn', true);
        prefs.setString('user', json.encode(res['data']));
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Login Successfully'),
            behavior: SnackBarBehavior.floating,
          ));
        });
        setState(() {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const WelcomePage()));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(res['message']),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } else {
      checkConnectivity;
    }
  }

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }

  void checkConnectivity(BuildContext context) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Internet Connection'),
            content: const Text('Please check your internet connection.'),
            actions: <Widget>[
              FilledButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
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

  // void showSoftKeyboard() {
  //   SystemChannels.textInput.invokeMethod('TextInput.show');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
              image: AssetImage('assets/images/maps.jpg'),
              fit: BoxFit.cover,
            )),
            child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Image(
                      image: AssetImage('assets/images/aai.png'),
                      height: 70,
                      width: 70,
                    ),
                    SizedBox(height: 60.0),
                    TextField(
                      style: TextStyle(
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
                        labelStyle: TextStyle(color: Colors.black),
                        prefixIcon: const Icon(Icons.person, size: 24),
                        prefixIconColor: Colors.black,
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 2.0),
                          borderRadius: BorderRadius.circular(70.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                          borderRadius: BorderRadius.circular(70.0),
                        ),
                        suffixIcon: _showClearIcon
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: _clearText,
                              )
                            : null,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: _passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                      obscureText: _obscured,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(90.0),
                        ),
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.black),
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
                              BorderSide(color: Colors.black, width: 2.0),
                          borderRadius: BorderRadius.circular(70.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                          borderRadius: BorderRadius.circular(70.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.0),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 222, 8, 8),
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
