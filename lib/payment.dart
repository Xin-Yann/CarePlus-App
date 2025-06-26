import 'package:careplusapp/otp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'order_history.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String name;
  final String email;
  final String contact;
  final String address;

  const PaymentPage({
    super.key,
    required this.cartItems,
    required this.name,
    required this.email,
    required this.contact,
    required this.address,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController cardNo = TextEditingController();
  final TextEditingController expiryDate = TextEditingController();
  final TextEditingController cvv = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double _calculateSubtotal() {
    double subtotal = 0.0;
    for (var item in widget.cartItems) {
      final quantity = item['quantity'] ?? 1;
      final price = double.tryParse(item['price'].toString()) ?? 0.0;
      subtotal += price * quantity;
    }
    return subtotal;
  }

  double _calculateShippingFee() {
    final subtotal = _calculateSubtotal();
    return subtotal > 100 ? 0.0 : 10.0;
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateShippingFee();
  }

  String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit OTP
  }

  Future<void> sendOtpToEmail(String email, String name, String otp) async {
    const serviceId = 'service_ug3yy5l';
    const templateId = 'template_mtee97c';
    const userId = 'Zp05uSYdpxgcXjWlR';

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
          'user_name': name,
          'otp': otp,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP email');
    }
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFE1D9D0),
        body: DefaultTabController(
          length: 2,
          child: Padding(
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
                    const SizedBox(width: 100),
                    const Text(
                      'PAYMENT',
                      style: TextStyle(
                        color: Color(0xFF6B4518),
                        fontFamily: 'Crimson',
                        fontSize: 35,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Product List
                        Column(
                          children:
                              widget.cartItems.map((item) {
                                final quantity = item['quantity'] ?? 1;
                                final price =
                                    double.tryParse(item['price'].toString()) ??
                                    0.0;
                                final total = price * quantity;

                                return Card(
                                  color: const Color(0xFFF0ECE7),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    leading: Image.network(
                                      item['image'] ?? '',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.image_not_supported,
                                              ),
                                    ),
                                    title: Text(item['name']),
                                    subtitle: Text("Quantity: $quantity"),
                                    trailing: Text(
                                      "RM ${total.toStringAsFixed(2)}",
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Tab bar
                        TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFF6B4518),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFF6B4518),
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.credit_card),
                              text: "Debit/Credit Card",
                            ),
                            Tab(
                              icon: Icon(Icons.account_balance_wallet),
                              text: "TNG E-wallet",
                            ),
                          ],
                        ),

                        // Tab content
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildCreditCardTab(context),
                              _buildEWalletTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

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
              const SizedBox(height: 10),
              Text(
                "Subtotal: RM${_calculateSubtotal().toStringAsFixed(2)}",
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16, color: Color(0xFF6B4518)),
              ),
              const SizedBox(height: 10),
              Text(
                "Shipping Fee: RM${_calculateShippingFee().toStringAsFixed(2)}",
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16, color: Color(0xFF6B4518)),
              ),
              const SizedBox(height: 10),
              Text(
                "Total: RM${_calculateTotal().toStringAsFixed(2)}",
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4518),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  int currentTabIndex = _tabController.index;
                  final otp = generateOTP();

                  if (currentTabIndex == 0) {
                    // Credit Card tab
                    final cardNumber = cardNo.text;
                    final expiry = expiryDate.text;
                    final cvvNo = cvv.text;

                    if (cardNumber.isEmpty ||
                        expiry.isEmpty ||
                        cvvNo.length != 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please complete your card details."),
                        ),
                      );
                      return;
                    }

                    try {
                      await sendOtpToEmail(widget.email, widget.name, otp);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OTPPage(
                            cartItems: widget.cartItems,
                            name: widget.name,
                            email: widget.email,
                            contact: widget.contact,
                            address: widget.address,
                            subtotal: _calculateSubtotal(),
                            shippingFee: _calculateShippingFee(),
                            total: _calculateTotal(),
                            otp: otp,
                          ),
                        ),
                      );

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to send OTP: $e")),
                      );
                    }

                  } else if (currentTabIndex == 1) {
                    // 💰 E-Wallet tab
                    // Save order to Firestore
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
                        'subtotal': _calculateSubtotal(),
                        'shippingFee': _calculateShippingFee(),
                        'total': _calculateTotal(),
                        'paymentType': 'TNG',
                        'orderStatus': 'Order Placed',
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

                      final cartQuery = await FirebaseFirestore.instance
                          .collection('cart')
                          .where('email', isEqualTo: widget.email)
                          .get();

                      for (final doc in cartQuery.docs) {
                        final data = doc.data();
                        final List<dynamic> allItems = data['items'] ?? [];

                        // Get the product IDs that were purchased
                        final productIds = widget.cartItems.map((item) => item['id']).toSet();

                        // Keep only the items that were NOT purchased
                        final remainingItems = allItems.where((item) => !productIds.contains(item['id'])).toList();

                        // Update the cart with the remaining items
                        await doc.reference.update({'items': remainingItems});
                      }

                    });

                    Navigator.push(context, MaterialPageRoute(builder: (context) => OrderHistory()));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4518),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Pay',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Payment tab content widgets
  Widget _buildCreditCardTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              CardNumberInputFormat(),
              LengthLimitingTextInputFormatter(19),
            ],
            controller: cardNo,
            decoration: InputDecoration(
              hintText: 'Card Number',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.datetime,
            controller: expiryDate,
            onTap: () async {
              DateTime? date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now().add(const Duration(days: 1)),
                lastDate: DateTime(2090),
              );
              if (date != null) {
                expiryDate.text = date.toString().substring(0, 10);
              }
            },
            decoration: InputDecoration(
              hintText: 'Expiry Date',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.white),
              ),
              suffixIcon: Icon(Icons.calendar_month, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            keyboardType: TextInputType.number,
            controller: cvv,
            obscureText: true,
            inputFormatters: [
              LengthLimitingTextInputFormatter(3), // Limits to 3 characters
              FilteringTextInputFormatter.digitsOnly, // Allows only digits
            ],
            decoration: InputDecoration(
              hintText: 'CVV',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEWalletTab() {
    return ListView(
      // or whatever height your bottom bar is
      children: [
        Column(
          children: [
            Image.asset(
              'asset/image/tng.png',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ],
    );
  }
}

class CardNumberInputFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';

    if (digitsOnly.length > 19) {
      digitsOnly = digitsOnly.substring(0, 19);
    }

    for (int i = 0; i < digitsOnly.length && i < 19; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += digitsOnly[i];
    }

    // Count digits before the original cursor position
    int digitsBeforeCursor = 0;
    for (int i = 0; i < newValue.selection.end; i++) {
      if (i < newValue.text.length &&
          RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }
    // Map digitsBeforeCursor to the formatted string index
    int cursorPos = 0;
    int digitsCounted = 0;
    while (cursorPos < formatted.length && digitsCounted < digitsBeforeCursor) {
      if (RegExp(r'\d').hasMatch(formatted[cursorPos])) {
        digitsCounted++;
      }
      cursorPos++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPos),
    );
  }
}

