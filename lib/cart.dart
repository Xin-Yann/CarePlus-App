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
  List<Map<String, dynamic>> cartItems = [];
  Map<String, bool> itemChecked = {};
  Map<String, int> itemQuantity = {};

  @override
  void initState() {
    super.initState();

    // ✅ Initialize the future to avoid LateInitializationError
    _cartItemsFuture = fetchUserCartItems();

    // Preload itemChecked and itemQuantity after fetching
    _cartItemsFuture.then((items) {
      setState(() {
        cartItems = items;
        for (var item in cartItems) {
          itemChecked[item['id']] = false;
          itemQuantity[item['id']] = item['quantity'] ?? 1;
        }
      });
    });
  }

  Future<List<Map<String, dynamic>>> fetchUserCartItems() async {
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) {
        print('No logged-in user found');
        return [];
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('cart')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      final doc = querySnapshot.docs.first;
      final docId = doc.id;
      final docData = doc.data();
      final items = List<Map<String, dynamic>>.from(docData['items'] ?? []);

      // Inject `cartId` and unique `id` per item using index
      return List.generate(items.length, (index) {
        final item = items[index];
        return {
          'uiKey': '$docId-$index', // unique id for UI logic
          'cartDocId': docId,     // to update Firestore later
          ...item,
        };
      });
    } catch (e) {
      print('Error fetching cart items: $e');
      return [];
    }
  }

  void handleItemChanged(CartItemUpdate update) async {
    try {
      final String productType = update.type;
      final String productName = update.name;

      // Step 1: Check stock from uncontrolled_medicine
      final querySnapshot = await FirebaseFirestore.instance
          .collection('uncontrolled_medicine')
          .doc('symptoms')
          .collection(productType)
          .where('name', isEqualTo: productName)
          .limit(1)
          .get();

      int stock = 9999;
      if (querySnapshot.docs.isNotEmpty) {
        final docData = querySnapshot.docs.first.data();
        final rawStock = docData['stock'];
        if (rawStock is int) {
          stock = rawStock;
        } else if (rawStock is String) {
          stock = int.tryParse(rawStock) ?? 9999;
        }
      }

      // Step 2: Reject if quantity exceeds stock
      if (update.quantity > stock) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Stock Limit Exceeded'),
            content: Text('Cannot add more than $stock items of this product.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
        return;
      }

      // Step 3: Extract doc ID and item index from update.id
      final parts = update.uiKey.split('-');
      final cartDocId = parts[0];
      final itemIndex = int.tryParse(parts[1] ?? '');

      if (itemIndex == null) {
        print('Invalid item index');
        return;
      }

      final docRef = FirebaseFirestore.instance.collection('cart').doc(cartDocId);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        print('Cart document not found');
        return;
      }

      // Step 4: Get the items array and modify
      List<Map<String, dynamic>> items =
      List<Map<String, dynamic>>.from(snapshot.data()?['items'] ?? []);

      if (itemIndex < 0 || itemIndex >= items.length) {
        print('Item index out of bounds');
        return;
      }

      if (update.quantity == 0) {
        // Step 5: Handle item removal
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove item?'),
            content: const Text('Do you want to remove this product from the cart?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
            ],
          ),
        );

        if (confirmed == true) {
          items.removeAt(itemIndex);
          await docRef.update({'items': items});

          setState(() {
            itemChecked.remove(update.uiKey);
            itemQuantity.remove(update.uiKey);
            cartItems.removeWhere((item) => item['uiKey'] == update.uiKey);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item removed from cart')),
          );
        }
      } else {
        // Step 6: Update quantity
        items[itemIndex]['quantity'] = update.quantity;
        await docRef.update({'items': items});

        setState(() {
          itemChecked[update.uiKey] = update.isChecked;
          itemQuantity[update.uiKey] = update.quantity;
          final idx = cartItems.indexWhere((item) => item['uiKey'] == update.uiKey);
          if (idx >= 0) cartItems[idx]['quantity'] = update.quantity;
        });
      }
    } catch (e) {
      print('Error updating cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating cart')),
      );
    }
  }


  double calculateTotal(List<Map<String, dynamic>> items) {
    double total = 0.0;
    for (var item in items) {
      final key = item['uiKey'];
      final isChecked = itemChecked[key] ?? false;
      final qty = itemQuantity[key] ?? (item['quantity'] ?? 1);
      if (isChecked) {
        final price = double.tryParse(item['price'].toString()) ?? 0.0;
        total += price * qty;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      bottomNavigationBar: // Total
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0XFFF0ECE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 15),
            Text(
              'Total: RM${calculateTotal(cartItems).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4518),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final selectedItems = cartItems.where((item) {
                  final id = item['uiKey'];
                  return itemChecked[id] ?? false;

                }).toList();

                if (selectedItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one item.')),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutPage(checkedItems: selectedItems),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4518),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
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
              // Header: Always visible
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
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

              // Cart Items Section
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _cartItemsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const Center(child: Text('No items in cart.'));
                    }

                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final key = item['uiKey'] ?? 'unknown-$index';  // fallback to avoid null
                        itemChecked.putIfAbsent(key, () => false);
                        itemQuantity.putIfAbsent(key, () => item['quantity'] ?? 1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: CartItemWidget(
                            item: item,
                            isChecked: itemChecked[key]!,
                            quantity: itemQuantity[key]!,
                            onChanged: handleItemChanged,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
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

  const CartItemWidget({
    super.key,
    required this.item,
    required this.isChecked,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        color: const Color(0XFFF0ECE7),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
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
            onChanged: (bool? newValue) {
              onChanged(CartItemUpdate(
                uiKey: item['uiKey'],
                productId: item['id'],
                isChecked: newValue ?? false,
                quantity: quantity,
                type: item['symptom'] ?? '',
                name: item['name'] ?? '',
              ));
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: item.containsKey('image') && item['image'] != null && item['image'].toString().isNotEmpty
                ? Image.network(item['image'], width: 70, height: 70, fit: BoxFit.cover)
                : Image.asset('asset/image/weblogo.png', width: 70, height: 70, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Product Name',
                  style: const TextStyle(color: Color(0xFF6B4518), fontSize: 16),
                ),
                const SizedBox(height: 15),
                Text(
                  'RM${item['price'] ?? 0}',
                  style: const TextStyle(color: Color(0xFF6B4518), fontSize: 16),
                ),
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
                      icon: const Icon(Icons.remove),
                      color: Colors.brown,
                      onPressed: () {
                        onChanged(CartItemUpdate(
                          uiKey: item['uiKey'],
                          productId: item['id'],
                          isChecked: isChecked,
                          quantity: quantity - 1,
                          type: item['symptom'] ?? '',
                          name: item['name'] ?? '',
                        ));

                      },
                    ),
                    Text('$quantity'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      color: Colors.brown,
                      onPressed: () {
                        onChanged(CartItemUpdate(
                          uiKey: item['uiKey'],
                          productId: item['id'],
                          isChecked: isChecked,
                          quantity: quantity + 1,
                          type: item['symptom'] ?? '',
                          name: item['name'] ?? '',
                        ));
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

  CartItemUpdate({
    required this.uiKey,
    required this.productId,
    required this.isChecked,
    required this.quantity,
    required this.type,
    required this.name,
  });
}

