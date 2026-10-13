# 🚀 INSTRUCCIONES DE DESPLIEGUE Y EJECUCIÓN

## 📋 REQUISITOS PREVIOS

```
✓ Flutter SDK 3.11.5 o superior
✓ Dart SDK incluido con Flutter
✓ Un editor (VS Code, Android Studio, o similar)
✓ Git configurado
```

---

## 1️⃣ CONFIGURACIÓN INICIAL

### Clonar/Descargar el Proyecto
```bash
# Si es nuevo proyecto (ya tendrías el workspace)
cd c:\Projects\ALO-Group-App\alo_field_app
```

### Limpiar y Obtener Dependencias
```bash
flutter clean
flutter pub get
```

### Verificar Configuración
```bash
flutter doctor
# Todos los checks deben estar verdes ✓
```

---

## 2️⃣ CONFIGURACIÓN DEL ARCHIVO .env

Crear archivo `.env.dev` en la raíz del proyecto:

```env
# .env.dev
API_BASE_URL=https://api.alo-group.com
SAP_BASE_URL=https://sap.alo-group.com
ENVIRONMENT=development
```

Crear archivo `.env.prod` para producción:

```env
# .env.prod
API_BASE_URL=https://api.prod.alo-group.com
SAP_BASE_URL=https://sap.prod.alo-group.com
ENVIRONMENT=production
```

---

## 3️⃣ INICIAR PROXY SAP (OBLIGATORIO)

**IMPORTANTE:** La aplicación NO se conecta directamente a SAP B1. Requiere un proxy local para manejar CORS y certificados SSL.

### Opción A: Inicio Automático (Windows)
```bash
# Doble clic en start.bat (raíz del proyecto)
# Esto inicia automáticamente el proxy y la app
```

### Opción B: Inicio Manual
```bash
# Terminal 1: Iniciar proxy SAP
cd alo_field_app/tools
dart run sap_proxy.dart

# Dejar esta terminal abierta. Verás:
#   Proxy:   http://localhost:8080
#   SAP:     https://sap.alo-group.com:50000
#   SSL:     Ignorado (badCertificateCallback)
```

**No cierres esta terminal** mientras uses la aplicación.

## 4️⃣ EJECUTAR LA APLICACIÓN

### Opción A: En Navegador (Chrome)
```bash
flutter run -d chrome
```

**Ventajas**: Accesible vía Live Preview, debugging en F12

### Opción B: En Android Emulator
```bash
# Primero, asegúrate que el emulador esté corriendo
# Desde Android Studio: AVD Manager

flutter run -d emulator-5554
```

### Opción C: En Dispositivo Físico
```bash
# Conectar dispositivo vía USB
flutter devices  # Listar dispositivos
flutter run -d <device_id>
```

### Opción D: En iOS (Mac)
```bash
flutter run -d ios
```

---

## 4️⃣ VALIDACIÓN POSTERIOR A EJECUCIÓN

### Pantalla 1: Login
```
🔍 Verificar:
  ✓ Logo y título "ALO Field" visible
  ✓ Subtítulo "Gestión Técnica en Terreno"
  ✓ 2 campos de texto (email, password)
  ✓ Botón "Ingresar" con color verde primario
  ✓ Mensaje: "Solo usuarios @alo-group.com"

⌨️ Ingresar:
  Email: test@alo-group.com
  Password: password123

✅ Esperado: Carga spinner, luego navega a /dashboard
```

### Pantalla 2: Dashboard (MainNavigation)
```
🔍 Verificar:
  ✓ 4 tabs en BottomNavigationBar:
    - Inicio (Home icon) ← activo
    - Mapa (Map icon)
    - Ejecución (Assignment icon)
    - Perfil (Person icon)
  
  ✓ Página principal: DashboardPage
    - AppBar verde (#0F6E56)
    - Título: "Dashboard Técnico"
    - 3 Cards con órdenes de prueba

✅ Cada card muestra:
  - Punto de prioridad (rojo/naranja/gris)
  - ID de orden (OT-1001, etc)
  - Cliente
  - Estado (Pendiente, En Camino, Finalizada)
  - Prioridad (Alta, Media, Baja)
  - Técnico
  - Botón "Ver Detalles"
```

### Pantalla 3: Navegación de Tabs
```
📍 Tab "Mapa":
  ✓ Carga MapsPage
  ✓ Muestra 3 ubicaciones
  ✓ Cada card con ubicación y estado

📍 Tab "Ejecución":
  ✓ Carga ExecutionPage
  ✓ Muestra 2 ejecuciones en progreso
  ✓ ProgressIndicator funcional

📍 Tab "Perfil":
  ✓ Carga ProfilePage
  ✓ Avatar con inicial "J"
  ✓ Datos del usuario (nombre, email, rol, etc)
  ✓ Botón "Cerrar Sesión" en rojo
```

### Pantalla 4: Logout
```
1. Tap en tab Perfil
2. Tap en botón "Cerrar Sesión"
3. ✅ Regresa a /login automáticamente
```

---

## 🔧 COMANDOS ÚTILES

### Análisis de Código
```bash
# Verificar errores y warnings
flutter analyze

# Ejecutar con output verbose
flutter run -v

# Build production
flutter build apk
flutter build ios
flutter build web
```

