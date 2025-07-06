import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorePrescriptionPatient extends StatefulWidget {
  const DoctorePrescriptionPatient({super.key});

  @override
  State<DoctorePrescriptionPatient> createState() =>
      _DoctorePrescriptionPatientState();
}

class _DoctorePrescriptionPatientState
    extends State<DoctorePrescriptionPatient> {
  List<Map<String, dynamic>> sessions = [];
  String? doctorId;

  @override
  void initState() {
    super.initState();
    fetchDoctorIdAndSessions();
  }

  Future<void> fetchDoctorIdAndSessions() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doctorSnapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('email', isEqualTo: currentUser.email)
        .limit(1)
        .get();

    if (doctorSnapshot.docs.isEmpty) return;

    final fetchedDoctorId = doctorSnapshot.docs.first.id;
    setState(() {
      doctorId = fetchedDoctorId;
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('session')
        .where('doctorId', isEqualTo: fetchedDoctorId)
        .get();

    final sessionList = await Future.wait(snapshot.docs.map((doc) async {
      final sessionData = doc.data();
      final userId = sessionData['userId'];

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userName = userDoc.exists && userDoc.data() != null
          ? userDoc.data()!['name'] ?? 'Unknown'
          : 'Unknown';

      return {
        ...sessionData,
        'id': doc.id,
        'userId': userId,
        'userName': userName,
      };
    }).toList());

    sessionList.sort((a, b) {
      final dateA = a['date'] ?? '';
      final dateB = b['date'] ?? '';
      final timeA = a['time'] ?? '';
      final timeB = b['time'] ?? '';

      final dateCompare = dateB.compareTo(dateA);
      if (dateCompare != 0) return dateCompare;

      return timeB.compareTo(timeA);
    });

    setState(() {
      sessions = sessionList;
    });
  }

  Future<void> checkPrescriptionAndNavigate(Map<String, dynamic> session) async {
    final sessionId = session['id'];
    final currentDoctorId = doctorId;
    final userId = session['userId'];

    if (currentDoctorId == null || userId == null) return;

    final query = await FirebaseFirestore.instance
        .collection('e-Prescription')
        .doc(userId)
        .collection('drugs')
        .where('sessionId', isEqualTo: sessionId)
        .where('doctorId', isEqualTo: currentDoctorId)
        .get();

    if (query.docs.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/doctor_ePrescription_details',
        arguments: session,
      );
    } else {
      Navigator.pushNamed(
        context,
        '/doctor_ePrescription_medList',
        arguments: {
          'session': session,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () =>  Navigator.pushNamed(context, '/doctor_home'),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Color(0xFF6B4518),
                  ),
                ),
                const Text(
                  'MY PATIENT',
                  style: TextStyle(
                    color: Color(0xFF6B4518),
                    fontFamily: 'Crimson',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: sessions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: const Color(0xFFF5EFE6),
                  child: ListTile(
                    title: Text(
                      session['userName'],
                      style:
                      const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${session['date'] ?? '-'}'),
                        Text('Time: ${session['time'] ?? '-'}'),
                      ],
                    ),
                    onTap: () => checkPrescriptionAndNavigate(session),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
