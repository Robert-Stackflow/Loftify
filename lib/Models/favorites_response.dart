class FavoriteFolder {
  String? coverUrl;
  int? id;
  int? isDefault;
  int? lastSubscribeTime;
  String? name;
  int? postCount;
  int? postSubscribed;
  int? status;
  int? subscribedCount;
  List<String>? tags;
  List<String>? themes;
  int? userId;

  FavoriteFolder({
    this.coverUrl,
    this.id,
    this.isDefault,
    this.lastSubscribeTime,
    this.name,
    this.postCount,
    this.postSubscribed,
    this.status,
    this.subscribedCount,
    this.tags,
    this.themes,
    this.userId,
  });

  factory FavoriteFolder.fromJson(Map<String, dynamic> json) {
    return FavoriteFolder(
      coverUrl: json['coverUrl'],
      id: json['id'],
      isDefault: json['isDefault'],
      lastSubscribeTime: json['lastSubscribeTime'],
      name: json['name'],
      postCount: json['postCount'],
      postSubscribed: json['postSubscribed'],
      status: json['status'],
      subscribedCount: json['subscribedCount'],
      tags: (json['tags'] as List).map((e) => e as String).toList(),
      themes: (json['themes'] as List).map((e) => e as String).toList(),
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coverUrl': coverUrl,
      'id': id,
      'isDefault': isDefault,
      'lastSubscribeTime': lastSubscribeTime,
      'name': name,
      'postCount': postCount,
      'postSubscribed': postSubscribed,
      'status': status,
      'subscribedCount': subscribedCount,
      'tags': tags,
      'themes': themes,
      'userId': userId,
    };
  }
}
