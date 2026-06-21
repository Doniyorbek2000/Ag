import 'package:logger/logger.dart';
import 'api_client.dart';

/// Fire-and-forget reporting of conversations and tool actions to the
/// backend for analytics and admin visibility. Failures are silently
/// swallowed — this is telemetry, not critical-path logic.
class BackendSyncService {
  static final BackendSyncService _instance = BackendSyncService._internal();
  factory BackendSyncService() => _instance;
  BackendSyncService._internal();

  final _api = ApiClient();
  final _log = Logger();

  Future<void> reportMessage({
    required String role,
    required String content,
    String source = 'mobile',
  }) async {
    if (_api.token == null) return;
    try {
      await _api.post('/conversations', data: {
        'source': source,
        'role': role,
        'content': content,
      });
    } catch (e) {
      _log.w('Backend sync (conversation) skipped: $e');
    }
  }

  Future<void> reportToolAction({
    required String type,
    required Map<String, dynamic> payload,
    required bool success,
    String? resultMessage,
  }) async {
    if (_api.token == null) return;
    try {
      await _api.post('/tool-actions', data: {
        'type': type,
        'payload': payload,
        'status': success ? 'success' : 'failure',
        if (resultMessage != null) 'result': {'message': resultMessage},
      });
    } catch (e) {
      _log.w('Backend sync (tool action) skipped: $e');
    }
  }
}
