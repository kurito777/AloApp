# AloApp
app movil para tecnicos, contralando operacion y trazabilidad de estas.
1. Tecnologías utilizadas
Frontend / Aplicación
Flutter 3.44.0 — Framework principal para el desarrollo multiplataforma.
Dart — Lenguaje de programación utilizado por Flutter.
Flutter Web — Utilizado para ejecutar y probar la aplicación desde navegador.
Android — Plataforma objetivo para la aplicación móvil de técnicos.
Windows / Web — Utilizados como entornos adicionales de desarrollo y pruebas.
Gestión de estado
flutter_bloc — Implementación del patrón BLoC para manejar el estado de la aplicación.
equatable — Comparación de objetos y estados dentro de los BLoC.
Inyección de dependencias
get_it — Service Locator utilizado para centralizar y administrar las dependencias de la aplicación.
Comunicación con APIs
Dio — Cliente HTTP para comunicación con servicios/API externos.
Configuración de ambientes
flutter_dotenv — Manejo de variables de configuración mediante archivos .env.

Se contemplan actualmente:

.env.dev
.env.prod

Esto permite separar configuraciones de desarrollo y producción sin modificar directamente el código fuente.

Herramientas de desarrollo
Visual Studio Code — IDE principal.
Git — Control de versiones.
GitHub — Repositorio remoto del proyecto.
PowerShell — Terminal utilizada para ejecutar Flutter, Dart y Git.
2. Instrucciones de ejecución local
Requisitos previos

Antes de ejecutar el proyecto se debe contar con:

Flutter instalado.
Dart incluido con Flutter.
Git instalado.
Visual Studio Code.
Google Chrome o Microsoft Edge para ejecutar Flutter Web.

Verificar Flutter:

flutter doctor

El resultado debe mostrar al menos:

[√] Flutter
[√] Chrome
[√] Network resources

Para desarrollo Android también se requiere Android Studio y Android SDK.

Clonar el proyecto

Desde PowerShell:

cd C:\Projects
git clone <URL_DEL_REPOSITORIO>
cd ALO-Group-App\alo_field_app

Si el proyecto ya está clonado:

cd C:\Projects\ALO-Group-App\alo_field_app
Instalar dependencias

Ejecutar:

flutter pub get

Esto descarga las dependencias definidas en pubspec.yaml.

Configurar variables de entorno

El proyecto utiliza:

.env.dev
.env.prod

Para desarrollo local se debe configurar .env.dev.

Ejemplo:

API_URL=https://dev-api.com

Los valores reales de conexión deben ser proporcionados por el ambiente correspondiente. No se deben subir credenciales, tokens o contraseñas al repositorio.

Los archivos están incluidos como assets en pubspec.yaml:

flutter:
  uses-material-design: true


  assets:
    - .env.dev
    - .env.prod
Limpiar el proyecto

Si existen problemas con paquetes, archivos generados o cambios de configuración:

flutter clean

Luego:

flutter pub get
Ejecutar en Chrome

Para desarrollo web:

flutter run -d chrome

Esta es la opción recomendada actualmente para verificar visualmente la aplicación.

Ejecutar mediante Web Server

También se puede utilizar:

flutter run -d web-server

Flutter entregará una URL similar a:

http://localhost:XXXXX

Sin embargo, para desarrollo habitual se recomienda:

flutter run -d chrome

porque Flutter puede administrar directamente el navegador y las herramientas de debugging.

Ejecutar en Windows

Si el entorno de Windows está configurado:

flutter run -d windows

Actualmente esto requiere tener instalado Visual Studio con Desktop development with C++.

Ver dispositivos disponibles

Para verificar los dispositivos detectados:

flutter devices

Ejemplo:

Windows (desktop)
Chrome (web)
Edge (web)
Verificar el proyecto

Antes de comenzar el desarrollo:

flutter analyze

Y para ejecutar las pruebas:

flutter test

Flujo recomendado:

flutter clean
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
3. Arquitectura de la solución

La aplicación utiliza una arquitectura Feature-First, separando cada módulo funcional de la aplicación en su propio contexto.

La estructura principal es:

