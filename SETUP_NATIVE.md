# Setup nativo — Atención Digna (app del paciente)

La app está lista para correr en **modo mock** sin ninguna configuración
nativa: solo `flutter run`. Cuando quieras conectar con servicios reales
(backend NestJS + Firebase + ubicación + push), sigue estas instrucciones.

---

## 1. Modo demo (mock) vs modo real

| Modo  | Comando | Qué usa |
|---|---|---|
| Mock  | `flutter run` | Datos en memoria, login fake, sin red |
| Real  | `flutter run --dart-define=USE_REMOTE=true --dart-define=API_BASE_URL=https://atencion-digna-api.up.railway.app` | Backend NestJS real + Firebase + GPS |

El switch está en [`lib/core/config/app_config.dart`](lib/core/config/app_config.dart).
Cada provider de Riverpod elige automáticamente la implementación correcta:

```dart
final branchesRepositoryProvider = Provider<BranchesRepository>((ref) {
  if (!AppConfig.useRemote) return BranchesRepositoryImpl();    // mock
  return BranchesRemoteRepositoryImpl(...);                     // HTTP real
});
```

---

## 2. Backend NestJS

Antes de pasar a `USE_REMOTE=true`, levanta el backend:

```bash
cd backend
npm install
npm run start:dev
# escucha en http://localhost:3000
```

Endpoints expuestos:
- `GET  /sucursales/cercanas?lat=&lng=&id_estudio=&limit=`
- `GET  /pacientes/:id/estudios-hoy`
- `POST /checkin/pase`
- `POST /checkin/validacion-clinica`
- `GET  /pacientes/:id/espera`
- `SSE  /pacientes/:id/espera/stream`
- `POST /encuestas`
- `GET  /pacientes/:id/resultados`
- `GET  /ia/health` (proxy al microservicio FastAPI)

Para que la app del emulador Android pueda hablar con tu Nest local,
usa `http://10.0.2.2:3000` como base URL (ya es el default).

---

## 3. Firebase (auth + push notifications)

### 3.1 Crear proyecto

1. Entra a https://console.firebase.google.com → **Add project**
2. Habilita **Authentication → Sign-in method → Google**
3. Habilita **Cloud Messaging**

### 3.2 Configurar la app Flutter

```bash
# Una sola vez por máquina
dart pub global activate flutterfire_cli

# Desde la carpeta `aplicacion/`
flutterfire configure
```

Esto genera `lib/firebase_options.dart` y descarga:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### 3.3 Inicializar en `main.dart`

Después de hacer `flutterfire configure`, descomenta la sección Firebase en
`lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/notifications/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationsService.instance.init();
  runApp(const ProviderScope(child: AtencionDignaApp()));
}
```

### 3.4 Android extra

En `android/build.gradle.kts` agrega el plugin de Google services
(flutterfire lo hace solo, pero verifica). En `android/app/build.gradle.kts`:

```kotlin
plugins {
  id("com.google.gms.google-services")
}
```

SHA-1 para Google Sign-In (sino, el login crashea con `ApiException 10`):

```bash
cd android
./gradlew signingReport
# copia el SHA1 de la variant `debug` y pegalo en Firebase Console
# → Project Settings → Your apps → Android → Add fingerprint
```

### 3.5 iOS extra

- Bundle ID en Firebase Console debe coincidir con el de Xcode
- Para push: subir APNs Authentication Key en Firebase Console → Cloud Messaging
- En Xcode: Capabilities → habilitar **Push Notifications** y **Background Modes → Remote notifications**

---

## 4. Geolocalización

### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
  ...
</manifest>
```

`minSdkVersion 21` o superior.

### iOS — `ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicacion para mostrarte las sucursales mas cercanas.</string>
```

`platform :ios, '12.0'` o superior en `ios/Podfile`.

El `LocationService` ya pide permisos automáticamente y cae a Coyoacán
(`UserLocation.fallback`) si el usuario los niega — el flujo nunca se rompe.

---

## 5. Notificaciones — payload del backend

Cuando el backend Nest necesite mandar una push, usa Firebase Admin SDK
con un payload así:

```json
{
  "token": "<fcm_device_token>",
  "notification": {
    "title": "Es tu turno",
    "body": "Dirigete al Area 2 - Laboratorio"
  },
  "data": {
    "type": "your_turn",
    "studyId": "2"
  },
  "android": { "priority": "high" },
  "apns": { "payload": { "aps": { "sound": "default" } } }
}
```

Tipos que la app entiende (ver `NotificationsService`):
- `preparation_reminder` — recordatorio de ayuno/preparación
- `your_turn` — pasa al área del estudio
- `result_ready` — resultados disponibles

---

## 6. Comandos útiles

```bash
# correr en mock
flutter run

# correr contra backend local
flutter run --dart-define=USE_REMOTE=true

# correr contra backend en Railway
flutter run \
  --dart-define=USE_REMOTE=true \
  --dart-define=API_BASE_URL=https://atencion-digna-api.up.railway.app

# build de release Android
flutter build apk --release \
  --dart-define=USE_REMOTE=true \
  --dart-define=API_BASE_URL=https://atencion-digna-api.up.railway.app
```
