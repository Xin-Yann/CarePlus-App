import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'footer.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController name = TextEditingController();
  final TextEditingController birthDate = TextEditingController();
  final TextEditingController ic = TextEditingController();
  final TextEditingController contact = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController address = TextEditingController();
  bool isEditing = false;


  @override
  void initState() {
    super.initState();
    fetchUserData();
  }


  Future<void> fetchUserData() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final usersRef = FirebaseFirestore.instance.collection('users');

      // Query Firestore to find the document with the user's email
      final querySnapshot = await usersRef
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();

        setState(() {
          name.text = data['name'] ?? '';
          birthDate.text = data['birthDate'] ?? '';
          contact.text = data['contact'] ?? '';
          email.text = data['email'] ?? '';
          address.text = data['address'] ?? '';
          ic.text = data['icNumber'] ?? '';
        });
      }
      }
  }

  Future<void> deleteUserAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final usersRef = FirebaseFirestore.instance.collection('users');

        // Find the custom document by matching user's email
        final querySnapshot = await usersRef
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final docID = querySnapshot.docs.first.id;

          // Delete Firestore document with custom ID
          await usersRef.doc(docID).delete();

          // Delete Firebase Auth user
          await user.delete();

          print("User account deleted successfully.");
          Navigator.pushReplacementNamed(context, '/');
        } else {
          print("User document with custom ID not found.");
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print("The user must reauthenticate before this operation can be executed.");
        // TODO: Prompt user to reauthenticate (e.g., with email/password)
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

                    //Birth Date
                    SizedBox(height: 15.0),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Birth Date',
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
                          controller: birthDate,
                          readOnly: true,
                          style: TextStyle(
                            color: isEditing ? Colors.black :  Colors.grey[600],
                          ),
                          onTap: () async {
                            DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1800),
                              lastDate: DateTime(2090),
                            );
                            if (date != null) {
                              birthDate.text = date.toString().substring(0, 10);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Birth Date',
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
                              borderSide: BorderSide(
                                color: Colors.white,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: const Color(0XFFCCCCCC)),
                            ),
                            suffixIcon: Icon(
                              Icons.calendar_month,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),

                    //IC
                    SizedBox(height: 15.0),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'NRIC/MYKAD',
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
                          controller: ic,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isEditing ? Colors.black :  Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'NRIC/MYKAD',
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
                          keyboardType: TextInputType.number,
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

                    //Address
                    SizedBox(height: 15.0),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Address',
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
                          controller: address,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: isEditing ? Colors.black :  Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Address',
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
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (isEditing) {
                              // Save the changes
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                final usersRef = FirebaseFirestore.instance.collection('users');

                                // Find document with matching email (or uid if stored)
                                final querySnapshot = await usersRef
                                    .where('email', isEqualTo: user.email)
                                    .limit(1)
                                    .get();

                                if (querySnapshot.docs.isNotEmpty) {
                                  final doc = querySnapshot.docs.first;
                                  final docID = doc.id;

                                  await usersRef.doc(docID).update({
                                    'name': name.text.trim(),
                                    'birthDate': birthDate.text.trim(),
                                    'contact': contact.text.trim(),
                                    'email': email.text.trim(),
                                    'address': address.text.trim(),
                                    'icNumber': ic.text.trim(),
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Profile updated successfully.')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('User document not found.')),
                                  );
                                }
                              }
                            }

                            setState(() {
                              isEditing = !isEditing; // Toggle the editing state
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(200, 50),
                            textStyle: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Crimson',
                            ),
                            backgroundColor: const Color(0xFF6B4518),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isEditing ? 'Save' : 'Edit'),
                        ),
                      ),
                    )
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
