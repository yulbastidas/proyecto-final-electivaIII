import 'package:pets/domain/entities/comment_entity.dart';
import 'package:pets/domain/entities/post.dart';
import 'package:pets/domain/repositories/feed_repository.dart';

class PostsService {
  final FeedRepository _repo;

  PostsService(this._repo);

  Future<List<Post>> fetchFeed({String? status}) {
    return _repo.getFeed(status: status, limit: 30, offset: 0);
  }

  Future<Post> publish({
    String? content,
    required String status,
    List<int>? imageBytes,
    String? filename,
    String? countryCode,
  }) {
    return _repo.createPost(
      content: content,
      status: status,
      imageBytes: imageBytes,
      filename: filename,
      countryCode: countryCode,
    );
  }

  Future<Post> like(int postId) => _repo.toggleLike(postId);

  Future<void> remove(int postId) => _repo.deletePost(postId);

  Future<CommentEntity> addComment({
    required int postId,
    required String authorId,
    required String text,
  }) {
    return _repo.addComment(postId: postId, authorId: authorId, text: text);
  }
}
