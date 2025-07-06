import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class PharmacyAddProduct extends StatefulWidget {
  const PharmacyAddProduct({super.key});

  @override
  State<PharmacyAddProduct> createState() => _PharmacyAddProductState();
}

class _PharmacyAddProductState extends State<PharmacyAddProduct> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  String imageUrl = '';
  String? selectedCategory;
  io.File? selectedImage;

  final List<String> categories = [
    'Allergy',
    'Anxiety',
    'Asthma',
    'Cough',
    'Diarrhoea',
    'Fever',
    'Heartburn',
    'Nasal Congestion',
    'Pain',
    'Skin Allergy'
  ];

  Future<void> pickAndUploadImage() async {
    const imgbbApiKey = 'e6f550d58c3ce65d422f1483a8b92ef7';

    if (kIsWeb) {
      final uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.first.then((event) async {
        final file = uploadInput.files?.first;
        if (file == null) return;

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        await reader.onLoadEnd.first;

        final bytes = reader.result as Uint8List;
        final base64Image = base64Encode(bytes);

        final response = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
          body: {'image': base64Image},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            imageUrl = data['data']['url'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image upload failed')),
          );
        }
      });
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final imageTemp = io.File(picked.path);
      setState(() {
        selectedImage = imageTemp;
      });

      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          imageUrl = data['data']['url'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload failed')),
        );
      }
    }
  }

  Future<void> addProduct() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final price = double.tryParse(priceController.text) ?? 0.0;
    final stock = int.tryParse(stockController.text) ?? 0;

    if (selectedCategory == null ||
        name.isEmpty ||
        description.isEmpty ||
        imageUrl.isEmpty ||
        price <= 0 ||
        stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    final counterRef =
    FirebaseFirestore.instance.collection('metadata').doc('productCounter');
    final snapshot = await counterRef.get();

    int lastId = 0;
    if (snapshot.exists && snapshot.data()?['lastProductId'] != null) {
      lastId = snapshot.data()!['lastProductId'];
    }

    final newId = lastId + 1;
    final productId = 'UM$newId';

    await FirebaseFirestore.instance
        .collection('uncontrolled_medicine')
        .doc('symptoms')
        .collection(selectedCategory!)
        .doc(productId)
        .set({
      'id': productId,
      'category': selectedCategory,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image': imageUrl,
    });

    await counterRef.set({'lastProductId': newId});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added successfully')),
    );

    // Update dropdown
    Navigator.pop(context, selectedCategory);
  }

  InputDecoration get inputDecoration => const InputDecoration(
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B4518);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        title: const Text(
          'Add Product',
          style: TextStyle(
            fontFamily: 'Crimson',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF7F2EF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (!kIsWeb && selectedImage != null)
                    ? Image.file(selectedImage!, fit: BoxFit.cover)
                    : imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : const Icon(Icons.broken_image, size: 100),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: pickAndUploadImage,
              icon: const Icon(Icons.image),
              label: const Text("Upload Image"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              decoration: inputDecoration.copyWith(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: inputDecoration.copyWith(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56, maxHeight: 150),
              child: SingleChildScrollView(
                child: TextField(
                  controller: descriptionController,
                  maxLines: null,
                  decoration: inputDecoration.copyWith(labelText: 'Description'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: inputDecoration.copyWith(labelText: 'Price (RM)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: inputDecoration.copyWith(labelText: 'Stock'),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: addProduct,
                icon: const Icon(Icons.check),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brown,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
