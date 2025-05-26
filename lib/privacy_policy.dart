import 'package:flutter/material.dart';

class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicy> createState() => _LoginState();
}

class _LoginState extends State<PrivacyPolicy> {
  final TextEditingController num1 = TextEditingController();
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1D9D0),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/register');
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top: 25.0),
            child: Text(
              'PRIVACY POLICY',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B4518),
                fontFamily:
                    'Crimson', // Make sure your font is declared correctly in pubspec.yaml
                fontSize: 40,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              8.0,
            ).copyWith(top: 20.0, left: 40.0, right: 40.0),
            child: Text(
              '1. Payment details are securely handled by a third-party payment gateway, and sensitive information is not stored within the app.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(
              8.0,
            ).copyWith(top: 20.0, left: 40.0, right: 40.0),
            child: Text(
              "2.To fulfill shipping services, HealthConnect may share users' shipping information with third-party shipping providers.",
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              8.0,
            ).copyWith(top: 20.0, left: 40.0, right: 40.0),
            child: Text(
              '3. Chat conversations within the app are secured with end-to-end encryption to protect against unauthorized access.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              8.0,
            ).copyWith(top: 20.0, left: 40.0, right: 40.0),
            child: Text(
              '4. Users have the right to access, modify, or delete their personal information.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              8.0,
            ).copyWith(top: 20.0, left: 40.0, right: 40.0),
            child: Text(
              '5. HealthConnect may request access to device location for features such as locating nearby pharmacy. Users can control location-sharing preferences in the app settings.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              8.0,
            ).copyWith(top: 20.0, left: 40.0, right: 40.0),
            child: Text(
              '6. Users acknowledge that third-party shipping providers have their own terms and conditions, and HealthConnect is not responsible for the practices of these third parties.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
