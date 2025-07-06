import 'package:flutter/material.dart';
import 'CustomTextField.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  State<ForgotPassword> createState() => _ForgotPasswordSate();
}

class _ForgotPasswordSate extends State<ForgotPassword> {
  final TextEditingController email = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String? errorText;

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _auth.sendPasswordResetEmail(email: email.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
          ),
        );
        Navigator.pushNamed(context, '/login');
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found with that email.';
        } else {
          message = 'Error: ${e.message}';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1D9D0),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          // Optional: prevent overflow
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 130.0),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'FORGOT PASSWORD',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B4518),
                      fontFamily: 'Crimson',
                      fontSize: 50,
                    ),
                  ),
                ),
                SizedBox(height: 35.0),
                CustomTextField(
                  hintText: 'Email',
                  valueController: email,
                  onChanged: () {},
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      errorText!,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(height: 35.0),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (email.text.isEmpty) {
                        setState(() {
                          errorText = "Please enter your email address.";
                        });
                        return;
                      }
                      bool isValidEmail = RegExp(
                        r'^[^@]+@[^@]+\.[^@]+',
                      ).hasMatch(email.text);
                      if (!isValidEmail) {
                        setState(() {
                          errorText = "Please enter a valid email address.";
                        });
                        return;
                      }
                      setState(() {
                        errorText = null;
                      });
                      _sendResetEmail();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 60),
                      textStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Crimson',
                      ),
                      backgroundColor: const Color(0XFF4B352A),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
