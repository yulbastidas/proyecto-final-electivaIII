import 'package:pets/domain/entities/post.dart';
import 'package:pets/domain/entities/comment_entity.dart';

abstract class FeedRepository {
  Future<List<Post>> getFeed({String? status, int limit, int offset});

  Future<Post> createPost({
    String? content,
    required String status,
    List<int>? imageBytes,
    String? filename,
    String? countryCode,
  });

  Future<Post> toggleLike(int postId);
  Future<void> deletePost(int postId);

  Future<CommentEntity> addComment({
    required int postId,
    required String authorId,
    required String text,
  });
}
