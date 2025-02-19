import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

class VideoControllerNotifier extends StateNotifier<VideoPlayerController?> {
  VideoControllerNotifier() : super(null);

  Future<void> initializeController(String url) async {
    // Checking if the controller is already initialized
    if (state != null && state!.value.isInitialized) return;

    // Create a new controller
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));

    // Initialize and play the video when ready

    await controller.initialize();
    controller.setLooping(true);
    state = controller;
    controller.play();
  }

  @override
  void dispose() {
    state?.dispose();
    super.dispose();
  }
}

// Provider to access the video controller state
final videoControllerProvider =
    StateNotifierProvider<VideoControllerNotifier, VideoPlayerController?>(
      (ref) => VideoControllerNotifier(),
    );
