import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'active_page.dart';
import 'incident_details_page.dart';

class AlertPage extends StatefulWidget {
  final String incidentId;
  final String title;
  final String code;
  final String time;
  final String status;
  final String userId;

  const AlertPage({
    super.key,
    required this.incidentId,
    required this.title,
    required this.code,
    required this.time,
    required this.status,
    required this.userId,
  });

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();

    player.setReleaseMode(ReleaseMode.loop); // 🔁 يكرر الصوت
    player.play(AssetSource('sounds/alert.mp3')); // 🔥 المسار
  }

  @override
  void dispose() {
    player.stop(); // 🔇 يوقف الصوت لما نطلع
    super.dispose();
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

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "RoadGuard",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "Emergency Services System",
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),

            SizedBox(height: 60),

            Container(
              padding: EdgeInsets.all(35),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.2),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
                size: 60,
              ),
            ),

            SizedBox(height: 30),

            Text(
              "Emergency Alert",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Ringing...",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),

            SizedBox(height: 50),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE53935),
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                player.stop(); // 🔇 يوقف الصوت أول

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IncidentDetailsPage(
                      title: widget.title,
                      code: widget.code,
                      time: widget.time,
                      status: widget.status,
                      incidentId: widget.incidentId,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
              child: Text("Received", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
