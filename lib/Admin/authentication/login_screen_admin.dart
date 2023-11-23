// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:security/Admin/admin_index_page.dart';
import 'package:security/Admin/authentication/forget_password_screen.dart';
import 'package:security/Admin/services/admin_credentials.dart';
import 'package:security/Users/authentication/login_screen.dart';

class LoginScreenAdmin extends StatefulWidget {
  @override
  _LoginScreenAdminState createState() => _LoginScreenAdminState();
}

class _LoginScreenAdminState extends State<LoginScreenAdmin> {

  bool _isPasswordVisible = false;
  String? emailError;
  String? passwordError;
  bool isLoading = false; // Track loading state

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$")
        .hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 8;
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

  Future<void> _login() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        emailError = "Please enter email.";
      });
      return;
    } else if (!_isValidEmail(_emailController.text.trim())) {
      setState(() {
        emailError = "Invalid email format.";
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        passwordError = "Please enter password.";
      });
      return;
    } else if (!_isValidPassword(_passwordController.text)) {
      setState(() {
        passwordError = "Password must be at least 8 characters long.";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        if (await _isAdmin(userCredential.user!)) {
          AdminCredentials.email = _emailController.text.trim();
          AdminCredentials.password = _passwordController.text;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminIndexPage()),
          );
        } else {
          await FirebaseAuth.instance.signOut();
          _showErrorForDialogForNonAdmin("Error", "You are not an admin.");
        }
      } else {
        _showErrorDialog("Login Failed", "Please try again.");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'INVALID_LOGIN_CREDENTIALS') {
        _showErrorDialog("Login Failed", "Invalid email or password.");
      } else {
        _showErrorDialog(
            "Error", "An error occurred during login. Please try again.");
        print("Error: $e");
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorForDialogForNonAdmin(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                      (Route<dynamic> route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            child: Stack(
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        const Text(
                          '! Admin Login !',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          key: const Key("email"),
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: const OutlineInputBorder(),
                            errorText: emailError,
                          ),
                          onChanged: (value) {
                            setState(() {
                              emailError = null;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          key: const Key("password"),
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            errorText: passwordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              passwordError = null;
                            });
                          },
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => LoginScreen()));
                              },
                              child: const Text(
                                'Back to User Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ForgetPassword()));
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                          key: const Key("loginButton"),
                          onPressed: () {
                            _login();
                          },
                          child: const Text('Login'),
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(365, 50),
                            textStyle: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
