# ALO Group Field App — Integración SAP B1 Service Layer

> Paquete de integración Flutter ↔ SAP B1 para el UDO **VID_RTOV** (Órdenes de Taller)

---

## Índice

1. [Inicio rápido (5 minutos)](#inicio-rápido)
2. [Arquitectura implementada](#arquitectura)
3. [Flujo de datos completo](#flujo-de-datos)
4. [Archivos incluidos](#archivos-incluidos)
5. [Eventos disponibles](#eventos-disponibles)
6. [Estados que emite el BLoC](#estados)
7. [Debugging tips](#debugging-tips)
8. [Troubleshooting](#troubleshooting)
9. [Próximas fases](#próximas-fases)

---

## Inicio rápido

```bash
# 1. Instalar dependencias (si no están ya)
flutter pub add flutter_dotenv dio equatable flutter_bloc

# 2. Crear archivo de entorno
cp SAP_INTEGRATION/.env.example alo_field_app/.env.dev

# 3. Editar .env.dev con credenciales reales
notepad alo_field_app/.env.dev

# 4. Copiar archivos Dart al proyecto (ver sección Archivos)

# 5. Actualizar pubspec.yaml (ver PUBSPEC_UPDATES.txt)

# 6. Ejecutar
flutter run --dart-define-from-file=.env.dev
```

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                         FLUTTER UI                           │
│                  DashboardPageUpdated                        │
│           BlocBuilder / BlocListener                        │
└────────────────────────┬────────────────────────────────────┘
                         │ Events / States
┌────────────────────────▼────────────────────────────────────┐
│                      BLoC LAYER                              │
│                    DashboardBloc                             │
│  • Cache en memoria (_cachedOrders)                         │
│  • Filtrado/búsqueda local (sin re-llamadas SAP)            │
│  • Manejo de 8 eventos → 7 estados                          │
└────────────────────────┬────────────────────────────────────┘
                         │ Repository calls
┌────────────────────────▼────────────────────────────────────┐
│                   REPOSITORY LAYER                           │
│                 DashboardRepository                          │
│  • Transforma Map → OrderModel                              │
│  • Traduce excepciones a mensajes amigables                 │
└──────────┬─────────────────────────────┬────────────────────┘
           │                             │
┌──────────▼──────────┐    ┌────────────▼──────────────────┐
│   DashboardService  │    │       SapAuthService           │
│ • GET /VID_RTOV     │    │ • POST /Login                  │
│ • PATCH /VID_RTOV() │    │ • POST /Logout                 │
│ • OData filters     │    │ • Session cache + auto-refresh │
└──────────┬──────────┘    └────────────┬──────────────────┘
           │                             │
┌──────────▼─────────────────────────────▼──────────────────┐
│                   SAP B1 SERVICE LAYER                       │
│         https://sap.alo-group.com:50000/b1s/v1             │
│                  UDO: VID_RTOV                              │
└────────────────────────────────────────────────────────────┘
```

**Patrón:** Clean Architecture + Feature-First + BLoC

---

## Flujo de datos

```
Usuario abre app
      │
      ▼
DashboardPageUpdated.initState()
      │ add(LoadDashboardOrders)
      ▼
DashboardBloc._onLoadDashboardOrders()
      │ emit(DashboardLoading)
      │
      ▼
DashboardRepository.fetchDashboardOrders()
      │
      ▼
DashboardService.fetchOrders()
      │ getAuthHeaders() ── SapAuthService
      │ GET /VID_RTOV?$filter=U_TecnicoCode eq 'X'
      │ &$top=50&$orderby=DocNum desc
      ▼
SAP B1 → JSON { value: [ {...}, {...} ] }
      │
      ▼
List<Map> → List<OrderModel> (fromJson)
      │
      ▼
DashboardBloc emit(DashboardLoaded)
      │
      ▼
UI ListView renderiza OrderCards

Usuario presiona "Iniciar"
      │ add(InitiateOrder)
      ▼
DashboardBloc._onInitiateOrder()
      │ emit(OrderUpdating)
      │
      ▼
DashboardRepository.initiateOrder()
      │
      ▼
DashboardService.patchOrder(docEntry, {U_Estado: 'EC'})
      │ PATCH /VID_RTOV(DocEntry)
      ▼
SAP B1 → 204 No Content
      │
      ▼
Cache local actualizado (sin re-llamada SAP)
      │ emit(OrderUpdateSuccess)
      │ emit(DashboardLoaded) con lista actualizada
      ▼
UI muestra SnackBar verde + card actualizada
```

---

## Archivos incluidos

| Archivo | Ruta en proyecto | Descripción |
|---------|-----------------|-------------|
| `sap_config.dart` | `lib/core/config/` | Configuración SAP: URLs, timeouts, traducciones de estado |
| `order_model.dart` | `lib/features/orders/data/models/` | Modelo OT con 35+ campos SAP + OrderDetailLine |
| `sap_auth_service.dart` | `lib/features/dashboard/data/services/` | Login/logout SAP B1, gestión de sesión |
| `dashboard_service.dart` | `lib/features/dashboard/data/services/` | GET/PATCH VID_RTOV, filtros OData, reintentos |
| `dashboard_repository.dart` | `lib/features/dashboard/data/repositories/` | Transformación datos, manejo de errores |
| `dashboard_event.dart` | `lib/features/dashboard/presentation/bloc/` | 8 eventos del BLoC |
| `dashboard_state.dart` | `lib/features/dashboard/presentation/bloc/` | 7 estados del BLoC |
| `dashboard_bloc.dart` | `lib/features/dashboard/presentation/bloc/` | Lógica principal, cache en memoria |
| `dashboard_page_updated.dart` | `lib/features/dashboard/presentation/pages/` | UI completa con todos los estados |

**Documentos:**

| Archivo | Descripción |
|---------|-------------|
| `README.md` | Este archivo |
| `INSTRUCCIONES_INTEGRACION_SAP.md` | Guía paso a paso de integración |
| `APP_DART_INTEGRATION_GUIDE.dart` | Código de ejemplo para main.dart |
| `PUBSPEC_UPDATES.txt` | Cambios necesarios en pubspec.yaml |
| `.env.example` | Template de variables de entorno |

---

## Eventos disponibles

| Evento | Parámetros | Descripción |
|--------|-----------|-------------|
| `LoadDashboardOrders` | `technicianCode?`, `estados?` | Carga inicial desde SAP |
| `RefreshDashboardOrders` | `technicianCode?`, `estados?` | Pull-to-refresh |
| `FilterOrdersByStatus` | `status?` (null = todos) | Filtro por estado SAP |
| `SearchOrders` | `query` | Búsqueda en tiempo real (local) |
| `InitiateOrder` | `docEntry`, `docNum` | Inicia OT → estado EC |
| `MarkOrderAsArrived` | `docEntry`, `docNum`, `gpsLat?`, `gpsLng?` | Llegada → estado EA |
| `FinishOrder` | `docEntry`, `docNum`, `comments?`, `photoUrls` | Finaliza → estado F |
| `ToggleShowAllOrders` | — | Alterna activas / todas |

---

## Estados

| Estado | Descripción | Datos clave |
|--------|-------------|-------------|
| `DashboardInitial` | Antes de cargar | — |
| `DashboardLoading` | Cargando desde SAP | — |
| `DashboardLoaded` | Lista lista | `orders`, `displayedOrders`, `statusFilter`, `searchQuery`, `showAll` |
| `DashboardEmpty` | Sin resultados | `reason` |
| `DashboardError` | Error de carga | `message`, `canRetry` |
| `OrderUpdating` | Actualizando OT | `docEntry`, `docNum`, `action`, `previousOrders` |
| `OrderUpdateSuccess` | OT actualizada | `updatedOrder`, `message` |
| `OrderUpdateError` | Error al actualizar | `docEntry`, `docNum`, `message`, `previousOrders` |

---

## Debugging tips

### Ver requests SAP en consola

```dart
// En sap_auth_service.dart y dashboard_service.dart se usa dart:developer
// Los logs aparecen con prefijo [SAP Auth] y [DashboardService]
// En VS Code: Debug Console
// En terminal: flutter run -v
```

### Verificar sesión SAP manualmente

```bash
curl -k -X POST https://sap.alo-group.com:50000/b1s/v1/Login \
  -H "Content-Type: application/json" \
  -d '{"CompanyDB":"TU_EMPRESA","UserName":"SVCMOBILE","Password":"TU_PASSWORD"}'
# Respuesta esperada: {"SessionId":"...","SessionTimeout":30,...}
```

### Verificar UDO VID_RTOV

```bash
# Con cookie de sesión activa:
curl -k "https://sap.alo-group.com:50000/b1s/v1/VID_RTOV?\$top=1" \
  -H "Cookie: B1SESSION=TU_SESSION_ID"
```

### Forzar recarga ignorando cache

```dart
context.read<DashboardBloc>().add(
  const RefreshDashboardOrders(estados: ['P', 'EC', 'EA', 'EP']),
);
```

---

## Troubleshooting

| Problema | Causa probable | Solución |
|----------|----------------|----------|
| `SapNetworkException: No se pudo conectar` | URL incorrecta o sin acceso de red | Verificar `SAP_BASE_URL` en .env y conectividad |
| `SapAuthException: Credenciales inválidas` | Usuario/contraseña incorrectos | Verificar credenciales SVCMOBILE en SAP |
| `SapAuthException: SAP no retornó SessionId` | CompanyDB incorrecto | Verificar `SAP_COMPANY` en .env |
| Lista vacía en dashboard | Filtro U_TecnicoCode sin coincidencias | Verificar código técnico; probar sin filtro |
| PATCH devuelve 404 | DocEntry incorrecto | Verificar que DocEntry sea el campo correcto (no DocNum) |
| Error de certificado SSL | Certificado auto-firmado SAP | El código ya lo maneja con `badCertificateCallback` |
| Sesión expira constantemente | SessionTimeout < 30 min en SAP | Configurado para refrescar a los 25 min automáticamente |
| `DotEnvNotInitialized` | dotenv no cargado en main.dart | Asegurar `await dotenv.load()` antes de inicializar servicios |

---

## Próximas fases

### Fase 2 — GPS y Tracking
- Captura de coordenadas GPS reales al marcar llegada
- Mapa en tiempo real con posición del técnico
- Historial de ruta por OT

### Fase 3 — Evidencias Fotográficas
- Captura de fotos desde la cámara del dispositivo
- Upload a servidor de archivos / SharePoint
- URLs de evidencias guardadas en campo SAP

### Fase 4 — Firma Digital
- Firma del cliente al finalizar la OT
- Generación de PDF de servicio con firma
- Envío automático por email desde SAP

### Fase 5 — Modo Offline
- SQLite local con sincronización diferida
- Queue de operaciones pendientes
- Resolución de conflictos al reconectar

---

*Generado para ALO Group Field App — Junio 2026*
