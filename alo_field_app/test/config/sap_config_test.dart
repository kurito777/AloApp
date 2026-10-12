import 'package:flutter_test/flutter_test.dart';
import 'package:alo_field_app/core/config/sap_config.dart';

void main() {
  group('translateOmState (catálogo real VID_MTOM)', () {
    test('P/L/C/X', () {
      expect(SapConfig.translateOmState('P'), 'Planificada');
      expect(SapConfig.translateOmState('L'), 'Liberada');
      expect(SapConfig.translateOmState('C'), 'Cerrada');
      expect(SapConfig.translateOmState('X'), 'Cancelada');
    });
    test('desconocido → null (cae a Status O/C en la UI)', () {
      expect(SapConfig.translateOmState('Z'), isNull);
      expect(SapConfig.translateOmState(null), isNull);
    });
  });

  group('isOmEditableState', () {
    test('P y L editables', () {
      expect(SapConfig.isOmEditableState('P'), isTrue);
      expect(SapConfig.isOmEditableState('L'), isTrue);
    });
    test('C y X no editables', () {
      expect(SapConfig.isOmEditableState('C'), isFalse);
      expect(SapConfig.isOmEditableState('X'), isFalse);
    });
    test('null/vacío se trata como editable', () {
      expect(SapConfig.isOmEditableState(null), isTrue);
      expect(SapConfig.isOmEditableState(''), isTrue);
    });
  });

  group('allowlist de escritura', () {
    test('incluye los UDO esperados', () {
      expect(SapConfig.writableUdos, contains('VID_MTOM'));
      expect(SapConfig.writableUdos, contains('VID_RTOV'));
      expect(SapConfig.writableUdos, contains('VID_MTSOLREP'));
    });
  });

  group('translateState / stateToSapCode (ciclo OT)', () {
    test('ida y vuelta', () {
      expect(SapConfig.translateState('EC'), 'En Camino');
      expect(SapConfig.stateToSapCode('En Camino'), 'EC');
      expect(SapConfig.stateToSapCode('Finalizada'), 'F');
    });
  });
}
