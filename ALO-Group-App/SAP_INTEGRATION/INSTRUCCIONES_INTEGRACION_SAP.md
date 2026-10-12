# Instrucciones de Integración SAP B1 — ALO Group Field App

> Guía paso a paso para conectar Flutter con SAP B1 Service Layer en 1 hora.

---

## Checklist previo

Antes de comenzar, verifica que tienes:

- [ ] Acceso de red a `https://sap.alo-group.com:50000`
- [ ] Credenciales del usuario SAP de servicio (`SVCMOBILE`)
- [ ] El `CompanyDB` correcto de tu empresa SAP
- [ ] Flutter SDK `^3.11.5` instalado
- [ ] El proyecto `alo_field_app` abierto en VS Code

Para verificar acceso SAP:
```bash
curl -k -I https://sap.alo-group.com:50000/b1s/v1
# Respuesta esperada: HTTP/1.1 401 Unauthorized (el servidor responde = OK)
```

---

## PASO 1: Preparar proyecto

### 1.1 Verificar dependencias en `pubspec.yaml`

Abre `alo_field_app/pubspec.yaml` y verifica que estas dependencias estén presentes:

```yaml
dependencies:
  flutter_bloc: ^9.1.1
  equatable: ^2.0.8
  dio: ^5.9.2
  flutter_dotenv: ^6.0.1
```

Si faltan, agrégalas y ejecuta:
```bash
flutter pub get
```

### 1.2 Declarar assets de .env en `pubspec.yaml`

```yaml
flutter:
  assets:
    - .env.dev
    - .env.prod   # si usas producción
```

---

## PASO 2: Configurar credenciales SAP

### 2.1 Copiar el template

```bash
cd alo_field_app
cp ../SAP_INTEGRATION/.env.example .env.dev
```

### 2.2 Editar `.env.dev` con valores reales

```env
SAP_BASE_URL=https://sap.alo-group.com:50000/b1s/v1
SAP_COMPANY=TU_EMPRESA_AQUI
SAP_SERVICE_USER=SVCMOBILE
SAP_SERVICE_PASSWORD=TU_PASSWORD_REAL_AQUI
```

> **IMPORTANTE:** Nunca commitees `.env.dev` con contraseñas reales.
> Asegúrate de que `.gitignore` contenga:
> ```
> *.env
> .env.*
> !.env.example
> ```

---

## PASO 3: Copiar archivos Dart

Copia los archivos siguiendo esta estructura exacta:

```
alo_field_app/lib/
├── core/
│   └── config/
│       └── sap_config.dart              ← COPIAR AQUÍ
└── features/
    ├── orders/
    │   └── data/
    │       └── models/
    │           └── order_model.dart      ← REEMPLAZAR (tenía solo 7 campos)
    └── dashboard/
        ├── data/
        │   ├── services/
        │   │   ├── sap_auth_service.dart ← COPIAR AQUÍ
        │   │   └── dashboard_service.dart← REEMPLAZAR (estaba vacío)
        │   └── repositories/
        │       └── dashboard_repository.dart ← REEMPLAZAR (estaba vacío)
        └── presentation/
            ├── bloc/
            │   ├── dashboard_event.dart  ← REEMPLAZAR
            │   ├── dashboard_state.dart  ← REEMPLAZAR
            │   └── dashboard_bloc.dart   ← REEMPLAZAR
            └── pages/
                └── dashboard_page_updated.dart ← NUEVO ARCHIVO
```

> `dashboard_page.dart` original se mantiene como respaldo. La nueva versión
> es `dashboard_page_updated.dart`. Puedes renombrarla después.

---

## PASO 4: Actualizar `main.dart` y service locator

### 4.1 Verificar que `main.dart` carga el .env

```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env.dev");  // ← debe estar ANTES de setupLocator
  await setupLocator();
  runApp(const AloFieldApp());
}
```

### 4.2 Actualizar `service_locator.dart`

En `lib/core/services/service_locator.dart`, reemplaza el registro del dashboard
con los nuevos servicios:

```dart
import 'package:get_it/get_it.dart';
import '../features/dashboard/data/services/sap_auth_service.dart';
import '../features/dashboard/data/services/dashboard_service.dart';
import '../features/dashboard/data/repositories/dashboard_repository.dart';
import '../features/dashboard/presentation/bloc/dashboard_bloc.dart';

final sl = GetIt.instance;

Future<void> setupLocator() async {
  // SAP Auth (Singleton — una sola sesión)
  sl.registerLazySingleton<SapAuthService>(() => SapAuthService());

  // Dashboard Service
  sl.registerLazySingleton<DashboardService>(
    () => DashboardService(authService: sl<SapAuthService>()),
  );

  // Dashboard Repository
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(service: sl<DashboardService>()),
  );

  // Dashboard BLoC (Factory — nueva instancia por página)
  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(repository: sl<DashboardRepository>()),
  );

  // ... resto de registros existentes
}
```

### 4.3 Actualizar `app.dart` (MultiBlocProvider)

