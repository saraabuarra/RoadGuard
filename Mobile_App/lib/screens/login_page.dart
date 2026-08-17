import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../main.dart';
import 'dashboard_page.dart';
import 'resetPassword_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode passwordFocus = FocusNode();

  bool hidePassword = true;

  Future<void> handleLogin(BuildContext context) async {
    String email = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    try {
      // تسجيل دخول من Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // جلب userId من Realtime Database
      final snapshot = await FirebaseDatabase.instance.ref("users").get();

      String currentUserId = "";

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        data.forEach((key, value) {
          final user = Map<String, dynamic>.from(value);

          if (user["Email"] == email) {
            currentUserId = key;
          }
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage(userId: currentUserId)),
      );
    } on FirebaseAuthException {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Wrong email or password")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF000000),
                  Color(0xFF1a0000),
                  Color(0xFF3b0000),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => StartPage()),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', width: 100),

                SizedBox(height: 20),

                Text(
                  "RoadGuard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  "Emergency Services Access",
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),

                SizedBox(height: 40),

                TextField(
                  controller: usernameController,
                  style: TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(passwordFocus);
                  },
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                TextField(
                  controller: passwordController,
                  focusNode: passwordFocus,
                  obscureText: hidePassword,
                  style: TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    handleLogin(context);
                  },
                  decoration: InputDecoration(
                    hintText: "Enter your password",
                    hintStyle: TextStyle(color: Colors.grey),

                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),

                    filled: true,
                    fillColor: Colors.black.withOpacity(0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE53935),
                    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    handleLogin(context);
                  },
                  child: Text(
                    "LOGIN",
                    style: TextStyle(color: Colors.white, letterSpacing: 1.5),
                  ),
                ),

                SizedBox(height: 15),

                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResetPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Reset Password?",
                      style: TextStyle(
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
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
