# Evidencias de pruebas — AloApp

Esta carpeta contiene las evidencias de pruebas del proyecto.

## Qué subir aquí
- Captura de la ejecución de `flutter test` (resultado de las pruebas unitarias).
- Capturas de las pruebas funcionales: login, visualización de órdenes propias e intento de acceso a órdenes ajenas (control de acceso).
- Registro de resultados (OK / incidencias) por caso de prueba.

## Pruebas unitarias existentes
- `test/sap_config_test.dart`
- `test/order_model_test.dart`
- `test/started_activity_test.dart`

## Cómo generar la evidencia
Desde la carpeta de la app (`Codigo app/alo_field_app`):

```bash
flutter test
```

Guardar la captura del resultado en esta carpeta (p. ej. `flutter_test_resultado.png`).
