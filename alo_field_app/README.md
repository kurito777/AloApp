# ALO Field App

Aplicación móvil Flutter para gestión de órdenes de taller y mantenimiento en terreno, integrada con SAP B1 Service Layer.

## 🏗️ Arquitectura

```
┌─────────────┐      HTTP       ┌──────────────┐      HTTPS      ┌─────────────┐
│  Flutter App │ ──────────────▶│ SAP CORS Proxy│ ──────────────▶│  SAP B1 SL  │
│  (localhost) │  8080/b1s/v1   │  (Dart)       │  50000/b1s/v1  │ (on-premise)│
└─────────────┘                 └──────────────┘                 └─────────────┘
```

**Nota:** La app NO se conecta directamente a SAP. Usa un proxy local (`tools/sap_proxy.dart`) para:
- Agregar headers CORS (necesario para desarrollo web)
- Manejar cookies de sesión SAP automáticamente
- Ignorar certificados SSL auto-firmados de SAP

## 🚀 Inicio Rápido

### Windows
```bash
# Doble clic en:
start.bat
```

### Manual (todos los SO)
```bash
# 1. Instalar dependencias
flutter pub get

# 2. Iniciar proxy SAP (terminal 1)
cd tools
dart run sap_proxy.dart

# 3. Iniciar app Flutter (terminal 2)
flutter run
```

## ⚙️ Configuración

### Variables de Entorno

Crear archivo `.env.dev` en la raíz del proyecto:

```env
# SAP B1 Service Layer
SAP_BASE_URL=http://localhost:8080/b1s/v1
SAP_COMPANY=ZTEST_AR_TRIBUTARIO
SAP_SERVICE_USER=INDACC02
SAP_SERVICE_PASSWORD=TestIC2024

# Entorno
ENVIRONMENT=development
```

**Importante:** El `SAP_BASE_URL` debe apuntar al proxy (`localhost:8080`), no directamente a SAP.

## 📱 Funcionalidades

- ✅ **Dashboard de Órdenes**: Lista de OTs y OMs asignadas al técnico
- ✅ **Filtros y Búsqueda**: Filtrar por estado, buscar por cliente/dirección/técnico
- ✅ **Actualización de Estados**: Marcar llegada (EA), inicio (EP), finalización (F)
- ✅ **GPS**: Registrar coordenadas de llegada automáticamente
- ✅ **Detalle de Orden**: Ver materiales, repuestos, historial
- ✅ **Modo Offline**: Caché en memoria para consultas sin re-llamadas a SAP

## 🛠️ Stack Tecnológico

- **Framework**: Flutter 3.11.5+
- **Lenguaje**: Dart 3.0+
- **Estado**: BLoC (flutter_bloc)
- **HTTP**: Dio 5.x
- **Variables de entorno**: flutter_dotenv
- **Arquitectura**: Limpia / Repositorio + Servicio + BLoC

## 📂 Estructura del Proyecto

```
lib/
├── core/
│   ├── config/
│   │   └── sap_config.dart          # Configuración centralizada SAP
│   └── utils/
│       └── logger.dart              # Logging
├── features/
│   ├── dashboard/
│   │   ├── bloc/                    # DashboardBloc + eventos + estados
│   │   ├── data/
│   │   │   ├── models/              # OrderModel, OrderDetailLine
│   │   │   ├── repositories/        # DashboardRepository
│   │   │   └── services/            # DashboardService, SapAuthService
│   │   └── presentation/
│   │       └── pages/               # DashboardPage
│   ├── orders/
│   │   └── data/models/             # OrderModel (compartido)
│   ├── auth/
│   │   └── presentation/pages/      # LoginPage
│   └── admin/
│       └── presentation/pages/      # AdminPage
└── main.dart                        # Punto de entrada

tools/
├── sap_proxy.dart                   # Proxy CORS para SAP B1
└── test_proxy.dart                  # Test de conexión al proxy
```

## 🔧 Comandos Útiles

```bash
# Análisis de código
flutter analyze

# Ejecutar tests
flutter test

# Build producción
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web

# Limpiar y reinstalar
flutter clean
flutter pub get
```

## 🐛 Troubleshooting

### Error: "Sin conexión a SAP"

**Causa:** El proxy no está corriendo en el puerto 8080.

**Solución:**
1. Abrir terminal en `alo_field_app/tools`
2. Ejecutar: `dart run sap_proxy.dart`
3. Dejar la terminal abierta mientras usas la app

### Error: "Credenciales inválidas"

**Solución:** Verificar que `.env.dev` tenga las credenciales correctas de SAP B1.

### Error: "Timeout al conectar"

**Causa:** SAP B1 no está accesible desde tu red.

**Solución:** Verificar conectividad con:
```bash
curl -k https://sap.alo-group.com:50000/b1s/v1/Login
```

## 📊 Estados de Orden

| Código | Estado        | Color     |
|--------|---------------|-----------|
| P      | Pendiente     | Naranja   |
| EC     | En Camino     | Amarillo  |
| EA     | En Área       | Azul      |
| EP     | En Proceso    | Púrpura   |
| F      | Finalizada    | Verde     |
| C      | Cancelada     | Rojo      |

## 📞 Soporte

Para issues o preguntas:
1. Revisar logs en Console de Flutter
2. Verificar que el proxy esté corriendo
3. Consultar `INSTRUCCIONES_DESPLIEGUE.md`

---

**Versión:** 1.0.0  
**Última actualización:** Junio 2026