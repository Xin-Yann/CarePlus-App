import 'package:careplusapp/otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'order_history.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController cardName = TextEditingController();
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

  //Generate 6 digit OTP
  late String _otp;
  late DateTime _expiryTime;

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
          'expiry': expiry,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP email: ${response.body}');
    }
  }

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

    final index = DateTime.now().millisecondsSinceEpoch % ids.length;
    return ids[index];
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
            padding: const EdgeInsets.all(8.0).copyWith(top: 40),
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ListTile(
                                      leading: Image.network(
                                        item['image'] ?? '',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          // Fallback to asset image
                                          return Image.asset(
                                            'asset/image/weblogo.png',
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),

                                      title: Text(item['name'] ?? 'Unnamed Drug'),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (item['type'] == 'prescription') ...[
                                            const SizedBox(height:10),
                                            Text(
                                              'Strength: ${item['strength'] ?? 'Unknown'}',
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 10),
                                          Text("Quantity: $quantity"),

                                        ],
                                      ),
                                      trailing: Text(
                                        "RM ${total.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                      final otp = generateOTP();
                      final formattedExpiry = DateFormat(
                        'hh:mm a, MMM dd',
                      ).format(_expiryTime);

                      await sendOtpToEmail(
                        email: widget.email,
                        name: widget.name,
                        otp: otp,
                        expiry: formattedExpiry,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => OTPPage(
                                cartItems: widget.cartItems,
                                name: widget.name,
                                email: widget.email,
                                contact: widget.contact,
                                address: widget.address,
                                subtotal: _calculateSubtotal(),
                                shippingFee: _calculateShippingFee(),
                                total: _calculateTotal(),
                                otp: otp, // 6‑digit code
                                expiry: _expiryTime,
                              ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to send OTP: $e")),
                      );
                    }
                  } else if (currentTabIndex == 1) {
                    // E-Wallet tab
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
                        'subtotal'         : _calculateSubtotal(),
                        'shippingFee'      : _calculateShippingFee(),
                        'total'            : _calculateTotal(),
                        'paymentType'      : 'TNG',
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

                        print('Deducting $qty from $productRef (stock: $currentStock)');
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

                    print('Transaction completed successfully!');

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OrderHistory()),
                    );
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
            controller: cardName,
            decoration: InputDecoration(
              hintText: 'Card Holder Name',
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
              LengthLimitingTextInputFormatter(3),
              FilteringTextInputFormatter.digitsOnly,
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
      children: [
        Column(
          children: [
            SizedBox(height: 40),
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

    int digitsBeforeCursor = 0;
    for (int i = 0; i < newValue.selection.end; i++) {
      if (i < newValue.text.length &&
          RegExp(r'\d').hasMatch(newValue.text[i])) {
        digitsBeforeCursor++;
      }
    }

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
