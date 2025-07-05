import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../CustomTextField.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';
import 'dart:io' as io;

class PharmacyRegister extends StatefulWidget {
  const PharmacyRegister({Key? key}) : super(key: key);

  @override
  State<PharmacyRegister> createState() => _RegisterPharmacy();
}

class _RegisterPharmacy extends State<PharmacyRegister> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController contact = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController password = TextEditingController();
  // final TextEditingController map = TextEditingController();
  // final TextEditingController socialMedia = TextEditingController();
  final TextEditingController operationHours = TextEditingController();
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[\W_]).{6,}$');
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  String? errorText;
  File? _profileImage;
  String? _imageUrl;

  final ImagePicker _picker = ImagePicker();

  String hashValue(String input) {
    return sha256.convert(utf8.encode(input.trim())).toString();
  }

  Future<void> _pickAndUploadImage() async {
    const imgbbApiKey = 'e6f550d58c3ce65d422f1483a8b92ef7';

    if (kIsWeb) {
      final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) {
        final file = uploadInput.files?.first;
        if (file == null) return;

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        reader.onLoadEnd.listen((event) async {
          final bytes = reader.result as Uint8List; // ✅ fix
          final base64Image = base64Encode(bytes);

          final response = await http.post(
            Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
            body: {'image': base64Image},
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final newImageUrl = data['data']['url'];
            setState(() {
              _imageUrl = newImageUrl;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image upload failed')),
            );
          }
        });
      });
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final imageTemp = io.File(picked.path);
      setState(() {
        _profileImage = imageTemp;
      });

      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newImageUrl = data['data']['url'];
        setState(() {
          _imageUrl = newImageUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image upload failed')));
      }
    }
  }

  Future<void> _registerPharmacy() async {
    bool isValidEmail = emailRegex.hasMatch(email.text);
    bool isValidPassword = passwordRegex.hasMatch(password.text);
    bool isDoctorEmail = email.text.trim().endsWith('@pharmacy.com');

    if (name.text.isEmpty ||
        contact.text.isEmpty ||
        email.text.isEmpty ||
        password.text.isEmpty ||
        address.text.isEmpty ||
        operationHours.text.isEmpty) {
      setState(() {
        errorText = "Please fill in all fields.";
      });
      return;
    }

    if (!isDoctorEmail) {
      setState(() {
        errorText = "Only emails ending in @pharmacy.com are allowed.";
      });
      return;
    }

    if (!isValidEmail) {
      setState(() {
        errorText = "Please enter a valid email address.";
      });
      return;
    }

    if (!isValidPassword) {
      setState(() {
        errorText =
            "Password must be at least 6 characters and include uppercase, lowercase, and a symbol.";
      });
      return;
    }

    if (!_agreeToTerms) {
      setState(() {
        errorText = "Please agree to the terms and conditions.";
      });
      return;
    }

    try {
      // Map of state to possible doc IDs
      Map<String, List<String>> stateDocIds = {
        "Perlis": ["P1", "P2", "P3"],
        "Kedah": ["P4", "P5", "P6"],
        "Penang": ["P7", "P8", "P9"],
        "Perak": ["P10", "P11", "P12"],
        "Selangor": ["P13", "P14", "P15"],
        "Negeri Sembilan": ["P16", "P17", "P18"],
        "Melaka": ["P19", "P20", "P21"],
        "Kelantan": ["P22", "P23", "P24"],
        "Terengganu": ["P25", "P26", "P27"],
        "Pahang": ["P28", "P29", "P30"],
        "Johor": ["P31", "P32", "P33"],
        "Sabah": ["P34", "P35", "P36"],
        "Sarawak": ["P37", "P38", "P39"],
      };

      // Extract the last word of the address
      String addressText = address.text.trim().toLowerCase();
      String? matchedState;
      for (String state in stateDocIds.keys) {
        if (addressText.contains(state.toLowerCase())) {
          matchedState = state;
          break;
        }
      }

      if (matchedState == null) {
        setState(() {
          errorText =
          "Could not detect a valid Malaysian state in the address.";
        });
        return;
      }

      if (matchedState == null) {
        setState(() {
          errorText =
              "Could not detect a valid Malaysian state from the address.";
        });
        return;
      }

      // Find an available docId
      String selectedDocId = '';
      for (String id in stateDocIds[matchedState]!) {
        DocumentSnapshot doc =
            await _firestore
                .collection('pharmacy')
                .doc('state')
                .collection(matchedState)
                .doc(id)
                .get();
        if (!doc.exists) {
          selectedDocId = id;
          break;
        }
      }

      if (selectedDocId.isEmpty) {
        setState(() {
          errorText = "All pharmacy IDs are used in $matchedState.";
        });
        return;
      }

      // Create user
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        await _firestore
            .collection('pharmacy')
            .doc('state')
            .collection(matchedState)
            .doc(selectedDocId)
            .set({
              'pharmacy_id': selectedDocId,
              'name': name.text.trim(),
              'email': email.text.trim(),
              'password': hashValue(password.text),
              'contact': contact.text.trim(),
              // 'map': map.text.trim(),
              // 'social_media': socialMedia.text.trim(),
              'address': address.text.trim(),
              'operation_hours': operationHours.text.trim(),
              'imageUrl': _imageUrl ?? '',
            });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pharmacy registration successful!')),
        );

        Navigator.pushReplacementNamed(context, '/pharmacy_home');
      }
    } on FirebaseAuthException catch (e) {
      print('Error: ${e.message}');
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0).copyWith(top: 60.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/pharmacy_login');
                    },
                    icon: Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ],
              ),
            ),

            Column(
              children: [
                Text(
                  'PHARMACY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B4518),
                    fontFamily: 'Crimson',
                    fontSize: 50,
                  ),
                ),
                Text(
                  'REGISTER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B4518),
                    fontFamily: 'Crimson',
                    fontSize: 50,
                  ),
                ),
              ],
            ),

            SizedBox(height: 25.0),
            _profileImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _profileImage!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            )
                : (_imageUrl != null && _imageUrl!.isNotEmpty)
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _imageUrl!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                loadingBuilder: (
                    context,
                    child,
                    loadingProgress,
                    ) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator();
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.broken_image,
                    size: 50,
                  );
                },
              ),
            )
                : CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 50),
            ),

            TextButton(
              onPressed: _pickAndUploadImage,
              child: Text('Pick Profile Image'),
            ),

            SizedBox(height: 14.0),

            //Name
            CustomTextField(
              hintText: 'Name',
              valueController: name,
              onChanged: () {},
            ),

            SizedBox(height: 14.0),

            //Password
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 382,
                height: 60,
                child: TextField(
                  controller: password,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.white,
                      ), // Border when focused
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 14.0),

            //Contact
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 382,
                height: 60,
                child: TextField(
                  controller: contact,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    ContactInputFormat(),
                    LengthLimitingTextInputFormatter(14),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Contact No',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.white,
                      ), // Border when focused
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 14.0),

            CustomTextField(
              hintText: 'Email',
              valueController: email,
              onChanged: () {},
            ),

            SizedBox(height: 14.0),

            CustomTextField(
              hintText: 'Address',
              valueController: address,
              onChanged: () {},
            ),

            SizedBox(height: 14.0),

            CustomTextField(
              hintText: 'Operation Hours',
              valueController: operationHours,
              onChanged: () {},
            ),

            SizedBox(height: 14.0),

            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Container(
            //     width: 382,
            //     height: 60,
            //     child: TextField(
            //       controller: map,
            //       decoration: InputDecoration(
            //         hintText: 'Google Maps Link',
            //         hintStyle: TextStyle(
            //           color: Colors.grey[500],
            //           fontStyle: FontStyle.italic,
            //         ),
            //         filled: true,
            //         fillColor: Colors.white,
            //         contentPadding: EdgeInsets.symmetric(
            //           horizontal: 16,
            //           vertical: 16,
            //         ),
            //         enabledBorder: OutlineInputBorder(
            //           borderRadius: BorderRadius.circular(30),
            //           borderSide: BorderSide(color: Colors.white),
            //         ),
            //         focusedBorder: OutlineInputBorder(
            //           borderRadius: BorderRadius.circular(30),
            //           borderSide: BorderSide(
            //             color: Colors.white,
            //           ), // Border when focused
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            //
            // SizedBox(height: 14.0),
            //
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Container(
            //     width: 382,
            //     height: 60,
            //     child: TextField(
            //       controller: socialMedia,
            //       keyboardType: TextInputType.number,
            //       decoration: InputDecoration(
            //         hintText: 'Social Media Page Link',
            //         hintStyle: TextStyle(
            //           color: Colors.grey[500],
            //           fontStyle: FontStyle.italic,
            //         ),
            //         filled: true,
            //         fillColor: Colors.white,
            //         contentPadding: EdgeInsets.symmetric(
            //           horizontal: 16,
            //           vertical: 16,
            //         ),
            //         enabledBorder: OutlineInputBorder(
            //           borderRadius: BorderRadius.circular(30),
            //           borderSide: BorderSide(color: Colors.white),
            //         ),
            //         focusedBorder: OutlineInputBorder(
            //           borderRadius: BorderRadius.circular(30),
            //           borderSide: BorderSide(
            //             color: Colors.white,
            //           ), // Border when focused
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            SizedBox(height: 20.0),

            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(left: 30.0),
                  child: Checkbox(
                    value: _agreeToTerms,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _agreeToTerms = newValue ?? false;
                      });
                    },
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // align left
                  children: [
                    Text(
                      'I understand and agree with the',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),

                    Row(
                      children: [
                        Builder(
                          builder:
                              (context) => GestureDetector(
                                onTap: () {
                                  print("Tapped");
                                  Navigator.pushNamed(
                                    context,
                                    '/pharmacy_terms_condition',
                                  );
                                },
                                child: Text(
                                  'Terms and Condition ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6B4518),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        ),
                        Text(
                          'and ',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        Builder(
                          builder:
                              (context) => GestureDetector(
                                onTap: () {
                                  print("Tapped");
                                  Navigator.pushNamed(
                                    context,
                                    '/pharmacy_privacy',
                                  );
                                },
                                child: Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6B4518),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                ).copyWith(left: 30.0, right: 30.0),
                child: Text(
                  errorText!,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(
                8.0,
              ).copyWith(top: 25.0, bottom: 30.0),
              child: ElevatedButton(
                onPressed: () {
                  _registerPharmacy();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50), // width: 200, height: 50
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Crimson',
                  ),
                  backgroundColor: const Color(0xFF6B4518), // Background color
                  foregroundColor: Colors.white,
                ),
                child: Text('Register'),
              ),
            ),

            // Builder(
            //   builder:
            //       (context) => GestureDetector(
            //     onTap: () {
            //       print("Tapped");
            //       Navigator.pushNamed(context, '/login');
            //     },
            //     child: Text(
            //       'Login',
            //       textAlign: TextAlign.center,
            //       style: TextStyle(
            //         color: Color(0xFF6B4518),
            //         decoration: TextDecoration.underline,
            //         fontFamily:
            //         'Crimson', // Make sure your font is declared correctly in pubspec.yaml
            //         fontSize: 20,
            //       ),
            //     ),
            //   ),

            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Builder(
            //     builder:
            //         (context) => GestureDetector(
            //           onTap: () {
            //             print("Tapped");
            //             Navigator.pushNamed(context, '/doctor_login');
            //           },
            //           child: Text(
            //             'Doctor Login',
            //             textAlign: TextAlign.center,
            //             style: TextStyle(
            //               color: Color(0xFF6B4518),
            //               decoration: TextDecoration.underline,
            //               fontFamily:
            //                   'Crimson', // Make sure your font is declared correctly in pubspec.yaml
            //               fontSize: 20,
            //             ),
            //           ),
            //         ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class ContactInputFormat extends TextInputFormatter {
  final String? forcedPattern;

  ContactInputFormat({this.forcedPattern});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Extract digits only from new input
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    String formatted = '';
    int maxLength;
    String pattern;

    // Decide which pattern to use
    if (forcedPattern != null) {
      pattern = forcedPattern!;
    } else {
      pattern = digitsOnly.length > 10 ? 'pattern2' : 'pattern1';
    }

    if (pattern == 'pattern1') {
      maxLength = 10;
      for (int i = 0; i < digitsOnly.length && i < maxLength; i++) {
        formatted += digitsOnly[i];
        if (i == 1 || i == 4) {
          if (i != maxLength - 1) formatted += '-';
        }
      }
    } else if (pattern == 'pattern2') {
      maxLength = 11;
      for (int i = 0; i < digitsOnly.length && i < maxLength; i++) {
        formatted += digitsOnly[i];
        if (i == 2 || i == 6) {
          if (i != maxLength - 1) formatted += '-';
        }
      }
    } else {
      formatted = digitsOnly;
    }

    // Count digits before the original cursor position
    int digitsBeforeCursor = 0;
    for (int i = 0; i < newValue.selection.end; i++) {
      if (i < newValue.text.length &&
          RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }
    // Map digitsBeforeCursor to the formatted string index
    int cursorPos = 0;
    int digitsCounted = 0;
    while (cursorPos < formatted.length && digitsCounted < digitsBeforeCursor) {
      if (RegExp(r'\d').hasMatch(formatted[cursorPos])) {
        digitsCounted++;
      }
      cursorPos++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPos),
    );
  }
}
