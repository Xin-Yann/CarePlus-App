import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class DoctorChatMessage extends StatefulWidget {
  final String sessionId;
  final String sessionTime;
  final String sessionDate;
  final String userId;

  const DoctorChatMessage({
    super.key,
    required this.sessionId,
    required this.sessionTime,
    required this.sessionDate,
    required this.userId,
  });

  @override
  State<DoctorChatMessage> createState() => _DoctorChatMessageState();
}

class _DoctorChatMessageState extends State<DoctorChatMessage> {
  final _messageController = TextEditingController();
  bool isActive = false;
  String? doctorId;

  @override
  void initState() {
    super.initState();
    fetchDoctorId();
    validateSession();
  }

  Future<void> fetchDoctorId() async {
    final sessionDoc = await FirebaseFirestore.instance
        .collection('session')
        .doc(widget.sessionId)
        .get();

    if (sessionDoc.exists) {
      setState(() {
        doctorId = sessionDoc.data()?['doctorId'];
      });
    }
  }

  void validateSession() {
    try {
      final now = DateTime.now();
      final sessionDate = DateFormat('yyyy-MM-dd').parse(widget.sessionDate);

      final isToday = now.year == sessionDate.year &&
          now.month == sessionDate.month &&
          now.day == sessionDate.day;

      if (!isToday) {
        setState(() => isActive = false);
        return;
      }

      final parts = widget.sessionTime.split(' - ');
      final start = DateFormat('h:mm a').parse(parts[0]);
      final end = DateFormat('h:mm a').parse(parts[1]);

      final startTime = DateTime(sessionDate.year, sessionDate.month, sessionDate.day, start.hour, start.minute);
      final endTime = DateTime(sessionDate.year, sessionDate.month, sessionDate.day, end.hour, end.minute);

      setState(() {
        isActive = now.isAfter(startTime) && now.isBefore(endTime);
      });
    } catch (e) {
      print("⚠️ Session validation failed: $e");
      setState(() => isActive = false);
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || doctorId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(doctorId)
          .collection('messages')
          .add({
        'text': text.trim(),
        'timestamp': DateTime.now(), // Immediate display
        'senderId': doctorId,
        'sessionId': widget.sessionId,
      });

      _messageController.clear();
    } catch (e) {
      print("❌ Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to send message."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Stream<List<QueryDocumentSnapshot>> getCombinedMessagesStream() {
    if (doctorId == null) return const Stream.empty();

    final userStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.userId)
        .collection('messages')
        .where('sessionId', isEqualTo: widget.sessionId)
        .snapshots();

    final doctorStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(doctorId)
        .collection('messages')
        .where('sessionId', isEqualTo: widget.sessionId)
        .snapshots();

    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<QueryDocumentSnapshot>>(
      userStream,
      doctorStream,
          (userSnap, doctorSnap) => [...userSnap.docs, ...doctorSnap.docs],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'MESSAGE',
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
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Session time: ${widget.sessionTime}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          Expanded(
            child: doctorId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: getCombinedMessagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                messages.sort((a, b) {
                  final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
                  final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
                  return aTime.compareTo(bTime);
                });

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet for this session.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == doctorId;
                    final timestamp = msg['timestamp'] as Timestamp?;
                    final msgDate = timestamp?.toDate();
                    final showDate = (index == 0 ||
                        DateFormat('yyyy-MM-dd').format(
                          (messages[index - 1]['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970),
                        ) != DateFormat('yyyy-MM-dd').format(msgDate ?? DateTime(1970)))
                        ? DateFormat('MMMM dd, yyyy').format(msgDate ?? DateTime.now())
                        : null;

                    return Column(
                      children: [
                        if (showDate != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              showDate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.grey[300] : Colors.brown[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(msg['text'] ?? ''),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: isActive,
                    decoration: InputDecoration(
                      hintText: isActive
                          ? "Type your message..."
                          : "Chat disabled until session time",
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: isActive ? () => sendMessage(_messageController.text) : null,
                  color: isActive ? Colors.brown : Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
