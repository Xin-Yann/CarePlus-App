import 'dart:io';
import 'package:careplusapp/Pharmacy/pharmacy_footer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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
  String? errorText;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    loggedInEmail = user?.email ?? '';
    fetchPharmacyData();
  }

  Map<String, dynamic>? pharmacyData;
  String? pharmacyImageUrl;
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

    // Map<String, List<String>> stateDocIds = {
    //   "Perlis": ["P1", "P2", "P3"],
    //   "Kedah": ["P4", "P5", "P6"],
    //   "Penang": ["P7", "P8", "P9"],
    //   "Perak": ["P10", "P11", "P12"],
    //   "Selangor": ["P13", "P14", "P15"],
    //   "Negeri Sembilan": ["P16", "P17", "P18"],
    //   "Melaka": ["P19", "P20", "P21"],
    //   "Kelantan": ["P22", "P23", "P24"],
    //   "Terengganu": ["P25", "P26", "P27"],
    //   "Pahang": ["P28", "P29", "P30"],
    //   "Johor": ["P31", "P32", "P33"],
    //   "Sabah": ["P34", "P35", "P36"],
    //   "Sarawak": ["P37", "P38", "P39"],
    // };

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
                address.text = data['address'] ?? '';
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

  Future<void> savePharmacyData({String? imageUrl}) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      print('User is not logged in or missing email.');
      return;
    }

    String fullAddress = address.text.trim();

    if (fullAddress.isEmpty) {
      print('Address is empty.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the full address including the state.')),
      );
      return;
    }

    // Extract last word from address to detect state
    List<String> words = fullAddress
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    String lastWord = words.isNotEmpty ? words.last : '';

    // // Map of state to document IDs (make sure this is defined somewhere globally)
    // Map<String, List<String>> stateDocIds = {
    //   "Perlis": ["P1", "P2", "P3"],
    //   "Kedah": ["P4", "P5", "P6"],
    //   "Penang": ["P7", "P8", "P9"],
    //   "Perak": ["P10", "P11", "P12"],
    //   "Selangor": ["P13", "P14", "P15"],
    //   "Negeri Sembilan": ["P16", "P17", "P18"],
    //   "Melaka": ["P19", "P20", "P21"],
    //   "Kelantan": ["P22", "P23", "P24"],
    //   "Terengganu": ["P25", "P26", "P27"],
    //   "Pahang": ["P28", "P29", "P30"],
    //   "Johor": ["P31", "P32", "P33"],
    //   "Sabah": ["P34", "P35", "P36"],
    //   "Sarawak": ["P37", "P38", "P39"],
    // };

    // Find matching state ignoring case
    String? matchedState;
    for (String state in stateDocIds.keys) {
      if (lastWord.toLowerCase() == state.toLowerCase()) {
        matchedState = state;
        break;
      }
    }

    if (matchedState == null) {
      setState(() {
        errorText = "Could not detect a valid Malaysian state from the address.";
      });
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final pharmacyCollection =
    firestore.collection('pharmacy').doc('state').collection(matchedState);

    final docIds = stateDocIds[matchedState]!;

    String? foundDocId;

    // Find the document in the matched state's collection with matching email
    for (final docId in docIds) {
      final docSnapshot = await pharmacyCollection.doc(docId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['email'] == user.email) {
          foundDocId = docId;
          break;
        }
      }
    }

    if (foundDocId == null) {
      print('No pharmacy document found for user email in $matchedState');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your pharmacy record was not found in the database.')),
      );
      return;
    }

    // Prepare data for update
    Map<String, dynamic> updatedData = {
      'name': name.text.trim(),
      'address': fullAddress,
      'contact': contact.text.trim(),
      'email': email.text.trim(),
      'operation_hours': operationHours.text.trim(),
    };

    if (imageUrl != null && imageUrl.isNotEmpty) {
      updatedData['imageUrl'] = imageUrl;
    }

    // Update the document in Firestore
    await pharmacyCollection.doc(foundDocId).update(updatedData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pharmacy profile updated successfully.')),
    );

    print('Pharmacy data updated for doc ID $foundDocId');
  }

  Future<void> _pickAndUploadImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;

    setState(() {
      _profileImage = File(pickedImage.path);
    });

    final bytes = await _profileImage!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('https://api.imgur.com/3/image'),
      headers: {'Authorization': 'Client-ID f10c4d5c7204b1b'},
      body: {'image': base64Image, 'type': 'base64'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _imageUrl = data['data']['link'];
      });
      print('Uploaded: $_imageUrl');
    } else {
      print('Upload failed: ${response.body}');
    }
  }

  Future<void> deletePharmacyAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.email == null) {
        print('User is not logged in or missing email.');
        return;
      }

      String fullAddress = address.text.trim();

      if (fullAddress.isEmpty) {
        print('Address is empty.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter the full address to identify the state.')),
        );
        return;
      }

      // Extract last word from address
      List<String> words = fullAddress
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(' ')
          .where((w) => w.isNotEmpty)
          .toList();
      String lastWord = words.isNotEmpty ? words.last : '';

      String? matchedState;
      for (String state in stateDocIds.keys) {
        if (lastWord.toLowerCase() == state.toLowerCase()) {
          matchedState = state;
          break;
        }
      }

      if (matchedState == null) {
        print('State could not be matched from the address.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not detect a valid Malaysian state from the address.')),
        );
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final pharmacyCollection = firestore
          .collection('pharmacy')
          .doc('state')
          .collection(matchedState);

      final docIds = stateDocIds[matchedState]!;

      String? foundDocId;

      for (final docId in docIds) {
        final docSnapshot = await pharmacyCollection.doc(docId).get();
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null && data['email'] == user.email) {
            foundDocId = docId;
            break;
          }
        }
      }

      if (foundDocId == null) {
        print('No matching pharmacy document found in $matchedState');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pharmacy record not found. Cannot delete.')),
        );
        return;
      }

      // Delete the pharmacy document
      await pharmacyCollection.doc(foundDocId).delete();

      // Delete Firebase Auth user
      await user.delete();

      print('Pharmacy account and user deleted successfully.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your pharmacy account has been deleted.')),
      );

      Navigator.pushReplacementNamed(context, '/');

    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print("Reauthentication required.");
        // TODO: Trigger reauthentication UI
      } else {
        print("Firebase Auth error: ${e.message}");
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          deletePharmacyAccount();
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

                    SizedBox(height: 30.0,),

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

                    // Show "Change Profile Pic" button only when editing
                    if (isEditing)
                      SizedBox(height: 20.0,),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            // Your function to pick new image
                            _pickAndUploadImage();
                          },
                          icon: Icon(Icons.camera_alt),
                          label: Text('Change Profile Pic'),
                        ),
                      ),

                    SizedBox(height: 10.0,),

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

                    //Operating Hours
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
                      child: ElevatedButton(
                        onPressed: () async {
                          if (isEditing) {
                            await savePharmacyData(imageUrl: _imageUrl);
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

                    SizedBox(height: 20.0,),

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
      bottomNavigationBar: const PharmacyFooter(),
    );
  }
}
