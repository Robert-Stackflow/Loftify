class Illust {
  String originalName;
  int blogId;
  String blogLofterId;
  String blogNickName;
  int part;
  int postId;
  String url;
  String extension;
  String postTitle;
  String postDigest;
  List<String> tags;
  int publishTime;

  Illust({
    required this.extension,
    required this.url,
    required this.postId,
    required this.originalName,
    required this.blogId,
    required this.blogLofterId,
    required this.blogNickName,
    required this.part,
    required this.postTitle,
    required this.postDigest,
    required this.tags,
    required this.publishTime,
  });

  @override
  String toString() {
    return 'Illust{originalName: $originalName, blogId: $blogId, blogLofterId: $blogLofterId, blogNickName: $blogNickName, part: $part, postId: $postId, url: $url, extension: $extension}';
  }
}
