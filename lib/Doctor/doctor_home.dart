import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:careplusapp/Doctor/doctor_footer.dart';
import 'package:intl/intl.dart';

import 'doctor_chat_message.dart';

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
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final isoDate = DateFormat('yyyy-MM-dd').format(startOfToday);
    final loggedInEmail = FirebaseAuth.instance.currentUser?.email;

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance
              .collection('doctors')
              .where('email', isEqualTo: loggedInEmail)
              .limit(1)
              .get(),
      builder: (context, doctorSnap) {
        if (doctorSnap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!doctorSnap.hasData || doctorSnap.data!.docs.isEmpty) {
          return const Center(child: Text('Doctor record not found.'));
        }

        final doctorData = doctorSnap.data!.docs.first.data();
        final doctorId = doctorData['doctor_id'];
        final doctorName = doctorData['name'] ?? 'Doctor';

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
                      ).copyWith(top: 35.0, left: 255.0),
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

                Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 10.0, bottom: 10.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Welcome, $doctorName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Crimson',
                      ),
                    ),
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
                      padding: const EdgeInsets.all(8.0).copyWith(top: 32.0, left: 70.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/chat_with_patient');
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
                SizedBox(height: 20),

                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('session')
                          .where(
                            'date',
                            isGreaterThanOrEqualTo: isoDate,
                          )
                          .orderBy('date')
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
                        final sessionId = session.id;


                        if (user == null) {
                          return const Center(
                            child: Text("User not logged in"),
                          );
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
                                (() {
                                  final rawDate = data['date'];
                                  if (rawDate is Timestamp) {
                                    return DateFormat(
                                      'dd MMM yyyy (EEEE)',
                                    ).format(rawDate.toDate());
                                  } else if (rawDate is String) {
                                    try {
                                      final parsedDate = DateTime.parse(
                                        rawDate,
                                      );
                                      return DateFormat(
                                        'dd MMM yyyy (EEEE)',
                                      ).format(parsedDate);
                                    } catch (e) {
                                      return rawDate;
                                    }
                                  } else {
                                    return 'N/A';
                                  }
                                })();

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DoctorChatMessage(
                                      sessionId: sessionId,
                                      sessionDate: data['date'],
                                      sessionTime: data['time'],
                                      userId: userId,
                                    ),
                                  ),
                                );
                              },
                                child: Container(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Date: $dateStr'),
                                    Text('Time: ${data['time'] ?? ''}'),
                                  ],
                                ),
                                leading: const Icon(Icons.medical_information),
                              ),
                                ),
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
      },
    );
  }
}
