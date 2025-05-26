import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'footer.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _HomeState();
}

class _HomeState extends State<Cart> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _agreeToTerms = false;
  int quantity = 1;

  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0).copyWith(top: 60.0),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/home');
                      },
                      icon: Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0).copyWith(left: 35),
                      child: Text(
                        'SHOPPING CART',
                        style: TextStyle(
                          color: const Color(0xFF6B4518),
                          fontFamily: 'Crimson',
                          fontSize: 35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(
                  horizontal: 5.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0XFFF0ECE7),
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                         Checkbox(
                            value: _agreeToTerms,
                            onChanged: (bool? newValue) {
                              setState(() {
                                _agreeToTerms = newValue ?? false;
                              });
                            },
                          ),

                        Text(
                          'Pharmacy Name',
                          style: const TextStyle(
                            color: const Color(0xFF6B4518),
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (bool? newValue) {
                            setState(() {
                              _agreeToTerms = newValue ?? false;
                            });
                          },
                        ),

                        // Product Image
                        Image.asset(
                          'asset/image/weblogo.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),

                        // Spacer between image and info
                        SizedBox(width: 10),

                        // Expanded column with name, price, and quantity controls
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pharmacy Name',
                                style: const TextStyle(
                                  color: Color(0xFF6B4518),
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Product Price',
                                style: const TextStyle(
                                  color: Color(0xFF6B4518),
                                  fontSize: 16,
                                ),
                              ),

                              // Push quantity controls slightly down
                              SizedBox(height: 8),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.indeterminate_check_box),
                                    color: Colors.brown,
                                    iconSize: 25,
                                    onPressed: () {
                                      if (quantity > 1) {
                                        setState(() {
                                          quantity--;
                                        });
                                      }
                                      if (quantity == 1) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                "Are you sure you want to remove the product?",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 25,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Crimson',
                                                  color: const Color(0XFF4B352A),
                                                ),
                                              ),
                                              actionsAlignment: MainAxisAlignment.center,
                                              actions: [
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: Text("Cancel"),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0XFF4B352A),
                                                    foregroundColor: Colors.white,
                                                    textStyle: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Crimson',
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();

                                                    // Add remove logic here
                                                  },
                                                  child: Text("Continue"),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0XFF4B352A),
                                                    foregroundColor: Colors.white,
                                                    textStyle: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Crimson',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    },
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_box),
                                    color: Colors.brown,
                                    iconSize: 25,
                                    onPressed: () {
                                      setState(() {
                                        quantity++;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }
}
