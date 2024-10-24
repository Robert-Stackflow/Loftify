class LoginResponse {
  int result;
  int status;
  String desc;
  int? userid;
  String? deviceid;
  String? token;

  LoginResponse(
      {required this.result,
      required this.status,
      required this.userid,
      required this.deviceid,
      required this.token,
      required this.desc});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
        result: json['result'] as int,
        status: json['status'] as int,
        userid: json['userid'] != null
            ? json['userid'] as int
            : json['userId'] != null
                ? json['userId'] as int
                : null,
        deviceid: json['deviceid'],
        token: json['token'],
        desc: json['desc']);
  }

  Map<String, dynamic> toJson() => {
        'result': result,
        'status': status,
        'userid': userid,
        'deviceid': deviceid,
        'token': token,
        'desc': desc
      };
}
