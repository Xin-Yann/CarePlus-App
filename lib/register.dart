import 'package:flutter/material.dart';
import 'CustomTextField.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController name = TextEditingController();
  final TextEditingController birthDate = TextEditingController();
  final TextEditingController ic = TextEditingController();
  final TextEditingController contact = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController address = TextEditingController();
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[\W_]).{6,}$');
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  String? errorText;

  String hashValue(String input) {
    return sha256.convert(utf8.encode(input.trim())).toString();
  }

  Future<void> _registerUser() async {
    bool isValidEmail = emailRegex.hasMatch(email.text);
    bool isValidPassword = passwordRegex.hasMatch(password.text);

    if (name.text.isEmpty ||
        birthDate.text.isEmpty ||
        ic.text.isEmpty ||
        contact.text.isEmpty ||
        email.text.isEmpty ||
        password.text.isEmpty ||
        address.text.isEmpty) {
      setState(() {
        errorText = "Please fill in all fields.";
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
      final usersRef = _firestore.collection('users');
      final snapshot = await usersRef.where('user_id', isGreaterThanOrEqualTo: 'U').get();
      final count = snapshot.size;
      final customID = 'U${count + 1}';

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await usersRef.doc(customID).set({
          'user_id': customID,
          'name': name.text.trim(),
          'birthDate': birthDate.text.trim(),
          'icNumber': ic.text.trim(),
          'contact': contact.text.trim(),
          'email': email.text.trim(),
          'password': hashValue(password.text),
          'address': address.text.trim(),
        });

        Navigator.pushNamed(context, '/home');
        print('User registered with ID: $customID');
      }
    } catch (e) {
      setState(() {
        errorText = "Registration failed: ${e.toString()}";
      });
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
                      Navigator.pushNamed(context, '/');
                    },
                    icon: Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'REGISTER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B4518),
                  fontFamily: 'Crimson',
                  fontSize: 50,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 370,
                height: 60,
                child: TextField(
                  controller: name,
                  decoration: InputDecoration(
                    hintText: 'Name',
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

            //Birth Date
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 370,
                height: 60,
                child: TextField(
                  controller: birthDate,
                  readOnly: true,
                  onTap: () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2090),
                    );
                    if (date != null) {
                      birthDate.text = date.toString().substring(0, 10);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Birth Date',
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
                    suffixIcon: Icon(Icons.calendar_month, color: Colors.grey),
                  ),
                ),
              ),
            ),

            //IC
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 370,
                height: 60,
                child: TextField(
                  controller: ic,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    ICInputFormat(),
                    LengthLimitingTextInputFormatter(14),
                  ],
                  decoration: InputDecoration(
                    hintText: 'NRIC/MYKAD',
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


            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 370,
                height: 60,
                child: TextField(
                  controller: email,
                  decoration: InputDecoration(
                    hintText: 'Email',
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

            //Address
            CustomTextField(
              hintText: 'Address',
              valueController: address,
              onChanged: () {},
            ),

            SizedBox(height: 25.0,),

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
                                    '/terms_condition',
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
                                    '/privacy_policy',
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
              padding: const EdgeInsets.all(8.0).copyWith(top: 25.0, bottom: 20.0),
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

class ICInputFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';

    if (digitsOnly.length > 12) {
      digitsOnly = digitsOnly.substring(0, 12);
    }

    for (int i = 0; i < digitsOnly.length && i < 12; i++) {
      formatted += digitsOnly[i];
      if (i == 5 || i == 7) {
        formatted += '-';
      }
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
        if (i == 2 || i == 5) {
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
