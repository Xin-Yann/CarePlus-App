import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:careplusapp/Pharmacy/pharmacy_footer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PharmacyHome extends StatefulWidget {
  const PharmacyHome({super.key});

  @override
  State<PharmacyHome> createState() => _PharmacyHomeState();
}

class _PharmacyHomeState extends State<PharmacyHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  List<String> _buildMonthList() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final date = DateTime(now.year, now.month - i);
      return DateFormat('yyyy-MM').format(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Bar ──
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 35.0, left: 20.0),
                  child: Image.asset(
                    'asset/image/weblogo.png',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 35.0, right: 20.0),
                  child: GestureDetector(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacementNamed(context, '/pharmacy_login');
                    },
                    child: Image.asset(
                      'asset/image/exit.png',
                      width: 33,
                      height: 33,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20.0),

            // ── Title ──
            Padding(
              padding: const EdgeInsets.only(top: 25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Monthly Sales',
                    style: TextStyle(
                      color: Color(0xFF6B4518),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Crimson',
                      fontSize: 30,
                    ),
                  ),
                ],
              ),
            ),


            Padding(
              padding: const EdgeInsets.only(left: 15.0, top: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Filter by month:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _selectedMonth,
                    items: _buildMonthList().map((String month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            // ── Chart from Firestore Orders ──
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('orders').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading orders'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final Map<String, double> symptomTotals = {};
                for (final doc in snapshot.data!.docs) {
                  final ts = doc['timestamp'] as Timestamp?;
                  if (ts == null) continue;

                  final orderDate = ts.toDate();
                  final orderMonth = DateFormat('yyyy-MM').format(orderDate);
                  if (orderMonth != _selectedMonth) continue;

                  final items = doc['items'] as List<dynamic>? ?? [];
                  for (final item in items) {
                    final symptom = item['symptom']?.toString() ?? 'Unknown';

                    final rawPrice = item['price'];
                    double unitPrice = rawPrice is num
                        ? rawPrice.toDouble()
                        : double.tryParse(rawPrice.toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

                    final qty = (item['quantity'] ?? 1) as num;
                    final subtotal = unitPrice * qty;

                    symptomTotals[symptom] = (symptomTotals[symptom] ?? 0) + subtotal;
                  }
                }

                if (symptomTotals.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text('No sales data for this month'),
                  );
                }

                final symptoms = symptomTotals.keys.toList()..sort();
                final grandTotal = symptomTotals.values.fold(0.0, (a, b) => a + b);

                final sections = <PieChartSectionData>[
                  for (int i = 0; i < symptoms.length; i++)
                    PieChartSectionData(
                      value: symptomTotals[symptoms[i]]!,
                      title: '${(symptomTotals[symptoms[i]]! / grandTotal * 100).toStringAsFixed(1)}%',
                      color: Colors.primaries[i % Colors.primaries.length],
                      radius: 60,
                    ),
                ];

                return Column(
                  children: [
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Legend ──
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: List.generate(symptoms.length, (i) {
                        final symptom = symptoms[i];
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: Colors.primaries[i % Colors.primaries.length],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$symptom – RM ${symptomTotals[symptom]!.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PharmacyFooter(),
    );
  }
}
