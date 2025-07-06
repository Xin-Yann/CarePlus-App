import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_confirmation.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  late Future<List<Map<String, dynamic>>> _cartItemsFuture;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> cartItems = [];
  final Map<String, bool> itemChecked = {};
  final Map<String, int> itemQuantity = {};

  @override
  void initState() {
    super.initState();
    _cartItemsFuture = _fetchUserCartItems();

    _cartItemsFuture.then((items) {
      setState(() {
        cartItems.addAll(items);
        for (final item in items) {
          itemChecked[item['uiKey']] = false;
          itemQuantity[item['uiKey']] = item['quantity'] ?? 1;
        }
      });
    });
  }

  Future<List<Map<String, dynamic>>> _fetchUserCartItems() async {
    try {
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) return [];

      final qs =
          await FirebaseFirestore.instance
              .collection('cart')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (qs.docs.isEmpty) return [];

      final cartDoc = qs.docs.first;
      final docId = cartDoc.id;
      final raw = List<Map<String, dynamic>>.from(cartDoc['items'] ?? []);

      final result = <Map<String, dynamic>>[];
      for (var i = 0; i < raw.length; i++) {
        final r = raw[i];
        final id = (r['id'] ?? r['drugId'])?.toString();
        if (id == null || id.isEmpty) continue;

        final p = r['price'];
        final price =
            p is num
                ? p.toDouble()
                : num.tryParse(p.toString())?.toDouble() ?? 0.0;

        result.add({
          'uiKey': '$docId-$i',
          'cartDocId': docId,
          'id': id,
          'price': price,
          'type': r.containsKey('drugId') ? 'prescription' : 'uncontrolled',
          ...r,
        });
      }
      return result;
    } catch (e) {
      debugPrint('Error fetching cart items: $e');
      return [];
    }
  }

  bool get _allSelected =>
      cartItems.isNotEmpty &&
      cartItems.every((item) => itemChecked[item['uiKey']] == true);

  bool get _noneSelected =>
      cartItems.every((item) => itemChecked[item['uiKey']] != true);

  bool? get _selectAllValue =>
      _allSelected ? true : (_noneSelected ? false : null);

  void _toggleSelectAll(bool? value) {
    final bool newValue = (value ?? false);

    setState(() {
      for (final item in cartItems) {
        itemChecked[item['uiKey']] = newValue;
      }
    });
  }

  double _cartTotal() {
    double total = 0.0;
    for (final item in cartItems) {
      final key = item['uiKey'];
      final sel = itemChecked[key] ?? false;
      final qty = itemQuantity[key] ?? (item['quantity'] ?? 1);
      if (sel) {
        final price = double.tryParse(item['price'].toString()) ?? 0.0;
        total += price * qty;
      }
    }
    return total;
  }

  Future<void> _handleItemChanged(CartItemUpdate u) async {
    try {
      /* 1. Stock check for uncontrolled medicine */
      if (u.type == 'uncontrolled') {
        final qs =
            await FirebaseFirestore.instance
                .collection('uncontrolled_medicine')
                .doc('symptoms')
                .collection(u.symptom)
                .where('name', isEqualTo: u.name)
                .limit(1)
                .get();

        final rawStock = qs.docs.isNotEmpty ? qs.docs.first['stock'] : 9999;
        final stock =
            rawStock is int
                ? rawStock
                : int.tryParse(rawStock.toString()) ?? 9999;

        if (u.quantity > stock) {
          await showDialog<void>(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text('Stock Limit Exceeded'),
                  content: Text(
                    'Cannot add more than $stock items of this product.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
          return;
        }
      }

      final parts = u.uiKey.split('-');
      final cartDocId = parts[0];
      final idx = int.tryParse(parts[1] ?? '');
      if (idx == null) return;

      final docRef = FirebaseFirestore.instance
          .collection('cart')
          .doc(cartDocId);
      final snap = await docRef.get();
      if (!snap.exists) return;

      final rows = List<Map<String, dynamic>>.from(snap['items'] ?? []);
      if (idx < 0 || idx >= rows.length) return;

      if (u.quantity == 0) {
        final confirm = await showDialog<bool>(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Remove item?'),
                content: const Text(
                  'Do you want to remove this product from the cart?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yes'),
                  ),
                ],
              ),
        );
        if (confirm != true) return;

        rows.removeAt(idx);
        await docRef.update({'items': rows});
        setState(() {
          cartItems.removeWhere((e) => e['uiKey'] == u.uiKey);
          itemChecked.remove(u.uiKey);
          itemQuantity.remove(u.uiKey);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Item removed from cart')));
        return;
      }

      rows[idx]['quantity'] = u.quantity;
      await docRef.update({'items': rows});
      setState(() {
        itemChecked[u.uiKey] = u.isChecked;
        itemQuantity[u.uiKey] = u.quantity;
      });
    } catch (e) {
      debugPrint('Error updating cart: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error updating cart')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0XFFF0ECE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: RM${_cartTotal().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4518),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4518),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
              ),
              onPressed: () {
                final selected =
                    cartItems
                        .where((e) => itemChecked[e['uiKey']] ?? false)
                        .toList();
                if (selected.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one item.'),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutPage(checkedItems: selected),
                  ),
                );
              },
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 35, left: 8, right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /* Header */
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                  ),
                  const SizedBox(width: 40),
                  const Text(
                    'SHOPPING CART',
                    style: TextStyle(
                      color: Color(0xFF6B4518),
                      fontFamily: 'Crimson',
                      fontSize: 35,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              /* Cart content */
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _cartItemsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }

                    if (cartItems.isEmpty) {
                      return const Center(child: Text('No items in cart.'));
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(
                            8,
                          ).copyWith(top: 0, left: 220),
                          child: CheckboxListTile(
                            title: const Text('Select All'),
                            controlAffinity: ListTileControlAffinity.trailing,
                            tristate: true,
                            value: _selectAllValue,
                            onChanged: _toggleSelectAll,
                          ),
                        ),

                        Expanded(
                          child: ListView.builder(
                            itemCount: cartItems.length,
                            itemBuilder: (_, i) {
                              final item = cartItems[i];
                              final key = item['uiKey'];

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: CartItemWidget(
                                  item: item,
                                  isChecked: itemChecked[key]!,
                                  quantity: itemQuantity[key]!,
                                  onChanged: (u) async {
                                    await _handleItemChanged(u);
                                    setState(() {});
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isChecked;
  final int quantity;
  final ValueChanged<CartItemUpdate> onChanged;

  Future<void> deleteCartItem(BuildContext context, String itemId) async {
    try {
      final email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('email', isEqualTo: email)
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from cart')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove item')),
      );
    }
  }

  const CartItemWidget({
    super.key,
    required this.item,
    required this.isChecked,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final itemId = item['cartItemId'] ?? item['id'] ?? item['drugId'] ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0XFFF0ECE7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isChecked,
            onChanged: (v) {
              if (v == null) return;
              onChanged(
                CartItemUpdate(
                  uiKey: item['uiKey'],
                  productId: item['id'] ?? item['drugId'] ?? '',
                  isChecked: v,
                  quantity: quantity,
                  type: item['type'] ?? '',
                  symptom: item['symptom'] ?? '',
                  name: item['name'] ?? '',
                ),
              );
            },
          ),

          /* image */
          Padding(
            padding: const EdgeInsets.all(8),
            child:
                (item['image'] ?? '').toString().isNotEmpty
                    ? Image.network(
                      item['image'],
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                    : Image.asset(
                      'asset/image/weblogo.png',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
          ),
          const SizedBox(width: 10),

          /* details */
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] ?? 'Product',
                        maxLines: 2,
                        softWrap: true,
                        style: const TextStyle(color: Color(0xFF6B4518), fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        onChanged(
                          CartItemUpdate(
                            uiKey: item['uiKey'],
                            productId: item['id'] ?? item['drugId'] ?? '',
                            isChecked: isChecked,
                            quantity: 0,
                            type: item['type'] ?? '',
                            symptom: item['symptom'] ?? '',
                            name: item['name'] ?? '',
                          ),
                        );
                      },
                    ),

                  ],
                ),
                if (item['type'] == 'prescription') ...[
                  SizedBox(height: 15),
                  Text(
                    'Strength: ${item['strength'] ?? 'Unknown'}',
                    style: const TextStyle(
                      color: Color(0xFF6B4518),
                      fontSize: 16,
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                Text(
                  'RM${item['price'] ?? 0}',
                  style: const TextStyle(
                    color: Color(0xFF6B4518),
                    fontSize: 16,
                  ),
                ),

                /* quantity */
                Row(
                  children: [
                    const Text(
                      'Quantity:',
                      style: TextStyle(
                        color: Color(0xFF6B4518),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.brown),
                      onPressed: () {
                        if (item['type'] == 'prescription') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Prescription item quantity cannot be changed.',
                              ),
                            ),
                          );
                          return;
                        }
                        onChanged(
                          CartItemUpdate(
                            uiKey: item['uiKey'],
                            productId: item['id'] ?? item['drugId'] ?? '',
                            isChecked: isChecked,
                            quantity: quantity - 1,
                            type: item['type'] ?? '',
                            symptom: item['symptom'] ?? '',
                            name: item['name'] ?? '',
                          ),
                        );
                      },
                    ),
                    Text('$quantity'),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.brown),
                      onPressed: () {
                        if (item['type'] == 'prescription') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Prescription item quantity cannot be changed.',
                              ),
                            ),
                          );
                          return;
                        }
                        onChanged(
                          CartItemUpdate(
                            uiKey: item['uiKey'],
                            productId: item['id'] ?? item['drugId'] ?? '',
                            isChecked: isChecked,
                            quantity: quantity + 1,
                            type: item['type'] ?? '',
                            symptom: item['symptom'] ?? '',
                            name: item['name'] ?? '',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartItemUpdate {
  final String uiKey;
  final String productId;
  final bool isChecked;
  final int quantity;
  final String type;
  final String name;
  final String symptom;

  CartItemUpdate({
    required this.uiKey,
    required this.productId,
    required this.isChecked,
    required this.quantity,
    required this.type,
    required this.name,
    required this.symptom,
  });
}
