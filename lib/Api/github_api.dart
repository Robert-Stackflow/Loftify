import 'package:dio/dio.dart';
import 'package:loftify/Utils/iprint.dart';

import '../Models/github_response.dart';
import '../Utils/ilogger.dart';

class GithubApi {
  static Future<List<ReleaseItem>> getReleases(String user, String repo) async {
    try {
      final response =
          await Dio().get("https://api.github.com/repos/$user/$repo/releases");
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          final List<ReleaseItem> items =
              (data).map((e) => ReleaseItem.fromJson(e)).toList();
          return items;
        }
      }
    } catch (e, t) {
      ILogger.error("Failed to load releases", e, t);
    }
    return [];
  }
}
