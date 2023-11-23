import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:security/Admin/services/admin_credentials.dart';
import 'package:security/Global/list_faculties.dart';
import 'package:security/Admin/userManagement/admin_manage_users.dart';

class CreateUsersPage extends StatefulWidget {
  @override
  _CreateUsersPageState createState() => _CreateUsersPageState();
}

class _CreateUsersPageState extends State<CreateUsersPage> {
  bool _isCreatingUser = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _userRole = 'Teacher';
  final List<String> _userRoles = ['Teacher', 'Student'];
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _imageFile;
  final picker = ImagePicker();
  bool _passwordVisible = false;
  String? _isStrongPassword(String password) {
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    bool hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    bool hasNumber = RegExp(r'\d').hasMatch(password);
    bool hasSymbol = RegExp(r'[\W_]').hasMatch(password);

    if (!hasMinLength) {
      return 'Password must be at least 8 characters';
    } else if (!hasUppercase) {
      return 'Password must contain at least one uppercase letter';
    } else if (!hasLowercase) {
      return 'Password must contain at least one lowercase letter';
    } else if (!hasNumber) {
      return 'Password must contain at least one number';
    } else if (!hasSymbol) {
      return 'Password must contain at least one symbol';
    }

    return null;
  }

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  final Set<String> selectedFaculties = Set<String>();

  Future<void> _pickImage(ImageSource source) async {
    final selected = await picker.pickImage(source: source);
    if (selected != null) {
      setState(() {
        _imageFile = File(selected.path);
      });
    }
  }

  Future<String> _uploadImage() async {
    if (_imageFile != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pics/${_auth.currentUser!.uid}.jpg');
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    }
    return 'https://firebasestorage.googleapis.com/v0/b/intinow.appspot.com/o/placeholders%2FprofilePicPlaceholder.jpg?alt=media&token=b2592223-55ca-4758-9f9d-2793d3166b68';
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0.9._%-]+@[a-zA-Z0.9.-]+\.[a-zA-Z]{2,4}$")
        .hasMatch(email);
  }

  Future<bool> _isAdmin(User user) async {
    DocumentSnapshot adminDoc =
        await _firestore.collection('Admin').doc(user.uid).get();
    if (adminDoc.exists) {
      if (adminDoc['role'] == 'Admin') {
        return true;
      }
    }
    return false;
  }

  void _showFacultiesSelectionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Column(
            children: [
              const ListTile(
                title: Text(
                  'Faculties',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: Faculties.getFaculties().length,
                  itemBuilder: (context, index) {
                    final faculty = Faculties.getFaculties()[index];
                    return CheckboxListTile(
                      title: Text(faculty),
                      value: selectedFaculties.contains(faculty),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedFaculties.add(faculty);
                          } else {
                            selectedFaculties.remove(faculty);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: selectedFaculties.isNotEmpty
                    ? () {
                        Navigator.pop(context);
                      }
                    : null,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith(
                    (states) {
                      if (states.contains(MaterialState.disabled)) {
                        return Colors.grey;
                      }
                      return null;
                    },
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Users')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    await showModalBottomSheet(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(10),
                            child: const Text(
                              'Upload Profile Picture',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.camera),
                            title: const Text('Camera'),
                            onTap: () {
                              _pickImage(ImageSource.camera);
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.image),
                            title: const Text('Gallery'),
                            onTap: () {
                              _pickImage(ImageSource.gallery);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage:
                            _imageFile != null ? FileImage(_imageFile!) : null,
                        child: _imageFile == null
                            ? const Icon(Icons.camera_alt, size: 50)
                            : null,
                      ),
                      if (_imageFile != null)
                        GestureDetector(
                          onTap: _removeImage,
                          child: const CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField(
                  value: _userRole,
                  onChanged: (value) {
                    setState(() {
                      _userRole = value.toString();
                      selectedFaculties.clear();
                    });
                  },
                  items: _userRoles
                      .map((role) =>
                          DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  decoration: const InputDecoration(
                      labelText: 'User Role', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 5),
                if (_userRole == 'Teacher' || _userRole == 'Student')
                  OutlinedButton(
                    onPressed: () {
                      _showFacultiesSelectionSheet();
                    },
                    style: OutlinedButton.styleFrom(
                      fixedSize: const Size(365, 50),
                    ),
                    child: const Text(
                      'Choose Faculties',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                      labelText: 'Name',
                      border: const OutlineInputBorder(),
                      errorText: _nameError),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                      labelText: 'Email',
                      border: const OutlineInputBorder(),
                      errorText: _emailError),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    errorText: _passwordError,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    errorText: _confirmPasswordError,
                  ),
                ),
                const SizedBox(height: 20),
                _isCreatingUser
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          _clearErrors();
                          if (_nameController.text.isEmpty) {
                            setState(() {
                              _nameError = 'Name is required';
                            });
                            return;
                          }

                          if (_emailController.text.isEmpty) {
                            setState(() {
                              _emailError = 'Email is required';
                            });
                            return;
                          } else if (!_isValidEmail(_emailController.text)) {
                            setState(() {
                              _emailError = 'Enter a valid email';
                            });
                            return;
                          }

                          if (_passwordController.text.isEmpty) {
                            setState(() {
                              _passwordError = 'Password is required';
                            });
                            return;
                          }

                          String? passwordError =
                              _isStrongPassword(_passwordController.text);
                          if (passwordError != null) {
                            setState(() {
                              _passwordError = passwordError;
                            });
                            return;
                          }

                          if (_confirmPasswordController.text.isEmpty) {
                            setState(() {
                              _confirmPasswordError =
                                  'Password confirmation is required';
                            });
                            return;
                          }

                          if (_passwordController.text !=
                              _confirmPasswordController.text) {
                            setState(() {
                              _passwordError = 'Passwords do not match';
                              _confirmPasswordError = 'Passwords do not match';
                            });
                            return;
                          }

                          setState(() {
                            _isCreatingUser = true;
                          });

                          try {
                            final currentUser = _auth.currentUser;
                            if (currentUser != null) {
                              final isAdmin = await _isAdmin(currentUser);
                              if (isAdmin) {
                                UserCredential userCredential =
                                    await _auth.createUserWithEmailAndPassword(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                );
                                String imageUrl = await _uploadImage();
                                await _firestore
                                    .collection('Users')
                                    .doc(userCredential.user!.uid)
                                    .set({
                                  'name': _nameController.text,
                                  'email': _emailController.text,
                                  'role': _userRole,
                                  'profilePicture': imageUrl,
                                  'faculties': selectedFaculties.toList(),
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('User created successfully')));
                                await _auth.signOut();
                                await _auth.signInWithEmailAndPassword(
                                  email: AdminCredentials.email!,
                                  password: AdminCredentials.password!,
                                );

                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            AdminManageUsersPage()));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Only Admin can create users')));
                              }
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Error: ${e.toString()}')));
                          } finally {
                            setState(() {
                              _isCreatingUser = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(365, 50),
                          textStyle: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        child: const Text('Create User'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
