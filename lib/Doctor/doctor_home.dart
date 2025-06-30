import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:careplusapp/Doctor/doctor_footer.dart';
import 'package:intl/intl.dart';

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
                            Navigator.pushReplacementNamed(
                              context,
                              '/doctor_login',
                            );
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
                    'Appointment List',
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
                  ).copyWith(top: 32.0, left: 80.0),
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
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('session')
                        .orderBy('date', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No sessions found.'));
                  }

                  final sessions = snapshot.data!.docs;

                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final data = session.data() as Map<String, dynamic>;
                      final user = FirebaseAuth.instance.currentUser;

                      if (user == null) {
                        return const Center(child: Text("User not logged in"));
                      }

                      final loggedInEmail = user.email!.trim();
                      final doctorId = data['doctorId'];

                      return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        future:
                            FirebaseFirestore.instance
                                .collection('doctors')
                                .where('doctor_id', isEqualTo: doctorId)
                                .where('email', isEqualTo: loggedInEmail)
                                .limit(1)
                                .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const ListTile(
                              title: Text('Loading doctor…'),
                              subtitle: LinearProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final userId = data['userId'];

                          return FutureBuilder<
                            QuerySnapshot<Map<String, dynamic>>
                          >(
                            future:
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .where('user_id', isEqualTo: userId)
                                    .limit(1)
                                    .get(),
                            builder: (context, userSnap) {
                              if (userSnap.connectionState !=
                                  ConnectionState.done) {
                                return const ListTile(
                                  title: Text('Loading user…'),
                                  subtitle: LinearProgressIndicator(),
                                );
                              }

                              if (!userSnap.hasData ||
                                  userSnap.data!.docs.isEmpty) {
                                return const ListTile(
                                  title: Text('Patient not found'),
                                );
                              }

                              final user = userSnap.data!.docs.first.data();
                              final dateStr =
                                  data['date'] is Timestamp
                                      ? DateFormat('dd MMM yyyy').format(
                                        (data['date'] as Timestamp).toDate(),
                                      )
                                      : (data['date']?.toString() ?? 'N/A');

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0ECE7),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  title: Text(
                                    '${user['name'] ?? 'Patient'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Date: $dateStr'),
                                      Text('Time: ${data['time'] ?? ''}'),
                                    ],
                                  ),
                                  leading: const Icon(
                                    Icons.medical_information,
                                  ),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/sessionDetail',
                                      arguments: session.id,
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: const DoctorFooter(),
    );
  }
}
