import 'package:video_player_test/core/features/video_player/data/models/video_model.dart';

class VideoRepository {
  Future<VideoModel> fetchVideo() async {
    return VideoModel(
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    );
  }
}
