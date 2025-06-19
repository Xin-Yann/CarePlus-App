import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'product_details.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Product extends StatelessWidget {
  final String symptom;

  const Product({super.key, required this.symptom});

  String formatPrice(dynamic priceValue) {
    if (priceValue == null) return 'RM 0.00';

    if (priceValue is num) {
      return 'RM ${priceValue.toStringAsFixed(2)}';
    }

    if (priceValue is String) {
      final parsed = double.tryParse(priceValue.replaceAll(',', '.'));
      if (parsed != null) {
        return 'RM ${parsed.toStringAsFixed(2)}';
      }
    }

    return 'RM 0.00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4518),
        foregroundColor: Colors.white,
        title: Text(
          '$symptom Products',
          style: const TextStyle(
            fontFamily: 'Crimson',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('uncontrolled_medicine')
            .doc('symptoms')
            .collection(symptom)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading products.'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final product = docs[index];
              final image = product['image'] ?? '';
              final name = product['name'] ?? '';
              final price = product['price'];
              final description =
                  product['description'] ?? 'No description available';

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F2EF),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade400,
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetails(
                          name: name,
                          image: image,
                          description: description,
                          price: formatPrice(price),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          image,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 80),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 120,
                          child: Stack(
                            children: [
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Crimson',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      formatPrice(price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6B4518),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('You must be logged in to add to cart')),
                                      );
                                      return;
                                    }

                                    final cartRef = FirebaseFirestore.instance.collection('cart');

                                    try {
                                      // Find cart doc for this user
                                      final query = await cartRef.where('email', isEqualTo: user.email).limit(1).get();

                                      if (query.docs.isEmpty) {
                                        // No cart doc for user, create new doc with products array containing this product
                                        await cartRef.add({
                                          'email': user.email,
                                          'products': [
                                            {
                                              'name': name,
                                              'image': image,
                                              'description': description,
                                              'price': price,
                                              'quantity': 1,
                                            }
                                          ],
                                          'timestamp': Timestamp.now(),
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('$name added to cart')),
                                        );
                                      } else {
                                        // Cart doc exists
                                        final doc = query.docs.first;
                                        final data = doc.data();

                                        List products = List.from(data['products'] ?? []);

                                        // Check if product exists in products array
                                        final productIndex = products.indexWhere((p) => p['name'] == name);

                                        if (productIndex != -1) {
                                          // Product exists, update quantity
                                          final currentQty = products[productIndex]['quantity'] ?? 0;
                                          products[productIndex]['quantity'] = currentQty + 1;
                                        } else {
                                          // Product not exists, add new
                                          products.add({
                                            'name': name,
                                            'image': image,
                                            'description': description,
                                            'price': price,
                                            'quantity': 1,
                                          });
                                        }

                                        // Update the cart doc
                                        await doc.reference.update({
                                          'products': products,
                                          'timestamp': Timestamp.now(),
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('$name added/updated in cart')),
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
                                    backgroundColor: const Color(0xFF6B4518),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Add to Cart'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
