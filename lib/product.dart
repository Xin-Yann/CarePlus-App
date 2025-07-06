import 'package:careplusapp/cart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'product_details.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Product extends StatelessWidget {
  final String symptom;
  final String type;
  const Product({super.key, required this.symptom, required this.type});

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
          onPressed: () => Navigator.pop(context, '/home'),
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
              final id = product['id'];
              final image = product['image'] ?? '';
              final name = product['name'] ?? '';
              final price = product['price'];
              final description =
                  product['description'] ?? 'No description available';
              final stock = product['stock'];
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
                          id:id,
                          name: name,
                          image: image,
                          description: description,
                          price: formatPrice(price),
                          symptom: symptom,
                          type: type,
                          stock: stock,
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
                                    onPressed:stock > 0
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

                                        if (userCartQuery.docs.isEmpty) {
                                          // First time: create cart document with initial item
                                          await cartRef.add({
                                            'email': userEmail,
                                            'timestamp': Timestamp.now(),
                                            'items': [
                                              {
                                                'id':id,
                                                'name': name,
                                                'image': image,
                                                'description': description,
                                                'price': price,
                                                'quantity': 1,
                                                'symptom': symptom,
                                                'type': 'uncontrolled'
                                              }
                                            ],
                                          });

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('$name added to cart')),
                                          );

                                          Navigator.push(context, MaterialPageRoute(builder: (context) => Cart()));

                                        } else {
                                          final cartDoc = userCartQuery.docs.first;
                                          final docRef = cartDoc.reference;
                                          final data = cartDoc.data() as Map<String, dynamic>;
                                          final items = List<Map<String, dynamic>>.from(data['items'] ?? []);


                                          final index = items.indexWhere((item) => item['name'] == name);

                                          if (index >= 0) {
                                            // Product already in cart, update quantity
                                            items[index]['quantity'] = (items[index]['quantity'] ?? 0) + 1;
                                            items[index]['timestamp'] = Timestamp.now();
                                          } else {
                                            // Add new product to cart
                                            items.add({
                                              'id':id,
                                              'name': name,
                                              'image': image,
                                              'description': description,
                                              'price': price,
                                              'quantity': 1,
                                              'timestamp': Timestamp.now(),
                                              'symptom': symptom,
                                              'type': 'uncontrolled'
                                            });
                                          }

                                          await docRef.update({
                                            'items': items,
                                            'timestamp': Timestamp.now(),
                                          });

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('$name added/updated in cart')),
                                          );

                                          Navigator.push(context, MaterialPageRoute(builder: (context) => Cart()));
                                        }
                                      } catch (e) {
                                        print('Error updating cart: $e');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to update cart')),
                                        );
                                      }
                                    }:null,
                                    style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6B4518),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: Text(stock > 0 ? 'Add to Cart' : 'Out of Stock'),
                                )

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
