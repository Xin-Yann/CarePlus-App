import 'package:flutter/material.dart';
import '../CustomTextField.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorLogin extends StatefulWidget {
  const DoctorLogin({Key? key}) : super(key: key);

  @override
  State<DoctorLogin> createState() => _LoginDoctor();
}

class _LoginDoctor extends State<DoctorLogin> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[\W_]).{6,}$');
  bool _obscurePassword = true;

  String? errorText;

  Future<void> _loginDoctor() async {
    bool isValidEmail = emailRegex.hasMatch(email.text);
    bool isValidPassword = passwordRegex.hasMatch(password.text);
    bool isDoctorEmail = email.text.trim().endsWith('@doctor.com');

    if (email.text.isEmpty || password.text.isEmpty) {
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

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login successful!')));

        Navigator.pushReplacementNamed(context, '/doctor_home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          errorText = 'No user found for this email.';
        } else if (e.code == 'wrong-password') {
          errorText = 'Incorrect password.';
        } else if (e.code == 'invalid-credential') {
          errorText = 'Incorrect email or password.';
        } else {
          errorText = 'Login failed: ${e.message}';
        }
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0).copyWith(top: 70.0),
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
            SizedBox(height: 80.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'DOCTOR LOGIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B4518),
                  fontFamily: 'Crimson',
                  fontSize: 50,
                ),
              ),
            ),

            SizedBox(height: 15.0),

            CustomTextField(
              hintText: 'Email',
              valueController: email,
              onChanged: () {},
            ),

            SizedBox(height: 15.0),

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
                      borderSide: BorderSide(color: Colors.white),
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

            SizedBox(height: 15.0),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  if (email.text.isEmpty && password.text.isEmpty) {
                    setState(() {
                      errorText =
                          "Please enter your email address and password.";
                    });
                    return;
                  } else if (email.text.isEmpty) {
                    setState(() {
                      errorText = "Please enter your email address.";
                    });
                    return;
                  } else if (password.text.isEmpty) {
                    setState(() {
                      errorText = "Please enter your password.";
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

                  bool isValidPassword = passwordRegex.hasMatch(password.text);

                  if (!isValidPassword) {
                    setState(() {
                      errorText =
                          "Password must be at least 6 characters and include uppercase, lowercase, and a symbol.";
                    });
                    return;
                  }

                  setState(() {
                    errorText = null;
                  });
                  _loginDoctor();
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
                child: Text('Login'),
              ),
            ),

            SizedBox(height: 15.0),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Don't have account?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Crimson',
                      fontSize: 20,
                    ),
                  ),
                ),

                //Register
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Builder(
                    builder:
                        (context) => GestureDetector(
                          onTap: () {
                            print("Tapped");
                            Navigator.pushNamed(context, '/doctor_register');
                          },
                          child: Text(
                            'Register',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF6B4518),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Crimson',
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
      ),
    );
  }
}
