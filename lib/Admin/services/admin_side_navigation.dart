import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:security/Admin/admin_index_page.dart';
import 'package:security/Admin/authentication/login_screen_admin.dart';
import 'package:security/Admin/discussions/admin_manage_discussions.dart';
import 'package:security/Admin/profile/user_details_admin.dart';
import 'package:security/Admin/userManagement/admin_manage_users.dart';


class SideNavigationBar extends StatefulWidget {
  @override
  _SideNavigationBarState createState() => _SideNavigationBarState();
}

class _SideNavigationBarState extends State<SideNavigationBar> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  DocumentSnapshot? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      var userDocument = await FirebaseFirestore.instance
          .collection('Admin')
          .doc(currentUser!.uid)
          .get();
      if (userDocument.exists) {
        setState(() {
          userData = userDocument;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            TextButton(
              style: TextButton.styleFrom(primary: Colors.transparent),
              onPressed: () {
                if (userData != null) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AdminUserDetailsPage(userReference: userData!.reference),
                  ));
                }
              },
              child: UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                margin: EdgeInsets.zero,
                currentAccountPicture: CircleAvatar(
                  backgroundImage: userData != null && userData!['profilePicture'] != null
                      ? NetworkImage(userData!['profilePicture'])
                      : null,
                  child: userData != null && userData!['profilePicture'] != null
                      ? null
                      : Text(
                    userData != null ? userData!['name'][0] : 'A',
                    style: const TextStyle(fontSize: 40.0),
                  ),
                ),
                accountName: Text(
                  userData != null ? userData!['name'] : ' ',
                  style: const TextStyle(color: Colors.black),
                ),
                accountEmail: Text(
                  userData != null ? userData!['email'] : ' ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
            _customListTile(context, Icons.dashboard, 'Dashboard'),
            _customListTile(context, Icons.question_answer_outlined, 'Discussions'),
            _customListTile(context, Icons.people_alt_outlined, 'Users'),
            _customListTile(context, Icons.logout, 'Logout Account'),
          ],
        ),
      ),
    );
  }

  Widget _customListTile(BuildContext context, IconData icon, String text) {
    return TextButton(
      style: TextButton.styleFrom(primary: Colors.transparent),
      onPressed: () {
        if (text == 'Dashboard') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminIndexPage()));
        }
        if (text == 'Discussions') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminManageDiscussionsPage()));
        }
        if (text == 'Users') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminManageUsersPage()));
        }
        if (text == 'Logout Account') {
          _showLogoutDialog(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          leading: Icon(
            icon,
            color: Colors.black,
          ),
          title: Text(
            text,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to log out?'),
          actions: [
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreenAdmin()),
                      (Route<dynamic> route) => false,
                );
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }
}