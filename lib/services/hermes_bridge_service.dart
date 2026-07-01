import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'app_launcher_service.dart';
import 'screen_automation_service.dart';

/// A lightweight HTTP bridge that lets a local Hermes instance control the
/// device through ArcaneFlow.
///
/// Binds to `127.0.0.1:8767` by default so only apps on the same device can
/// reach it (Termux, adb shell, etc.).
///
/// Endpoints:
///   GET  /health               -> {"ok": true}
///   GET  /screenshot          -> {"image": "base64_jpeg"}
///   GET  /ui_tree             -> {"nodes": [...]}
///   GET  /screen_description  -> {"description": "..."}
///   POST /tap                 -> {"x": double, "y": double}
///   POST /swipe               -> {"startX","startY","endX","endY","duration"}
///   POST /type                -> {"text": "..."}
///   POST /click_by_text       -> {"text": "..."}
///   POST /press_back
///   POST /press_home
///   POST /open_notifications
///   POST /open_app            -> {"app_name": "..."}
class HermesBridgeService {
  static const String _defaultHost = '127.0.0.1';
  static const int _defaultPort = 8767;

  final ScreenAutomationService _screen;
  final AppLauncherService _launcher;
  HttpServer? _server;
  bool get isRunning => _server != null;

  HermesBridgeService(this._screen, this._launcher);

  Future<void> start({String host = _defaultHost, int port = _defaultPort}) async {
    if (_server != null) return;
    _server = await HttpServer.bind(host, port);
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path.toLowerCase();
      final method = request.method;

      if (path == '/health' && method == 'GET') {
        return _json(request, {'ok': true, 'running': isRunning});
      }

      if (path == '/screenshot' && method == 'GET') {
        final image = await _screen.takeScreenshot();
        if (image == null || image.isEmpty) {
          return _json(request, {'ok': false, 'error': 'Screenshot failed or unavailable'}, status: 503);
        }
        return _json(request, {'ok': true, 'image': image, 'format': 'jpeg_base64'});
      }

      if (path == '/ui_tree' && method == 'GET') {
        final nodes = await _screen.dumpScreen();
        return _json(request, {'ok': true, 'nodes': nodes, 'count': nodes.length});
      }

      if (path == '/screen_description' && method == 'GET') {
        final desc = await _screen.getScreenDescription();
        return _json(request, {'ok': true, 'description': desc});
      }

      if (path == '/tap' && method == 'POST') {
        final body = await _bodyJson(request);
        final ok = await _screen.clickAt(
          (body['x'] as num).toDouble(),
          (body['y'] as num).toDouble(),
        );
        return _json(request, {'ok': ok});
      }

      if (path == '/swipe' && method == 'POST') {
        final body = await _bodyJson(request);
        final ok = await _screen.swipe(
          (body['startX'] as num).toDouble(),
          (body['startY'] as num).toDouble(),
          (body['endX'] as num).toDouble(),
          (body['endY'] as num).toDouble(),
        );
        return _json(request, {'ok': ok});
      }

      if (path == '/type' && method == 'POST') {
        final body = await _bodyJson(request);
        final ok = await _screen.typeText(
          body['text'] as String,
          fieldHint: body['fieldHint'] as String?,
        );
        return _json(request, {'ok': ok});
      }

      if (path == '/click_by_text' && method == 'POST') {
        final body = await _bodyJson(request);
        final ok = await _screen.clickByText(body['text'] as String);
        return _json(request, {'ok': ok});
      }

      if (path == '/press_back' && method == 'POST') {
        final ok = await _screen.pressBack();
        return _json(request, {'ok': ok});
      }

      if (path == '/press_home' && method == 'POST') {
        final ok = await _screen.pressHome();
        return _json(request, {'ok': ok});
      }

      if (path == '/open_notifications' && method == 'POST') {
        final ok = await _screen.openNotifications();
        return _json(request, {'ok': ok});
      }

      if (path == '/open_app' && method == 'POST') {
        final body = await _bodyJson(request);
        final result = await _launcher.openApp(body['app_name'] as String);
        return _json(request, {'ok': !result.startsWith('Could not find') && !result.startsWith('Error'), 'message': result});
      }

      return _json(request, {'ok': false, 'error': 'Unknown endpoint'}, status: 404);
    } catch (e) {
      return _json(request, {'ok': false, 'error': e.toString()}, status: 500);
    }
  }

  Future<Map<String, dynamic>> _bodyJson(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    if (body.isEmpty) return {};
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<void> _json(HttpRequest request, Map<String, dynamic> payload, {int status = 200}) async {
    final response = request.response;
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(payload));
    await response.close();
  }
}
