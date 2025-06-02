import 'package:flutter/material.dart';
import 'messaging_session_booking.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpecialistDoctorDetails extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const SpecialistDoctorDetails({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final imageUrl = doctor['imageUrl']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4518),
        foregroundColor: Colors.white,
        title: const Text(
          "Doctor Details",
          style: TextStyle(
            fontFamily: 'Crimson',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : const NetworkImage('https://via.placeholder.com/150'),
                    onBackgroundImageError: (exception, stackTrace) {
                      debugPrint('Error loading image: $exception');
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailTile("Name", doctor['name']),
                _buildDetailTile("Email", doctor['email']),
                _buildDetailTile("Contact", doctor['contact']),
                _buildDetailTile("Specialty", doctor['specialty']),
                _buildDetailTile("Professional", doctor['professional']),
                _buildDetailTile("MMC", doctor['MMC']),
                _buildDetailTile("NSR", doctor['NSR']),
                _buildDetailTile("Language", doctor['language']),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You must be logged in')),
                  );
                  return;
                }

                // Safely retrieve doctorId
                final String? doctorId = doctor['doctor_id']?.toString() ?? doctor['docId']?.toString();

                if (doctorId == null || doctorId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Doctor ID not found')),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagingSessionBooking(
                      doctorId: doctorId,
                      userId: user.uid,
                    ),
                  ),
                );
              },
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
              child: const Text('Book Messaging Session'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF6B4518),
            ),
          ),
          Expanded(
            child: Text(
              (value != null && value.toString().isNotEmpty)
                  ? value.toString()
                  : 'Not provided',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
