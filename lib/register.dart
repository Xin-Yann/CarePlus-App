import 'package:flutter/material.dart';
import 'CustomTextField.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  bool _agreeToTerms = false;

  Future<void> _registerUser() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please agree to the terms and conditions.')),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name.text.trim(),
          'birthDate': birthDate.text.trim(),
          'icNumber': ic.text.trim(),
          'contact': contact.text.trim(),
          'email': email.text.trim(),
          'address': address.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registration successful!')));

        Navigator.pushReplacementNamed(context, '/'); // Go to home screen
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1BFA9),
      appBar: AppBar(backgroundColor: const Color(0xFFC1BFA9)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'REGISTER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B4518),
                fontFamily:
                    'Crimson', // Make sure your font is declared correctly in pubspec.yaml
                fontSize: 50,
              ),
            ),
          ),

          CustomTextField(
            hintText: 'Name',
            valueController: name,
            onChanged: () {},
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 382,
              height: 60,
              child: TextField(
                controller: birthDate,
                readOnly: true, // Prevents keyboard from showing
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
                  suffixIcon: Icon(Icons.calendar_month, color: Colors.grey),
                ),
              ),
            ),
          ),

          CustomTextField(
            hintText: 'Identity Card Number (last 4 digit)',
            valueController: ic,
            onChanged: () {},
          ),

          CustomTextField(
            hintText: 'Contact',
            valueController: contact,
            onChanged: () {},
          ),

          CustomTextField(
            hintText: 'Email',
            valueController: email,
            onChanged: () {},
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 382,
              height: 60,
              child: TextField(
                controller: password,
                obscureText: true,
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
                ),
              ),
            ),
          ),

          CustomTextField(
            hintText: 'Address',
            valueController: address,
            onChanged: () {},
          ),

          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Container(
          //     width: 380,
          //     height: 60,
          //     child: TextField(
          //       decoration: InputDecoration(
          //         hintText: 'Address',
          //         hintStyle: TextStyle(
          //           color: Colors.grey[500],
          //           fontStyle: FontStyle.italic,
          //         ),
          //         filled: true,
          //         fillColor: Colors.white,
          //         contentPadding: EdgeInsets.symmetric(
          //           horizontal: 16,
          //           vertical: 16,
          //         ), // Padding
          //         enabledBorder: OutlineInputBorder(
          //           borderRadius: BorderRadius.circular(30),
          //         ),
          //         focusedBorder: OutlineInputBorder(
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
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
                                  '/terms_condition',
                                );
                              },
                              child: Text(
                                'Terms and Condition ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B4518),
                                  decoration:
                                      TextDecoration
                                          .underline, // optional underline
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
                                Navigator.pushNamed(context, '/privacy_policy');
                              },
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B4518),
                                  decoration:
                                      TextDecoration
                                          .underline, // optional underline
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
          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top: 19.0),
            child: ElevatedButton(
              onPressed: () {
                _registerUser();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 60), // width: 200, height: 50
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Crimson',
                ),
                backgroundColor: const Color(0XFFA8A692), // Background color
                foregroundColor: Colors.white,
              ),
              child: Text('Register'),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Builder(
              builder:
                  (context) => GestureDetector(
                    onTap: () {
                      print("Tapped");
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      'Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B4518),
                        decoration: TextDecoration.underline,
                        fontFamily:
                            'Crimson', // Make sure your font is declared correctly in pubspec.yaml
                        fontSize: 20,
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
