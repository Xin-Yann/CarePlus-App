import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:careplusapp/Doctor/doctor_footer.dart';

class DoctorHome extends StatefulWidget {
  const DoctorHome({super.key});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void initState() {
    super.initState();
  }

  Future<void> _signOutUser() async {
    await FirebaseAuth.instance.signOut();
    // Optional: Navigate to login page
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(
                    8.0,
                  ).copyWith(top: 35.0, left: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {});
                    },
                    child: Image.asset(
                      'asset/image/weblogo.png',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(
                    8.0,
                  ).copyWith(top: 35.0, left: 200.0),
                  child: Builder(
                    builder:
                        (context) => GestureDetector(
                      onTap: () {
                        print("Tapped");
                        Navigator.pushReplacementNamed(context, '/cart');
                      },
                      child: Image.asset(
                        'asset/image/cart.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(
                    8.0,
                  ).copyWith(top: 35.0, left: 15.0),
                  child: Builder(
                    builder:
                        (context) => GestureDetector(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/doctor_login');
                        print("Doctor signed out");
                      },
                      child: Image.asset(
                        'asset/image/exit.png',
                        width: 33,
                        height: 33,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.0),

            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(
                    8.0,
                  ).copyWith(top: 25.0, left: 20.0),
                  child: Text(
                    'Pharmacy List',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Crimson',
                      fontSize: 30,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(
                    8.0,
                  ).copyWith(top: 32.0, left: 120.0),
                  child: Text(
                    'view more',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0XFF797979),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Crimson',
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0XFFF0ECE7),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DoctorFooter(),
    );
  }
}
