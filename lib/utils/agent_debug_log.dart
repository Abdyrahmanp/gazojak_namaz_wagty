import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

const _sessionId = '478832';
const _logPath = '/home/gelnox/.cursor/debug-logs/debug-478832.log';
const _ingestPath =
    '/ingest/0ee31fb2-f7d5-4657-a9b2-3dbc4c81daea';

void agentDebugLog({
  required String location,
  required String message,
  required String hypothesisId,
  Map<String, dynamic>? data,
  String runId = 'pre-fix',
}) {
  final payload = <String, dynamic>{
    'sessionId': _sessionId,
    'location': location,
    'message': message,
    'data': data ?? <String, dynamic>{},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'hypothesisId': hypothesisId,
    'runId': runId,
  };

  debugPrint('AGENT_DEBUG ${jsonEncode(payload)}');

  // #region agent log
  Future<void>(() async {
    for (final host in const ['127.0.0.1', '10.0.2.2']) {
      try {
        final client = HttpClient();
        final request = await client.postUrl(
          Uri.parse('http://$host:7635$_ingestPath'),
        );
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('X-Debug-Session-Id', _sessionId);
        request.write(jsonEncode(payload));
        await request.close();
        client.close();
        break;
      } catch (_) {}
    }

    try {
      await File(_logPath).writeAsString(
        '${jsonEncode(payload)}\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  });
  // #endregion
}
