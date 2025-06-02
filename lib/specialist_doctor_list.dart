import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'specialist_doctor_details.dart'; // Make sure this import is correct

class SpecialistDoctorList extends StatefulWidget {
  const SpecialistDoctorList({super.key});

  @override
  State<SpecialistDoctorList> createState() => _SpecialistDoctorListState();
}

class _SpecialistDoctorListState extends State<SpecialistDoctorList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _specialties = [
    'All Specialties',
    'Internal Medicine',
    'Ear, Nose, and Throat (ENT)',
    'Cardiology',
    'Dermatology',
    'Endocrinology',
    'Gastroenterology & Hepatology',
    'Nephrology',
    'Obstetrics & Gynaecology',
    'Orthopaedic',
    'General Medicine',
  ];

  String _selectedSpecialty = 'All Specialties';

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
                    color: const Color(0xFF6B4518),
                  ),
                ),
                const Center(
                  child: Text(
                    'DOCTOR LIST',
                    style: TextStyle(
                      color: Color(0xFF6B4518),
                      fontFamily: 'Crimson',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              value: _selectedSpecialty,
              items: _specialties.map((specialty) {
                return DropdownMenuItem(
                  value: specialty,
                  child: Text(specialty),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSpecialty = value;
                  });
                }
              },
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: (_selectedSpecialty == 'All Specialties')
                  ? _firestore.collection('doctors').snapshots()
                  : _firestore
                  .collection('doctors')
                  .where('specialty', isEqualTo: _selectedSpecialty)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedSpecialty == 'All Specialties'
                          ? "No doctors found."
                          : "No doctors found in $_selectedSpecialty.",
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                final doctors = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doc = doctors[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final String name = data['name']?.toString() ?? 'Unknown';
                    final String imageUrl = data['imageUrl']?.toString() ?? '';
                    final String specialty = data['specialty']?.toString() ?? '';

                    return _buildDoctorCard(
                      imageUrl: imageUrl,
                      name: name,
                      specialty: specialty,
                      doctorData: data,
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

  Widget _buildDoctorCard({
    required String imageUrl,
    required String name,
    required String specialty,
    required Map<String, dynamic> doctorData,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFF7F3EF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpecialistDoctorDetails(doctor: doctorData),
            ),
          );
        },
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 32,
          backgroundImage: imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : const NetworkImage('https://via.placeholder.com/150'),
          backgroundColor: Colors.grey[200],
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          specialty,
          style: const TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
