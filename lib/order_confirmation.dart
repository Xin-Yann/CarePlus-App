import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> checkedItems;

  const CheckoutPage({super.key, required this.checkedItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController name = TextEditingController();
  final TextEditingController contact = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController address = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final usersRef = FirebaseFirestore.instance.collection('users');

      final querySnapshot =
          await usersRef.where('email', isEqualTo: user.email).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();

        setState(() {
          name.text = data['name'] ?? '';
          contact.text = data['contact'] ?? '';
          email.text = data['email'] ?? '';
          address.text = data['address'] ?? '';
        });
      }
    }
  }

  double calculateShippingFee(double total) {
    return total > 100.0 ? 0.0 : 10.0;
  }

  double calculateSubtotal(List<Map<String, dynamic>> items) {
    double total = 0.0;
    for (var item in items) {
      final quantity = item['quantity'] ?? 1;
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      total += price * quantity;
    }
    return total;
  }

  double calculateTotal(List<Map<String, dynamic>> items) {
    double total = 0.0;
    for (var item in items) {
      final quantity = item['quantity'] ?? 1;
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      total += price * quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = calculateSubtotal(widget.checkedItems);
    final shippingFee = calculateShippingFee(subtotal);
    final grandTotal = subtotal + shippingFee;

    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0ECE7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Subtotal: RM${subtotal.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, color: Color(0xFF6B4518)),
            ),
            const SizedBox(height: 8),
            Text(
              'Shipping: RM${shippingFee.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, color: Color(0xFF6B4518)),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: RM${grandTotal.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4518),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                // Show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Proceeding to payment...")),
                );

                // Navigate to PaymentPage and pass cartItems
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PaymentPage(
                          cartItems: widget.checkedItems,
                          name: name.text,
                          email: email.text,
                          contact: contact.text,
                          address: address.text,
                        ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4518),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Make Payment',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0).copyWith(top: 70),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(width: 80),
                const Text(
                  'CHECKOUT',
                  style: TextStyle(
                    color: Color(0xFF6B4518),
                    fontFamily: 'Crimson',
                    fontSize: 35,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: 400,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0XFFF0ECE7),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shipping Details:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4518),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text("Name: ${name.text}"),
                  const SizedBox(height: 8),
                  Text("Email: ${email.text}"),
                  const SizedBox(height: 8),
                  Text("Contact: ${contact.text}"),
                  const SizedBox(height: 8),
                  Text("Address: ${address.text}"),
                ],
              ),
            ),

            //const Divider(thickness: 1),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
              child: Text(
                'Selected Items:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4518),
                ),
              ),
            ),
            SingleChildScrollView(
              child: SizedBox(
                height: 300,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: widget.checkedItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.checkedItems[index];
                    return Card(
                      color: const Color(0xFFF0ECE7),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Container(
                        height: 120,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: Image.network(
                                item['image'] ?? '',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported),
                              ),
                              title: Text(item['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  Text(
                                    'Quantity: ${item['quantity']}',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