### Testing
```bash
# Ejecutar tests
flutter test

# Test con cobertura
flutter test --coverage
```

### Debugging
```bash
# Abrir DevTools
flutter pub global activate devtools
devtools

# Profiling
flutter run --profile
```

### Limpieza
```bash
# Limpiar todo
flutter clean

# Obtener dependencias nuevamente
flutter pub get

# Actualizar dependencias
flutter pub upgrade
```

---

## 🌐 ACCESO A LIVE PREVIEW (VS CODE)

### Método 1: Extensión Live Preview
```
1. Instalar extensión "Live Preview" en VS Code
2. Click derecho en index.html → "Open with Live Preview"
3. Abre en navegador automaticamente
```

### Método 2: Live Server
```
1. Instalar extensión "Live Server"
2. Click derecho en carpeta proyecto → "Open with Live Server"
3. Abre en http://localhost:5500
```

### Método 3: Comando Flutter
```bash
flutter run -d chrome

# Abierto en http://localhost:xxxxx
# Con hot reload habilitado
```

---

## 📊 MONITOREO Y DEBUGGING

### Inspector de Widgets (Flutter DevTools)
```bash
# Con app en ejecución, presionar 'w' en terminal
# O:
flutter pub global activate devtools
devtools

# Luego acceder a http://localhost:9100
```

### Console Output
```
✅ Sin rojo = sin errores
⚠️  Amarillo = warnings
🔴 Rojo = errores críticos
```

### Performance
```
Target: 60 FPS
Monitorear en DevTools:
- Frame times
- Memory usage
- Hot reload speed
```

---

## 🐛 TROUBLESHOOTING

### Problema: "Build failed"
```bash
# Solución:
flutter clean
flutter pub get
flutter run
```

### Problema: "GoRoute not found"
```
Verificar:
1. Ruta existe en app_router.dart
2. Path es correcto
3. Nombre coincide (si uses .pushNamed)
```

### Problema: "BLoC not provided"
```
Verificar:
1. BLoC está en MultiBlocProvider en app.dart
2. BLoC está registrado en service_locator.dart
3. Importaciones correctas
```

### Problema: "Exception en hot reload"
```bash
# Usar hot restart en lugar de hot reload
# En terminal: 'r' vs 'R'
# O: 
flutter run --no-fast-start
```

### Problema: ".env not found"
```
Verificar:
1. Archivo .env.dev existe en raíz del proyecto
2. main.dart carga: await dotenv.load(fileName: ".env.dev");
3. Variables en EnvConfig son accesibles
```

### Problema: "Sin conexión a SAP"
```
Causa: El proxy SAP no está corriendo en puerto 8080

Solución:
1. Abrir terminal en alo_field_app/tools
2. Ejecutar: dart run sap_proxy.dart
3. Dejar terminal abierta mientras usas la app
4. Verificar que SAP_BASE_URL=http://localhost:8080/b1s/v1 en .env.dev

Verificación:
- Abrir navegador: http://localhost:8080/b1s/v1/Login
- Debería responder (aunque sea 401 por falta de credenciales)
- Si no responde, el proxy no está corriendo
```

### Problema: "Credenciales inválidas"
```
Verificar:
1. SAP_SERVICE_USER y SAP_SERVICE_PASSWORD en .env.dev
2. Usuario tiene permisos en SAP B1
3. CompanyDB es correcto (NOMBRE_COMPANY_DB para testing)

Test manual:
curl -k -X POST http://localhost:8080/b1s/v1/Login \
  -H "Content-Type: application/json" \
  -d '{"CompanyDB":"NOMBRE_COMPANY_DB","UserName":"usuario_servicio","Password":"REEMPLAZAR_PASSWORD","Language":25}'
```

---

## 📱 DEPLOY A DISPOSITIVO REAL

### Android
```bash
# Conectar dispositivo vía USB
# Habilitar "USB Debugging" en Settings > Developer Options

flutter devices
flutter run -d <device_name>
```

### iOS
```bash
# En Mac:
# Conectar iPhone vía cable
# Confiar en computadora en el dispositivo

flutter devices
flutter run -d <device_name>
```

### Web
```bash
# Build para web
flutter build web

# Deployal en:
# - Firebase Hosting
# - Vercel
# - Netlify
# - Cualquier servidor web

firebase deploy  # si usas Firebase
```

---

## ✅ CHECKLIST FINAL

Antes de pasar a producción:

```
□ flutter analyze - Sin errores críticos
□ flutter test - Tests pasando
□ Pruebas manuales completadas
□ Performance aceptable (60 FPS)
□ Sin memory leaks
□ Funciona en diferentes dispositivos
□ Responsive design verificado
□ Pantallas de error implementadas
□ Logging apropiado
□ Credenciales y secrets en .env
□ README actualizado
□ Versión incrementada en pubspec.yaml
```

---

## 📞 CONTACTO Y SOPORTE

Para issues o preguntas:
1. Revisar logs en Console
2. Ejecutar flutter doctor
3. Limpiar y reinstalar dependencias
4. Consultar documentación oficial: https://flutter.dev

---

**Proyecto Lista para Usar** ✅
