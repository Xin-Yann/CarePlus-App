import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pharmacy_product_details.dart';
import 'pharmacy_add_product.dart';

class PharmacyManageProduct extends StatefulWidget {
  const PharmacyManageProduct({super.key});

  @override
  State<PharmacyManageProduct> createState() => _PharmacyManageProductState();
}

class _PharmacyManageProductState extends State<PharmacyManageProduct> {
  final List<Map<String, String>> productCategories = [
    {'name': 'Allergy'},
    {'name': 'Anxiety'},
    {'name': 'Asthma'},
    {'name': 'Cough'},
    {'name': 'Diarrhoea'},
    {'name': 'Fever'},
    {'name': 'Heartburn'},
    {'name': 'Nasal Congestion'},
    {'name': 'Pain'},
    {'name': 'Skin Allergy'},
  ];

  String? selectedCategory;

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
  void initState() {
    super.initState();
    selectedCategory = productCategories.first['name'];
  }

  @override
  Widget build(BuildContext context) {
    final brown = const Color(0xFF6B4518);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Color(0xFF6B4518)),
        onPressed: () async {
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => const PharmacyAddProduct(),
            ),
          );

          if (result != null && result.isNotEmpty) {
            setState(() {
              selectedCategory = result;
            });
          }
        },
      ),
      backgroundColor: const Color(0xFFE1D9D0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4518),
        foregroundColor: Colors.white,
        title: const Text(
          'Manage Products',
          style: TextStyle(
            fontFamily: 'Crimson',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade400),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCategory,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: productCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat['name'],
                      child: Text(cat['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: selectedCategory == null
                ? const Center(child: Text('Select a category.'))
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('uncontrolled_medicine')
                  .doc('symptoms')
                  .collection(selectedCategory!)
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
                    final data = product.data() as Map<String, dynamic>;
                    final image = data['image'] ?? '';
                    final name = data['name'] ?? '';
                    final price = data['price'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
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
                              builder: (_) => PharmacyProductDetails(
                                productDoc: product,
                                category: selectedCategory!,
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
                              child: SizedBox(
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
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PharmacyProductDetails(
                                                productDoc: product,
                                                category: selectedCategory!,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit, size: 18),
                                        label: const Text('Edit'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: brown,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
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
          ),
        ],
      ),
    );
  }
}
