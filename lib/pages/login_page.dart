import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tajiri_ai/components//input.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginpageState();
}

class _LoginpageState extends State<LoginPage> {
  bool _isLoading =false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
    bool isLoggedIn = false;
void login() async {
  if (_formKey.currentState!.validate()) {

    final email = _emailController.text;
    final password = _passwordController.text;
    setState(() {
      _isLoading = true;
    });
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
        ),
      );
    }

    try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      isLoggedIn = true;
      Navigator.pushReplacementNamed(context, "/homepage");
      _emailController.clear();
      _passwordController.clear();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: ${e.code}",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );

    }finally{
      setState(() {

        _isLoading = false;
      });

    }
  }else{
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Form Invalid: Retry Again")));
    setState(() {

      _isLoading = false;
    });
  }
}


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading? CircularProgressIndicator(value: 0.7,): Column(
          spacing: 15,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Image.asset("assets/logo.png", width: 200, height: 150),
            // Title
            Text(
              "Login",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 1, 0, 86),
              ),
            ),
           Form(


             key: _formKey,
             child: SizedBox(
               width: 300,
               child: SingleChildScrollView(
                 child: Column(
                     spacing: 15,
                     children: [
                     // Email Text field
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
                     }),
                       // Password TextField
                       TextFormField(
                         controller: _passwordController,
                         decoration: InputDecoration(labelText: 'Password',  border: OutlineInputBorder(
                           borderSide: BorderSide(color: Colors.black),
                         ),),
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
                       SizedBox(width: _isLoading? 35: 300,
                         child:  ElevatedButton(
                           onPressed: ()  {
                            login();
                         
                           },
                           child: Text("Login"),
                         ),
                       ),
                 
                     ]
                 
                 
                 
                            ),
               ),
             )),
            // Submit Button

            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/registerpage');
              },
              child: Text(
                "Don't have an account?",
                style: TextStyle(
                  fontSize: 15,
                  color: const Color.fromARGB(255, 1, 0, 86),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
