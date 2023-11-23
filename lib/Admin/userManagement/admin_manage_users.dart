import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:security/Admin/services/admin_side_navigation.dart';
import 'package:security/Admin/userManagement/create_users_page.dart';
import 'package:security/Admin/userManagement/user_details.dart';

class AdminManageUsersPage extends StatefulWidget {
  AdminManageUsersPage({Key? key}) : super(key: key);

  @override
  _AdminManageUsersPageState createState() => _AdminManageUsersPageState();
}

class _AdminManageUsersPageState extends State<AdminManageUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? currentUserId;
  String _searchTerm = '';
  TextEditingController _searchController = TextEditingController();
  String _filterRole = '';

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Manage Users',
          style: TextStyle(fontSize: 20),
        ),
      ),
      drawer: SideNavigationBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildUserList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CreateUsersPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 2.0),
                hintText: 'Search users',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchTerm = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            _showFilterDropdown(context);
          },
        ),
      ],
    );
  }

  void _showFilterDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Role',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 8.0),
              DropdownButton<String>(
                isExpanded: true,
                value: _filterRole.isNotEmpty ? _filterRole : null,
                items: <String>['Teacher', 'Student', 'Clear Filter']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    if (newValue == 'Clear Filter') {
                      _filterRole = '';
                    } else {
                      _filterRole = newValue ?? '';
                    }
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        List<QueryDocumentSnapshot> userDocuments =
            snapshot.data!.docs.where((doc) {
          var user = doc.data() as Map<String, dynamic>;
          if (_searchTerm.isNotEmpty &&
              !user['name'].toLowerCase().contains(_searchTerm.toLowerCase())) {
            return false;
          }
          if (_filterRole.isNotEmpty &&
              _filterRole != 'Clear Filter' &&
              user['role'] != _filterRole) {
            return false;
          }
          return true;
        }).toList();

        return ListView.builder(
          itemCount: userDocuments.length,
          itemBuilder: (context, index) {
            var user = userDocuments[index].data() as Map<String, dynamic>;
            DocumentReference userReference = userDocuments[index]
                .reference;
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserDetailsPage(
                        userReference:
                            userReference),
                  ),
                );
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user['profilePicture']),
                ),
                title: Text(user['name']),
                subtitle: Text(user['role']),
              ),
            );
          },
        );
      },
    );
  }
}
