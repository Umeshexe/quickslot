import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickslot/core/constants/api_constants.dart';

Dio createDioClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // pull userId from extras and attach as header
        final userId = options.extra['userId'] as String?;
        if (userId != null) {
          options.headers['x-user-id'] = userId;
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // ignore: avoid_print
        print('[http] ${error.requestOptions.method} '
            '${error.requestOptions.path} → ${error.response?.statusCode}');
        handler.next(error);
      },
    ),
  );

  return dio;
}

// single dio instance shared across the app
final dioClientProvider = Provider<Dio>((ref) => createDioClient());
