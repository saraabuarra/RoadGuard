import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'ChangePasswordPage.dart';

class SettingsPage extends StatefulWidget {
  final String userId; // 🔥 نمرر اليوزر الحالي

  SettingsPage({required this.userId});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  String userName = "";
  String userPhone = "";
  String userEmail = "";

  String role = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final snapshot = await FirebaseDatabase.instance
        .ref("users")
        .child(widget.userId)
        .get();

    print("USER ID = ${widget.userId}");
    print("EXISTS = ${snapshot.exists}");
    print("VALUE = ${snapshot.value}");

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        role = data["Role"]?.toString() ?? "";

        userName = data["Name"]?.toString() ?? "";
        userPhone = data["Phone"]?.toString() ?? "";
        userEmail = data["Email"]?.toString() ?? "";
      });
    }
  }

  bool hasChanges() {
    return nameController.text.isNotEmpty ||
        phoneController.text.isNotEmpty ||
        emailController.text.isNotEmpty;
  }

  void handleSave() async {
    if (!hasChanges()) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.black,
          title: Text("No Changes", style: TextStyle(color: Colors.white)),
          content: Text(
            "You didn’t modify anything",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: Text("OK", style: TextStyle(color: Colors.redAccent)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      final db = FirebaseDatabase.instance.ref();

      Map<String, dynamic> updatedData = {};

      if (nameController.text.isNotEmpty) {
        updatedData["Name"] = nameController.text;
      }

      if (phoneController.text.isNotEmpty) {
        updatedData["Phone"] = phoneController.text;
      }

      if (emailController.text.isNotEmpty) {
        updatedData["Email"] = emailController.text;
      }

      // ✅ التعديل على اليوزر الصحيح
      await db.child("users").child(widget.userId).update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Updated successfully"),
          backgroundColor: Colors.green,
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),

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

                SizedBox(height: 10),

                Text(
                  "Profile Settings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  "Manage your account information",
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),

                SizedBox(height: 30),

                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                ),

                SizedBox(height: 30),

                buildField(
                  "Full Name",
                  nameController,
                  Icons.person,
                  hint: userName,
                ),

                buildField(
                  "Phone Number",
                  phoneController,
                  Icons.phone,
                  hint: userPhone,
                ),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email, color: Colors.white70),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          userEmail,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                buildRoleCard(role),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 20),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.lock_reset, color: Colors.white),
                    label: Text(
                      "Change Password",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Colors.redAccent.withOpacity(0.5),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChangePasswordPage()),
                      );
                    },
                  ),
                ),

                SizedBox(height: 25),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE53935),
                    minimumSize: Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: handleSave,
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: 10),

                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white24),
                    minimumSize: Size(double.infinity, 55),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRoleCard(String role) {
    String currentRole = role.toString().toLowerCase();

    IconData roleIcon = Icons.security;
    Color roleColor = Colors.redAccent;

    if (currentRole == "police") {
      roleIcon = Icons.local_police;
      roleColor = Colors.redAccent;
    } else if (currentRole == "ambulance") {
      roleIcon = Icons.medical_services;
      roleColor = Colors.redAccent;
    } else if (currentRole == "firefighter") {
      roleIcon = Icons.local_fire_department;
      roleColor = Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Role", style: TextStyle(color: Colors.white70, fontSize: 13)),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: roleColor.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: roleColor.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: roleColor.withOpacity(0.15),
                  child: Icon(roleIcon, color: roleColor, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    role.isEmpty ? "Unknown" : role,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget buildField(
    String title,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    String hint = "",
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white70, fontSize: 13)),

          SizedBox(height: 6),

          TextField(
            controller: controller,
            readOnly: readOnly,
            obscureText: title == "Password",
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint.isEmpty ? title : hint,
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: Icon(icon, color: Colors.white70),
              filled: true,
              fillColor: Colors.black.withOpacity(0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
