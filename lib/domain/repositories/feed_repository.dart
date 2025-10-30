import '../entities/post_entity.dart';
import '../entities/comment_entity.dart';

abstract class FeedRepository {
  Future<List<PostEntity>> listPosts();
  Future<int> createPost({
    required String description,
    required String status,
    String? mediaUrl,
  });
  Future<List<CommentEntity>> listComments(int postId);
  Future<int> addComment({required int postId, required String text});
  Future<void> deleteOwnComment(int commentId);
}
