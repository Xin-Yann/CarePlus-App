import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'footer.dart';
import 'order_history.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> states = ['Kedah'];
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
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> fetchPharmacyData() async {
    Map<String, List<Map<String, dynamic>>> tempData = {};

    for (String state in states) {
      final querySnapshot = await _firestore
          .collection('pharmacy')
          .doc('state')
          .collection(state)
          .limit(3)
          .get();

      tempData[state] = querySnapshot.docs.map((doc) => doc.data()).toList();
    }

    setState(() {
      pharmacyData = tempData;
    });
  }

  Future<void> fetchDoctorData() async {
    try {
      final querySnapshot =
      await _firestore.collection('doctors').limit(3).get();

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
                  padding: const EdgeInsets.all(8.0).copyWith(top: 35.0, left: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => OrderHistory()));
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
                  padding: const EdgeInsets.all(8.0).copyWith(top: 35.0, left: 200.0),
                  child: GestureDetector(
                    onTap: () {
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
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 35.0, left: 15.0),
                  child: GestureDetector(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: Image.asset(
                      'asset/image/exit.png',
                      width: 33,
                      height: 33,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Yours Health, Yours Way!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B4518),
                fontFamily: 'Engagement',
                fontSize: 30,
              ),
            ),

            const SizedBox(height: 10.0),

            // ------------------------ Pharmacy List ------------------------
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 25.0, left: 20.0),
                  child: const Text(
                    'Pharmacy List',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Crimson',
                      fontSize: 30,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 32.0, left: 100.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/pharmacy_list');
                    },
                    child: const Text(
                      'view more',
                      style: TextStyle(
                        color: Color(0XFF797979),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(top: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: pharmacyData.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entry.value.map((data) {
                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(top: 10.0),
                        decoration: BoxDecoration(
                          color: const Color(0XFFF0ECE7),
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                data['imageUrl'] ?? '',
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 60),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Unnamed Pharmacy',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['address'] ?? 'No address available',
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
                  );
                }).toList(),
              ),
            ),

            // ------------------------ Doctor List ------------------------
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 25.0, left: 20.0),
                  child: const Text(
                    'Doctor List',
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
                    child: const Text(
                      'view more',
                      style: TextStyle(
                        color: Color(0XFF797979),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: doctorData.map((doctor) {
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(top: 15.0),
                    decoration: BoxDecoration(
                      color: const Color(0XFFF0ECE7),
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image(
                            image: doctor['imageUrl'] != null
                                ? NetworkImage(doctor['imageUrl'])
                                : const AssetImage('assets/default_avatar.png') as ImageProvider,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                              const SizedBox(height: 4),
                              Text(
                                doctor['specialty'] ?? 'Specialty not available',
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

            const SizedBox(height: 20.0),
          ],
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }
}
