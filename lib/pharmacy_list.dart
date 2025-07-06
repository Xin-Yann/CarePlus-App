import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class PharmacyList extends StatefulWidget {
  const PharmacyList({super.key});

  @override
  State<PharmacyList> createState() => _PharmacyListState();
}

class _PharmacyListState extends State<PharmacyList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedState;

  final List<String> _states = [
    'Perlis',
    'Kedah',
    'Penang',
    'Perak',
    'Selangor',
    'Negeri Sembilan',
    'Melaka',
    'Kelantan',
    'Terengganu',
    'Pahang',
    'Johor',
    'Sabah',
    'Sarawak'
  ];

  Future<void> _signOutUser() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<List<QueryDocumentSnapshot>> _fetchAllPharmacies() async {
    List<QueryDocumentSnapshot> allPharmacies = [];

    for (String state in _states) {
      var snapshot = await _firestore
          .collection('pharmacy')
          .doc('state')
          .collection(state)
          .get();
      allPharmacies.addAll(snapshot.docs);
    }

    return allPharmacies;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                  top: 50.0, left: 16.0, right: 16.0, bottom: 20.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: Color(0xFF6B4518),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'PHARMACY LIST',
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

            // Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedState,
                    hint: const Text("Choose State"),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: _states.map((state) {
                      return DropdownMenuItem(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value;
                      });
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Pharmacy list
            _selectedState == null
                ? FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _fetchAllPharmacies(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("No pharmacies found."));
                }

                var allPharmacies = snapshot.data!;

                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: allPharmacies.length,
                  itemBuilder: (context, index) {
                    var pharmacy = allPharmacies[index];
                    return _buildPharmacyCard(pharmacy);
                  },
                );
              },
            )
                : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('pharmacy')
                  .doc('state')
                  .collection(_selectedState!)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text(
                          "No pharmacies found in $_selectedState."));
                }

                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var pharmacy = snapshot.data!.docs[index];
                    return _buildPharmacyCard(pharmacy);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyCard(QueryDocumentSnapshot pharmacy) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0XFFF0ECE7),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pharmacy['imageUrl'] != null && pharmacy['imageUrl'] != "")
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                pharmacy['imageUrl'],
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 80),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            pharmacy['name'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final mapUrl = pharmacy['map'];
              final url = Uri.parse(mapUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open map')),
                );
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(child: Text(pharmacy['address'])),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.blue),
              const SizedBox(width: 6),
              Text(pharmacy['operation_hours']),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.phone, color: Colors.teal),
              const SizedBox(width: 6),
              Text(pharmacy['contact']),
            ],
          ),
          const SizedBox(height: 6),
          if (pharmacy['social_media'] != null &&
              pharmacy['social_media'].toString().isNotEmpty)
            InkWell(
              onTap: () async {
                final url = Uri.parse(pharmacy['social_media']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch URL')),
                  );
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.facebook, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    pharmacy['name'],
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
