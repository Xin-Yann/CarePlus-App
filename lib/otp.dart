import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_history.dart';

class OTPPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String name;
  final String email;
  final String contact;
  final String address;
  final String otp;
  final double subtotal;
  final double shippingFee;
  final double total;

  const OTPPage({
    super.key,
    required this.cartItems,
    required this.name,
    required this.email,
    required this.contact,
    required this.address,
    required this.otp,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
  });

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final TextEditingController _otpController = TextEditingController();
  String _message = '';

  @override
  Future<void> _verifyOTP() async {
    if (_otpController.text.trim() == widget.otp) {
      setState(
        () => Text(
          _message,
          style: TextStyle(color: Color(0xFF6B4518), fontSize: 16),
        ),
      );

      final Map<String, DocumentSnapshot> productSnapshots = {};

      for (final item in widget.cartItems) {
        final productRef = FirebaseFirestore.instance
            .collection('uncontrolled_medicine')
            .doc('symptoms')
            .collection(item['symptom'])
            .doc(item['id']);

        final doc = await productRef.get();
        if (!doc.exists) {
          setState(() {
            print('cartItems → ${widget.cartItems}');
            print( 'Error: Product ${item['id']} in ${item['symptom']} does not exist.');
          });
          return;
        }

        productSnapshots[item['id']] = doc;

      }

      final counterRef = FirebaseFirestore.instance.collection('metadata').doc('orderCounter');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(counterRef);
        int lastOrderNumber = snapshot.exists ? (snapshot['lastOrderNumber'] ?? 0) : 0;
        final newOrderNumber = lastOrderNumber + 1;
        final orderId = 'ORD-${newOrderNumber.toString().padLeft(3, '0')}';

        if (snapshot.exists) {
          transaction.update(counterRef, {'lastOrderNumber': newOrderNumber});
        } else {
          transaction.set(counterRef, {'lastOrderNumber': newOrderNumber});
        }

        final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
        transaction.set(orderRef, {
          'orderId': orderId,
          'email': widget.email,
          'name': widget.name,
          'contact': widget.contact,
          'address': widget.address,
          'items': widget.cartItems,
          'subtotal': widget.subtotal,
          'shippingFee': widget.shippingFee,
          'total': widget.total,
          'paymentType': 'Credit Card',
          'orderStatus': 'Debit/Credit Card',
          'timestamp': Timestamp.now(),
        });

        //Deduct stock after make payment
        for (final item in widget.cartItems) {
          final qty = item['quantity'] ?? 1;
          final String productId = item['id'];
          final String symptom = item['symptom'];

          final productRef = FirebaseFirestore.instance
              .collection('uncontrolled_medicine')
              .doc('symptoms')
              .collection(symptom)
              .doc(productId);

          final snapshot = productSnapshots[productId]!;
          final currentStock = snapshot.get('stock');

          if (currentStock is! num || currentStock < qty) {
            throw Exception('Invalid or insufficient stock for $productId');
          }

          transaction.update(productRef, {
            'stock': FieldValue.increment(-qty),
          });
        }
      });

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => OrderHistory()),
      // );
    } else {
      setState(() => _message = 'Incorrect OTP. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),

      body: Padding(
        padding: const EdgeInsets.all(24.0).copyWith(top: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const SizedBox(width: 40),
                const Text(
                  'OTP VERIFICATION',
                  style: TextStyle(
                    color: Color(0xFF6B4518),
                    fontFamily: 'Crimson',
                    fontSize: 30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Center(
              child: Text(
                'Enter the OTP sent to ${widget.email}',
                style: const TextStyle(fontSize: 18, color: Color(0xFF6B4518)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Enter OTP',
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4518),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                ),
                child: const Text(
                  'Verify',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                _message,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
