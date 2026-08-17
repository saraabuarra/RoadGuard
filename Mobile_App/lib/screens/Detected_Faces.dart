import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DetectedFacesPage extends StatelessWidget {
  final String incidentId;

  const DetectedFacesPage({super.key, required this.incidentId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0a0a0a), Color(0xFF2b0000), Color(0xFF000000)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(height: 20),

              const Text(
                "Detected Faces",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(incidentId, style: const TextStyle(color: Colors.white70)),

              const SizedBox(height: 10),

              const Text(
                "Faces automatically detected from captured video evidence",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),

              const SizedBox(height: 12),

              StreamBuilder(
                stream: FirebaseDatabase.instance
                    .ref("incidents/$incidentId/detectedFaces")
                    .onValue,
                builder: (context, snapshot) {
                  int count = 0;

                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    final faces = snapshot.data!.snapshot.value as List;
                    count = faces.length;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$count Faces Detected",
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              Expanded(
                child: StreamBuilder(
                  stream: FirebaseDatabase.instance
                      .ref("incidents/$incidentId/detectedFaces")
                      .onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data!.snapshot.value;

                    if (data == null) {
                      return const Center(
                        child: Text(
                          "No Faces Detected",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final faces = data as List;

                    return GridView.builder(
                      itemCount: faces.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                      itemBuilder: (context, index) {
                        final face = faces[index];
                        print(face);
                        print(face['image']);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Scaffold(
                                    backgroundColor: Colors.black,
                                    body: Stack(
                                      children: [
                                        SizedBox.expand(
                                          child: InteractiveViewer(
                                            minScale: 1,
                                            maxScale: 5,
                                            child: Image.network(
                                              face['image'],
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),

                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Image.network(
                                face['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print("ERROR = $error");

                                  return const Center(
                                    child: Text(
                                      "Image Error",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
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

  Widget faceCard(String id) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            id,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Detected at 14:23:15",
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
