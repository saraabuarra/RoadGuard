import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'incident_details_page.dart';

class HandledPage extends StatelessWidget {
  final String? incidentIdToOpen;
  final String userId;

  const HandledPage({super.key, this.incidentIdToOpen, required this.userId});

  @override
  Widget build(BuildContext context) {
    return buildPage(
      context,
      title: "Handled Incidents",
      items: [
        Expanded(
          child: StreamBuilder(
            stream: FirebaseDatabase.instance.ref("incidents").onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data =
                  snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;

              if (data == null) {
                return const Center(
                  child: Text(
                    "No incidents",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              /// ✅ FIX: دعم كابيتال وسمول
              final handledItems = data.entries.where((e) {
                return (e.value['status'] ?? "").toString().toLowerCase() ==
                    "handled";
              }).toList();
              if (incidentIdToOpen != null &&
                  handledItems.any((e) => e.key == incidentIdToOpen)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final incident = handledItems.firstWhere(
                    (e) => e.key == incidentIdToOpen,
                  );

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IncidentDetailsPage(
                        title: incident.value["type"] ?? "Unknown",
                        code: incident.key,
                        time: incident.value["timestamp"] ?? "",
                        status: "Handled",
                        incidentId: incident.key,
                        userId: userId,
                      ),
                    ),
                  );
                });
              }

              return ListView(
                children: handledItems.map((e) {
                  final incident = e.value;

                  return buildItem(
                    context,
                    incident['type'] ?? "Unknown",
                    e.key,
                    incident['timestamp'] ?? "",
                    e.key,
                    userId,
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget buildPage(
  BuildContext context, {
  required String title,
  required List<Widget> items,
}) {
  return Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF000000),
            Color(0xFF140000),
            Color(0xFF2a0000),
            Color(0xFF000000),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RoadGuard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Resolved Emergency Cases",
                      style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 25),

            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            SizedBox(height: 25),

            ...items,
          ],
        ),
      ),
    ),
  );
}

/// 🔥 الكارد
Widget buildItem(
  BuildContext context,
  String title,
  String code,
  String time,
  String incidentId,
  String userId,
) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
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
    },
    child: Container(
      margin: EdgeInsets.only(bottom: 18),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003d1a), Color(0xFF00c853)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.5),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔥 أيقونة حسب النوع
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              title.toLowerCase() == "fire"
                  ? Icons.local_fire_department
                  : Icons.directions_car,
              color: Colors.white,
              size: 24,
            ),
          ),

          SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "HANDLED",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 5),

                Text(
                  code,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white70, size: 14),
                    SizedBox(width: 5),
                    Text(
                      time,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