```dart
// lib/app.dart
MultiBlocProvider(
  providers: [
    BlocProvider<DashboardBloc>(
      create: (_) => sl<DashboardBloc>(),
    ),
    // ... otros BLoCs existentes
  ],
  child: MaterialApp.router(routerConfig: router),
)
```

### 4.4 Actualizar la ruta del dashboard

En `lib/core/routes/app_router.dart`, actualiza la ruta `/dashboard`:

```dart
import '../../features/dashboard/presentation/pages/dashboard_page_updated.dart';

GoRoute(
  path: '/dashboard',
  builder: (context, state) => const DashboardPageUpdated(
    technicianCode: null, // o pasar el código del técnico autenticado
  ),
),
```

---

## PASO 5: Ejecutar y probar

```bash
# Desarrollo
flutter run --dart-define-from-file=alo_field_app/.env.dev

# Con logs verbosos (para ver requests SAP)
flutter run -v --dart-define-from-file=alo_field_app/.env.dev
```

---

## PASO 6: Verificar funcionalidad (6 tests manuales)

Abre la app y verifica uno a uno:

### Test 1 — Carga inicial
- [ ] La pantalla muestra `CircularProgressIndicator` durante la carga
- [ ] Aparecen cards de órdenes reales de SAP (no mock data)
- [ ] Cada card muestra: ID, cliente, dirección, técnico, estado

### Test 2 — Búsqueda
- [ ] Escribir nombre de un cliente → las cards se filtran en tiempo real
- [ ] Borrar la búsqueda → se restauran todas las órdenes
- [ ] Buscar por número de OT → filtra correctamente

### Test 3 — Filtros por estado
- [ ] Tocar el chip "Pendiente" → solo muestra OTs en estado P
- [ ] Tocar "Todos" → restaura todas las órdenes activas
- [ ] Tocar el ícono de filtro (AppBar) → alterna entre activas/todas

### Test 4 — Expandir card
- [ ] Tocar una card → se expande mostrando: contacto, fecha, materiales
- [ ] Tocar de nuevo → se colapsa
- [ ] Las cards con materiales muestran la lista de repuestos

### Test 5 — Actualización de estado (OT en estado P)
- [ ] Tocar "Iniciar" en una OT pendiente
- [ ] Aparece spinner en la card durante el PATCH
- [ ] SnackBar verde confirma éxito
- [ ] El estado de la card cambia a "En Camino"

### Test 6 — Pull-to-refresh
- [ ] Deslizar hacia abajo → `RefreshIndicator` se activa
- [ ] La lista se recarga desde SAP
- [ ] Los datos se actualizan con la última información

---

## Troubleshooting detallado

| Problema | Causa | Solución |
|----------|-------|----------|
| `DotEnvNotInitialized` al arrancar | `dotenv.load()` no ejecutado antes de `setupLocator()` | Verificar orden en `main.dart` |
| Lista siempre vacía | `technicianCode` no coincide con ninguna OT | Probar con `technicianCode: null` para ver todas las OTs |
| Error 401 en todas las llamadas | Credenciales incorrectas o CompanyDB erróneo | Probar login manual con curl |
| Error de certificado SSL | SAP usa certificado auto-firmado | Ya manejado en `_buildDio()`, no requiere acción |
| Timeout en 30 segundos | SAP lento o red saturada | Aumentar `SapConfig.connectTimeout` en `sap_config.dart` |
| `type 'Null' is not a subtype of type 'int'` en fromJson | Campo SAP retorna null donde se espera int | Los campos están declarados como `int?` — revisar modelo |
| PATCH devuelve error "Object not found" | `DocEntry` incorrecto (no confundir con `DocNum`) | `DocEntry` es el ID interno de SAP; `DocNum` es el número visible |
| La sesión expira en mitad de la operación | Timeout de sesión SAP < 30 min | El `SapAuthService` hace auto-refresh; verificar logs |
| `RepositoryException` sin mensaje claro | Error no catalogado | Activar logs verbose: `flutter run -v` |

---

## Seguridad

### Obligatorio en producción
- [ ] Nunca commitear `.env.dev` o `.env.prod` con contraseñas reales
- [ ] Usar `flutter_secure_storage` para guardar el `SessionId` entre sesiones
- [ ] Implementar certificate pinning para el dominio SAP en producción
- [ ] El usuario `SVCMOBILE` debe tener solo permisos de lectura/escritura en VID_RTOV

### Recomendado
- [ ] Rotar la contraseña de `SVCMOBILE` periódicamente
- [ ] Habilitar logs de auditoría en SAP para las operaciones del usuario de servicio
- [ ] Usar HTTPS siempre (ya configurado en `SAP_BASE_URL`)

---

## Próximos pasos (post-MVP)

1. Pasar el `technicianCode` del usuario autenticado al `DashboardPageUpdated`
2. Agregar paginación (scroll infinito) para más de 50 órdenes
3. Implementar GPS real en `MarkOrderAsArrived`
4. Integrar modo offline con SQLite

---

*Documento generado para ALO Group Field App — Junio 2026*
