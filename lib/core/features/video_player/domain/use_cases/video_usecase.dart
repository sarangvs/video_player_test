import 'package:video_player_test/core/features/video_player/data/models/video_model.dart';
import 'package:video_player_test/core/features/video_player/data/repositories/video_repository.dart';

class GetVideoUseCase {
  final VideoRepository repository;

  GetVideoUseCase(this.repository);

  Future<VideoModel> execute() async {
    return repository.fetchVideo();
  }
}
