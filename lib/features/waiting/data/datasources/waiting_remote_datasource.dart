import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/wait_status.dart';

/// Cliente del backend Nest. Usa Server-Sent Events (SSE) sobre Dio para
/// recibir actualizaciones en vivo del estado de la cola.
class WaitingRemoteDataSource {
  WaitingRemoteDataSource(this._api);
  final ApiClient _api;

  Stream<WaitStatus> watchStatus(String patientId) async* {
    final response = await _api.dio.get<ResponseBody>(
      '/pacientes/$patientId/espera/stream',
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ),
    );

    final stream = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stream) {
      // SSE: solo nos interesan las lineas "data: ..."
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;
      try {
        final j = jsonDecode(payload) as Map<String, dynamic>;
        yield _fromJson(j);
      } catch (_) {
        // ignorar lineas malformadas (heartbeats, etc.)
      }
    }
  }

  WaitStatus _fromJson(Map<String, dynamic> j) => WaitStatus(
    currentStudy: j['currentStudy'] as String,
    area: j['area'] as String,
    peopleAhead: (j['peopleAhead'] as num).toInt(),
    estimatedMinutes: (j['estimatedMinutes'] as num).toDouble(),
    saturationLevel: j['saturationLevel'] as String,
    isYourTurn: j['isYourTurn'] as bool,
  );
}
