import 'package:flutter/material.dart';

class DoctorPrivacyPolicy extends StatefulWidget {
  const DoctorPrivacyPolicy({Key? key}) : super(key: key);

  @override
  State<DoctorPrivacyPolicy> createState() => _DoctorPrivacyPolicyState();
}

class _DoctorPrivacyPolicyState extends State<DoctorPrivacyPolicy> {
  final TextEditingController num1 = TextEditingController();
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1D9D0),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/doctor_register');
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 32.0,),
          Text(
            'DOCTOR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B4518),
              fontFamily:
              'Crimson',
              fontSize: 40,
            ),
          ),

          Text(
            'PRIVACY POLICY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B4518),
              fontFamily:
              'Crimson', // Make sure your font is declared correctly in pubspec.yaml
              fontSize: 40,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              8.0,
            ).copyWith(top: 40.0, left: 40.0, right: 40.0),
            child: Text(
              '1. We collect your name, contact, email, credentials (MMC, NSR), specialty, and profile image..',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(
              8.0,
            ).copyWith(top: 20.0, left: 40.0, right: 40.0),
            child: Text(
              "2.Your data is securely stored and encrypted where necessary.",
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              8.0,
            ).copyWith(top: 20.0, left: 40.0, right: 40.0),
            child: Text(
              '3. Data is used to verify your identity, manage your profile, and connect you with users.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              8.0,
            ).copyWith(top: 20.0, left: 40.0, right: 40.0),
            child: Text(
              '4. We do not sell your personal information to third parties.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              8.0,
            ).copyWith(top: 20.0, left: 40.0, right: 40.0),
            child: Text(
              '5. Data is shared only with users (limited info), service providers, or when legally required.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(
              8.0,
            ).copyWith(top: 20.0, left: 40.0, right: 40.0),
            child: Text(
              '6. You can access, update, or request deletion of your data anytime.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
