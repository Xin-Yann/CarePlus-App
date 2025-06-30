import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorePrescriptionMedList extends StatefulWidget {
  final Map<String, dynamic> session;

  const DoctorePrescriptionMedList({super.key, required this.session});

  @override
  State<DoctorePrescriptionMedList> createState() =>
      _DoctorePrescriptionMedListState();
}

class _DoctorePrescriptionMedListState
    extends State<DoctorePrescriptionMedList> {
  List<Map<String, dynamic>> allDrugs = [];
  String searchText = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchAllDrugs();
  }

  Future<void> fetchAllDrugs() async {
    try {
      final drugs = <Map<String, dynamic>>[];

      final List<String> symptomList = [
        'Allergy',
        'Anxiety',
        'Asthma',
        'Cough',
        'Diarrhoea',
        'Fever',
        'Heartburn',
        'Nasal Congestion',
        'Pain',
        'Skin Allergy',
      ];

      for (final symptom in symptomList) {
        final snapshot = await FirebaseFirestore.instance
            .collection('controlled_medicine')
            .doc('symptoms')
            .collection(symptom)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data != null && data['name'] != null) {
            drugs.add({
              ...data,
              'id': doc.id,
              'symptom': symptom, // ✅ Add symptom to each drug entry
            });
          }
        }
      }

      drugs.sort((a, b) => (a['name'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['name'] ?? '').toString().toLowerCase()));

      setState(() {
        allDrugs = drugs;
        _loading = false;
      });
    } catch (e) {
      print("❌ Error fetching drugs: $e");
      setState(() {
        allDrugs = [];
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredDrugs {
    return allDrugs.where((drug) {
      final name = drug['name'];
      if (name == null) return false;
      return name.toString().toLowerCase().contains(searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: Column(
        children: [
          // Header
          Padding(
            padding:
            const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 20),
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
                const Text(
                  'DRUG LIST',
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

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase();
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search Drug Name',
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),
          ),

          // Drug List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filteredDrugs.isEmpty
                ? const Center(child: Text("No drugs found."))
                : ListView.separated(
              itemCount: filteredDrugs.length,
              separatorBuilder: (context, index) => const Divider(
                color: Colors.black26,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final drug = filteredDrugs[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  title: Text(
                    drug['name'] ?? 'Unnamed Drug',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000000),
                    ),
                  ),
                  subtitle: Text(
                    "${drug['symptom'] ?? ''}",
                    style: const TextStyle(color: Color(0xFF000000)),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF000000),
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/doctor_add_ePrescription',
                      arguments: {
                        'session': widget.session,
                        'drug': drug,
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
