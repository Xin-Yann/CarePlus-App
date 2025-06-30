import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyProductDetails extends StatefulWidget {
  final DocumentSnapshot productDoc;
  final String category;

  const PharmacyProductDetails({
    super.key,
    required this.productDoc,
    required this.category,
  });

  @override
  State<PharmacyProductDetails> createState() => _PharmacyProductDetailsState();
}

class _PharmacyProductDetailsState extends State<PharmacyProductDetails> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late String imageUrl;

  @override
  void initState() {
    super.initState();
    final data = widget.productDoc.data() as Map<String, dynamic>;
    nameController = TextEditingController(text: data['name']);
    descriptionController = TextEditingController(text: data['description']);
    priceController = TextEditingController(text: data['price'].toString());
    imageUrl = data['image'] ?? '';
  }

  void updateProduct() async {
    await widget.productDoc.reference.update({
      'name': nameController.text,
      'description': descriptionController.text,
      'price': double.tryParse(priceController.text) ?? 0.0,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product updated successfully')),
    );
  }

  void deleteProduct() async {
    await widget.productDoc.reference.delete();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B4518);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Text('Product Details'),
      ),
      backgroundColor: const Color(0xFFF7F2EF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl, height: 200, fit: BoxFit.cover)
            else
              const Icon(Icons.broken_image, size: 100),
            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: deleteProduct,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: updateProduct,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}