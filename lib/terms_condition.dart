import 'package:flutter/material.dart';

class TermsCondition extends StatefulWidget {
  const TermsCondition({Key? key}) : super(key: key);

  @override
  State<TermsCondition> createState() => _LoginState();
}

class _LoginState extends State<TermsCondition> {
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
              'TERMS & CONDITION',
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
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0, left: 40.0, right: 40.0),
            child: Text(
              '1. HealthConnect enables users to schedule appointments with pharmacy through the app.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0, left: 40.0, right: 40.0),
            child: Text(
              "2. Users are responsible for providing accurate and up-to-date information during the booking process, and any discrepancies are the user's responsibility.",
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0,left: 40.0, right: 40.0),
            child: Text(
              '3. HealthConnect is not responsible for delays caused by unforeseen circumstances or issues with third-party shipping providers.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0,left: 40.0, right: 40.0),
            child: Text(
              '4. Users should report any damage or loss of items during the delivery process promptly.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0,left: 40.0, right: 40.0),
            child: Text(
              '5. HealthConnect will work with users to address and resolve such issues within the bounds of its policies.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0,left: 40.0, right: 40.0),
            child: Text(
              '6. Users are responsible for contacting the pharmacy directly to initiate and process refund requests for pharmacy-related purchases.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0).copyWith(top:20.0,left: 40.0, right: 40.0),
            child: Text(
              '7. Refunds are typically processed using the same payment method used for the original transaction.',
              style: TextStyle(fontSize: 16, color: Colors.black),
              softWrap: true,
            ),
          ),

        ],
      ),
    );
  }
}
