import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'doctor_ePrescription_details.dart';

class DoctorAddePrescription extends StatefulWidget {
  final Map<String, dynamic> session;
  final Map<String, dynamic> drug;

  const DoctorAddePrescription({
    super.key,
    required this.session,
    required this.drug,
  });

  @override
  State<DoctorAddePrescription> createState() => _DoctorAddePrescriptionState();
}

class _DoctorAddePrescriptionState extends State<DoctorAddePrescription> {
  String? selectedStrength;
  String? selectedQuantity;
  String? selectedRefill;
  String? selectedSig;

  List<Map<String, dynamic>> _strengthDetails = [];
  List<String> strengths = [];
  bool _loadingStrengths = true;

  final List<String> quantities = ['30', '60', '90', '120'];
  final List<String> refills = ['None', '1', '3', '5'];
  final List<String> smartSigs = [
    'Take 1 capsule by mouth twice a day',
    'Take 2 capsules by mouth twice a day',
    'Take 1 capsule by mouth three times a day',
  ];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    fetchStrengths();
  }

  Future<void> fetchStrengths() async {
    final String symptom = widget.drug['symptom'] ?? '';
    final String drugId = widget.drug['id'] ?? '';

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('controlled_medicine')
          .doc('symptoms')
          .collection(symptom)
          .doc(drugId)
          .collection('Strength')
          .get();

      final List<Map<String, Object>> fetched = snapshot.docs.map((doc) {
        return {
          'mg': doc.id,
          'price': double.tryParse(doc['price'].toString()) ?? 0.0,
        };
      }).toList();

      fetched.sort((a, b) {
        final aMg = int.tryParse(a['mg'].toString().replaceAll('mg', '').trim()) ?? 0;
        final bMg = int.tryParse(b['mg'].toString().replaceAll('mg', '').trim()) ?? 0;
        return aMg.compareTo(bMg);
      });

      setState(() {
        _strengthDetails = fetched;
        strengths = fetched.map((e) => e['mg'].toString()).toList();
        _loadingStrengths = false;
      });
    } catch (e) {
      print('Error fetching strengths: $e');
      setState(() {
        strengths = [];
        _loadingStrengths = false;
      });
    }
  }

  // Count price
  double getUnitPrice() {
    if (_strengthDetails.isEmpty || selectedStrength == null) return 0.0;
    final found = _strengthDetails.firstWhere(
          (s) => s['mg'] == selectedStrength,
      orElse: () => <String, Object>{},
    );
    if (found.isEmpty) return 0.0;
    return found['price'] as double? ?? 0.0;
  }

  double getTotalPrice() {
    final unitPrice = getUnitPrice();
    final qty = int.tryParse(selectedQuantity ?? '0') ?? 0;
    return unitPrice * qty;
  }

  Future<void> savePrescription() async {
    final userId = widget.session['userId'] ?? '';
    final doctorId = widget.session['doctorId'] ?? '';
    final sessionId = widget.session['id'] ?? '';
    final drugId = widget.drug['id'] ?? '';
    final symptom = widget.drug['symptom'] ?? '';

    if (userId == '' || sessionId == '' || doctorId == '' || drugId == '') {
      throw Exception('Missing required fields');
    }

    final prescription = {
      'userId': userId,
      'doctorId': doctorId,
      'sessionId': sessionId,
      'drugId': drugId,
      'symptom': symptom,
      'strength': selectedStrength,
      'quantity': selectedQuantity,
      'refill': selectedRefill,
      'sig': selectedSig,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('e-Prescription')
        .doc(userId)
        .collection('drugs')
        .add(prescription);
  }

  @override
  Widget build(BuildContext context) {
    final drug = widget.drug;
    final sessionDate = widget.session['date'] ?? '';
    final drugName = drug['name'] ?? 'No Name';

    final price = getTotalPrice().toStringAsFixed(2);

    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: SafeArea(
        child: Column(
          children: [
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
                    'ADD DRUG',
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
            Expanded(
              child: _loadingStrengths
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(sessionDate,
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.medical_services,
                          size: 28, color: Colors.black87),
                      const SizedBox(width: 8),
                      Text(
                        drugName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildLabel('Strength:'),
                  buildChips(strengths, selectedStrength,
                          (s) => setState(() => selectedStrength = s)),
                  const SizedBox(height: 16),
                  buildLabel('Quantity:'),
                  buildChips(quantities, selectedQuantity,
                          (s) => setState(() => selectedQuantity = s)),
                  const SizedBox(height: 16),
                  buildLabel('Refill:'),
                  buildChips(refills, selectedRefill,
                          (s) => setState(() => selectedRefill = s)),
                  const SizedBox(height: 16),
                  buildLabel('Smart Sigs:'),
                  buildChips(smartSigs, selectedSig,
                          (s) => setState(() => selectedSig = s)),
                  const SizedBox(height: 16),
                  buildPrecautions(drug),
                  const SizedBox(height: 16),
                  const Text('Drug Interaction Alert',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 24)),
                  const SizedBox(height: 8),
                  if (drug['drug_interaction_alert'] != null &&
                      drug['drug_interaction_alert'].toString().isNotEmpty)
                    Text(drug['drug_interaction_alert']),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Price:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 16)),
                      Text('RM $price',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD6C5B7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 10),
                    ),
                    onPressed: _saving
                        ? null
                        : () async {
                      setState(() => _saving = true);
                      try {
                        await savePrescription();
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text(
                                'Do you want to add another drug?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Yes')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('No')),
                            ],
                          ),
                        );
                        if (result == true) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DoctorePrescriptionDetails(
                                    session: widget.session)),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')));
                      } finally {
                        setState(() => _saving = false);
                      }
                    },
                    child: const Text('Add',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLabel(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.bold));

  Widget buildChips(
      List<String> options, String? selected, Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelect(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6B4518)
                  : const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(option,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black)),
          ),
        );
      }).toList(),
    );
  }

  Widget buildPrecautions(Map<String, dynamic> drug) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFAF6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Precautions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 8),
          if (drug['allergies'] != null && drug['allergies'].toString().isNotEmpty)
            const Text('Allergies:',
                style: TextStyle(fontWeight: FontWeight.bold)),
          if (drug['allergies'] != null && drug['allergies'].toString().isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text('• ${drug['allergies']}')),
          const SizedBox(height: 8),
          if (drug['diagnosis'] != null && drug['diagnosis'].toString().isNotEmpty)
            const Text('Diagnosis:',
                style: TextStyle(fontWeight: FontWeight.bold)),
          if (drug['diagnosis'] != null && drug['diagnosis'].toString().isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text('• ${drug['diagnosis']}')),
        ],
      ),
    );
  }
}
