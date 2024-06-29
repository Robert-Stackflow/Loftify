class SimpleResponse {
  int result;
  int status;
  String desc;

  SimpleResponse(
      {required this.result, required this.status, required this.desc});

  factory SimpleResponse.fromJson(Map<String, dynamic> json) {
    return SimpleResponse(
        result: json['result'] as int,
        status: json['status'] as int,
        desc: json['desc']);
  }

  Map<String, dynamic> toJson() =>
      {'result': result, 'status': status, 'desc': desc};
}
