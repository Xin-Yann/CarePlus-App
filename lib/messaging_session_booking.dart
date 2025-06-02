import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MessagingSessionBooking extends StatefulWidget {
  final String doctorId;
  final String userId;

  const MessagingSessionBooking({
    super.key,
    required this.doctorId,
    required this.userId,
  });

  @override
  State<MessagingSessionBooking> createState() => _MessagingSessionBookingState();
}

class _MessagingSessionBookingState extends State<MessagingSessionBooking> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, bool> _bookedSlots = {};

  List<String> _generateTimeSlots() {
    return List.generate(12, (index) {
      final start = TimeOfDay(hour: 10 + index, minute: 0);
      final end = TimeOfDay(hour: 11 + index, minute: 0);
      return "${start.format(context)} - ${end.format(context)}";
    });
  }

  Future<void> _fetchBookedSlots() async {
    if (_selectedDate == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final querySnapshot = await _firestore
        .collection('session')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('date', isEqualTo: formattedDate)
        .get();

    final booked = <String, bool>{};
    for (final doc in querySnapshot.docs) {
      booked[doc['time']] = true;
    }

    setState(() {
      _bookedSlots = booked;
      _isLoading = false;
    });
  }

  Future<String> _generateBookingId() async {
    final snapshot = await _firestore.collection('session').get();
    final ids = snapshot.docs
        .map((doc) => doc.id)
        .where((id) => id.startsWith('B'))
        .map((id) => int.tryParse(id.substring(1)) ?? 0)
        .toList();

    final maxId = ids.isNotEmpty ? ids.reduce((a, b) => a > b ? a : b) : 0;
    return 'B${maxId + 1}';
  }

  Future<void> _bookSession() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both date and time slot')),
      );
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    final query = await _firestore
        .collection('session')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('date', isEqualTo: formattedDate)
        .where('time', isEqualTo: _selectedTimeSlot)
        .get();

    if (query.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This time slot is already booked.')),
      );
      return;
    }

    final bookingId = await _generateBookingId();

    final sessionData = {
      'id': bookingId,
      'doctorId': widget.doctorId,
      'userId': widget.userId,
      'date': formattedDate,
      'time': _selectedTimeSlot,
    };

    try {
      await _firestore.collection('session').doc(bookingId).set(sessionData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking successful!')),
      );

      setState(() {
        _bookedSlots[_selectedTimeSlot!] = true;
        _selectedTimeSlot = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = _generateTimeSlots();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4518),
        foregroundColor: Colors.white,
        title: const Text(
          'Book Messaging Session',
          style: TextStyle(fontFamily: 'Crimson', fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFE1D9D0),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "Select Date",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B352A),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text(DateFormat('d/M/yyyy').format(today)),
                  selected: _selectedDate == today,
                  onSelected: (_) async {
                    setState(() {
                      _selectedDate = today;
                      _selectedTimeSlot = null;
                      _isLoading = true;
                    });
                    await _fetchBookedSlots();
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text(DateFormat('d/M/yyyy').format(tomorrow)),
                  selected: _selectedDate == tomorrow,
                  onSelected: (_) async {
                    setState(() {
                      _selectedDate = tomorrow;
                      _selectedTimeSlot = null;
                      _isLoading = true;
                    });
                    await _fetchBookedSlots();
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (_selectedDate != null) ...[
              const Center(
                child: Text(
                  "Select Time Slot",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B352A),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Expanded(
                child: ListView.builder(
                  itemCount: timeSlots.length,
                  itemBuilder: (context, index) {
                    final timeSlot = timeSlots[index];
                    final isBooked = _bookedSlots[timeSlot] == true;
                    bool isPastSlot = false;

                    if (_selectedDate != null) {
                      try {
                        if (timeSlot.contains(" - ")) {
                          final startTimeStr = timeSlot.split(" - ")[0];
                          final timeParts = startTimeStr.split(' ');
                          final time = timeParts[0];
                          final period = timeParts[1];

                          final hourMinute = time.split(':');
                          int hour = int.parse(hourMinute[0]);
                          final int minute = int.parse(hourMinute[1]);

                          if (period == 'PM' && hour != 12) hour += 12;
                          if (period == 'AM' && hour == 12) hour = 0;

                          final slotTime = DateTime(
                            _selectedDate!.year,
                            _selectedDate!.month,
                            _selectedDate!.day,
                            hour,
                            minute,
                          );

                          if (_selectedDate!.isAtSameMomentAs(today) &&
                              slotTime.isBefore(now)) {
                            isPastSlot = true;
                          }
                        } else {
                          isPastSlot = true;
                        }
                      } catch (_) {
                        isPastSlot = true;
                      }
                    }

                    return ListTile(
                      title: Text(timeSlot),
                      trailing: isBooked
                          ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 40),
                        ),
                        child: const Text('Booked'),
                      )
                          : isPastSlot
                          ? const Text(
                        'N/A',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedTimeSlot = timeSlot;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          _selectedTimeSlot == timeSlot
                              ? const Color(0xFF6B4518)
                              : Colors.grey[300],
                          foregroundColor:
                          _selectedTimeSlot == timeSlot
                              ? Colors.white
                              : Colors.black,
                          minimumSize: const Size(80, 40),
                        ),
                        child: Text(_selectedTimeSlot == timeSlot
                            ? 'Selected'
                            : 'Book'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _bookSession,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 60),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Crimson',
                    ),
                    backgroundColor: const Color(0XFF4B352A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Booking'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
