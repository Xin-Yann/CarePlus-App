import 'package:flutter/material.dart';
import 'CustomTextField.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  //final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _loginUser() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // // Optionally update last login info in Firestore
        // await _firestore.collection('users').doc(user.uid).set({
        //   'lastLogin': FieldValue.serverTimestamp(),
        // }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful!')),
        );

        Navigator.pushReplacementNamed(context, '/');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No user found for this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else {
        message = 'Login failed: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1BFA9),
      appBar: AppBar(backgroundColor: const Color(0xFFC1BFA9)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top: 150.0),
            child: Text(
              'LOGIN',
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

          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top: 30.0),
            child: ElevatedButton(
              onPressed: () {
                _loginUser();
                setState(() {});// Handle login button tap
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
              child: Text('Login'),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Don't have account?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B4518),
                    fontFamily:
                        'Crimson', // Make sure your font is declared correctly in pubspec.yaml
                    fontSize: 20,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Builder(
                  builder:
                      (context) => GestureDetector(
                        onTap: () {
                          print("Tapped");
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'Register',
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
        ],
      ),
    );
  }
}
