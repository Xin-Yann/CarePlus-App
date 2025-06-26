import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'footer.dart';

class OrderHistory extends StatefulWidget {
  @override
  State<OrderHistory> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistory> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController cardNo = TextEditingController();
  final TextEditingController expiryDate = TextEditingController();
  final TextEditingController cvv = TextEditingController();

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
        padding: const EdgeInsets.all(8.0).copyWith(top: 70),
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
                Tab(
                  icon: Icon(Icons.credit_card),
                  text: "Debit/Credit Card",
                ),
                Tab(
                  icon: Icon(Icons.account_balance_wallet),
                  text: "TNG E-wallet",
                ),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCreditCardTab(),
                  _buildEWalletTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Credit Card Tab Content
  Widget _buildCreditCardTab() {
    final email = FirebaseAuth.instance.currentUser?.email;
    print(email);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('email', isEqualTo: email)
          .where('paymentType', isEqualTo: 'Debit/Credit Card')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text('No credit-card orders yet.'));
        }

        final orders =
        snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();

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

  // E-Wallet Tab Content
  Widget _buildEWalletTab() {
    final email = FirebaseAuth.instance.currentUser?.email;
    print(email);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('email', isEqualTo: email)
          .where('paymentType', isEqualTo: 'TNG')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text('No credit-card orders yet.'));
        }

        final orders =
        snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();

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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: data['paymentType']?.toLowerCase() == 'tng'
            ? const Icon(Icons.account_balance_wallet)
            : const Icon(Icons.credit_card),
        title: Text('Order #${data['orderId'] ?? data['id'] ?? 'N/A'}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5,),
            Text('Total: RM ${_formatTotal(data['total'])}'),
            SizedBox(height: 10,),
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
                    color: data['orderStatus'] == 'Shipped'
                        ? Colors.orange
                        : data['orderStatus'] == 'Received'
                        ? Colors.green
                        : Colors.black,

                  ),
                ),
              ],
            ),

            SizedBox(height: 10,),
            Text(
              'Placed At: ${_formatTimestamp(data['timestamp'])}',
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text('Order #${data['orderId'] ?? data['id'] ?? 'N/A'}'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Placed At: ${_formatTimestamp(data['timestamp'])}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
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
                              color: data['orderStatus'] == 'Shipped'
                                  ? Colors.orange
                                  : data['orderStatus'] == 'Received'
                                  ? Colors.green
                                  : Colors.black,

                            ),
                          ),
                        ],
                      ),

                      const Divider(),
                      const SizedBox(height: 12),
                      const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),

                      const SizedBox(height: 12),
                      ...((data['items'] as List?)?.map((item) {
                        final itemMap = item as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(top:6,bottom: 8),
                          child: Row(
                            children: [
                              // ── product image ──
                              Image.network(
                                itemMap['image'] ?? '',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported, size: 40),
                              ),
                              const SizedBox(width: 8),

                              // ── product name ──
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemMap['name'] ?? 'Item',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Quantity: x${itemMap['quantity'] ?? 1}',
                                      style: const TextStyle(fontSize: 12, color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                              // ── price ──
                              Text(
                                'RM ${_formatTotal(itemMap['price'])}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );

                      }).toList() ?? [const Text('No items')]),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'RM ${_formatTotal(data['total'])}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
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
      final parsed  = double.tryParse(cleaned);
      if (parsed != null) return parsed.toStringAsFixed(2);
    }

    return '--'; // fallback
  }

}
