import 'package:ai3/components/my_button.dart';
import 'package:ai3/components/my_textfield.dart';
import 'package:ai3/components/square_tile.dart';
import 'package:ai3/pages/register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final TextEditingController usernameController = TextEditingController();
final TextEditingController passwordController = TextEditingController();

void navigateToRegisterPage(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => RegisterPage()),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  void signUserIn(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: usernameController.text,
        password: passwordController.text,
      );
    } catch (e) {
      // Handle any errors that occur during sign-in
      print('Error signing in: $e');
      // Display error message on the screen
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Failed'),
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
                  Icons.people,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 30),
                // Hello Again
                const Text(
                  'Hello Again!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 30),
                // email textfield
                MyTextField(
                  controller: usernameController,
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
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                //sign in button
                const SizedBox(height: 25),
                MyButton(
                  onTap: () => signUserIn(context),
                  color: const Color(0xFF121212),
                  text: 'Sign In',
                ),

                const SizedBox(height: 25),
                Column(
                  children: [
                    Divider(
                      thickness: 0.5,
                      color: Colors.grey[800],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Column(
                        children: [
                          Text(
                            'Or continue with',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SqaureTile(
                                icon: Icon(
                                  Icons.g_mobiledata_outlined,
                                  color: Colors.green,
                                  size: 32,
                                  semanticLabel: 'Google',
                                ),
                              ),
                              SizedBox(width: 25),
                              SqaureTile(
                                icon: Icon(
                                  Icons.facebook,
                                  color: Colors.blue,
                                  size: 32,
                                  semanticLabel: 'Facebook',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      thickness: 0.5,
                      color: Colors.grey[800],
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () => navigateToRegisterPage(context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Not a member?",
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Register Now",
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
