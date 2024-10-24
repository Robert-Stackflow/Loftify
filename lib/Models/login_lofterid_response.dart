class LoginLofterIDResponse {
  int status;
  String desc;
  int? userId;
  String? token;

  LoginLofterIDResponse(
      {required this.status,
      required this.desc,
      required this.userId,
      required this.token});

  factory LoginLofterIDResponse.fromJson(Map<String, dynamic> json) {
    return LoginLofterIDResponse(
        status: json['status'] as int,
        userId: json['userId'] != null
            ? json['userId'] as int
            : json['userid'] != null
                ? json['userid'] as int
                : null,
        token: json['token'],
        desc: json['desc']);
  }

  Map<String, dynamic> toJson() =>
      {'status': status, 'userid': userId, 'token': token, 'desc': desc};
}
