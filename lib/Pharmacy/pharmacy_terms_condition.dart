import 'package:flutter/material.dart';

class PharmacyTermsCondition extends StatefulWidget {
  const PharmacyTermsCondition({Key? key}) : super(key: key);

  @override
  State<PharmacyTermsCondition> createState() => _PharmacyTermsConditionState();
}

class _PharmacyTermsConditionState extends State<PharmacyTermsCondition> {
  final TextEditingController num1 = TextEditingController();
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1D9D0),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/pharmacy_register');
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 55.0,),
          Text(
            'PHARMACY',
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
              '1.Portal use is limited to approved admin and pharmacy staff.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0, left: 40.0, right: 40.0),
            child: Text(
              "2. Do not share login details; each user must have a unique account.",
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0,left: 40.0, right: 40.0),
            child: Text(
              '3. All information must be true, updated, and legally compliant.',
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
