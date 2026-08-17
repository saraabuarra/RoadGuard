import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'incident_details_page.dart';
import 'responding_page.dart';
import 'handled_page.dart';

class ActivePage extends StatelessWidget {
  final String userId;

  const ActivePage({
    super.key,
    required this.userId,
  });
  @override
  Widget build(BuildContext context) {
    final userId = this.userId;
    return buildPage(
      context,
      title: "Active Incidents",
      items: [
        /// 🔥 Firebase Stream
        StreamBuilder(
          stream: FirebaseDatabase.instance.ref("incidents").onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Expanded(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final data =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;

            if (data == null) {
              return const Expanded(
                child: Center(
                  child: Text(
                    "No incidents",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            /// 🔥 FIX: دعم كابيتال وسمول
            final activeItems = data.entries.where((e) {
              return (e.value['status'] ?? "").toString().toLowerCase() ==
                  "active";
            }).toList();

            return Expanded(
              child: ListView(
                children: activeItems.map((e) {
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
              ),
            );
          },
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
      decoration: const BoxDecoration(
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
            const SizedBox(height: 40),

            /// 🔙 رجوع
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "RoadGuard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Real-time Emergency Monitoring",
                      style: TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 25),

            /// 🔴 العنوان
            Row(
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  "Active Incidents",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            /// 🔥 القائمة
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
){
  return InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncidentDetailsPage(
            title: title,
            code: code,
            time: time,
            status: "Active",
            incidentId: incidentId,
            userId: userId,
          ),
        ),
      );

      if (result == "responding") {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RespondingPage(
        incidentIdToOpen: incidentId,
        userId: userId,
      ),
    ),
  );
}
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3b0000), Color(0xFFb71c1c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🚗 / 🔥 أيقونة حسب النوع
          Container(
            padding: const EdgeInsets.all(10),
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

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔴 عنوان + ACTIVE
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "ACTIVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  code,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 8),

                /// ⏰ الوقت
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
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
