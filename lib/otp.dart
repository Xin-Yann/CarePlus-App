import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'order_history.dart';
import 'dart:math';
import 'package:http/http.dart' as http;

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
  final DateTime expiry;

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
    required this.expiry,
  });

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final TextEditingController _otpController = TextEditingController();
  String _message = '';
  late DateTime _expiry;
  late String _otp;
  late DateTime _expiryTime;
  Timer? _cooldownTimer;
  bool _canResend = true;
  static const int _maxResends = 3;
  int  _resendCount = 0;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override

  Map<String, dynamic>? pharmacyData;
  String? _pharmacyState;
  String? _pharmacyId;
  Map<String, List<String>> stateDocIds = {
    "Perlis": ["P1", "P2", "P3"],
    "Kedah": ["P4", "P5", "P6"],
    "Penang": ["P7", "P8", "P9"],
    "Perak": ["P10", "P11", "P12"],
    "Selangor": ["P13", "P14", "P15"],
    "Negeri Sembilan": ["P16", "P17", "P18"],
    "Melaka": ["P19", "P20", "P21"],
    "Kelantan": ["P22", "P23", "P24"],
    "Terengganu": ["P25", "P26", "P27"],
    "Pahang": ["P28", "P29", "P30"],
    "Johor": ["P31", "P32", "P33"],
    "Sabah": ["P34", "P35", "P36"],
    "Sarawak": ["P37", "P38", "P39"],
  };

  Future<void> fetchPharmacyData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      print('User is not logged in or missing email.');
      return;
    }

    final Useremail = user.email!;


    for (final entry in stateDocIds.entries) {
      final state = entry.key;
      for (final id in entry.value) {
        final doc = await FirebaseFirestore.instance
            .collection('pharmacy')
            .doc('state')
            .collection(state)
            .doc(id)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('email')) {
            print('Checking ${state} / ${id} -> Email: ${data['email']}');
            if (data['email'] == Useremail) {
              setState(() {
                _pharmacyState = state;
                _pharmacyId = id;
              });
              print('Match found in ${state} / ${id}');
              return;
            }
          }
        }

      }
    }

    print('Pharmacy record not found.');
  }

  String? _extractState(String address) {
    for (final state in stateDocIds.keys) {
      if (address.toLowerCase().contains(state.toLowerCase())) {
        return state;
      }
    }
    return null;
  }

  String? _assignPharmacyId(String address) {
    final state = _extractState(address);
    if (state == null) return null;

    final ids = stateDocIds[state];
    if (ids == null || ids.isEmpty) return null;

    // Simple round‑robin: spread the load fairly each time an order comes in.
    final index = DateTime.now().millisecondsSinceEpoch % ids.length;
    return ids[index];
  }

  String generateOTP() {
    final random = Random();
    _otp = (100000 + random.nextInt(900000)).toString();
    _expiryTime = DateTime.now().add(const Duration(minutes: 10));
    return _otp;
  }

  Future<void> sendOtpToEmail({
    required String email,
    required String name,
    required String otp,
    required String expiry,
  }) async {
    const serviceId = 'service_ug3yy5l';
    const templateId = 'template_mtee97c';
    const userId    = 'Zp05uSYdpxgcXjWlR';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'user_email': email,
          'user_name' : name,
          'otp'       : otp,
          'expiry'    : expiry,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP email: ${response.body}');
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    // Increment first; if it exceeds the limit, cancel.
    _resendCount++;
    if (_resendCount > _maxResends) {
      _cancelPayment();            // 🚫 roll back flow
      return;
    }
    _otp = generateOTP();
    _expiry = _expiryTime;

    final formattedExpiry =
    DateFormat('hh:mm a, MMM dd').format(_expiry);

    await sendOtpToEmail(
      email: widget.email,
      name: widget.name,
      otp: _otp,
      expiry: formattedExpiry,
    );

    _startResendCooldown();
    setState(() => _message = 'A new OTP has been sent to your email.');
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _canResend = false);
    _cooldownTimer = Timer(const Duration(seconds: 30), () {
      setState(() => _canResend = true);
    });
  }

  void _cancelPayment() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment cancelled: too many OTP requests')),
    );
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim() != widget.otp) {
      setState(() => _message = 'Incorrect OTP. Try again.');
      return;
    }

    if (DateTime.now().isAfter(widget.expiry)) {
      setState(() => _message = 'OTP expired. Please request a new one.');
      return;
    }

    try {
      final Map<String, Map<String, dynamic>> productDataMap = {};
      final Map<String, DocumentReference> productRefMap = {};

      for (final item in widget.cartItems) {
        final qty = item['quantity'] ?? 1;
        final symptom = item['symptom']?.toString();
        final drugId = (item['drugId'] ?? item['id'])?.toString();
        final strength = item['strength']?.toString();
        final isPrescription = item['type'] == 'prescription';

        if ([symptom, drugId].any((v) => v == null || v.isEmpty)) {
          print('⚠️ Skipping invalid cart item: $item');
          continue;
        }

        final collection = isPrescription ? 'controlled_medicine' : 'uncontrolled_medicine';
        final productRef = isPrescription
            ? FirebaseFirestore.instance
            .collection(collection)
            .doc('symptoms')
            .collection(symptom!)
            .doc(drugId!)
            .collection('Strength')
            .doc(strength!)
            : FirebaseFirestore.instance
            .collection(collection)
            .doc('symptoms')
            .collection(symptom!)
            .doc(drugId!);

        try {
          final snapshot = await productRef.get();
          if (snapshot.exists) {
            final data = snapshot.data();
            if (data != null && data.containsKey('stock')) {
              productDataMap[drugId!] = data;
              productRefMap[drugId] = productRef;
              print('Pre-fetched $productRef: $data');
            } else {
              print('Missing "stock" in $productRef');
              throw Exception('Missing "stock" field');
            }
          } else {
            print('Product document not found: $productRef');
            throw Exception('Document not found');
          }
        } catch (e) {
          print('Error fetching $productRef: $e');
          throw e;
        }
      }

// 2️⃣ Run transaction using cached data
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final counterRef = FirebaseFirestore.instance.collection('metadata').doc('orderCounter');
        final counterSnap = await transaction.get(counterRef);
        final lastOrderNumber = counterSnap.exists ? (counterSnap['lastOrderNumber'] ?? 0) : 0;
        final newOrderNumber = lastOrderNumber + 1;
        final orderId = 'ORD-${newOrderNumber.toString().padLeft(3, '0')}';

        transaction.set(counterRef, {'lastOrderNumber': newOrderNumber});

        // Create order document
        final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
        final assignedId = _assignPharmacyId(widget.address);
        if (assignedId == null) {
          throw Exception('No pharmacy found for address: ${widget.address}');
        }

        transaction.set(orderRef, {
          'orderId'          : orderId,
          'email'            : widget.email,
          'name'             : widget.name,
          'contact'          : widget.contact,
          'address'          : widget.address,
          'items'            : widget.cartItems,
          'subtotal'         : widget.subtotal,
          'shippingFee'      : widget.shippingFee,
          'total'            : widget.total,
          'paymentType'      : 'Debit/Credit Card',
          'orderStatus'      : 'Order Placed',
          'assignedPharmacyId'  : assignedId,
          'assignedState'       : _extractState(widget.address),
          'timestamp'        : Timestamp.now(),
        });

        // Deduct stock
        for (final item in widget.cartItems) {
          final qty = item['quantity'] ?? 1;
          final drugId = (item['drugId'] ?? item['id'])?.toString() ?? '';

          final currentData = productDataMap[drugId];
          final productRef = productRefMap[drugId];

          if (currentData == null || productRef == null) {
            throw Exception('No product data/ref found for $drugId');
          }

          final currentStock = currentData['stock'];
          if (currentStock is! num || currentStock < qty) {
            throw Exception('Insufficient stock for $drugId (stock: $currentStock, qty: $qty)');
          }

          print('✅ Deducting $qty from $productRef (stock: $currentStock)');
          transaction.update(productRef, {
            'stock': FieldValue.increment(-qty),
          });
        }

        // Remove items from cart
        final cartQuery = await FirebaseFirestore.instance
            .collection('cart')
            .where('email', isEqualTo: widget.email)
            .get();

        for (final doc in cartQuery.docs) {
          final data = doc.data();
          final List<dynamic> allItems = data['items'] ?? [];

          final purchasedIds = widget.cartItems
              .map((item) => (item['drugId'] ?? item['id']).toString())
              .toSet();

          final remainingItems = allItems.where((item) {
            final key = (item['drugId'] ?? item['id']).toString();
            return !purchasedIds.contains(key);
          }).toList();

          await doc.reference.update({'items': remainingItems});
        }
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderHistory()),
      );
    } catch (e) {
      print('Transaction failed: $e');
      setState(() => _message = 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D9D0),

      body: Padding(
        padding: const EdgeInsets.all(24.0).copyWith(top: 40),
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
            const SizedBox(height: 15),
            Center(
              child: TextButton(
                onPressed: _canResend ? _resendOtp : null,
                child: Text(
                  _canResend ? 'Resend OTP' : 'Resend disabled (wait)',
                  style: TextStyle(
                    color: _canResend ? Color(0xFF6B4518) : Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
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
