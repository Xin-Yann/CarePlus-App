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
  }

  @override
  void dispose() {
    _tabController.dispose();
    cardNo.dispose();
    expiryDate.dispose();
    cvv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      bottomNavigationBar: const PharmacyFooter(),
      body: Padding(
        padding: const EdgeInsets.all(8.0).copyWith(top: 70),
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
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('orders')
        .where('paymentType', isEqualTo: 'Debit/Credit Card');

    if (selectedStatus != 'All') {
      query = query.where('orderStatus', isEqualTo: selectedStatus);
    }

    query = query.orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text('No credit-card orders yet.'));
        }

        final orders =
            snap.data!.docs
                .map((d) => d.data() as Map<String, dynamic>)
                .toList();

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
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('orders')
        .where('paymentType', isEqualTo: 'TNG');

    if (selectedStatus != 'All') {
      query = query.where('orderStatus', isEqualTo: selectedStatus);
    }
    query = query.orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text('No TNG e-wallet orders yet.'));
        }

        final orders =
            snap.data!.docs
                .map((d) => d.data() as Map<String, dynamic>)
                .toList();

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

  // String _formatTimestamp(dynamic ts) {
  //   if (ts is Timestamp) {
  //     final dt = ts.toDate();
  //     return '${dt.day}/${dt.month}/${dt.year}';
  //   }
  //   return '--';
  // }
  //
  // String _formatTotal(dynamic value) {
  //   if (value == null) return '--';
  //   if (value is num) return value.toStringAsFixed(2);
  //
  //   if (value is String) {
  //     final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
  //     final parsed = double.tryParse(cleaned);
  //     if (parsed != null) return parsed.toStringAsFixed(2);
  //   }
  //
  //   return '--';
  // }
}

class OrderCard extends StatelessWidget {
  const OrderCard(this.data, {Key? key}) : super(key: key);
  final Map<String, dynamic> data;

  String generateTrackingNumber() {
    const prefix = 'TR'; // <-- always at the front
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();

    // 10 random chars + the 2‑char prefix = 12 total
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
    return next.toString().padLeft(6, '0'); // 6‑digit, zero‑padded
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
                      const SizedBox(height: 15),
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
                          style: const TextStyle(fontSize: 12),
                        ),
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
                                    itemMap['image'] ?? '',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itemMap['name'] ?? 'Item',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Quantity: x${itemMap['quantity'] ?? 1}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'RM ${_formatTotal(itemMap['price'])}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
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
                        ).pop(); // close the dialog (optional)

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
                            ) // make sure this really *is* the doc‑id
                            .update({
                              'orderStatus': 'Shipped',
                              'trackingNo': trackingNo,
                              'deliveryDate': Timestamp.fromDate(deliveryDate),
                              // 'trackingUrl': tracking['trackingUrl'],
                            });
                      },
                    ),

                  if (data['orderStatus'] ==
                      'Shipped') // ← comparison, not assignment
                    TextButton(
                      child: Text('Delivered'),
                      onPressed: () async {
                        Navigator.of(context).pop(); // close the dialog

                        // OPTIONAL: simulate 3‑5 days after “Shipped” if you still want that
                        final rand = Random.secure();
                        final daysToAdd = 3 + rand.nextInt(3); // 3, 4, or 5
                        final deliveredDate = DateTime.now().add(
                          Duration(days: daysToAdd),
                        );

                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(data['orderId']) // real doc‑id
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
