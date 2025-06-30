import 'package:flutter/material.dart';
import 'product.dart';

class ProductCategory extends StatelessWidget {
  const ProductCategory({super.key});

  final List<Map<String, dynamic>> categories = const [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: Column(
        children: [
          // Custom AppBar
          Padding(
            padding: const EdgeInsets.only(
                top: 50.0, left: 16.0, right: 16.0, bottom: 20.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/home'),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Color(0xFF6B4518),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'PRODUCT',
                        style: TextStyle(
                          color: Color(0xFF6B4518),
                          fontFamily: 'Crimson',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'CATEGORIES',
                        style: TextStyle(
                          color: Color(0xFF6B4518),
                          fontFamily: 'Crimson',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Grid content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: categories.map((category) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              Product(symptom: category['name']),
                        ),
                      );
                    },
                    child: Container(
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            category['image'],
                            height: 60,
                            width: 60,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            category['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Crimson',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
