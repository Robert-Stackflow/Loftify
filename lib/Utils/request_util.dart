import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/iprint.dart';
import 'package:loftify/Utils/request_header_util.dart';

enum DomainType { api, www, da, short, image, captcha }

class RequestUtil {
  static RequestUtil instance = RequestUtil();
  static RequestUtil wwwInstance = RequestUtil(domainType: DomainType.www);
  static RequestUtil daInstance = RequestUtil(domainType: DomainType.da);
  static RequestUtil shortInstance = RequestUtil(domainType: DomainType.short);
  static RequestUtil imageInstance = RequestUtil(domainType: DomainType.image);
  static RequestUtil captchaInstance =
      RequestUtil(domainType: DomainType.captcha);
  late Dio dio;
  late BaseOptions options;
  CookieJar? cookieJar;
  CookieManager? cookieManager;
  static const String apiUrl = "https://api.lofter.com";
  static const String wwwUrl = "https://www.lofter.com";
  static const String daUrl = "https://da.lofter.com";
  static const String shortUrl = "https://s.lofter.com";
  static const String captchaUrl = "https://captcha.lofter.com";
  static const String imageUrl = "https://45.127.129.16";
  dynamic defaultParams = {"product": RequestHeaderUtil.getProduct()};

  static RequestUtil getInstance({DomainType domainType = DomainType.api}) {
    switch (domainType) {
      case DomainType.api:
        return instance;
      case DomainType.www:
        return wwwInstance;
      case DomainType.da:
        return daInstance;
      case DomainType.short:
        return shortInstance;
      case DomainType.image:
        return imageInstance;
      case DomainType.captcha:
        return captchaInstance;
    }
  }

  RequestUtil({DomainType domainType = DomainType.api}) {
    String baseURL = "";
    switch (domainType) {
      case DomainType.api:
        baseURL = apiUrl;
        break;
      case DomainType.www:
        baseURL = wwwUrl;
        break;
      case DomainType.da:
        baseURL = daUrl;
        break;
      case DomainType.short:
        baseURL = shortUrl;
        break;
      case DomainType.image:
        baseURL = imageUrl;
        break;
      case DomainType.captcha:
        baseURL = captchaUrl;
        break;
    }
    options = BaseOptions(
      baseUrl: baseURL,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 25),
      contentType: Headers.formUrlEncodedContentType,
      responseType: ResponseType.json,
    );
    dio = Dio(options);
    (dio.httpClientAdapter as IOHttpClientAdapter).validateCertificate =
        (X509Certificate? cert, String host, int port) => true;
    cookieJar = CookieJar();
    cookieManager = CookieManager(cookieJar!);
    dio.interceptors.add(cookieManager!);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          return handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> clearCookie() async {
    cookieJar?.deleteAll();
  }

  _get(
    url, {
    params,
    options,
    bool getFullResponse = false,
  }) async {
    Response? response;
    [params, options] = _processRequest(params: params, options: options);
    try {
      response = await dio.get(
        url,
        queryParameters: params,
        options: options,
      );
      _processResponse(response);
    } on DioException catch (e) {
      formatError(e);
    }
    if (getFullResponse) {
      return response;
    } else {
      return response?.data;
    }
  }

  _post(
    url, {
    params,
    data,
    options,
    bool stream = false,
  }) async {
    Response? response;
    [params, options] = _processRequest(params: params, options: options);
    try {
      response = await dio.post(
        url,
        queryParameters: params,
        data: stream && data is List<int>
            ? Stream.fromIterable(data.map((e) => [e]))
            : data,
        options: options,
      );
      _processResponse(response);
    } on DioException catch (e) {
      formatError(e);
    }
    return response?.data;
  }

  _processRequest({params, options}) {
    if (params != null) {
      params.addAll(defaultParams);
    } else {
      params = defaultParams;
    }
    options = options as Options? ?? Options();
    if (options.headers == null) {
      options.headers = RequestHeaderUtil.getHeaders();
    } else {
      options.headers?.addAll(RequestHeaderUtil.getHeaders());
    }
    return [params, options];
  }

  _processResponse(Response response) {
    Map<String, Object?> list = {
      "URL": response.requestOptions.uri,
    };
    if (response.requestOptions.headers['lofter-phone-login-auth'] != null) {
      list['Lofter-phone-login-auth'] =
          response.requestOptions.headers['lofter-phone-login-auth'] != null
              ? "有"
              : "无";
    }
    list["Cookie"] =
        response.requestOptions.headers['cookie'] != null ? "有" : "无";
    if (response.requestOptions.headers['cookie'] != null) {
      HiveUtil.put(
          key: HiveUtil.cookieKey,
          value: response.requestOptions.headers['cookie']);
    }
    list["Content-Length"] = response.requestOptions.headers['Content-Length'];
    list["Content-Type"] = response.requestOptions.contentType;
    if (response.requestOptions.headers['authorization'] != null) {
      list['Authorization'] =
          response.requestOptions.headers['authorization'] != null ? "有" : "无";
    }
    if (response.requestOptions.method == "POST" &&
        response.requestOptions.data != null) {
      list['Request Body'] = response.requestOptions.data;
    }
    if (response.data is Map<dynamic, dynamic>) {
      // list['splitter'] = "";
      if (response.data['code'] != null) {
        list['Code'] = response.data['code'];
      }
      if (response.data['msg'] != null) {
        list['Message'] = response.data['msg'];
      }
      if (response.data['meta'] != null &&
          response.data['meta']['status'] != null) {
        list['Status'] = response.data['meta']['status'];
      }
      if (response.data['meta'] != null &&
          response.data['meta']['msg'] != null) {
        list['Message'] = response.data['meta']['msg'];
      }
      // if (response.data['data'] != null) {
      //   list['Data'] = response.data['data'];
      // }
      // if (response.data['response'] != null) {
      //   list['Data'] = response.data['response'];
      // }
    }
    IPrint.format(
      tag: response.requestOptions.method,
      status: "Success",
      list: list,
    );
  }

  static get(
    url, {
    params,
    options,
    DomainType domainType = DomainType.api,
    bool getFullResponse = false,
  }) async {
    return getInstance(domainType: domainType)._get(
      url,
      params: params,
      options: options,
      getFullResponse: getFullResponse,
    );
  }

  static post(
    url, {
    params,
    data,
    options,
    DomainType domainType = DomainType.api,
    bool stream = false,
  }) async {
    return getInstance(domainType: domainType)._post(
      url,
      params: params,
      data: data,
      options: options,
      stream: stream,
    );
  }

  void formatError(DioException e) {
    String info =
        '[${e.requestOptions.method}] [${e.requestOptions.uri}] [${e.requestOptions.headers}] ';
    if (e.type == DioExceptionType.connectionTimeout) {
      IPrint.debug("$info:连接超时");
    } else if (e.type == DioExceptionType.sendTimeout) {
      IPrint.debug("$info:请求超时");
    } else if (e.type == DioExceptionType.receiveTimeout) {
      IPrint.debug("$info:响应超时");
    } else if (e.type == DioExceptionType.badResponse) {
      IPrint.debug("$info:出现异常");
    } else if (e.type == DioExceptionType.cancel) {
      IPrint.debug("$info:请求取消");
    } else {
      IPrint.debug("$info:$e");
    }
  }
}
