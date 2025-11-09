import 'package:pets/domain/entities/post.dart';

abstract class FeedRepository {
  Future<List<Post>> getFeed({String? status, int limit, int offset});

  Future<Post> createPost({
    String? content,
    required String status,
    List<int>? imageBytes,
    String? filename,
    String? countryCode,
  });

  Future<Post> toggleLike(int postId); // <-- reañadido
  Future<void> deletePost(int postId);
}
