import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../CustomTextField.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:io' as io;

class DoctorRegister extends StatefulWidget {
  const DoctorRegister({Key? key}) : super(key: key);

  @override
  State<DoctorRegister> createState() => _RegisterDoctor();
}

class _RegisterDoctor extends State<DoctorRegister> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController name = TextEditingController();
  final TextEditingController contact = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController professional = TextEditingController();
  final TextEditingController language = TextEditingController();
  final TextEditingController MMC = TextEditingController();
  final TextEditingController NSR = TextEditingController();
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[\W_]).{6,}$');
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  String? errorText;
  String selectedSpecialization = 'Select One Specializations';
  final List<String> specializations = [
    'Select One Specializations',
    'Cardiology',
    'Dermatology',
    'Ear, Nose, and Throat (ENT)',
    'Endocrinology',
    'Gastroenterology & Hepatology',
    'General Medicine',
    'Internal Medicine',
    'Nephrology',
    'Obstetrics & Gynaecology',
    'Orthopaedic',
  ];
  io.File? _profileImage;
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
          final bytes = reader.result as Uint8List;
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

  Future<void> _registerUser() async {
    bool isValidEmail = emailRegex.hasMatch(email.text);
    bool isValidPassword = passwordRegex.hasMatch(password.text);
    bool isDoctorEmail = email.text.trim().endsWith('@doctor.com');

    if (name.text.isEmpty ||
        contact.text.isEmpty ||
        email.text.isEmpty ||
        password.text.isEmpty ||
        professional.text.isEmpty ||
        language.text.isEmpty ||
        MMC.text.isEmpty ||
        NSR.text.isEmpty ||
        specializations.isEmpty) {
      setState(() {
        errorText = "Please fill in all fields.";
      });
      return;
    }

    if (!isDoctorEmail) {
      setState(() {
        errorText = "Only emails ending in @doctor.com are allowed.";
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
      final doctorsRef = _firestore.collection('doctors');
      final snapshot =
          await doctorsRef
              .where('doctor_id', isGreaterThanOrEqualTo: 'D')
              .get();
      final count = snapshot.size;
      final customID = 'D${count + 1}';

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('doctors').doc(customID).set({
          'doctor_id': customID,
          'name': name.text.trim(),
          'email': email.text.trim(),
          'password': hashValue(password.text),
          'contact': contact.text.trim(),
          'professional': professional.text.trim(),
          'language': language.text.trim(),
          'MMC': MMC.text.trim(),
          'NSR': NSR.text.trim(),
          'specialty': selectedSpecialization,
          'imageUrl': _imageUrl ?? '',
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registration successful!')));

        Navigator.pushReplacementNamed(
          context,
          '/doctor_home',
        );
      }
    } on FirebaseAuthException catch (e) {
      print('Error: ${e.message}');
    }

    TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
    ) {
      String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
      String formatted = '';

      for (int i = 0; i < digitsOnly.length && i < 12; i++) {
        formatted += digitsOnly[i];
        if (i == 5 || i == 7) {
          formatted += '-';
        }
      }

      int selectionIndex = formatted.length;
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: selectionIndex),
      );
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
                      Navigator.pushNamed(context, '/doctor_login');
                    },
                    icon: Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ],
              ),
            ),

            Column(
              children: [
                Text(
                  'DOCTOR',
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _profileImage != null
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
            ),

            TextButton(
              onPressed: _pickAndUploadImage,
              child: Text('Pick Profile Image'),
            ),

            SizedBox(height: 20,),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 370,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedSpecialization,
                    decoration: InputDecoration(
                      labelText: 'Specialty',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      filled: true,
                      fillColor:
                          Colors
                              .transparent,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedSpecialization = newValue!;
                      });
                    },
                    items:
                        specializations.map((String specialization) {
                          return DropdownMenuItem<String>(
                            value: specialization,
                            child: Text(specialization),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),

            SizedBox(height: 14.0),

            //Name
            CustomTextField(
              hintText: 'Name',
              valueController: name,
              onChanged: () {},
            ),

            SizedBox(height: 14.0),

            //Email
            CustomTextField(
              hintText: 'Email',
              valueController: email,
              onChanged: () {},
            ),

            SizedBox(height: 14.0),

            //Password
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 370,
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
                      ),
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
                width: 370,
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
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 14.0),

            CustomTextField(
              hintText: 'Professional Education/Qualification',
              valueController: professional,
              onChanged: () {},
            ),

            SizedBox(height: 14.0),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 370,
                height: 60,
                child: TextField(
                  controller: MMC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Malaysian Medical Council (MMC) Number',
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
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 14.0),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 370,
                height: 60,
                child: TextField(
                  controller: NSR,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'National Specialist Register (NSR) Number',
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
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 14.0),

            CustomTextField(
              hintText: 'Language',
              valueController: language,
              onChanged: () {},
            ),

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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    '/doctor_terms_condition',
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
                                    '/doctor_privacy',
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
                  _registerUser();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50),
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Crimson',
                  ),
                  backgroundColor: const Color(0xFF6B4518),
                  foregroundColor: Colors.white,
                ),
                child: Text('Register'),
              ),
            ),

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

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    String formatted = '';
    int maxLength;
    String pattern;

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

    int digitsBeforeCursor = 0;
    for (int i = 0; i < newValue.selection.end; i++) {
      if (i < newValue.text.length &&
          RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

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
