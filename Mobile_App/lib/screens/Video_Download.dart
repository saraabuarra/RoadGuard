import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

class VideoDownloadPage extends StatefulWidget {
  final String videoUrl;
  final int duration;
  final String format;
  final String timestamp;
  final List<Color> pageColors;
  final Color mainColor;

  const VideoDownloadPage({
    super.key,
    required this.videoUrl,
    required this.duration,
    required this.format,
    required this.timestamp,
    required this.pageColors,
    required this.mainColor,
  });

  @override
  State<VideoDownloadPage> createState() => _VideoDownloadPageState();
}

class _VideoDownloadPageState extends State<VideoDownloadPage> {
  late VideoPlayerController controller;
  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    controller.addListener(() {
      print(controller.value.position);
      print(controller.value.duration);
      print("playing = ${controller.value.isPlaying}");
      if (controller.value.position >=
          controller.value.duration - const Duration(milliseconds: 300)) {}

      if (mounted) {
        setState(() {});
      }
    });

    controller.initialize().then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.pageColors,
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
                const SizedBox(height: 40),

                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Video Download",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Text(
                  "VID-2026-002",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () async {
                    if (controller.value.position >=
                        controller.value.duration) {
                      await controller.seekTo(Duration.zero);
                    }

                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }

                    setState(() {});
                  },
                  child: controller.value.isInitialized
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 220,
                              width: double.infinity,
                              child: VideoPlayer(controller),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      backgroundColor: Colors.black,
                                      insetPadding: const EdgeInsets.all(10),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: GestureDetector(
                                              onTap: () {
                                                if (controller
                                                    .value
                                                    .isPlaying) {
                                                  controller.pause();
                                                } else {
                                                  controller.play();
                                                }
                                                setState(() {});
                                              },
                                              child: AspectRatio(
                                                aspectRatio: controller
                                                    .value
                                                    .aspectRatio,
                                                child: AnimatedBuilder(
                                                  animation: controller,
                                                  builder: (context, child) {
                                                    return Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        VideoPlayer(controller),

                                                        if (!controller
                                                                .value
                                                                .isPlaying ||
                                                            controller
                                                                    .value
                                                                    .position >=
                                                                controller
                                                                    .value
                                                                    .duration)
                                                          const Icon(
                                                            Icons
                                                                .play_circle_fill,
                                                            color: Colors
                                                                .redAccent,
                                                            size: 80,
                                                          ),
                                                      ],
                                                    );
                                                  },
                                                ),
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
                              ),
                            ),

                            if (!controller.value.isPlaying)
                              const Icon(
                                Icons.play_circle_fill,
                                color: Colors.redAccent,
                                size: 70,
                              ),
                          ],
                        )
                      : Container(
                          height: 190,
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                ),

                const SizedBox(height: 15),

                Text(
                  "Captured on ${widget.timestamp.replaceFirst("T", " ")}",
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    FileDownloader.downloadFile(
                      url: widget.videoUrl,
                      onDownloadCompleted: (path) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Video downloaded successfully"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black,
                          widget.mainColor.withOpacity(0.9),
                          Colors.black,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        "Download Video",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.mainColor, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Video Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Duration",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "${widget.duration} sec",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Format",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            widget.format,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ), // Column
          ), // SingleChildScrollView
        ), // Padding
      ), // Container
    ); // Scaffold
  }
}
