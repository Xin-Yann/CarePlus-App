import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_footer.dart';

class DoctorProfile extends StatefulWidget {
  const DoctorProfile({Key? key}) : super(key: key);

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController name = TextEditingController();
  final TextEditingController contact = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController professional = TextEditingController();
  final TextEditingController language = TextEditingController();
  final TextEditingController MMC = TextEditingController();
  final TextEditingController NSR = TextEditingController();
  final TextEditingController specializationController = TextEditingController();
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
    fetchDoctorData();
  }

  Future<void> fetchDoctorData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final loggedInEmail = user.email?.trim();

      // Query the 'doctors' collection where 'email' matches
      final querySnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .where('email', isEqualTo: loggedInEmail)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();

        if (mounted) {
          setState(() {
            name.text = data['name'] ?? '';
            email.text = data['email'] ?? '';
            contact.text = data['contact'] ?? '';
            professional.text = data['professional'] ?? '';
            language.text = data['language'] ?? '';
            MMC.text = data['MMC'] ?? '';
            NSR.text = data['NSR'] ?? '';
            specializationController.text = data['specialty'] ?? '';
            _imageUrl = data['imageUrl'] ?? '';
          });
        }
      } else {
        print("No doctor found with email: $loggedInEmail");
      }
    }
  }


  Future<void> deleteUserAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final uid = user.uid;

        // Delete user document from Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();

        // Delete the user's auth account
        await user.delete();

        // Navigate back or show a success message
        print("User account deleted successfully.");

        Navigator.pushReplacementNamed(context, '/');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print("The user must reauthenticate before this operation can be executed.");
        // Prompt user to log in again
      } else {
        print("Error deleting account: ${e.message}");
      }
    } catch (e) {
      print("Unexpected error: $e");
    }
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
                        Navigator.pushNamed(context, '/home');
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          deleteUserAccount();
                          print("Button pressed");
                        },
                        child: Text(
                          "DELETE ACCOUNT",
                          style: TextStyle(
                            color: const Color(0xFF6B4518),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                  _profileImage != null
                      ? ClipOval(
                    child: Image.file(
                      _profileImage!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  )
                      : (_imageUrl != null && _imageUrl!.isNotEmpty)
                      ? ClipOval(
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

                  SizedBox(height: 30.0,),

                  //Name
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Specialization',
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
                          controller: specializationController,
                          style: TextStyle(
                            color: isEditing ? Colors.black : Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Specialty',
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
                              borderSide: BorderSide(color: Color(0XFFCCCCCC)),
                            ),
                          ),
                        ),
                      ),
                    ),

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
                        'Professional Education/Qualification',
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
                          controller: professional,
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

                    //Address
                    SizedBox(height: 15.0),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Malaysian Medical Council (MMC) Number',
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
                          controller: MMC,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isEditing ? Colors.black :  Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Malaysian Medical Council (MMC) Number',
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
                              borderSide: BorderSide(color: Colors.white), // Border when focused
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: const Color(0XFFCCCCCC)),
                            ),
                          ),
                        ),
                      ),
                    ),

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
      bottomNavigationBar: const DoctorFooter(),
    );
  }
}
