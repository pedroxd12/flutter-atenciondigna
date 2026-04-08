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

  Future<WaitStatus> getCurrent(String patientId) async {
    final res = await _api.dio.get<Map<String, dynamic>>(
      '/pacientes/$patientId/espera',
    );
    return _fromJson(res.data!);
  }

  Future<List<QueueItem>> getQueue(String patientId) async {
    final res = await _api.dio.get<List<dynamic>>(
      '/pacientes/$patientId/espera/cola',
    );
    return (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (j) => QueueItem(
            initials: j['initials'] as String,
            folio: j['folio'] as String,
            estudio: j['estudio'] as String,
            posicion: (j['posicion'] as num).toInt(),
            isCurrent: j['isCurrent'] as bool,
            isMine: j['isMine'] as bool,
          ),
        )
        .toList();
  }

  WaitStatus _fromJson(Map<String, dynamic> j) {
    final branchJson = j['branch'] as Map<String, dynamic>?;
    return WaitStatus(
      currentStudy: j['currentStudy'] as String? ?? '',
      area: j['area'] as String? ?? '',
      peopleAhead: (j['peopleAhead'] as num?)?.toInt() ?? 0,
      estimatedMinutes: (j['estimatedMinutes'] as num?)?.toDouble() ?? 0,
      saturationLevel: j['saturationLevel'] as String? ?? 'bajo',
      isYourTurn: j['isYourTurn'] as bool? ?? false,
      folio: j['folio'] as String?,
      hasActiveService: j['hasActiveService'] as bool? ?? false,
      branch: branchJson == null
          ? null
          : WaitBranch(
              id: (branchJson['id'] as num).toInt(),
              name: branchJson['name'] as String,
              address: branchJson['address'] as String? ?? '',
              lat: (branchJson['lat'] as num).toDouble(),
              lng: (branchJson['lng'] as num).toDouble(),
            ),
    );
  }
}
