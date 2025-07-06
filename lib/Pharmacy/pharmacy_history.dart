import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pharmacy_footer.dart';

class PharmacyHistory extends StatefulWidget {
  @override
  State<PharmacyHistory> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<PharmacyHistory>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController cardNo = TextEditingController();
  final TextEditingController expiryDate = TextEditingController();
  final TextEditingController cvv = TextEditingController();

  String selectedStatus = 'All';
  final List<String> orderStatusOptions = [
    'All',
    'Order Placed',
    'Shipped',
    'Delivered',
    'Received',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchPharmacyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    cardNo.dispose();
    expiryDate.dispose();
    cvv.dispose();
    super.dispose();
  }

  Map<String, dynamic>? pharmacyData;
  String? _pharmacyState;
  String? _pharmacyId;
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

    if (user == null || user.email == null) {
      print('User is not logged in or missing email.');
      return;
    }

    final userEmail = user.email!;
    print('Looking for pharmacy with email: $userEmail');

    bool found = false;

    for (final entry in stateDocIds.entries) {
      final state = entry.key;
      for (final id in entry.value) {
        final doc = await FirebaseFirestore.instance
            .collection('pharmacy')
            .doc('state')
            .collection(state)
            .doc(id)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('email')) {
            print('📄 Checked: $state / $id -> Email: ${data['email']}');
            if (data['email'].toString().trim().toLowerCase() == userEmail.toLowerCase()) {
              setState(() {
                _pharmacyState = state;
                _pharmacyId = id;
              });
              print('Match found in $state / $id');
              found = true;
              return;
            }
          }
        }
      }
    }

    if (!found) {
      print('Pharmacy record not found for $userEmail');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      bottomNavigationBar: const PharmacyFooter(),
      body: Padding(
        padding: const EdgeInsets.all(8.0).copyWith(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed:
                      () => Navigator.pushNamed(context, '/pharmacy_home'),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(width: 100),
                const Text(
                  'ORDERS',
                  style: TextStyle(
                    color: Color(0xFF6B4518),
                    fontFamily: 'Crimson',
                    fontSize: 35,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6B4518),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF6B4518),
              tabs: const [
                Tab(icon: Icon(Icons.credit_card), text: "Debit/Credit Card"),
                Tab(
                  icon: Icon(Icons.account_balance_wallet),
                  text: "TNG E-wallet",
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(8.0).copyWith(top: 30, left: 20),
              child: Row(
                children: [
                  const Text(
                    'Filter: ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedStatus,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStatus = value;
                        });
                      }
                    },
                    items:
                        orderStatusOptions.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildCreditCardTab(), _buildEWalletTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardTab() {
    if (_pharmacyId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('orders')
        .where('paymentType', isEqualTo: 'Debit/Credit Card')
        .where('assignedPharmacyId', isEqualTo: _pharmacyId);

    if (selectedStatus != 'All') {
      query = query.where('orderStatus', isEqualTo: selectedStatus);
    }

    query = query.orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          print('Stream error: ${snap.error}');

          return Center(child: Text('${snap.error}'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData) {
          return const Center(child: Text('Loading orders…'));
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No Debit/Credit Card orders yet.'));
        }

        final orders =
        docs.map((d) => d.data() as Map<String, dynamic>).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              ...orders.map((data) => OrderCard(data)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEWalletTab() {
    if (_pharmacyId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('orders')
        .where('paymentType', isEqualTo: 'TNG')
        .where('assignedPharmacyId', isEqualTo: _pharmacyId);

    if (selectedStatus != 'All') {
      query = query.where('orderStatus', isEqualTo: selectedStatus);
    }

    query = query.orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          print('Stream error: ${snap.error}');

          return Center(child: Text('🔥 ${snap.error}'));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData) {
          return const Center(child: Text('Loading orders…'));
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No TNG e‑wallet orders yet.'));
        }

        final orders =
        docs.map((d) => d.data() as Map<String, dynamic>).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              ...orders.map((data) => OrderCard(data)).toList(),
            ],
          ),
        );
      },
    );

  }
}

class OrderCard extends StatelessWidget {
  const OrderCard(this.data, {Key? key}) : super(key: key);
  final Map<String, dynamic> data;

  String generateTrackingNumber() {
    const prefix = 'TR';
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();

    final randomPart =
        List.generate(10, (_) => chars[rand.nextInt(chars.length)]).join();

    return '$prefix$randomPart';
  }

  Future<String> nextSequentialTracking(Transaction tx) async {
    final counterRef = FirebaseFirestore.instance
        .collection('meta')
        .doc('trackingCounter');

    final snap = await tx.get(counterRef);
    final next = (snap.data()?['next'] ?? 100000) as int;
    tx.update(counterRef, {'next': next + 1});
    return next.toString().padLeft(6, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading:
            data['paymentType']?.toLowerCase() == 'tng'
                ? const Icon(Icons.account_balance_wallet)
                : const Icon(Icons.credit_card),
        title: Text('Order #${data['orderId'] ?? data['id'] ?? 'N/A'}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text('Total: RM ${_formatTotal(data['total'])}'),
            const SizedBox(height: 10),
            Text(
              'Placed At: ${_formatTimestamp(data['timestamp'])}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Order Status: ', style: TextStyle(fontSize: 14)),
                Text(
                  '${data['orderStatus'] ?? 'N/A'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        data['orderStatus'] == 'Shipped'
                            ? Colors.orange
                            : data['orderStatus'] == 'Received'
                            ? Colors.green
                            : data['orderStatus'] == 'Delivered'
                            ? Color(0xFF6B4518)
                            : Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            if (data['orderStatus'] == 'Shipped') ...[
              Text('Tracking Number: ${data['trackingNo']}'),
              SizedBox(height: 10),
              Text(
                'Estimated Delivery: ${_formatTimestamp(data['deliveryDate'])}',
              ),
              SizedBox(height: 10),
            ],

            if (data['orderStatus'] == 'Delivered')
              Text('Delivered Date: ${_formatTimestamp(data['deliveryDate'])}'),

            if (data['orderStatus'] == 'Received')
              Text(
                'Received Date: ${_formatTimestamp(data['receivedDate'])}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text('Order #${data['orderId'] ?? data['id'] ?? 'N/A'}'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name: ${data['name']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: ${data['email']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Contact: ${data['contact']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Address: ${data['address']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Placed At: ${_formatTimestamp(data['timestamp'])}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Order Status: ',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${data['orderStatus'] ?? 'N/A'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  data['orderStatus'] == 'Shipped'
                                      ? Colors.orange
                                      : data['orderStatus'] == 'Received'
                                      ? Colors.green
                                      : data['orderStatus'] == 'Delivered'
                                      ? Color(0xFF6B4518)
                                      : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (data['orderStatus'] == 'Shipped') ...[
                        Text('Tracking Number: ${data['trackingNo']}'),
                        SizedBox(height: 10),
                        Text(
                          'Estimated Delivery: ${_formatTimestamp(data['deliveryDate'])}',
                        ),
                        SizedBox(height: 10),
                      ],
                      if (data['orderStatus'] == 'Delivered')
                        Text(
                          'Delivered Date: ${_formatTimestamp(data['deliveryDate'])}',
                        ),

                      if (data['orderStatus'] == 'Received')
                        Text(
                          'Received Date: ${_formatTimestamp(data['receivedDate'])}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text(
                        'Items:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...((data['items'] as List?)?.map((item) {
                            final itemMap = item as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 8),
                              child: Row(
                                children: [
                                  Image.network(
                                    item['image'] ?? '',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'asset/image/weblogo.png',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          maxLines: 2,
                                          softWrap: true,
                                          itemMap['name'] ?? 'Item',
                                        ),

                                        const SizedBox(height: 5),
                                        Text(
                                          'Quantity: x${itemMap['quantity'] ?? 1}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'RM ${_formatTotal(itemMap['price'])}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList() ??
                          [const Text('No items')]),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'RM ${_formatTotal(data['total'])}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (data['orderStatus'] == 'Order Placed')
                    TextButton(
                      child: const Text('Order Shipped'),
                      onPressed: () async {
                        Navigator.of(
                          context,
                        ).pop();

                        final trackingNo = generateTrackingNumber();
                        final rand = Random.secure();
                        final daysToAdd = 3 + rand.nextInt(3);
                        final deliveryDate = DateTime.now().add(
                          Duration(days: daysToAdd),
                        );

                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(
                              data['orderId'],
                            )
                            .update({
                              'orderStatus': 'Shipped',
                              'trackingNo': trackingNo,
                              'deliveryDate': Timestamp.fromDate(deliveryDate),
                            });
                      },
                    ),

                  if (data['orderStatus'] ==
                      'Shipped')
                    TextButton(
                      child: Text('Delivered'),
                      onPressed: () async {
                        Navigator.of(context).pop();

                        final rand = Random.secure();
                        final daysToAdd = 3 + rand.nextInt(3);
                        final deliveredDate = DateTime.now().add(
                          Duration(days: daysToAdd),
                        );

                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(data['orderId'])
                            .update({
                              'orderStatus': 'Delivered',
                              'deliveryDate': Timestamp.fromDate(deliveredDate),
                            });
                      },
                    ),

                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    return '--';
  }

  String _formatTotal(dynamic value) {
    if (value == null) return '--';
    if (value is num) return value.toStringAsFixed(2);
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null) return parsed.toStringAsFixed(2);
    }
    return '--';
  }
}
