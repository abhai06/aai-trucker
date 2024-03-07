import 'dart:convert';

import 'package:drive/pages/my_task.dart';
import 'package:flutter/material.dart';
import 'package:drive/helper/db_helper.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drive/services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService apiService = ApiService();
  DBHelper dbHelper = DBHelper();
  List data = [];
  String? selectedValue;
  final TextEditingController oldPassword = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final bool _isLoading = true;
  bool isSaving = false;

  final ImagePicker _picker = ImagePicker();
  FocusNode textFieldFocusNode = FocusNode();
  FocusNode textFieldFocusNode1 = FocusNode();
  bool _obscured = true;
  bool _obscured1 = true;
  bool _showClearIcon = false;

  List<File>? selectedImages = [];
  var attach = [];
  @override
  void initState() {
    super.initState();
  }

  void dispose() {
    super.dispose();
  }

  setSelectedRadioTile(val) {
    setState(() {
      selectedValue = val;
    });
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

  void _toggleObscured1() {
    setState(() {
      _obscured1 = !_obscured1;
      if (textFieldFocusNode1.hasPrimaryFocus) {
        return;
      }
      textFieldFocusNode1.canRequestFocus = false;
    });
  }

  void _clearText() {
    setState(() {
      oldPassword.clear();
      _showClearIcon = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
            child: Container(
                child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                        const SizedBox(height: 40.0),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('Change Password', textAlign: TextAlign.start, style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 40.0),
                        TextFormField(
                          validator: customValidator,
                          controller: oldPassword,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                            labelText: 'Current Password',
                            border: const OutlineInputBorder(),
                            hintText: 'Current Password',
                            suffixIcon: _showClearIcon ? IconButton(icon: const Icon(Icons.clear, color: Colors.red), onPressed: _clearText) : null,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          controller: newPassword,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: _obscured,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            } else if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                            labelText: 'New Password',
                            border: const OutlineInputBorder(),
                            hintText: 'Enter New Password',
                            suffixIcon: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                              child: GestureDetector(
                                onTap: _toggleObscured,
                                child: Icon(_obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 24, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        TextFormField(
                          controller: confirmPassword,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: _obscured1,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            } else if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18.0),
                            labelText: 'Confirm Password',
                            border: const OutlineInputBorder(),
                            hintText: 'Confirm Password',
                            suffixIcon: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                              child: GestureDetector(
                                onTap: _toggleObscured1,
                                child: Icon(_obscured1 ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 24, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 222, 8, 8),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                )),
                            label: const Text('SAVE'),
                            icon: const Icon(Icons.save),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() {
                                        isSaving = true;
                                      });
                                      final password = {
                                        'old_password': oldPassword.text,
                                        'password': newPassword.text,
                                        'password_confirmation': confirmPassword.text
                                      };
                                      try {
                                        await apiService.post(password, 'change-password').then((response) {
                                          if (response['success'] == true) {
                                            setState(() {
                                              isSaving = false;
                                              oldPassword.clear();
                                              newPassword.clear();
                                              confirmPassword.clear();
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                                backgroundColor: Colors.green,
                                                content: Text('Password change successfully'),
                                                behavior: SnackBarBehavior.fixed,
                                              ));
                                            });
                                          } else {
                                            setState(() {
                                              isSaving = false;
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                backgroundColor: Colors.red,
                                                content: Text((response['message']!)),
                                                behavior: SnackBarBehavior.floating,
                                              ));
                                            });
                                          }
                                        });
                                      } catch (e) {
                                        isSaving = false;
                                        print(e);
                                      }
                                    }
                                  }),
                      ]),
                    )))));
  }

  String? customValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }
}
