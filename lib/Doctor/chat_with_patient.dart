import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'doctor_chat_message.dart';

class ChatWithPatient extends StatefulWidget {
  const ChatWithPatient({super.key});

  @override
  State<ChatWithPatient> createState() => _ChatWithPatientState();
}

class _ChatWithPatientState extends State<ChatWithPatient> {
  String? _customDoctorId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomDoctorId();
  }

  Future<void> _loadCustomDoctorId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _loading = false);
      return;
    }

    final userEmail = currentUser.email;
    final snapshot = await FirebaseFirestore.instance.collection('doctors').get();

    for (final doc in snapshot.docs) {
      if (doc.data()['email'] == userEmail) {
        setState(() {
          _customDoctorId = doc.id; // e.g., D1, D2
          _loading = false;
        });
        return;
      }
    }

    setState(() => _loading = false);
  }

  Future<Map<String, dynamic>?> getPatientDetails(String userId) async {
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE1D9D0),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_customDoctorId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFE1D9D0),
        body: Center(child: Text("Doctor ID not found")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: Column(
        children: [
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
                    color: Color(0xFF6B4518),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'CHAT WITH',
                      style: TextStyle(
                        color: Color(0xFF6B4518),
                        fontFamily: 'Crimson',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'PATIENT',
                      style: TextStyle(
                        color: Color(0xFF6B4518),
                        fontFamily: 'Crimson',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('session')
                  .where('doctorId', isEqualTo: _customDoctorId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No sessions found."));
                }

                final sessions = snapshot.data!.docs;

                // Sort sessions by date (desc), then time (desc)
                sessions.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aDateStr = aData['date'] ?? '';
                  final bDateStr = bData['date'] ?? '';
                  final aTimeStr = aData['time'] ?? '';
                  final bTimeStr = bData['time'] ?? '';

                  try {
                    final aDate = DateTime.parse(aDateStr);
                    final bDate = DateTime.parse(bDateStr);

                    if (aDate != bDate) {
                      return bDate.compareTo(aDate);
                    }

                    TimeOfDay parseStartTime(String timeRange) {
                      final start = timeRange.split(" - ").first;
                      final parts = RegExp(r'(\d+):(\d+) (\w+)').firstMatch(start);
                      if (parts != null) {
                        int hour = int.parse(parts.group(1)!);
                        final minute = int.parse(parts.group(2)!);
                        final period = parts.group(3)!;

                        if (period == 'PM' && hour != 12) hour += 12;
                        if (period == 'AM' && hour == 12) hour = 0;

                        return TimeOfDay(hour: hour, minute: minute);
                      }
                      return const TimeOfDay(hour: 0, minute: 0);
                    }

                    final aTime = parseStartTime(aTimeStr);
                    final bTime = parseStartTime(bTimeStr);

                    return (bTime.hour * 60 + bTime.minute)
                        .compareTo(aTime.hour * 60 + aTime.minute);
                  } catch (_) {
                    return 0;
                  }
                });

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final data = sessions[index].data() as Map<String, dynamic>;
                    final userId = data['userId'];
                    final sessionId = sessions[index].id;

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: getPatientDetails(userId),
                      builder: (context, snapshot) {
                        final patientData = snapshot.data;
                        final patientName = patientData?['name'] ?? 'Loading...';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: const Color(0xFFF5EFE6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B4518),
                              ),
                            ),
                            subtitle: Text(
                              "Date: ${data['date']}\nTime: ${data['time']}",
                              style: const TextStyle(color: Color(0xFF6B4518)),
                            ),
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
                          ),
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
    );
  }
}
