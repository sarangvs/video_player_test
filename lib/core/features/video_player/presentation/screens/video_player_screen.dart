import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_test/core/features/video_player/presentation/providers/video_provider.dart';
import 'package:video_player_test/core/features/video_player/providers/video_controller_provider.dart';

class VideoScreen extends ConsumerStatefulWidget {
  const VideoScreen({super.key});

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends ConsumerState<VideoScreen> {
  bool _controlsVisible = true; // To manage the visibility of controls
  late Timer _hideControlsTimer; // Timer for hiding controls

  @override
  void initState() {
    super.initState();
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer.cancel(); // Cancel the timer when widget is disposed
    super.dispose();
  }

  // Function to start the timer to hide controls after 2 seconds
  void _startHideControlsTimer() {
    _hideControlsTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  // Function to handle tap on the video and show controls again
  void _onVideoTap() {
    if (_controlsVisible) {
      _startHideControlsTimer(); // Restart timer when touched
    } else {
      setState(() {
        _controlsVisible = true;
      });
      _startHideControlsTimer(); // Restart timer when controls are shown
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    ? isPortrait
                        ? GestureDetector(
                          onTap:
                              _onVideoTap, // Detect tap to show/hide controls
                          child: Column(
                            children: [
                              // Video takes the top part of the screen
                              Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.3, // Adjust height
                                    child: VideoPlayer(controller),
                                  ),
                                  if (_controlsVisible) // Show controls only if visible
                                    Positioned(
                                      bottom: 100,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // 10-second skip backward button
                                          IconButton(
                                            icon: Icon(
                                              Icons.replay_10,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              final newPosition =
                                                  controller.value.position -
                                                  Duration(seconds: 10);
                                              controller.seekTo(newPosition);
                                            },
                                          ),

                                          // Play/Pause button
                                          IconButton(
                                            icon: Icon(
                                              controller.value.isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              controller.pause() !=
                                                  controller
                                                      .play(); // Plays both video and audio
                                            },
                                          ),

                                          // 10-second skip forward button
                                          IconButton(
                                            icon: Icon(
                                              Icons.forward_10,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              final newPosition =
                                                  controller.value.position +
                                                  Duration(seconds: 10);
                                              controller.seekTo(newPosition);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Seekbar
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ValueListenableBuilder<
                                            VideoPlayerValue
                                          >(
                                            valueListenable: controller,
                                            builder: (context, value, child) {
                                              return Slider(
                                                value:
                                                    value.position.inSeconds
                                                        .toDouble(),
                                                min: 0,
                                                max:
                                                    value.duration.inSeconds
                                                        .toDouble(),
                                                onChanged: (newValue) {
                                                  controller.seekTo(
                                                    Duration(
                                                      seconds: newValue.toInt(),
                                                    ),
                                                  );
                                                },
                                                activeColor: Colors.white,
                                                inactiveColor: Colors.grey,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // Blank space for description below the video
                              Expanded(
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: EdgeInsets.all(16),
                                  color: Colors.white,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Video Name",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Description goes here...",
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
                          ),
                        )
                        : SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: VideoPlayer(controller),
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
