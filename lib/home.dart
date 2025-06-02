import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'footer.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> states = ['Kedah']; // Add more if needed
  Map<String, List<Map<String, dynamic>>> pharmacyData = {};
  List<Map<String, dynamic>> doctorData = [];

  @override
  void initState() {
    super.initState();
    fetchPharmacyData();
    fetchDoctorData();
  }

  Future<void> _signOutUser() async {
    await FirebaseAuth.instance.signOut();
    // Optional: Navigate to login page
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> fetchPharmacyData() async {
    Map<String, List<Map<String, dynamic>>> tempData = {};

    for (String state in states) {
      final querySnapshot =
          await _firestore
              .collection('pharmacy')
              .doc('state')
              .collection(state)
              .limit(3)
              .get();

      print('Fetched ${querySnapshot.docs.length} documents for $state');

      tempData[state] = querySnapshot.docs.map((doc) => doc.data()).toList();
    }

    setState(() {
      pharmacyData = tempData;
    });
  }

  Future<void> fetchDoctorData() async {
    try {
      final querySnapshot = await _firestore.collection('doctors').get();

      setState(() {
        doctorData = querySnapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error fetching doctor data: $e');
    }
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
                            Navigator.pushReplacementNamed(context, '/');
                            print("User signed out");
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
            Text(
              'Yours Health, Yours Way!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B4518),
                fontFamily: 'Engagement',
                fontSize: 30,
              ),
            ),

            SizedBox(height: 10.0),

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
                  padding: const EdgeInsets.all(8.0).copyWith(top: 32.0, left: 120.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/pharmacy_list');
                    },
                    child: Text(
                      'view more',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0XFF797979),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Crimson',
                        fontSize: 20,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(
                    8.0,
                  ).copyWith(top: 25.0, left: 20.0),
                  child: Text(
                    'Doctor List',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Crimson',
                      fontSize: 30,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 32.0, left: 120.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/specialist_doctor_list');
                    },
                    child: Text(
                      'view more',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0XFF797979),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Crimson',
                        fontSize: 20,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ).copyWith(top: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    pharmacyData.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Height for horizontal scroll area
                          Column(
                            children:
                                entry.value.map((data) {
                                  return Container(
                                    padding: const EdgeInsets.all(16.0),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ).copyWith(top: 10.0),
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
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (data['image'] != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              data['image'],
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        SizedBox(
                                          width: 12,
                                        ), // spacing between image and text
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['name'] ??
                                                    'Unnamed Pharmacy',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                data['address'] ??
                                                    'No address available',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(
                    8.0,
                  ).copyWith(top: 25.0, left: 20.0),
                  child: Text(
                    'Doctor List',
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
                  ).copyWith(top: 32.0, left: 125.0),
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                children:
                    doctorData.map((doctor) {
                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: Image(
                                image: doctor['imageUrl'] != null
                                    ? NetworkImage(doctor['imageUrl'])
                                    : const AssetImage('assets/default_avatar.png') as ImageProvider,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter, // useful to center faces
                              ),
                            ),

                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor['name'] ?? 'Unnamed Doctor',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    doctor['specialty'] ??
                                        'Specialty not available',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }
}
