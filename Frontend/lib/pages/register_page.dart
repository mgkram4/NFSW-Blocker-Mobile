import 'package:ai3/components/my_button.dart';
import 'package:ai3/components/my_textfield.dart';
import 'package:ai3/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final TextEditingController emailController = TextEditingController();
final TextEditingController passwordController = TextEditingController();
final TextEditingController confirmPasswordController = TextEditingController();

void navigateToLoginPage(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
  );
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  void signUpUser(BuildContext context) async {
    try {
      if (passwordController.text == confirmPasswordController.text) {
        // Sign up the user
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Sign in the user after successful sign-up
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Clear the text fields
        emailController.clear();
        passwordController.clear();
        confirmPasswordController.clear();

        // Show success alert
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Sign up successful!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the alert dialog
                  // Navigate to the desired page after successful sign-in
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Display an error message if passwords don't match
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Passwords do not match'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Handle any errors that occur during sign-up
      print('Error signing up: $e');
      // Display error message on the screen
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Up Failed'),
          content: const Text('Please check your credentials and try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_add,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 30),
                // Sign Up
                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 30),
                // email textfield
                MyTextField(
                  controller: emailController,
                  hintText: "Email",
                  obscureText: false,
                  textColor: Colors.white,
                  fillColor: const Color(0xFF424242),
                ),
                // password textfield
                const SizedBox(height: 30),
                MyTextField(
                  controller: passwordController,
                  hintText: "Password",
                  obscureText: true,
                  textColor: Colors.white,
                  fillColor: const Color(0xFF424242),
                ),
                // confirm password textfield
                const SizedBox(height: 30),
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: "Confirm Password",
                  obscureText: true,
                  textColor: Colors.white,
                  fillColor: const Color(0xFF424242),
                ),
                //sign up button
                const SizedBox(height: 25),
                MyButton(
                  onTap: () => signUpUser(context),
                  color: const Color(0xFF121212),
                  text: 'Sign Up',
                ),

                const SizedBox(height: 25),

                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () => navigateToLoginPage(context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already a member?",
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Sign In",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
