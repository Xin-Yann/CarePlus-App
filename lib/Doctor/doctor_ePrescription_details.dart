import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorePrescriptionDetails extends StatelessWidget {
  final Map<String, dynamic> session;

  const DoctorePrescriptionDetails({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final userId = session['userId'] ?? '';
    final sessionId = session['id'] ?? '';
    final sessionDate = session['date'] ?? '';
    final sessionTime = session['time'] ?? '';
    final patientName = session['userName'] ?? 'Unknown';

    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Color(0xFF6B4518)),
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/doctor_ePrescription_medList',
            arguments: {
              'session': session,
            },
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: const Color(0xFF6B4518),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${patientName.toString().toUpperCase()}'S",
                        style: const TextStyle(
                          color: Color(0xFF6B4518),
                          fontFamily: 'Crimson',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Text(
                        "E-PRESCRIPTION",
                        style: TextStyle(
                          color: Color(0xFF6B4518),
                          fontFamily: 'Crimson',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Session: $sessionId | $sessionDate @ $sessionTime',
                style: const TextStyle(color: Colors.black87),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('e-Prescription')
                    .doc(userId)
                    .collection('drugs')
                    .where('sessionId', isEqualTo: sessionId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No prescriptions found.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final prescription = docs[index].data() as Map<String, dynamic>;
                      final drugId = prescription['drugId'];
                      final symptom = prescription['symptom'];
                      final strength = prescription['strength'];

                      if (symptom == null || drugId == null || strength == null) {
                        return const Text('❌ Missing data.');
                      }

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('controlled_medicine')
                            .doc('symptoms')
                            .collection(symptom)
                            .doc(drugId)
                            .get(),
                        builder: (context, drugSnapshot) {
                          if (drugSnapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (drugSnapshot.hasError) {
                            return const Text('Error fetching drug details.');
                          }

                          if (!drugSnapshot.hasData || drugSnapshot.data!.data() == null) {
                            return const Text('Drug information not found.');
                          }

                          final data = drugSnapshot.data!.data() as Map<String, dynamic>;
                          final drugName = data['name'] ?? 'Unknown Drug';

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('controlled_medicine')
                                .doc('symptoms')
                                .collection(symptom)
                                .doc(drugId)
                                .collection('Strength')
                                .doc(strength)
                                .get(),
                            builder: (context, strengthSnapshot) {
                              if (strengthSnapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              String price = '-';
                              if (strengthSnapshot.hasData && strengthSnapshot.data!.exists) {
                                final strengthData = strengthSnapshot.data!.data() as Map<String, dynamic>;
                                price = strengthData['price']?.toString() ?? '-';
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5EFE6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      drugName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6B4518),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Strength: ${strength}'),
                                    Text('Quantity: ${prescription['quantity'] ?? '-'}'),
                                    Text('Refill: ${prescription['refill'] ?? '-'}'),
                                    Text('Sig: ${prescription['sig'] ?? '-'}'),
                                    Text('Price: RM $price'),
                                  ],
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
            ),
          ],
        ),
      ),
    );
  }
}
