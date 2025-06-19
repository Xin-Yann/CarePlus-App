import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    fetchUserCartItems().then((items) {
      setState(() {
        cartItems = items;
        for (var item in cartItems) {
          itemChecked.putIfAbsent(item['id'], () => false);
          itemQuantity.putIfAbsent(item['id'], () => item['quantity'] ?? 1);
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
          .get();

      return querySnapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      print('Error fetching cart items: $e');
      return [];
    }
  }

  void handleItemChanged(CartItemUpdate update) async {
    try {
      final String productType = update.type;
      final String productName = update.name;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('uncontrolled_medicine')
          .doc('symptoms')
          .collection(productType)
          .where('name', isEqualTo: productName)
          .limit(1)
          .get();

      print('productType: $productType');
      print('productName: $productName');
      print('Documents found: ${querySnapshot.docs.length}');

      int stock = 9999; // default large stock if not found

      if (querySnapshot.docs.isNotEmpty) {
        final docData = querySnapshot.docs.first.data();

        final rawStock = docData['stock'];
        if (rawStock is int) {
          stock = rawStock;
        } else if (rawStock is String) {
          stock = int.tryParse(rawStock) ?? 9999;
        }

        print('Stock found: $stock');
      } else {
        print('No stock document found for product "$productName"');
      }

      if (update.quantity > stock) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Stock Limit Exceeded'),
            content: Text('Cannot add more than $stock items of this product.'),
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

      if (update.quantity == 0) {
        // Confirm removal
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove item?'),
            content: const Text('Do you want to remove this product from the cart?'),
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

        if (confirmed == true) {
          setState(() {
            itemChecked.remove(update.id);
            itemQuantity.remove(update.id);
            cartItems.removeWhere((item) => item['id'] == update.id);
          });

          // Remove from Firestore cart collection
          await FirebaseFirestore.instance.collection('cart').doc(update.id).delete();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item removed from cart')),
          );
        }
      } else {
        // Update quantity and checked state
        setState(() {
          itemChecked[update.id] = update.isChecked;
          itemQuantity[update.id] = update.quantity;
          final idx = cartItems.indexWhere((item) => item['id'] == update.id);
          if (idx >= 0) {
            cartItems[idx]['quantity'] = update.quantity;
          }
        });

        // Update quantity in Firestore
        await FirebaseFirestore.instance
            .collection('cart')
            .doc(update.id)
            .update({'quantity': update.quantity});
      }
    } catch (e) {
      print('Error checking stock or updating cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating cart')),
      );
    }
  }

  double calculateTotal(List<Map<String, dynamic>> items) {
    double total = 0.0;
    for (var item in items) {
      final id = item['id'];
      final isChecked = itemChecked[id] ?? false;
      final qty = itemQuantity[id] ?? (item['quantity'] ?? 1);
      if (isChecked) {
        final priceStr = item['price'] ?? '0';
        final price = double.tryParse(priceStr.toString()) ?? 0.0;
        total += price * qty;
      }
    }
    return total;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _cartItemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final cartItems = snapshot.data ?? [];
            if (cartItems.isEmpty) {
              return const Center(child: Text('No items in cart.'));
            }

            return Padding(
              padding: const EdgeInsets.only(top: 35, left: 8, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
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

                  // Scrollable cart items list
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final id = item['id'];
                        itemChecked.putIfAbsent(id, () => false);
                        itemQuantity.putIfAbsent(id, () => item['quantity'] ?? 1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: CartItemWidget(
                            item: item,
                            isChecked: itemChecked[id]!,
                            quantity: itemQuantity[id]!,
                            onChanged: handleItemChanged,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Fixed total price + checkout button container
                  Container(
                    width: 500,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0XFFF0ECE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          'Total: \RM${calculateTotal(cartItems).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B4518),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            final selectedItems = cartItems.where((item) {
                              final id = item['id'];
                              return itemChecked[id] ?? false;
                            }).toList();

                            if (selectedItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select at least one item.')),
                              );
                              return;
                            }

                            // Proceed with selectedItems (navigate or confirm)
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B4518),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          ),
                          child: const Text(
                            'Proceed to Checkout',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
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
                id: item['id'],
                isChecked: isChecked,
                quantity: quantity,
                type: item['type'],
                name: item['name'],
              ));
            },
          ),
          item.containsKey('image')
              ? Image.network(item['image'], width: 70, height: 70, fit: BoxFit.cover)
              : Image.asset('asset/image/weblogo.png', width: 70, height: 70, fit: BoxFit.cover),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] ?? 'Product Name',
                  style: const TextStyle(color: Color(0xFF6B4518), fontSize: 16),
                ),
                Text(
                  '\RM${(item['price'] ?? 0)}',
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
                          id: item['id'],
                          isChecked: isChecked,
                          quantity: quantity - 1,
                          type: item['type'],
                          name: item['name'],
                        ));
                      },

                    ),
                    Text('$quantity'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      color: Colors.brown,
                      onPressed: () {
                        onChanged(CartItemUpdate(
                          id: item['id'],
                          isChecked: isChecked,
                          quantity: quantity + 1,
                          type: item['type'],
                          name: item['name'],
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
  final String id;
  final bool isChecked;
  final int quantity;
  final String type;
  final String name; // Add this field

  CartItemUpdate({
    required this.id,
    required this.isChecked,
    required this.quantity,
    required this.type,
    required this.name,  // require in constructor
  });
}

