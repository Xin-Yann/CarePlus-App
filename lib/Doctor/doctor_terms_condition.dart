import 'package:flutter/material.dart';

class DoctorTermsCondition extends StatefulWidget {
  const DoctorTermsCondition({Key? key}) : super(key: key);

  @override
  State<DoctorTermsCondition> createState() => _DoctorTermsConditionState();
}

class _DoctorTermsConditionState extends State<DoctorTermsCondition> {
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
          SizedBox(height: 55.0,),
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
            'TERMS & CONDITION',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B4518),
              fontFamily:
              'Crimson',
              fontSize: 40,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:40.0, left: 40.0, right: 40.0),
            child: Text(
              '1. Only licensed medical professionals can register and use this portal.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0, left: 40.0, right: 40.0),
            child: Text(
              "2. You must provide truthful and complete professional details.",
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0,left: 40.0, right: 40.0),
            child: Text(
              '3. You’re responsible for keeping your login credentials secure.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0,left: 40.0, right: 40.0),
            child: Text(
              '4. You must follow ethical and legal standards when interacting with users.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0,left: 40.0, right: 40.0),
            child: Text(
              '5. Misleading advice, impersonation, or abuse will lead to account suspension.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0,left: 40.0, right: 40.0),
            child: Text(
              '6. Terms may change, and continued use means you accept the latest version.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
