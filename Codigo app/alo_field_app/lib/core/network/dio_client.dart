import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/env_config.dart';

class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,

        connectTimeout: const Duration(
          seconds: 15,
        ),

        receiveTimeout: const Duration(
          seconds: 15,
        ),

        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      PrettyDioLogger(
        requestBody: true,
        responseBody: true,
      ),
    );
  }
}