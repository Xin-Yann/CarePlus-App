import 'dart:html' as html;
import 'dart:io';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_footer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final ImagePicker _picker = ImagePicker();
  bool isEditing = false;
  File? _profileImage;
  String? _imageUrl;
  String? selectedSpecialization;
  String loggedInEmail = '';
  String? errorText;
  final List<String> specializations = [
    'Select One Specializations',
    'Cardiology',
    'Dermatology',
    'Ear, Nose, and Throat (ENT)',
    'Endocrinology',
    'Gastroenterology & Hepatology',
    'General Medicine',
    'Internal Medicine',
    'Nephrology',
    'Obstetrics & Gynaecology',
    'Orthopaedic',
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    loggedInEmail = user?.email ?? '';
    fetchDoctorData();
    print('Selected specialty: $selectedSpecialization');
    print('Specializations list: $specializations');
  }

  Future<void> fetchDoctorData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final loggedInEmail = user.email?.trim();

      // Query the 'doctors' collection where 'email' matches
      final querySnapshot =
          await FirebaseFirestore.instance
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
            selectedSpecialization = data['specialty'] ?? '';
            _imageUrl = data['imageUrl'] ?? '';
          });
        }
      } else {
        print("No doctor found with email: $loggedInEmail");
      }
    }
  }

  Future<void> saveDoctorData({String? imageUrl}) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      print('User not logged in or email missing.');
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final doctorsRef = firestore.collection('doctors');

    try {
      // Find the doctor's document by matching the email
      final snapshot =
          await doctorsRef.where('email', isEqualTo: user.email).limit(1).get();

      if (snapshot.docs.isEmpty) {
        print('Doctor document not found.');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Doctor profile not found.')));
        return;
      }

      final docId = snapshot.docs.first.id;

      // Prepare updated data
      Map<String, dynamic> updatedData = {
        'name': name.text.trim(),
        'email': email.text.trim(),
        'contact': contact.text.trim(),
        'professional': professional.text.trim(),
        'language': language.text.trim(),
        'MMC': MMC.text.trim(),
        'NSR': NSR.text.trim(),
        'specialty': selectedSpecialization,
      };

      if (imageUrl != null && imageUrl.isNotEmpty) {
        updatedData['imageUrl'] = imageUrl;
      }

      // Update the Firestore document
      await doctorsRef.doc(docId).update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Doctor profile updated successfully.')),
      );

      print('Doctor data updated for doc ID $docId');
    } catch (e) {
      print('Error while saving doctor data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update doctor profile.')),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    const imgbbApiKey = 'e6f550d58c3ce65d422f1483a8b92ef7';

    if (kIsWeb) {
      final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) {
        final file = uploadInput.files?.first;
        if (file == null) return;

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        reader.onLoadEnd.listen((event) async {
          final bytes = reader.result as Uint8List; // ✅ fix
          final base64Image = base64Encode(bytes);

          final response = await http.post(
            Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
            body: {'image': base64Image},
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final newImageUrl = data['data']['url'];
            setState(() {
              _imageUrl = newImageUrl;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image upload failed')),
            );
          }
        });
      });
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final imageTemp = io.File(picked.path);
      setState(() {
        _profileImage = imageTemp;
      });

      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey'),
        body: {'image': base64Image},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newImageUrl = data['data']['url'];
        setState(() {
          _imageUrl = newImageUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image upload failed')));
      }
    }
  }

  Future<void> deleteDoctorAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final email = user.email;

        // Query doctor by email to find the correct doc ID (e.g., 'D1', 'D2', etc.)
        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('doctors')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          final docId = querySnapshot.docs.first.id;

          // Delete doctor document
          await FirebaseFirestore.instance
              .collection('doctors')
              .doc(docId)
              .delete();

          // Delete the user's auth account
          await user.delete();

          print("Doctor account deleted successfully.");
          Navigator.pushReplacementNamed(context, '/');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Your doctor account has been deleted.')),
          );
        } else {
          print("Doctor document not found.");
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print(
          "The doctor must reauthenticate before this operation can be executed.",
        );
        // You can show a dialog to prompt re-authentication here
      } else {
        print("Error deleting doctor account: ${e.message}");
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
          padding: const EdgeInsets.all(8.0).copyWith(top: 40.0),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/doctor_home');
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
                          deleteDoctorAccount();
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

                    SizedBox(height: 30.0),

                    Center(
                      child:
                          _profileImage != null
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
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return const CircularProgressIndicator();
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                    );
                                  },
                                ),
                              )
                              : CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.person, size: 50),
                              ),
                    ),

                    // Show "Change Profile Pic" button only when editing
                    if (isEditing) ...[
                      SizedBox(height: 20.0),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            _pickAndUploadImage();
                          },
                          icon: Icon(Icons.camera_alt),
                          label: Text('Change Profile Pic'),
                        ),
                      ),
                    ],

                    SizedBox(height: 20.0),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Specialty',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6B4518),
                        ),
                      ),
                    ),

                    //Name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: SizedBox(
                        width: 382,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                isEditing
                                    ? Colors.white
                                    : const Color(0xFFCCCCCC),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: DropdownButtonFormField<String>(
                            isExpanded:
                                true, // Make dropdown take full width and align left
                            value:
                                selectedSpecialization?.isNotEmpty == true
                                    ? selectedSpecialization
                                    : null,
                            decoration: InputDecoration(
                              // enabledBorder: OutlineInputBorder(
                              //   borderRadius: BorderRadius.circular(30),
                              //   borderSide: BorderSide(color: Colors.white),
                              // ),
                              // focusedBorder: OutlineInputBorder(
                              //   borderRadius: BorderRadius.circular(30),
                              //   borderSide: BorderSide(color: Colors.white),
                              // ),
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 15,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            onChanged:
                                isEditing
                                    ? (String? newValue) {
                                      setState(() {
                                        selectedSpecialization = newValue!;
                                      });
                                    }
                                    : null,
                            items:
                                specializations.map((String specialization) {
                                  return DropdownMenuItem<String>(
                                    value: specialization,
                                    child: Align(
                                      alignment:
                                          Alignment
                                              .centerLeft, // Align text left
                                      child: Text(specialization),
                                    ),
                                  );
                                }).toList(),
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
                            color: isEditing ? Colors.black : Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Name',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                            filled: true,
                            fillColor:
                                isEditing ? Colors.white : Color(0XFFCCCCCC),
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
                              borderSide: BorderSide(
                                color: const Color(0XFFCCCCCC),
                              ),
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
                            color: isEditing ? Colors.black : Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                            filled: true,
                            fillColor:
                                isEditing ? Colors.white : Color(0XFFCCCCCC),
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
                              borderSide: BorderSide(
                                color: const Color(0XFFCCCCCC),
                              ),
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
                            color: isEditing ? Colors.black : Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Contact No',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                            filled: true,
                            fillColor:
                                isEditing ? Colors.white : Color(0XFFCCCCCC),
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
                              borderSide: BorderSide(
                                color: const Color(0XFFCCCCCC),
                              ),
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
                            color: isEditing ? Colors.black : Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Name',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                            filled: true,
                            fillColor:
                                isEditing ? Colors.white : Color(0XFFCCCCCC),
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
                              borderSide: BorderSide(
                                color: const Color(0XFFCCCCCC),
                              ),
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
                            color: isEditing ? Colors.black : Colors.grey[600],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Malaysian Medical Council (MMC) Number',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                            filled: true,
                            fillColor:
                                isEditing ? Colors.white : Color(0XFFCCCCCC),
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
                              ), // Border when focused
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(
                                color: const Color(0XFFCCCCCC),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 25.0),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isEditing) {
                            await saveDoctorData(imageUrl: _imageUrl);
                            setState(() {
                              isEditing = false;
                              _profileImage = null;
                            });
                          } else {
                            setState(() {
                              isEditing = true;
                            });
                          }
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

                    SizedBox(height: 20.0),

                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          errorText!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
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
