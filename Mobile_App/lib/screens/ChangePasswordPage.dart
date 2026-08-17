import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;

  Future<void> updatePassword() async {
    try {
      if (newPasswordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Passwords do not match"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No user logged in"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password updated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF140000), Color(0xFF2a0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),

                    Text(
                      "RoadGuard",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                Text(
                  "Change Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  "Update your account password securely",
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),

                SizedBox(height: 35),

                Center(
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.redAccent.withOpacity(0.15),
                    child: Icon(
                      Icons.lock_reset,
                      color: Colors.redAccent,
                      size: 45,
                    ),
                  ),
                ),

                SizedBox(height: 35),

                buildPasswordField(
                  "Current Password",
                  currentPasswordController,
                  hideCurrent,
                  () {
                    setState(() {
                      hideCurrent = !hideCurrent;
                    });
                  },
                ),

                buildPasswordField(
                  "New Password",
                  newPasswordController,
                  hideNew,
                  () {
                    setState(() {
                      hideNew = !hideNew;
                    });
                  },
                ),

                buildPasswordField(
                  "Confirm Password",
                  confirmPasswordController,
                  hideConfirm,
                  () {
                    setState(() {
                      hideConfirm = !hideConfirm;
                    });
                  },
                ),

                SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE53935),
                    minimumSize: Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: updatePassword,

                  child: Text(
                    "Update Password",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),

                SizedBox(height: 12),

                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white24),
                    minimumSize: Size(double.infinity, 55),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPasswordField(
    String title,
    TextEditingController controller,
    bool obscure,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white70, fontSize: 13)),

          SizedBox(height: 6),

          TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: title,
              hintStyle: TextStyle(color: Colors.white38),

              prefixIcon: Icon(Icons.lock, color: Colors.white70),

              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: onTap,
              ),

              filled: true,
              fillColor: Colors.black.withOpacity(0.45),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white24),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
