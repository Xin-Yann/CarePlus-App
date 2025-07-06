import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart.dart';

class ProductDetails extends StatefulWidget {
  final String name;
  final String image;
  final String description;
  final String price;
  final String symptom;
  final String id;
  final String type;
  final int stock;

  const ProductDetails({
    super.key,
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.price,
    required this.symptom,
    required this.stock,
    required this. type,
  });

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  int quantity = 1;

  void incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void decrementQuantity() {
    setState(() {
      if (quantity > 1) quantity--;
    });
  }

  @override
  Widget build(BuildContext context) {
    const brownColor = Color(0xFF6B4518);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EF),
      appBar: AppBar(
        backgroundColor: brownColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Product Details',
          style: TextStyle(
            fontFamily: 'Crimson',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                widget.image,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 100),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Crimson',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.price,
              style: const TextStyle(
                fontSize: 20,
                color: brownColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Quantity:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: decrementQuantity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brownColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Icon(Icons.remove, size: 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: incrementQuantity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brownColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Icon(Icons.add, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: widget.stock > 0
                    ? const Icon(Icons.shopping_cart)
                    : const SizedBox.shrink(),

                label: Text(widget.stock > 0 ? 'Add to Cart' : 'Out of Stock'),
                onPressed: widget.stock > 0
                    ?  () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You must be logged in to add to cart')),
                    );
                    return;
                  }

                  final cartRef = FirebaseFirestore.instance.collection('cart');
                  final userEmail = user.email;

                  try {
                    final userCartQuery = await cartRef.where('email', isEqualTo: userEmail).limit(1).get();
                    final priceOnly = widget.price
                        .replaceAll(RegExp(r'RM', caseSensitive: false), '')
                        .replaceAll(RegExp(r'[^\d.]'), '')
                        .trim();

                    print('widget.price = "${widget.price}"');
                    print('Cleaned price = "$priceOnly"');


                    if (userCartQuery.docs.isEmpty) {
                      await cartRef.add({
                        'email': userEmail,
                        'items': [
                          {
                            'id': widget.id,
                            'name': widget.name,
                            'image': widget.image,
                            'description': widget.description,
                            'price': priceOnly,
                            'quantity': 1,
                            'timestamp': Timestamp.now(),
                            'symptom': widget.symptom,
                            'type': 'uncontrolled'
                          }
                        ],
                        'timestamp': Timestamp.now(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${widget.name} added to cart')),
                      );

                      Navigator.push(context, MaterialPageRoute(builder: (context) => Cart()));
                    } else {
                      final cartDoc = userCartQuery.docs.first;
                      final docRef = cartDoc.reference;
                      final data = cartDoc.data() as Map<String, dynamic>;
                      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
                      final index = items.indexWhere((item) => item['name'] == widget.name);

                      if (index >= 0) {
                        // Product already in cart, update quantity
                        items[index]['quantity'] = (items[index]['quantity'] ?? 0) + 1;
                        items[index]['timestamp'] = Timestamp.now();
                      } else {
                        // Add new product to cart
                        items.add({
                          'id': widget.id,
                          'name': widget.name,
                          'image': widget.image,
                          'description': widget.description,
                          'price': priceOnly,
                          'quantity': 1,
                          'timestamp': Timestamp.now(),
                          'symptom': widget.symptom,
                          'type': 'uncontrolled'
                        });
                      }

                      await docRef.update({
                        'items': items,
                        'timestamp': Timestamp.now(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${widget.name} added/updated in cart')),
                      );

                      Navigator.push(context, MaterialPageRoute(builder: (context) => Cart()));
                    }
                  } catch (e) {
                    print('Error updating cart: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update cart')),
                    );
                  }
                } : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor: brownColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
