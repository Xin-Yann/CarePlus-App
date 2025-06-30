import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ePrescriptionPage extends StatefulWidget {
  final String userId;
  final String sessionId;
  final String sessionDate;
  final String sessionTime;

  const ePrescriptionPage({
    super.key,
    required this.userId,
    required this.sessionId,
    required this.sessionDate,
    required this.sessionTime,
  });

  @override
  State<ePrescriptionPage> createState() => _ePrescriptionPageState();
}

class _ePrescriptionPageState extends State<ePrescriptionPage> {
  bool _loading = true;
  List<QueryDocumentSnapshot> docs = [];

  @override
  void initState() {
    super.initState();
    fetchPrescriptions();
  }

  Future<void> fetchPrescriptions() async {
    setState(() => _loading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('e-Prescription')
        .doc(widget.userId)
        .collection('drugs')
        .where('sessionId', isEqualTo: widget.sessionId)
        .get();

    setState(() {
      docs = snapshot.docs;
      _loading = false;
    });
  }

  Future<DocumentSnapshot> fetchDrugData(String drugId, String? symptom) {
    if (symptom != null) {
      return FirebaseFirestore.instance
          .collection('controlled_medicine')
          .doc('symptoms')
          .collection(symptom)
          .doc(drugId)
          .get();
    } else {
      return Future.error('Symptom is null but no valid fallback collection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B4518);

    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
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
                      color: brown,
                    ),
                  ),
                  const Text(
                    "E-PRESCRIPTION",
                    style: TextStyle(
                      color: brown,
                      fontFamily: 'Crimson',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Session Info (single line)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Session: ${widget.sessionId} | ${widget.sessionDate} @ ${widget.sessionTime}',
                style: const TextStyle(color: Colors.black87),
              ),
            ),
            const SizedBox(height: 16),

            // Prescription List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : docs.isEmpty
                  ? const Center(child: Text('No prescriptions found.'))
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length + 1, // +1 for Add to Cart button
                itemBuilder: (context, index) {
                  if (index == docs.length) {
                    return Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Your cart logic here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Drugs added to cart')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add to Cart'),
                      ),
                    );
                  }

                  final prescription = docs[index].data() as Map<String, dynamic>;
                  final drugId = prescription['drugId'];
                  final symptom = prescription['symptom'];

                  return FutureBuilder<DocumentSnapshot>(
                    future: fetchDrugData(drugId, symptom),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Text('Error loading drug: ${snapshot.error}');
                      }

                      if (!snapshot.hasData || snapshot.data?.data() == null) {
                        return const Text('Drug info not found.');
                      }

                      final data = snapshot.data!;
                      final drug = data.data() as Map<String, dynamic>;
                      final drugName = drug['name'] ?? 'Unknown Drug';
                      final price = drug['price'] ?? '-';

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
                                color: brown,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Strength: ${prescription['strength'] ?? '-'}'),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
