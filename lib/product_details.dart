import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetails extends StatefulWidget {
  final String name;
  final String image;
  final String description;
  final String price;

  const ProductDetails({
    super.key,
    required this.name,
    required this.image,
    required this.description,
    required this.price,
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
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Add to Cart'),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You must be logged in to add to cart')),
                    );
                    return;
                  }

                  try {
                    // Query for existing cart item with same product name and same user email
                    final query = await FirebaseFirestore.instance
                        .collection('cart')
                        .where('email', isEqualTo: user.email)
                        .where('name', isEqualTo: widget.name)
                        .limit(1)
                        .get();

                    if (query.docs.isNotEmpty) {
                      // Existing item found - update quantity by adding new quantity
                      final doc = query.docs.first;
                      final currentQty = doc['quantity'] ?? 0;

                      await doc.reference.update({
                        'quantity': currentQty + quantity,
                        'timestamp': Timestamp.now(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${widget.name} is added into cart')),
                      );
                    } else {
                      // No existing item - add new doc with quantity
                      await FirebaseFirestore.instance.collection('cart').add({
                        'name': widget.name,
                        'image': widget.image,
                        'description': widget.description,
                        'price': widget.price,
                        'email': user.email,
                        'quantity': quantity,
                        'timestamp': Timestamp.now(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${widget.name} is added into cart')),
                      );
                    }
                  } catch (e) {
                    print('Error adding/updating cart: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add item to cart')),
                    );
                  }
                },

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
