import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_message.dart';

class ChatWithDoctor extends StatefulWidget {
  const ChatWithDoctor({super.key});

  @override
  State<ChatWithDoctor> createState() => _ChatWithDoctorState();
}

class _ChatWithDoctorState extends State<ChatWithDoctor> {
  String? _customUserId;
  bool _loadingUserId = true;

  @override
  void initState() {
    super.initState();
    _loadCustomUserId();
  }

  Future<void> _loadCustomUserId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userEmail = currentUser.email;
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      if (data['email'] == userEmail) {
        setState(() {
          _customUserId = doc.id;
          _loadingUserId = false;
        });
        return;
      }
    }

    setState(() => _loadingUserId = false);
  }

  Future<Map<String, dynamic>?> getDoctorDetails(String doctorId) async {
    final doc = await FirebaseFirestore.instance.collection('doctors').doc(doctorId).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUserId) {
      return const Scaffold(
        backgroundColor: Color(0xFFE1D9D0),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_customUserId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFE1D9D0),
        body: Center(child: Text("User ID not found")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: Column(
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
                    color: Color(0xFF6B4518),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('CHAT WITH',
                        style: TextStyle(
                            color: Color(0xFF6B4518),
                            fontFamily: 'Crimson',
                            fontSize: 36,
                            fontWeight: FontWeight.bold)),
                    Text('DOCTOR',
                        style: TextStyle(
                            color: Color(0xFF6B4518),
                            fontFamily: 'Crimson',
                            fontSize: 36,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          // Session List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('session')
                  .where('userId', isEqualTo: _customUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No sessions found."));
                }

                final sessions = snapshot.data!.docs;

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

                    if (aDate != bDate) return bDate.compareTo(aDate);

                    TimeOfDay parseTime(String timeRange) {
                      final start = timeRange.split(' - ').first.trim();
                      final match = RegExp(r'(\d+):(\d+)\s?(AM|PM)', caseSensitive: false).firstMatch(start);
                      if (match != null) {
                        int hour = int.parse(match.group(1)!);
                        int minute = int.parse(match.group(2)!);
                        final period = match.group(3)!.toUpperCase();
                        if (period == 'PM' && hour != 12) hour += 12;
                        if (period == 'AM' && hour == 12) hour = 0;
                        return TimeOfDay(hour: hour, minute: minute);
                      }
                      return const TimeOfDay(hour: 0, minute: 0);
                    }

                    final aTime = parseTime(aTimeStr);
                    final bTime = parseTime(bTimeStr);
                    return (bTime.hour * 60 + bTime.minute)
                        .compareTo(aTime.hour * 60 + aTime.minute);
                  } catch (_) {
                    return 0;
                  }
                });

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final doc = sessions[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final sessionId = doc.id;
                    final doctorId = data['doctorId'];
                    final sessionDate = data['date'];
                    final sessionTime = data['time'];

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: getDoctorDetails(doctorId),
                      builder: (context, snapshot) {
                        final doctor = snapshot.data;
                        final doctorName = doctor?['name'] ?? 'Loading...';
                        final specialty = doctor?['specialty'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: const Color(0xFFF5EFE6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doctorName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF6B4518))),
                                Text("Specialty: $specialty", style: const TextStyle(color: Colors.black)),
                                const SizedBox(height: 4),
                                Text("Date: ${data['date']}"),
                                Text("Time: ${data['time']}"),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF6B4518),
                                        side: const BorderSide(color: Color(0xFF6B4518)),
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/e-Prescription',
                                          arguments: {
                                            'userId': _customUserId!,
                                            'sessionId': sessionId,
                                            'sessionDate': sessionDate,
                                            'sessionTime': sessionTime,
                                          },
                                        );
                                      },
                                      child: const Text("View e-Prescription"),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6B4518),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatMessage(
                                              sessionId: sessionId,
                                              sessionDate: data['date'],
                                              sessionTime: data['time'],
                                              userId: _customUserId!,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text("Chat"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
