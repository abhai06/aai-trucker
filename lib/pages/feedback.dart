import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:drive/helper/db_helper.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drive/services/api_service.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final ApiService apiService = ApiService();
  DBHelper dbHelper = DBHelper();
  List data = [];
  String? selectedValue;
  final TextEditingController note = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final bool _isLoading = true;

  final ImagePicker _picker = ImagePicker();
  List<File>? selectedImages = [];
  var attach = [];
  @override
  void initState() {
    super.initState();
  }

  setSelectedRadioTile(val) {
    setState(() {
      selectedValue = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
            child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(height: 40.0),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('Enter your comments here.', textAlign: TextAlign.start, style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 40.0),
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      const Text('Add Attachment:', textAlign: TextAlign.start),
                      IconButton(
                          icon: SvgPicture.asset(
                            'assets/icons/gallery_thumbnail.svg',
                            width: 35.0,
                            height: 35.0,
                            color: Colors.green.shade900,
                          ),
                          onPressed: () async {
                            final image = await _picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              final directory = await getApplicationDocumentsDirectory();
                              String imagePath = image.path;
                              String filename = path.basename(imagePath);
                              final tempPath = path.join(directory.path, filename);
                              final imageFile = File(image.path);
                              await imageFile.copy(tempPath);
                              String imageExtension = path.extension(tempPath).replaceAll('.', '');
                              final bytes = await imageFile.readAsBytes();
                              final base64Image = base64Encode(bytes);
                              String mimeType = 'application/$imageExtension';
                              var base64 = 'data:$mimeType;base64,$base64Image';
                              setState(() {
                                selectedImages!.add(File(imagePath));
                                attach.add(base64);
                              });
                            }
                          }),
                      IconButton(
                          onPressed: () async {
                            final image = await _picker.pickImage(source: ImageSource.camera);
                            if (image != null) {
                              final directory = await getApplicationDocumentsDirectory();
                              var imagePath = File(image.path);
                              String filename = path.basename(image.path);
                              final tempPath = path.join(directory.path, filename);
                              await imagePath.copy(tempPath);
                              String imageExtension = path.extension(tempPath).replaceAll('.', '');
                              final bytes = await imagePath.readAsBytes();
                              final base64Image = base64Encode(bytes);
                              String mimeType = 'application/$imageExtension';
                              var base64 = 'data:$mimeType;base64,$base64Image';
                              setState(() {
                                selectedImages!.add(imagePath);
                                attach.add(base64);
                              });
                            }
                          },
                          icon: Icon(Icons.camera_alt, color: Colors.red.shade900),
                          iconSize: 28.0),
                    ]),
                    selectedImages!.isNotEmpty
                        ? SizedBox(
                            height: 100,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemCount: selectedImages!.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Image.file(selectedImages![index], fit: BoxFit.cover, width: 300, height: 300, alignment: Alignment.center),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Checkbox(
                                        value: true,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == false) {
                                              selectedImages!.removeAt(index);
                                              attach.removeAt(index);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          )
                        : const Align(
                            alignment: Alignment.center,
                            child: Text(
                              '',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            )),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      validator: customValidator,
                      controller: note,
                      decoration: const InputDecoration(labelText: 'Enter comments', border: OutlineInputBorder(), hintText: 'Enter comments'),
                    ),
                    const SizedBox(height: 20.0),
                    ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 222, 8, 8),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            )),
                        label: const Text('SUBMIT'),
                        icon: const Icon(Icons.save),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final remarks = {
                              'remarks': note.text,
                              'attachment': attach
                            };
                            await apiService.post(remarks, 'feedback').then((response) {
                              if (response['success'] == true) {
                                setState(() {
                                  note.clear();
                                  attach.clear();
                                  selectedImages!.clear();
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    backgroundColor: Colors.green,
                                    content: Text('Remarks sent successfully'),
                                    behavior: SnackBarBehavior.fixed,
                                  ));
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text('Remarks not sent.'),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            });
                          }
                        }),
                  ]),
                ))));
  }

  String? customValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field cannot be empty.';
    }
    return null;
  }
}
