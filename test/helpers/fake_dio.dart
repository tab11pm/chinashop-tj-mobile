import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// One captured outgoing request (for asserting method/path/query/body).
class CapturedRequest {
  CapturedRequest(this.method, this.path, this.query, this.data);
  final String method;
  final String path;
  final Map<String, dynamic> query;
  final dynamic data;
}

/// Dio HttpClientAdapter that returns canned JSON per "METHOD /path" and records
/// every request. No real network. `routes` maps "GET /api/x" → (status, body).
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.routes,
      {Map<String, Future<(int, Object?)> Function()>? asyncRoutes})
      : asyncRoutes = asyncRoutes ?? {};
  final Map<String, (int, Object?)> routes;
  final Map<String, Future<(int, Object?)> Function()> asyncRoutes;
  final List<CapturedRequest> captured = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured.add(CapturedRequest(
        options.method, options.path, options.queryParameters, options.data));
    final key = '${options.method} ${options.path}';
    final asyncRoute = asyncRoutes[key];
    final entry =
        asyncRoute == null ? routes[key] ?? (200, null) : await asyncRoute();
    final body = entry.$2 == null ? '' : jsonEncode(entry.$2);
    return ResponseBody.fromString(
      body,
      entry.$1,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  CapturedRequest requestTo(String method, String path) =>
      captured.firstWhere((r) => r.method == method && r.path == path);

  int requestCount(String method, String path) => captured
      .where((request) => request.method == method && request.path == path)
      .length;

  @override
  void close({bool force = false}) {}
}

(Dio, FakeAdapter) fakeDio(
  Map<String, (int, Object?)> routes, {
  Map<String, Future<(int, Object?)> Function()>? asyncRoutes,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test'));
  final adapter = FakeAdapter(routes, asyncRoutes: asyncRoutes);
  dio.httpClientAdapter = adapter;
  return (dio, adapter);
}
