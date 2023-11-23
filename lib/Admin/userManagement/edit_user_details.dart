// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:security/Global/list_faculties.dart';

class EditUserDetailsPage extends StatefulWidget {
  final DocumentReference userReference;

  EditUserDetailsPage({required this.userReference});

  @override
  _EditUserDetailsPageState createState() => _EditUserDetailsPageState();
}

class _EditUserDetailsPageState extends State<EditUserDetailsPage> {
  late TextEditingController _nameController;
  late String _currentRole;
  late List<String> _roles;
  late List<String> _userFaculties;
  String _profilePictureUrl = '';
  XFile? _pickedImageFile;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _currentRole = '';
    _roles = ['Teacher', 'Student'];
    _userFaculties = [];
    _loadCurrentUserData();
  }

  void _loadCurrentUserData() async {
    DocumentSnapshot userData = await widget.userReference.get();
    Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
    _nameController.text = data['name'];
    _currentRole = data['role'];
    _userFaculties = List.from(data['faculties'] ?? []);
    setState(() {
      _profilePictureUrl = data['profilePicture'];
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateUserDetails() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      if (_pickedImageFile != null) {
        String imageUrl = await uploadFileAndGetUrl(_pickedImageFile!);
        _profilePictureUrl = imageUrl;
      }

      await widget.userReference.update({
        'name': _nameController.text,
        'role': _currentRole,
        'profilePicture': _profilePictureUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User details updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update user details.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      _isUpdating = false;
    });
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = pickedFile;
      });
    }
  }

  Future<String> uploadFileAndGetUrl(XFile file) async {
    Reference storageReference =
    FirebaseStorage.instance.ref().child('profile_pics/${file.name}');
    UploadTask uploadTask = storageReference.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    await uploadTask;
    return await storageReference.getDownloadURL();
  }

  void _removeFaculty(String faculty) async {
    setState(() {
      _userFaculties.remove(faculty);
    });
    await widget.userReference.update({
      'faculties': _userFaculties,
    });
  }

  void _addFaculty(String faculty) async {
    if (!_userFaculties.contains(faculty)) {
      setState(() {
        _userFaculties.add(faculty);
      });
      await widget.userReference.update({
        'faculties': _userFaculties,
      });
    }
  }

  Future<void> showAddFacultyDialog(BuildContext context) async {
    final List<String> availableFaculties = Faculties.list.where((faculty) => !_userFaculties.contains(faculty)).toList();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Faculty'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableFaculties.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(availableFaculties[index]),
                  onTap: () {
                    _addFaculty(availableFaculties[index]);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              margin: const EdgeInsets.only(top: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    offset: const Offset(0, 0),
                    blurRadius: 10.0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _pickedImageFile != null
                            ? FileImage(File(_pickedImageFile!.path))
                            : (_profilePictureUrl.isNotEmpty
                                ? NetworkImage(_profilePictureUrl)
                                : null) as ImageProvider<Object>?,
                        child: _pickedImageFile == null &&
                                _profilePictureUrl.isEmpty
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.grey,
                        ),
                        onPressed: _changeProfilePicture,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _currentRole,
                    items: _roles.map((String role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _currentRole = newValue!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  for (String faculty in _userFaculties)
                    ListTile(
                      title: Text(faculty),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeFaculty(faculty),
                      ),
                    ),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => showAddFacultyDialog(context),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _isUpdating
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _updateUserDetails,
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(365, 50),
                      textStyle: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    child: const Text('Update Details'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}