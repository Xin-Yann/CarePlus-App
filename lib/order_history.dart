import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'footer.dart';

class OrderHistory extends StatefulWidget {
  @override
  State<OrderHistory> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistory>
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
      bottomNavigationBar: const Footer(),
      body: Padding(
        padding: const EdgeInsets.all(8.0).copyWith(top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/home'),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(width: 50),
                const Text(
                  'ORDER HISTORY',
                  style: TextStyle(
                    color: Color(0xFF6B4518),
                    fontFamily: 'Crimson',
                    fontSize: 35,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            //Tab bar
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

            // Tab content
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

  // Credit Card Tab Content
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
}

class OrderCard extends StatelessWidget {
  const OrderCard(this.data, {Key? key}) : super(key: key);
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
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
            SizedBox(height: 5),
            Text('Total: RM ${_formatTotal(data['total'])}'),
            SizedBox(height: 10),
            Text(
              'Placed At: ${_formatTimestamp(data['timestamp'])}',
              style: const TextStyle(fontSize: 12),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text('Order Status: ', style: const TextStyle(fontSize: 14)),

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
              Text('Received Date: ${_formatTimestamp(data['receivedDate'])}'),

            SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Order Status: ',
                            style: const TextStyle(fontSize: 14),
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
                        Text(
                          'Delivered Date: ${_formatTimestamp(data['deliveryDate'])}',
                        ),

                      if (data['orderStatus'] == 'Received')
                        Text(
                          'Received Date: ${_formatTimestamp(data['receivedDate'])}',
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
                                  //product image
                                  Image.network(
                                    item['image'] ?? '',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback to asset image
                                      return Image.asset(
                                        'asset/image/weblogo.png',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),

                                  //product name
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 15),
                                        Text(
                                          itemMap['name'] ?? 'Item',
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                        ),
                                        if (item['type'] == 'prescription') ...[
                                          SizedBox(height: 7),
                                          Text(
                                            overflow: TextOverflow.visible,
                                            'Strength: ${item['strength'] ?? 'Unknown'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 5),
                                        Text(
                                          'Quantity: x${itemMap['quantity'] ?? 1}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  //price
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
                      const Divider(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal:',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'RM ${_formatTotal(data['subtotal'])}',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Shipping Fee:',
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'RM ${_formatTotal(data['shippingFee'])}',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10,),
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
                  if (data['orderStatus'] == 'Delivered')
                    TextButton(
                      onPressed: () async {
                        final receivedDate = DateTime.now();
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(data['orderId'])
                            .update({
                              'orderStatus': 'Received',
                              'receivedDate': Timestamp.fromDate(receivedDate),
                            });

                        Navigator.of(context).pop();
                      },
                      child: const Text('Received'),
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

    // already a number
    if (value is num) return value.toStringAsFixed(2);

    // try to parse a string, stripping “RM”, commas, etc.
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null) return parsed.toStringAsFixed(2);
    }

    return '--'; // fallback
  }
}
