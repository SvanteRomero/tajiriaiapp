import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tajiri_ai/components/input.dart';
import 'package:tajiri_ai/models/userModel.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading= false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future registerUser() async {
    setState(() {
      _isLoading= true;
    });

    final email = _emailController.text;
    final password = _passwordController.text;
    final phone = _phoneController.text;
    final name = _nameController.text;
    final confirmPassword = _confirmPasswordController.text;

    try{
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await FirebaseFirestore.instance.collection('users').add({
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    Navigator.pushReplacementNamed(context, "/homepage");
    }on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ));
    }on FirebaseException catch (e){

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ));
    }finally{
      setState(() {
        _isLoading =false;
      });

    }

  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
registerUser();
    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Form Invalid, Try again"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 15,
            children: [
              Image.asset("assets/logo.png", width: 200, height: 150),
              // Title
              Text(
                "Register",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 1, 0, 86),
                ),
              ),

              SizedBox(
                width: 300,
                child: Form(
                  key: _formKey,
                  child: Column(
                    spacing: 15,
                    children: [
                      // Name TexField
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          hintText: "John Doe",
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                        },
                      ),
                      // Email TextField
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          hintText: "JohnDoe@example.com",
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          // Basic email format check (use a more robust regex or package for production)
                          final emailRegex = RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                          );
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }

                          return null; // Return null if valid
                        },
                      ),
                      TextFormField(
                        controller:
                            _phoneController, // Assuming _phoneController exists
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),

                          hintText: "0712345678",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a phone number';
                          }
                          // Add more specific phone validation if needed
                          return null; // Return null if valid
                        },
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null; // Return null if valid
                        },
                      ),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null; // Return null if valid
                        },
                      ),
                      SizedBox(
                        width: _isLoading?35:300,
                        child: _isLoading?CircularProgressIndicator():ElevatedButton(
                          onPressed: () {_submitForm();},
                          child: Text("Register"),
                        ),
                      ),

                    ],
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {

                  Navigator.pushNamed(context, '/loginpage');
                },
                child: Text(
                  "Already have an account?",
                  style: TextStyle(
                    fontSize: 15,
                    color: const Color.fromARGB(255, 1, 0, 86),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
