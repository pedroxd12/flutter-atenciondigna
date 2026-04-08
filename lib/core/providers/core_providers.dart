import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

/// Cliente HTTP global — inyectable en cualquier repository remoto.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
