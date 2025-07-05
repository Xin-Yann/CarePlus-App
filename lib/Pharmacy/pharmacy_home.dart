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
  String _selectedType = 'All'; // default value
  final TextEditingController name = TextEditingController();
  String loggedInEmail = '';

  List<String> _buildMonthList() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final date = DateTime(now.year, now.month - i);
      return DateFormat('yyyy-MM').format(date);
    });
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    loggedInEmail = user?.email ?? '';
    fetchPharmacyData();
  }

  Map<String, dynamic>? pharmacyData;
  Map<String, List<String>> stateDocIds = {
    "Perlis": ["P1", "P2", "P3"],
    "Kedah": ["P4", "P5", "P6"],
    "Penang": ["P7", "P8", "P9"],
    "Perak": ["P10", "P11", "P12"],
    "Selangor": ["P13", "P14", "P15"],
    "Negeri Sembilan": ["P16", "P17", "P18"],
    "Melaka": ["P19", "P20", "P21"],
    "Kelantan": ["P22", "P23", "P24"],
    "Terengganu": ["P25", "P26", "P27"],
    "Pahang": ["P28", "P29", "P30"],
    "Johor": ["P31", "P32", "P33"],
    "Sabah": ["P34", "P35", "P36"],
    "Sarawak": ["P37", "P38", "P39"],
  };

  Future<void> fetchPharmacyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    final email = user!.email!;
    for (final entry in stateDocIds.entries) {
      final state  = entry.key;
      for (final id in entry.value) {
        final doc = await FirebaseFirestore.instance
            .collection('pharmacy')
            .doc('state')           // ↙ verify this level is correct
            .collection(state)
            .doc(id)
            .get();

        if (!doc.exists) continue;
        final data = doc.data();
        if (data?['email'] == email) {
          setState(() {
            pharmacyData = data;
            name.text    = data?['name'] ?? '';   // 👈 now visible in UI
          });
          return; // stop looping
        }
      }
    }
    debugPrint('Pharmacy record not found for $email');
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
                      Navigator.pushReplacementNamed(
                        context,
                        '/pharmacy_login',
                      );
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

            Padding(
              padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
              child: Text(
                'Welcome, ${name.text}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Crimson',
                ),
              ),
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

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('orders').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading orders'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final Set<String> availableTypes = {}; // 👈 collect types first
                final Map<String, Map<String, double>> symptomTotals = {};

                for (final doc in snapshot.data!.docs) {
                  final ts = doc['timestamp'] as Timestamp?;
                  if (ts == null) continue;

                  final orderDate = ts.toDate();
                  final orderMonth = DateFormat('yyyy-MM').format(orderDate);
                  if (orderMonth != _selectedMonth) continue;

                  final items = doc['items'] as List<dynamic>? ?? [];
                  for (final item in items) {
                    final symptom = item['symptom']?.toString() ?? 'Unknown';
                    final type = item['type']?.toString() ?? 'Unknown';
                    availableTypes.add(type); // ✅ collect for dropdown

                    final rawPrice = item['price'];
                    double unitPrice =
                        rawPrice is num
                            ? rawPrice.toDouble()
                            : double.tryParse(
                                  rawPrice.toString().replaceAll(
                                    RegExp(r'[^\d.]'),
                                    '',
                                  ),
                                ) ??
                                0.0;

                    final qty = (item['quantity'] ?? 1) as num;
                    final subtotal = unitPrice * qty;

                    symptomTotals[type] ??= {};
                    symptomTotals[type]![symptom] =
                        (symptomTotals[type]![symptom] ?? 0) + subtotal;
                  }
                }

                final typeOptions = [
                  'All',
                  ...availableTypes.toList()..sort(),
                ]; // ✅ now it's safe

                if (symptomTotals.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text('No sales data for this month'),
                  );
                }

                // Step 1: Flatten nested map
                final Map<String, double> flatSymptomMap = {};
                symptomTotals.forEach((type, symptomsMap) {
                  if (_selectedType != 'All' && type != _selectedType) return;
                  symptomsMap.forEach((symptom, value) {
                    final label = '$type: $symptom';
                    flatSymptomMap[label] =
                        (flatSymptomMap[label] ?? 0) + value;
                  });
                });

                // Step 2: Early return check
                if (flatSymptomMap.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text('No sales data for this month'),
                  );
                }

                // Step 3: Build chart sections
                final symptoms = flatSymptomMap.keys.toList()..sort();
                final grandTotal = flatSymptomMap.values.fold(
                  0.0,
                  (a, b) => a + b,
                );

                final sections = List.generate(symptoms.length, (i) {
                  final label = symptoms[i];
                  final value = flatSymptomMap[label]!;
                  return PieChartSectionData(
                    value: value,
                    title: '${(value / grandTotal * 100).toStringAsFixed(1)}%',
                    color: Colors.primaries[i % Colors.primaries.length],
                    radius: 60,
                  );
                });

                return Column(
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 15.0,
                        left: 15.0,
                        right: 15.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Filter by Month
                          const Text(
                            'Month:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedMonth,
                            items:
                                _buildMonthList().map((String month) {
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

                          const SizedBox(width: 24), // spacing between filters
                          // Filter by Type
                          const Text(
                            'Type:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedType,
                            items:
                                typeOptions.map((String type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Type:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4), // small gap under the label
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 12,
                          runSpacing: 4,
                          children: List.generate(symptoms.length, (i) {
                            final label = symptoms[i];
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  color:
                                      Colors.primaries[i %
                                          Colors.primaries.length],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$label – RM ${flatSymptomMap[label]!.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
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
