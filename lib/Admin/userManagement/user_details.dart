// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:security/Admin/userManagement/edit_user_details.dart';

class UserDetailsPage extends StatelessWidget {
  final DocumentReference userReference;

  UserDetailsPage({required this.userReference});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userReference.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String userName = userData['name'];
          String userRole = userData['role'];
          String userEmail = userData['email'];
          List<dynamic> userFaculties = userData['faculties'] ?? [];
          String userProfilePicture = userData['profilePicture'];

          return SingleChildScrollView(
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
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(userProfilePicture),
                        backgroundColor: Colors.black,
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        userName,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        userRole,
                        style: TextStyle(
                            fontSize: 20, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        userEmail,
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 5.0),
                      if (userFaculties.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          margin: const EdgeInsets.only(top: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade400,
                                offset: const Offset(0, 2),
                                blurRadius: 4.0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Faculties:',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey),
                              ),
                              const SizedBox(height: 10.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: userFaculties
                                    .map((faculty) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4.0),
                                          child: Text(
                                            '- $faculty',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.black87),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditUserDetailsPage(
                                  userReference: userReference),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(365, 50),
                          textStyle: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        child: const Text('Edit'),
                      ),
                      const SizedBox(height: 10.0),
                      ElevatedButton(
                        onPressed: () => _confirmDelete(context),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red,
                          fixedSize: const Size(365, 50),
                          textStyle: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        child: const Text('Delete User'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: const Text('Are you sure you want to delete this user?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                _deleteUser(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(BuildContext context) async {
    try {
      await userReference.delete();
      Navigator.of(context).pop(); // Close the dialog
      Navigator.of(context).pop(); // Go back to the previous screen
    } catch (e) {
      Navigator.of(context).pop(); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: $e'),
        ),
      );
    }
  }
}
