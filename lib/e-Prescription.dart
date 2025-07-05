import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cart.dart';

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
  List<Map<String, dynamic>> prescriptionDrugs = [];

  Future<void> mergeCartItems(
    List<Map<String, dynamic>> newItems,
    BuildContext context,
  ) async {
    if (newItems.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;
    final email = user.email ?? 'unknown';

    final cartCol = FirebaseFirestore.instance.collection('cart');

    final querySnap =
        await cartCol.where('email', isEqualTo: email).limit(1).get();

    DocumentReference<Map<String, dynamic>> cartDoc;
    if (querySnap.docs.isNotEmpty) {
      cartDoc = querySnap.docs.first.reference;
    } else {
      // create a brand‑new cart doc
      cartDoc = cartCol.doc();
    }

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(cartDoc);

      final Map<String, Map<String, dynamic>> merged = {};

      if (snap.exists) {
        final stored =
            (snap.data()?['items'] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];

        for (final raw in stored) {
          final key = (raw['drugId'] ?? raw['id'])?.toString();
          if (key == null) continue;
          merged[key] = {...raw};
        }
      }

      // Fold in incoming items
      for (final p in newItems) {
        final key = (p['drugId'] ?? p['id'])?.toString();
        final name = p['name']?.toString();
        if (key == null || name == null) continue;

        final strength = p['strength']?.toString();
        final symptom = p['symptom']?.toString();

        final qty =
            p['quantity'] is int
                ? p['quantity'] as int
                : int.tryParse(p['quantity']?.toString() ?? '') ?? 1;

        final price =
            (() {
              final parsed =
                  p['price'] is num
                      ? (p['price'] as num).toDouble()
                      : double.tryParse(p['price']?.toString() ?? '') ?? 0.0;
              return parsed.toStringAsFixed(2);
            })();

        if (merged.containsKey(key)) {
          // Check if the existing item is a prescription
          if (merged[key]!['type'] == 'prescription') {
            // Replace the prescription item with the new one
            merged[key] = {
              'drugId': key,
              'name': name,
              'strength': strength,
              'symptom': symptom,
              'price': price,
              'quantity': qty,
              'type': 'prescription',
              'timestamp': Timestamp.now(),
            };
          }
          // } else {
          //   // If it's not a prescription (e.g., over-the-counter), keep and update quantity
          //   merged[key]!['quantity'] =
          //       (merged[key]!['quantity'] as int? ?? 0) + qty;
          //   merged[key]!['timestamp'] = Timestamp.now();
          // }
        } else {
          // New item, insert as usual
          merged[key] = {
            'drugId': key,
            'name': name,
            'strength': strength,
            'symptom': symptom,
            'price': price,
            'quantity': qty,
            'type': 'prescription',
            'timestamp': Timestamp.now(),
          };
        }
      }

      txn.set(cartDoc, {
        'email': email,
        'items': merged.values.toList(),
        'timestamp': Timestamp.now(),
      }, SetOptions(merge: true));
    });

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart updated')));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchPrescriptions();
  }

  Future<void> fetchPrescriptions() async {
    setState(() {
      _loading = true;
      prescriptionDrugs.clear();
    });

    final snapshot =
        await FirebaseFirestore.instance
            .collection('e-Prescription')
            .doc(widget.userId)
            .collection('drugs')
            .where('sessionId', isEqualTo: widget.sessionId)
            .get();

    final List<Map<String, dynamic>> tmpList = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final drugId = data['drugId'];
      final symptom = data['symptom'];
      final quantity = data['quantity'] ?? 1;
      final strength = data['strength'];

      try {
        final drugSnap = await fetchDrugData(drugId, symptom);
        if (!drugSnap.exists) continue;

        final drug = drugSnap.data() as Map<String, dynamic>;
        final drugName = drug['name'] ?? 'Unknown';

        final strengthStr = strength?.toString() ?? '';
        final priceAndStock = await fetchDrugPrice(
          drugId: drugId,
          symptom: symptom,
          strength: strengthStr,
        );

        if (priceAndStock == null) continue;

        final double price = priceAndStock['price']!.toDouble();
        final int stock = priceAndStock['stock']!.toInt();

        tmpList.add({
          'drugId': drugId,
          'name': drugName,
          'strength': strength,
          'symptom': symptom,
          'price': price,
          'stock': stock,
          'quantity': quantity,
          'type': 'prescription',
        });
      } catch (e) {
        print('Error fetching drug info for $drugId: $e');
      }
    }

    setState(() {
      docs = snapshot.docs;
      prescriptionDrugs = tmpList;
      _loading = false;
    });

    print('Loaded ${prescriptionDrugs.length} items into prescriptionDrugs');
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

  Future<Map<String, num>?> fetchDrugPrice({
    required String drugId,
    required String symptom,
    required String strength,
  }) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('controlled_medicine')
            .doc('symptoms')
            .collection(symptom)
            .doc(drugId)
            .collection('Strength')
            .doc(strength)
            .get();

    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || data['price'] == null) return null;

    final raw = data['price'];

    double? price;
    if (raw is num) {
      price = raw.toDouble();
    } else if (raw is String) {
      final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
      price = double.tryParse(cleaned);
    }

    final rawStock = data['stock'];
    int? stock;
    if (rawStock is int) {
      stock = rawStock;
    } else if (rawStock is String) {
      stock = int.tryParse(rawStock);
    }

    if (price == null || stock == null) return null;

    return {'price': price, 'stock': stock};
  }

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B4518);
    final bool isOutOfStock = prescriptionDrugs.any((drug) {
      final int stock = int.tryParse(drug['stock']?.toString() ?? '0') ?? 0;
      final int quantity = int.tryParse(drug['quantity']?.toString() ?? '0') ?? 0;
      return stock < quantity;
    });

    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                top: 50,
                left: 16,
                right: 16,
                bottom: 20,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed:
                          () => Navigator.pushReplacementNamed(
                            context,
                            '/chat_with_doctor',
                          ),
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

            // Session Info
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
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : docs.isEmpty
                      ? const Center(child: Text('No prescriptions found.'))
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final prescription =
                              docs[index].data() as Map<String, dynamic>;
                          final drugId = prescription['drugId'];
                          final symptom = prescription['symptom'];
                          final strengthStr =
                              prescription['strength']?.toString() ?? '';

                          return FutureBuilder<DocumentSnapshot>(
                            future: fetchDrugData(drugId, symptom),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Text(
                                  'Error loading drug: ${snapshot.error}',
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data?.data() == null) {
                                return const Text('Drug info not found.');
                              }

                              final drugData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              final drugName =
                                  drugData['name'] ?? 'Unknown Drug';

                              // Nested FutureBuilder for strength-specific price
                              return FutureBuilder<Map<String, num>?>(
                                future: fetchDrugPrice(
                                  drugId: drugId,
                                  symptom: symptom,
                                  strength: strengthStr,
                                ),
                                builder: (context, priceSnap) {
                                  if (priceSnap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (priceSnap.hasError) {
                                    return Text(
                                      'Error fetching price: ${priceSnap.error}',
                                    );
                                  }

                                  final p = priceSnap.data;
                                  debugPrint('p is $p');
                                  final rawPrice = p?['price'];
                                  final price = rawPrice is num
                                      ? rawPrice
                                      : num.tryParse(rawPrice.toString().replaceAll(RegExp(r'[^0-9.]'), ''));

                                  final quantityRaw = prescription['quantity'];
                                  final quantity = quantityRaw is int
                                      ? quantityRaw
                                      : int.tryParse(quantityRaw.toString()) ?? 1;

                                  final priceText = price != null
                                      ? 'RM ${price.toStringAsFixed(2)}'
                                      : 'Price not available';

                                  final totalPriceText = price != null
                                      ? 'RM ${(price * quantity).toStringAsFixed(2)}'
                                      : 'Total price not available';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5EFE6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          drugName,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6B4518),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Strength: ${prescription['strength'] ?? '-'}',
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Quantity: ${prescription['quantity'] ?? '-'}',
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Refill: ${prescription['refill'] ?? '-'}',
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Sig: ${prescription['sig'] ?? '-'}',
                                        ),
                                        const SizedBox(height: 5),
                                        Text('Price: $priceText'),
                                        const SizedBox(height: 5),
                                        Text('Total Price: $totalPriceText'),
                                        const SizedBox(height: 5),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
            ),

            if (!_loading && docs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child:
                // Disable when out of stock
                isOutOfStock
                    ? ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Out of Stock'),
                )
                    : ElevatedButton.icon(
                  onPressed:
                      isOutOfStock
                          ? null
                          : () async {
                            await mergeCartItems(prescriptionDrugs, context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => Cart()),
                            );
                          },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOutOfStock ? Colors.grey : brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),

                  // Show a different icon/label if out of stock
                  icon: const Icon(Icons.add_shopping_cart),

                  label: Text('Add All to Cart'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
