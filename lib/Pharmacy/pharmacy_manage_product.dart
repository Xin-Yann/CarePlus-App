import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pharmacy_product_details.dart';

class PharmacyManageProduct extends StatefulWidget {
  const PharmacyManageProduct({super.key});

  @override
  State<PharmacyManageProduct> createState() => _PharmacyManageProductState();
}

class _PharmacyManageProductState extends State<PharmacyManageProduct> {
  final List<Map<String, String>> productCategories = [
    {'name': 'Allergy', 'image': 'asset/image/allergy.png'},
    {'name': 'Anxiety', 'image': 'asset/image/anxiety.png'},
    {'name': 'Asthma', 'image': 'asset/image/asthma.png'},
    {'name': 'Cough', 'image': 'asset/image/cough.png'},
    {'name': 'Diarrhoea', 'image': 'asset/image/diarrhoea.png'},
    {'name': 'Fever', 'image': 'asset/image/fever.png'},
    {'name': 'Heartburn', 'image': 'asset/image/heartburn.png'},
    {'name': 'Nasal Congestion', 'image': 'asset/image/nasal_congestion.png'},
    {'name': 'Pain', 'image': 'asset/image/pain.png'},
    {'name': 'Skin Allergy', 'image': 'asset/image/skin_allergy.png'},
  ];

  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = productCategories.first['name'];
  }

  @override
  Widget build(BuildContext context) {
    final brown = const Color(0xFF6B4518);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EF),
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Text('Manage Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: selectedCategory,
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
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
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
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final image = data['image'] ?? '';
                    final name = data['name'] ?? '';
                    final price = data['price'] ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: image != null && image.isNotEmpty
                            ? Image.network(image, width: 60, height: 60, fit: BoxFit.cover)
                            : const Icon(Icons.image_not_supported),
                        title: Text(name),
                        subtitle: Text('RM ${price.toStringAsFixed(2)}'),
                        trailing: const Icon(Icons.edit),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PharmacyProductDetails(
                                productDoc: docs[index],
                                category: selectedCategory!,
                              ),
                            ),
                          );
                        },
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