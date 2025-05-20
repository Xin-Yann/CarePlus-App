import 'package:careplusapp/privacy_policy.dart';
import 'package:careplusapp/terms_condition.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';
import 'package:firebase_core/firebase_core.dart';

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
      initialRoute: '/',
      routes: {
        '/login': (context) => Login(),
        '/register':(context) => Register(),
        '/terms_condition':(context)=>TermsCondition(),
        '/privacy_policy': (context)=> PrivacyPolicy()
      },
      home: Scaffold(
        backgroundColor: const Color(0xFFD7CDC3),
        body: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 35.0, left: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      // Your tap action here
                      setState(() {});
                    },
                    child: Image.asset(
                      'asset/image/weblogo.png',  // Make sure this path matches your asset folder
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 35.0, left: 200.0),
                  child: Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        print("Tapped");
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Image.asset(
                        'asset/image/user.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 35.0, left: 20.0),
                  child: Image.asset(
                    'asset/image/logout.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            Text(
              'Yours Health, Yours Way!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B4518),
                fontFamily: 'Engagement',  // Make sure your font is declared correctly in pubspec.yaml
                fontSize: 30,
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 25.0, left: 20.0),
                  child: Text(
                    'Pharmacy List',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Crimson',  // Make sure your font is declared correctly in pubspec.yaml
                      fontSize: 30,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 32.0, left: 120.0),
                  child: Text(
                    'view more',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0XFF797979),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Crimson',  // Make sure your font is declared correctly in pubspec.yaml
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
