//import 'package:careplusapp/chat_with_us.dart';
import 'package:careplusapp/forgot_password.dart';
import 'package:careplusapp/privacy_policy.dart';
import 'package:careplusapp/profile.dart';
import 'package:careplusapp/terms_condition.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'register.dart';
import 'home.dart';
import 'cart.dart';
//import 'chat_user.dart';
import 'package:careplusapp/Doctor/doctor_login.dart';
import 'package:careplusapp/Doctor/doctor_register.dart';
import 'package:careplusapp/Doctor/doctor_home.dart';
//import 'package:careplusapp/Doctor/chat_patient.dart';
//import 'package:careplusapp/Doctor/chat_with_patient.dart';
import 'pharmacy_list.dart';
import 'specialist_doctor_list.dart';
import 'specialist_doctor_details.dart';
import 'package:careplusapp/Doctor/doctor_profile.dart';
import 'package:careplusapp/Doctor/doctor_privacy_policy.dart';
import 'package:careplusapp/Doctor/doctor_terms_condition.dart';
import 'package:careplusapp/Doctor/chat_patient.dart';
import 'package:careplusapp/Doctor/chat_with_patient.dart';
import 'product_category.dart';
import 'package:careplusapp/Pharmacy/pharmacy_login.dart';
import 'package:careplusapp/Pharmacy/pharmacy_register.dart';
import 'package:careplusapp/Pharmacy/pharmacy_home.dart';
import 'package:careplusapp/Pharmacy/pharmacy_profile.dart';
import 'package:careplusapp/Pharmacy/pharmacy_privacy_policy.dart';
import 'package:careplusapp/Pharmacy/pharmacy_terms_condition.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyAsFvE4JJP7mARCB1gdM3mn0gioshJK0Mg',
      appId: '1:104113039915:android:b4126445f563a92b1c186e',
      messagingSenderId: '104113039915',
      projectId: 'careplusapp-2bd07',
      storageBucket: 'careplusapp-2bd07.firebasestorage.app',
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // initialRoute: '/',
      routes: {
        '/home': (context) => Home(),
        '/login': (context) => Login(),
        '/register': (context) => Register(),
        '/terms_condition': (context) => TermsCondition(),
        '/privacy_policy': (context) => PrivacyPolicy(),
        '/forgot_password': (context) => ForgotPassword(),
        '/profile':(context) => Profile(),
        '/cart':(context) => Cart(),
        '/pharmacy_list':(context) => PharmacyList(),
        '/specialist_doctor_list':(context) => SpecialistDoctorList(),
        '/product_category':(context) => ProductCategory(),
        '/doctor_login':(context) => DoctorLogin(),
        '/doctor_register':(context) => DoctorRegister(),
        '/doctor_home':(context) => DoctorHome(),
        '/doctor_profile':(context) => DoctorProfile(),
        '/doctor_privacy':(context) => DoctorPrivacyPolicy(),
        '/doctor_terms_condition':(context) => DoctorTermsCondition(),
        '/pharmacy_login':(context) => PharmacyLogin(),
        '/pharmacy_register':(context) => PharmacyRegister(),
        '/pharmacy_home':(context) => PharmacyHome(),
        '/pharmacy_profile':(context) => PharmacyProfile(),
        '/pharmacy_privacy':(context) => PharmacyPrivacyPolicy(),
        '/pharmacy_terms_condition':(context) => PharmacyTermsCondition(),
      },
      home: Scaffold(
        backgroundColor: const Color(0xFFE1D9D0),
        body: Center(
          child: Column(
            children: [
              //Header
              SizedBox(height: 115.0),
              Padding(
                padding: const EdgeInsets.all(
                  8.0,
                ).copyWith(top: 15.0, left: 20.0),
                child: GestureDetector(
                  onTap: () {
                    // Your tap action here
                    setState(() {});
                  },
                  child: Image.asset(
                    'asset/image/weblogo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Welcome to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B4518),
                    fontFamily: 'Crimson',
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'CAREPLUS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B4518),
                    fontFamily: 'Crimson',
                    fontSize: 50,
                  ),
                ),
              ),

              //Body
              Text(
                'one-stop healthcare application',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B4518),
                  fontFamily: 'Crimson',
                  fontStyle: FontStyle.italic,
                  fontSize: 20,
                ),
              ),

              SizedBox(height: 50.0),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(300, 60),
                        textStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Crimson',
                        ),
                        backgroundColor: const Color(0XFF4B352A),
                        foregroundColor: Colors.white,
                      ),
                      child: Text('I am New Customer'),
                    );
                  }
                ),
              ),

              SizedBox(height: 25.0),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(300, 60),
                        textStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Crimson',
                        ),
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0XFF4B352A),
                        elevation: 0,
                        side: BorderSide(
                          color: Color(0XFF4B352A),
                          width: 2,
                        ),
                      ),
                      child: Text('I am Existing Customer'),
                    );
                  }
                ),
              ),

              //Admin Verification

              SizedBox(height: 85.0),

              //Doctor Portal
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0).copyWith(left: 20.0),
                    child: Builder(
                      builder: (context) {
                        return GestureDetector(
                          onTap: () {
                            print("Tap detected");
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                    "Are you a doctor at Care Plus?",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Crimson',
                                      color: const Color(0XFF4B352A),
                                    ),
                                  ),
                                  actionsAlignment: MainAxisAlignment.center,
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0XFFB5B5B5),
                                        foregroundColor: Colors.white,
                                        textStyle: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Crimson',
                                        ),
                                      ),
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            TextEditingController _codeController = TextEditingController();
                                            String? errorText;

                                            return StatefulBuilder(
                                              builder: (context, setState) {
                                                // Add listener to clear error when typing
                                                _codeController.addListener(() {
                                                  if (errorText != null) {
                                                    setState(() {
                                                      errorText = null;
                                                    });
                                                  }
                                                });

                                                return AlertDialog(
                                                  title: Text(
                                                    "Enter Security Code",
                                                    style: TextStyle(
                                                      fontFamily: 'Crimson',
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0XFF4B352A),
                                                      fontSize: 25,
                                                    ),
                                                  ),
                                                  content: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      TextField(
                                                        controller: _codeController,
                                                        decoration: InputDecoration(
                                                          hintText: "Enter code",
                                                        ),
                                                        obscureText: true,
                                                        keyboardType: TextInputType.number,
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
                                                    ],
                                                  ),
                                                  actions: [
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.of(context).pop(),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0XFFB5B5B5),
                                                        foregroundColor: Colors.white,
                                                        textStyle: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          fontFamily: 'Crimson',
                                                        ),
                                                      ),
                                                      child: Text("Cancel"),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        if (_codeController.text == "1234") {
                                                          Navigator.of(context).pop();
                                                          Navigator.pushReplacementNamed(context, '/doctor_login');
                                                        } else {
                                                          setState(() {
                                                            errorText = "Invalid security code";
                                                          });
                                                        }
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0XFF4B352A),
                                                        foregroundColor: Colors.white,
                                                        textStyle: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          fontFamily: 'Crimson',
                                                        ),
                                                      ),
                                                      child: Text("Submit"),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0XFF4B352A),
                                        foregroundColor: Colors.white,
                                        textStyle: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Crimson',
                                        ),
                                      ),
                                      child: Text("Continue"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Image.asset(
                            'asset/image/doctor.png',
                            width: 75,
                            height: 75,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0).copyWith(left: 20.0),
                    child: Builder(
                      builder: (context) {
                        return GestureDetector(
                          onTap: () {
                            print("Tap detected");
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                    "Are you a staff at Care Plus?",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Crimson',
                                      color: const Color(0XFF4B352A),
                                    ),
                                  ),
                                  actionsAlignment: MainAxisAlignment.center,
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0XFFB5B5B5),
                                        foregroundColor: Colors.white,
                                        textStyle: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Crimson',
                                        ),
                                      ),
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            TextEditingController _codeController = TextEditingController();
                                            String? errorText;

                                            return StatefulBuilder(
                                              builder: (context, setState) {
                                                // Add listener to clear error when typing
                                                _codeController.addListener(() {
                                                  if (errorText != null) {
                                                    setState(() {
                                                      errorText = null;
                                                    });
                                                  }
                                                });

                                                return AlertDialog(
                                                  title: Text(
                                                    "Enter Security Code",
                                                    style: TextStyle(
                                                      fontFamily: 'Crimson',
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0XFF4B352A),
                                                      fontSize: 25,
                                                    ),
                                                  ),
                                                  content: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      TextField(
                                                        controller: _codeController,
                                                        decoration: InputDecoration(
                                                          hintText: "Enter code",
                                                        ),
                                                        obscureText: true,
                                                        keyboardType: TextInputType.number,
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
                                                    ],
                                                  ),
                                                  actions: [
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.of(context).pop(),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0XFFB5B5B5),
                                                        foregroundColor: Colors.white,
                                                        textStyle: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          fontFamily: 'Crimson',
                                                        ),
                                                      ),
                                                      child: Text("Cancel"),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        if (_codeController.text == "1234") {
                                                          Navigator.of(context).pop();
                                                          Navigator.pushReplacementNamed(context, '/pharmacy_login');
                                                        } else {
                                                          setState(() {
                                                            errorText = "Invalid security code";
                                                          });
                                                        }
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0XFF4B352A),
                                                        foregroundColor: Colors.white,
                                                        textStyle: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          fontFamily: 'Crimson',
                                                        ),
                                                      ),
                                                      child: Text("Submit"),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0XFF4B352A),
                                        foregroundColor: Colors.white,
                                        textStyle: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Crimson',
                                        ),
                                      ),
                                      child: Text("Continue"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Image.asset(
                            'asset/image/pharmacy.png',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
