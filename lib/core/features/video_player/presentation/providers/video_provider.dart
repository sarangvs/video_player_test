import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player_test/core/features/video_player/data/models/video_model.dart';
import 'package:video_player_test/core/features/video_player/data/repositories/video_repository.dart';
import 'package:video_player_test/core/features/video_player/domain/use_cases/video_usecase.dart';

final videoRepositoryProvider = Provider((ref) => VideoRepository());
final getVideoUseCaseProvider = Provider(
  (ref) => GetVideoUseCase(ref.read(videoRepositoryProvider)),
);

final videoProvider = FutureProvider<VideoModel>((ref) async {
  final useCase = ref.read(getVideoUseCaseProvider);
  return useCase.execute();
});
