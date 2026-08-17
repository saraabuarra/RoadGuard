import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // ✅ هذا الصح
import 'dashboard_page.dart';
import 'map_page.dart';
import 'Detected_Faces.dart';
import 'Video_Download.dart';
import 'responding_page.dart';
import 'handled_page.dart';

class IncidentDetailsPage extends StatelessWidget {
  final String title;
  final String code;
  final String time;
  final String status;
  final String incidentId;
  final String userId;

  const IncidentDetailsPage({
    super.key,
    required this.title,
    required this.code,
    required this.time,
    required this.status,
    required this.incidentId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final currentStatus = status.trim().toLowerCase();

    bool isActive = currentStatus == "active";
    bool isResponding = currentStatus == "responding";
    bool isHandled = currentStatus == "handled";

    print("isActive = $isActive");
    print("isResponding = $isResponding");
    print("isHandled = $isHandled");

    Color mainColor = isActive
        ? const Color(0xFFD32F2F)
        : isResponding
        ? const Color(0xFFF57C00)
        : const Color(0xFF2E7D32);

    return FutureBuilder(
      future: FirebaseDatabase.instance
          .ref("incidents/$incidentId/location")
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final location = Map<String, dynamic>.from(snapshot.data!.value as Map);

        double testLat = (location["latitude"] as num).toDouble();

        double testLng = (location["longitude"] as num).toDouble();

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [mainColor, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white),
                          SizedBox(width: 6),
                          Text("Back", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: mainColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    Text(title, style: const TextStyle(color: Colors.white70)),

                    const SizedBox(height: 20),

                    /// 📍 GPS
                    buildCard(
                      "GPS Location",
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Latitude: $testLat",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "Longitude: $testLng",
                            style: const TextStyle(color: Colors.white70),
                          ),

                          const SizedBox(height: 10),

                          _MapBox(lat: testLat, lng: testLng),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance
                            .ref("incidents/$incidentId")
                            .get();

                        if (!snapshot.exists || snapshot.value == null) {
                          return;
                        }

                        final incidentData = Map<String, dynamic>.from(
                          snapshot.value as Map,
                        );

                        final videoData = Map<String, dynamic>.from(
                          incidentData["video"],
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoDownloadPage(
                              videoUrl: videoData["videoUrl"],
                              duration: videoData["duration"],
                              format: videoData["format"],
                              timestamp: incidentData["timestamp"],
                              pageColors: [
                                Colors.black,
                                mainColor.withOpacity(0.8),
                                mainColor,
                              ],
                              mainColor: mainColor,
                            ),
                          ),
                        );
                      },
                      child: buildCard(
                        isHandled ? "Stored Video Evidence" : "Video Evidence",
                        const Center(child: VideoCircle()),
                      ),
                    ),

                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance
                            .ref("incidents/$incidentId/detectedFaces")
                            .get();

                        if (!snapshot.exists || snapshot.value == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No faces detected")),
                          );

                          return;
                        }

                        final faces = snapshot.value as List;

                        if (faces.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No faces detected")),
                          );

                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DetectedFacesPage(incidentId: incidentId),
                          ),
                        );
                      },
                      child: buildCard(
                        isHandled ? "Face Detection Results" : "Face Detection",
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StreamBuilder(
                              stream: FirebaseDatabase.instance
                                  .ref("incidents/$incidentId/detectedFaces")
                                  .onValue,
                              builder: (context, snapshot) {
                                int count = 0;

                                if (snapshot.hasData &&
                                    snapshot.data!.snapshot.value != null) {
                                  final faces =
                                      snapshot.data!.snapshot.value as List;
                                  count = faces.length;
                                }

                                return Text(
                                  count == 0
                                      ? "No Faces Detected"
                                      : "Detected Faces\n$count",
                                  style: const TextStyle(color: Colors.white),
                                );
                              },
                            ),

                            CircleAvatar(
                              backgroundColor: mainColor,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    /// 🔥 BUTTON (المعدل فقط)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () async {
                          final ref = FirebaseDatabase.instance.ref(
                            "incidents/$incidentId",
                          );

                          if (isActive) {
                            await ref.update({"status": "Responding"});

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => IncidentDetailsPage(
      title: title,
      code: code,
      time: time,
      status: "Responding",
      incidentId: incidentId,
      userId: userId,
    ),
  ),
);
                          } else if (isResponding) {
                            await ref.update({"status": "Handled"});

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => IncidentDetailsPage(
      title: title,
      code: code,
      time: time,
      status: "Handled",
      incidentId: incidentId,
      userId: userId,
    ),
  ),
);
                          } else if (isHandled) {
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                          }
                        },
                        child: Text(
                          isActive
                              ? "Acknowledge"
                              : isResponding
                              ? "Mark as Handled"
                              : "Incident Resolved - Read Only",
                          style: const TextStyle(
                            color: Color(0xFFFFF3E0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// 🔥 Map Box
class _MapBox extends StatelessWidget {
  final double lat;
  final double lng;

  const _MapBox({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MapPage(lat: lat, lng: lng),
          ),
        );
      },
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.location_on, color: Colors.red, size: 30),
            SizedBox(height: 6),
            Text(
              "Tap to view location on map",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoCircle extends StatelessWidget {
  const VideoCircle();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      backgroundColor: Colors.black,
      child: Icon(Icons.play_arrow, color: Colors.orange),
    );
  }
}
