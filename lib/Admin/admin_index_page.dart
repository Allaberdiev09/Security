import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:security/Admin/discussions/admin_manage_discussions.dart';
import 'package:security/Admin/services/admin_side_navigation.dart';
import 'package:security/Admin/userManagement/admin_manage_users.dart';

class AdminIndexPage extends StatefulWidget {
  @override
  _AdminIndexPageState createState() => _AdminIndexPageState();
}

class _AdminIndexPageState extends State<AdminIndexPage> {

  Future<int> getTotalDiscussions() async {
    DataSnapshot dataSnapshot =
        await FirebaseDatabase.instance.ref().child('Discussions').get();
    return dataSnapshot.children.length;
  }

  Future<int> getTotalUsers() async {
    int usersCount =
        (await FirebaseFirestore.instance.collection('Users').get())
            .docs
            .length;
    return usersCount;
  }

  Widget _buildStatCard(
      String title, Future<int> countFuture, Color color, VoidCallback onTap) {
    return FutureBuilder<int>(
      future: countFuture,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        String countText = snapshot.hasData
            ? 'Total ${snapshot.data} ${title}'
            : 'Loading...';
        return GestureDetector(
          onTap: onTap,
          child: Card(
            elevation: 5,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child: Text(title[0]),
              ),
              title: Text('Manage $title'),
              subtitle: Text(countText),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      drawer: SideNavigationBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            _buildStatCard('Discussions', getTotalDiscussions(), Colors.green,
                () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => AdminManageDiscussionsPage()));
            }),
            _buildStatCard('Users', getTotalUsers(), Colors.redAccent, () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => AdminManageUsersPage()));
            }),
          ],
        ),
      ),
    );
  }
}
