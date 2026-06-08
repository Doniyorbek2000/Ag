import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adm_ai/services/api_client.dart';

DioException _dioError({dynamic data, int? statusCode}) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    response: statusCode == null && data == null
        ? null
        : Response(requestOptions: requestOptions, data: data, statusCode: statusCode),
  );
}

void main() {
  group('ApiException', () {
    test('toString returns the message', () {
      expect(ApiException('Nimadir xato ketdi').toString(), 'Nimadir xato ketdi');
    });

    test('carries an optional status code', () {
      final ex = ApiException('Ruxsat yo\'q', statusCode: 403);
      expect(ex.statusCode, 403);
    });
  });

  group('ApiException.fromDioError', () {
    test('extracts the server-provided error message and status code', () {
      final ex = ApiException.fromDioError(
        _dioError(data: {'error': 'Token muddati tugagan'}, statusCode: 401),
      );

      expect(ex.message, 'Token muddati tugagan');
      expect(ex.statusCode, 401);
    });

    test('falls back to a generic message when the response has no error field', () {
      final ex = ApiException.fromDioError(_dioError(data: {'ok': false}, statusCode: 500));

      expect(ex.message, 'Server bilan bog\'lanishda xato yuz berdi');
      expect(ex.statusCode, 500);
    });

    test('falls back to a generic message when there is no response at all', () {
      final ex = ApiException.fromDioError(_dioError());

      expect(ex.message, 'Server bilan bog\'lanishda xato yuz berdi');
      expect(ex.statusCode, isNull);
    });
  });
}
