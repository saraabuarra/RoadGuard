import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'active_page.dart';
import 'responding_page.dart';
import 'handled_page.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'alert_page.dart';

class DashboardPage extends StatefulWidget {
  final String userId;

  DashboardPage({required this.userId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool firstLoad = true;

  @override
  late DateTime openTime;
  void initState() {
    super.initState();
    openTime = DateTime.now();

    FirebaseDatabase.instance.ref("incidents").onChildAdded.listen((event) {
      final data = event.snapshot.value as Map?;

      if (data == null) return;

      String timestamp = data["timestamp"] ?? "";

      DateTime incidentTime = DateTime.parse(timestamp);

      if (incidentTime.isAfter(openTime)) {
        print("STATUS = ${data["status"]}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlertPage(
              incidentId: event.snapshot.key!,
              title: data["type"] ?? "",
              code: event.snapshot.key!,
              time: data["timestamp"] ?? "",
              status: data["status"] ?? "Active",
              userId: widget.userId,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF050505),
              Color(0xFF1a0000),
              Color(0xFF2b0000),
              Color(0xFF000814),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔥 HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RoadGuard",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Emergency Services System",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      /// 🔴 LOGOUT
                      GestureDetector(
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPage()),
                          );
                        },

                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Logout",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(width: 10),

                      /// ⚙️ SETTINGS
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SettingsPage(userId: widget.userId),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 30),

              Text(
                "Incident Dashboard",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),

              SizedBox(height: 25),

              /// 🔥 Firebase Counts
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseDatabase.instance.ref("incidents").onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final data =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;

                    if (data == null) {
                      return Center(
                        child: Text(
                          "No data",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    /// 🔥 counts (case insensitive)
                    int activeCount = data.entries
                        .where(
                          (e) =>
                              (e.value['status'] ?? "")
                                  .toString()
                                  .toLowerCase() ==
                              "active",
                        )
                        .length;

                    int respondingCount = data.entries
                        .where(
                          (e) =>
                              (e.value['status'] ?? "")
                                  .toString()
                                  .toLowerCase() ==
                              "responding",
                        )
                        .length;

                    int handledCount = data.entries
                        .where(
                          (e) =>
                              (e.value['status'] ?? "")
                                  .toString()
                                  .toLowerCase() ==
                              "handled",
                        )
                        .length;

                    return Column(
                      children: [
                        buildCard(
                          context: context,
                          color1: Color(0xFF5a0000),
                          color2: Color(0xFFc62828),
                          title: "Active",
                          subtitle: "Immediate attention required",
                          number: activeCount.toString(),
                          icon: Icons.warning_amber_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ActivePage(userId: widget.userId),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 20),

                        buildCard(
                          context: context,
                          color1: Color(0xFF5a2e00),
                          color2: Color(0xFFef6c00),
                          title: "Responding",
                          subtitle: "Units en route",
                          number: respondingCount.toString(),
                          icon: Icons.access_time,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RespondingPage(userId: widget.userId),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 20),

                        buildCard(
                          context: context,
                          color1: Color(0xFF003d1a),
                          color2: Color(0xFF00c853),
                          title: "Handled",
                          subtitle: "Resolved successfully",
                          number: handledCount.toString(),
                          icon: Icons.check_circle,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    HandledPage(userId: widget.userId),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCard({
    required BuildContext context,
    required Color color1,
    required Color color2,
    required String title,
    required String subtitle,
    required String number,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color2.withOpacity(0.35),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),

            SizedBox(width: 15),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),

            Spacer(),

            Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