lib/
│
├── main.dart
│
├── app.dart
│
├── core/
│   └── services/
│       └── service_locator.dart
│
└── features/
    │
    ├── auth/
    │   ├── data/
    │   │   ├── repositories/
    │   │   │   └── auth_repository.dart
    │   │   │
    │   │   └── services/
    │   │       └── auth_service.dart
    │   │
    │   └── presentation/
    │       ├── bloc/
    │       │   └── auth_bloc.dart
    │       │
    │       └── pages/
    │           └── login_page.dart
    │
    └── dashboard/
        ├── data/
        │   ├── repositories/
        │   │   └── dashboard_repository.dart
        │   │
        │   └── services/
        │       └── dashboard_service.dart
        │
        └── presentation/
            ├── bloc/
            │   ├── dashboard_bloc.dart
            │   └── dashboard_event.dart
            │
            └── pages/
Capas
main.dart

Es el punto de entrada de la aplicación.

Responsabilidades:

Inicializar Flutter.
Cargar las variables de entorno.
Inicializar las dependencias.
Ejecutar la aplicación.

Flujo:

main.dart
   │
   ├── WidgetsFlutterBinding.ensureInitialized()
   │
   ├── dotenv.load()
   │
   ├── setupDependencies()
   │
   └── runApp()
app.dart

Contiene la configuración global de la aplicación.

Actualmente se encarga de:

Configurar MaterialApp.
Configurar el tema visual.
Registrar los BlocProvider.
Definir la pantalla inicial.
Inicializar el Dashboard BLoC.

Flujo simplificado:

AloFieldApp
     │
     └── MultiBlocProvider
            │
            ├── AuthBloc
            │
            └── DashboardBloc
                    │
                    └── LoadDashboard()
Arquitectura por Feature

Cada funcionalidad se encuentra aislada dentro de features.

Por ejemplo:

features/
└── auth/

representa todo lo relacionado con autenticación.

Mientras:

features/
└── dashboard/

contiene todo lo relacionado con el Dashboard.

Esto permite que posteriormente podamos agregar módulos como:

features/
├── auth/
├── dashboard/
├── work_orders/
├── equipment/
├── customers/
├── service_calls/
├── notifications/
└── profile/

sin convertir el proyecto en una estructura monolítica difícil de mantener.

Patrón BLoC

La aplicación utiliza BLoC para separar la interfaz de usuario de la lógica de negocio.

El flujo esperado es:

UI
 │
 │ Event
 ▼
BLoC
 │
 │ llamada
 ▼
Repository
 │
 │ llamada
 ▼
Service
 │
 │ HTTP/API
 ▼
Backend / SAP

Por ejemplo, para el Dashboard:

DashboardPage
      │
      ▼
DashboardBloc
      │
      ▼
DashboardRepository
      │
      ▼
DashboardService
      │
      ▼
API

Esto evita colocar llamadas HTTP o lógica de negocio directamente dentro de las pantallas.

Repository

El Repository funciona como una capa intermedia entre el BLoC y los servicios.

Ejemplo:

DashboardBloc
      ↓
DashboardRepository
      ↓
DashboardService

Su objetivo es abstraer de dónde provienen los datos.

Por ejemplo, posteriormente podremos cambiar:

API REST

por:

SAP Business One Service Layer

o por:

n8n → SAP B1

sin tener que modificar directamente las pantallas.

Service

Los Service son responsables de la comunicación externa.

Ejemplo:

DashboardService

será el encargado de realizar solicitudes HTTP utilizando Dio.

La arquitectura queda:

DashboardBloc
      ↓
DashboardRepository
      ↓
DashboardService
      ↓
Dio
      ↓
API / n8n / SAP
Service Locator

core/services/service_locator.dart centraliza la creación y administración de dependencias mediante get_it.

La intención es evitar crear manualmente todas las dependencias dentro de cada pantalla o BLoC.

Conceptualmente:

Service Locator
      │
      ├── AuthService
      ├── DashboardService
      ├── Repositories
      └── futuras dependencias
Arquitectura general de ALO Field

La arquitectura objetivo queda de esta manera:

                         ALO FIELD APP
                              │
                              ▼
                       ┌──────────────┐
                       │ Presentation │
                       │     BLoC     │
                       └──────┬───────┘
                              │
                              ▼
                       ┌──────────────┐
                       │ Repository   │
                       └──────┬───────┘
                              │
                              ▼
                       ┌──────────────┐
                       │   Service    │
                       └──────┬───────┘
                              │
                              ▼
                            Dio
                              │
                              ▼
                         API / n8n
                              │
                              ▼
                      SAP Business One
Principio principal

La aplicación queda desacoplada en capas:

Interfaz → Estado → Negocio → Datos → API

Esto nos permitirá posteriormente incorporar la integración real con SAP Business One, sin tener que rehacer la aplicación cuando pasemos de datos mock a datos reales.
