import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'doctor_footer.dart';

class PharmacyProfile extends StatefulWidget {
  const PharmacyProfile({Key? key}) : super(key: key);

  @override
  State<PharmacyProfile> createState() => _PharmacyProfileState();
}

class _PharmacyProfileState extends State<PharmacyProfile> {
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController contact = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController password = TextEditingController();
  // final TextEditingController map = TextEditingController();
  final TextEditingController operationHours = TextEditingController();
  bool isEditing = false;
  File? _profileImage;
  String? _imageUrl;
  String? selectedSpecialization;
  String loggedInEmail = '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    loggedInEmail = user?.email ?? '';
    fetchPharmacyData();
  }

  Map<String, dynamic>? pharmacyData;
  String? pharmacyImageUrl;

  Future<void> fetchPharmacyData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      print('User is not logged in or missing email.');
      return;
    }

    final Useremail = user.email!;

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
                pharmacyData = data;
                pharmacyImageUrl = pharmacyData?['imageUrl'] ?? '';
                _imageUrl = pharmacyImageUrl;
                // Update controllers:
                name.text = data['name'] ?? '';
                email.text = data['email'] ?? '';
                contact.text = data['contact'] ?? '';
                operationHours.text = data['operation_hours'] ?? '';
                // map.text = data['map'] ?? '';
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
                        Navigator.pushNamed(context, '/pharmacy_home');
                      },
                      icon: Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'MY ACCOUNT',
                        style: TextStyle(
                          color: const Color(0xFF6B4518),
                          fontFamily: 'Crimson',
                          fontSize: 50,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: _profileImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _profileImage!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      )
                          : (_imageUrl != null && _imageUrl!.isNotEmpty)
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const CircularProgressIndicator();
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, size: 50);
                          },
                        ),
                      )
                          : CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, size: 50),
                      ),
                    ),

                    SizedBox(height: 30.0,),

                    //Name
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6B4518),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 382,
                        height: 60,
                        child: TextField(
                          enabled: isEditing,
                          controller: name,
                          style: TextStyle(
                            color: isEditing ? Colors.black :  Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Name',
                            hintStyle: TextStyle(
                              color: Colors.grey[500] ,
                              fontStyle: FontStyle.italic,
                            ),
                            filled: true,
                            fillColor: isEditing ? Colors.white : Color(0XFFCCCCCC),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: const Color(0XFFCCCCCC)),
                            ),
                          ),
                        ),
                      ),
                    ),

                    //Email
                    SizedBox(height: 15.0),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6B4518),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 382,
                        height: 60,
                        child: TextField(
                          enabled: isEditing,
                          controller: email,
                          style: TextStyle(
                            color: isEditing ? Colors.black :  Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                            filled: true,
                            fillColor: isEditing ? Colors.white : Color(0XFFCCCCCC),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: const Color(0XFFCCCCCC)),
                            ),
                          ),
                        ),
                      ),
                    ),


                    //Contact
                    SizedBox(height: 15.0),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Contact No',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6B4518),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 382,
                        height: 60,
                        child: TextField(
                          enabled: isEditing,
                          controller: contact,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isEditing ? Colors.black :  Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Contact No',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                            filled: true,
                            fillColor: isEditing ? Colors.white : Color(0XFFCCCCCC),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: const Color(0XFFCCCCCC)),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // //Password
                    // SizedBox(height: 15.0),
                    // Padding(
                    //   padding: const EdgeInsets.all(8.0),
                    //   child: Text(
                    //     'Password',
                    //     style: TextStyle(
                    //       fontSize: 16,
                    //       fontWeight: FontWeight.bold,
                    //       color: const Color(0xFF6B4518),
                    //     ),
                    //   ),
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.all(8.0),
                    //   child: Container(
                    //     width: 382,
                    //     height: 60,
                    //     child: TextField(
                    //       controller: password,
                    //       decoration: InputDecoration(
                    //         hintText: 'Password',
                    //         hintStyle: TextStyle(
                    //           color: Colors.grey[500],
                    //           fontStyle: FontStyle.italic,
                    //         ),
                    //         filled: true,
                    //         fillColor: Colors.white,
                    //         contentPadding: EdgeInsets.symmetric(
                    //           horizontal: 16,
                    //           vertical: 16,
                    //         ),
                    //         enabledBorder: OutlineInputBorder(
                    //           borderRadius: BorderRadius.circular(30),
                    //           borderSide: BorderSide(color: Colors.white),
                    //         ),
                    //         focusedBorder: OutlineInputBorder(
                    //           borderRadius: BorderRadius.circular(30),
                    //           borderSide: BorderSide(color: Colors.white), // Border when focused
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    //Professional Education/Qualification
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Operating Hours',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6B4518),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 382,
                        height: 60,
                        child: TextField(
                          enabled: isEditing,
                          controller: operationHours,
                          style: TextStyle(
                            color: isEditing ? Colors.black :  Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Operation Hours',
                            hintStyle: TextStyle(
                              color: Colors.grey[500] ,
                              fontStyle: FontStyle.italic,
                            ),
                            filled: true,
                            fillColor: isEditing ? Colors.white : Color(0XFFCCCCCC),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: const Color(0XFFCCCCCC)),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // //Address
                    // SizedBox(height: 15.0),
                    // Padding(
                    //   padding: const EdgeInsets.all(8.0),
                    //   child: Text(
                    //     'Google Map Link',
                    //     style: TextStyle(
                    //       fontSize: 16,
                    //       fontWeight: FontWeight.bold,
                    //       color: const Color(0xFF6B4518),
                    //     ),
                    //   ),
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.all(8.0),
                    //   child: Container(
                    //     width: 382,
                    //     height: 60,
                    //     child: TextField(
                    //       enabled: isEditing,
                    //       controller: map,
                    //       keyboardType: TextInputType.number,
                    //       style: TextStyle(
                    //         color: isEditing ? Colors.black :  Colors.grey[600],
                    //       ),
                    //       decoration: InputDecoration(
                    //         hintText: 'Google Map Link',
                    //         hintStyle: TextStyle(
                    //           color: Colors.grey[500],
                    //           fontStyle: FontStyle.italic,
                    //         ),
                    //         filled: true,
                    //         fillColor: isEditing ? Colors.white : Color(0XFFCCCCCC),
                    //         contentPadding: EdgeInsets.symmetric(
                    //           horizontal: 16,
                    //           vertical: 16,
                    //         ),
                    //         enabledBorder: OutlineInputBorder(
                    //           borderRadius: BorderRadius.circular(30),
                    //           borderSide: BorderSide(color: Colors.white),
                    //         ),
                    //         focusedBorder: OutlineInputBorder(
                    //           borderRadius: BorderRadius.circular(30),
                    //           borderSide: BorderSide(color: Colors.white), // Border when focused
                    //         ),
                    //         disabledBorder: OutlineInputBorder(
                    //           borderRadius: BorderRadius.circular(30),
                    //           borderSide: BorderSide(color: const Color(0XFFCCCCCC)),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    SizedBox(height: 25.0),
                    //Button
                    // Center(
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(8.0),
                    //     child: ElevatedButton(
                    //       onPressed: () async {
                    //         if (isEditing) {
                    //           // Save the changes
                    //           final user = FirebaseAuth.instance.currentUser;
                    //           if (user != null) {
                    //             await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                    //               'name': name.text.trim(),
                    //               'birthDate': birthDate.text.trim(),
                    //               'contact': contact.text.trim(),
                    //               'email': email.text.trim(),
                    //               'address': address.text.trim(),
                    //               'icNumber': ic.text.trim(),
                    //             });
                    //             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    //               content: Text('Profile updated successfully.'),
                    //             ));
                    //           }
                    //         }
                    //
                    //         setState(() {
                    //           isEditing = !isEditing; // Toggle the editing state
                    //         });
                    //       },
                    //       style: ElevatedButton.styleFrom(
                    //         minimumSize: Size(200, 50),
                    //         textStyle: TextStyle(
                    //           fontSize: 20,
                    //           fontWeight: FontWeight.bold,
                    //           fontFamily: 'Crimson',
                    //         ),
                    //         backgroundColor: const Color(0xFF6B4518),
                    //         foregroundColor: Colors.white,
                    //       ),
                    //       child: Text(isEditing ? 'Save' : 'Edit'),
                    //     ),
                    //   ),
                    // )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: const DoctorFooter(),
    );
  }
}
