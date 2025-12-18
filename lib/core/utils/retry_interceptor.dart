import 'package:dio/dio.dart';

/// Interceptor para reintentar peticiones HTTP fallidas
/// 
/// Implementa lógica de retry con backoff exponencial para mejorar
/// la resiliencia ante fallos de red temporales.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    this.retries = 2,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
    ],
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] as int? ?? 0;

    // Solo reintentar en errores de red/timeout y si quedan intentos
    if (retryCount < retries && _shouldRetry(err)) {
      // Esperar antes de reintentar
      if (retryCount < retryDelays.length) {
        await Future.delayed(retryDelays[retryCount]);
      }

      // Incrementar contador de reintentos
      final requestOptions = err.requestOptions;
      requestOptions.extra['retryCount'] = retryCount + 1;

      try {
        // Reintentar la petición
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }

    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.badResponse && 
         err.response?.statusCode != null &&
         err.response!.statusCode! >= 500);
  }
}
