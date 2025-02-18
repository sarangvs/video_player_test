import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_test/core/features/video_player/presentation/providers/video_provider.dart';
import 'package:video_player_test/core/features/video_player/providers/video_controller_provider.dart';

class VideoScreen extends ConsumerWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoAsync = ref.watch(videoProvider);
    final controller = ref.watch(videoControllerProvider);

    return OrientationBuilder(
      builder: (context, orientation) {
        bool isPortrait = orientation == Orientation.portrait;

        // Hide system UI in landscape mode
        if (!isPortrait) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        } else {
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: videoAsync.when(
              data: (videoUrl) {
                if (controller == null || !controller.value.isInitialized) {
                  ref
                      .read(videoControllerProvider.notifier)
                      .initializeController(videoUrl.url);
                }

                return controller != null && controller.value.isInitialized
                    ? Stack(
                      alignment: Alignment.center,
                      children: [
                        isPortrait
                            ? Column(
                              children: [
                                // Video at the top (YouTube-style)
                                FractionallySizedBox(
                                  widthFactor: 1,
                                  child: AspectRatio(
                                    aspectRatio: controller.value.aspectRatio,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        VideoPlayer(controller),
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: VideoControls(
                                            controller: controller,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Video details section
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    width: MediaQuery.of(context).size.width,
                                    color: Colors.white,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Butterfly Video",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          "A beautiful butterfly in slow motion",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                            : Container(
                              width: double.infinity,
                              height: double.infinity,
                              alignment: Alignment.center,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AspectRatio(
                                    aspectRatio: controller.value.aspectRatio,
                                    child: VideoPlayer(controller),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: VideoControls(
                                      controller: controller,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    )
                    : CircularProgressIndicator();
              },
              loading: () => CircularProgressIndicator(),
              error:
                  (error, stack) => Text(
                    'Error: $error',
                    style: TextStyle(color: Colors.white),
                  ),
            ),
          ),
        );
      },
    );
  }
}

// Video Controls Widget
class VideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  const VideoControls({super.key, required this.controller});

  @override
  _VideoControlsState createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
  bool isPlaying = false;
  bool showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (mounted) {
        setState(() {
          isPlaying = widget.controller.value.isPlaying;
        });
      }
    });

    // Show controls for first 2 seconds
    _startHideTimer(initialDelay: 2);
  }

  void _toggleControls() {
    setState(() {
      showControls = !showControls;
    });

    if (showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _startHideTimer({int initialDelay = 3}) {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: initialDelay), () {
      if (mounted) {
        setState(() {
          showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: AnimatedOpacity(
        opacity: showControls ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VideoProgressIndicator(
                widget.controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        isPlaying
                            ? widget.controller.pause()
                            : widget.controller.play();
                      });

                      _toggleControls();
                    },
                  ),
                  Text(
                    "${_formatDuration(widget.controller.value.position)} / ${_formatDuration(widget.controller.value.duration)}",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }
}
