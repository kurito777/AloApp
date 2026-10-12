import 'package:flutter_test/flutter_test.dart';
import 'package:alo_field_app/features/execution/data/models/started_activity.dart';

void main() {
  group('StartedActivity', () {
    StartedActivity build({String estado = 'EC'}) => StartedActivity(
          docEntry: 1,
          docNum: 2,
          technicianCode: '1146',
          estado: estado,
          startedAt: DateTime(2026, 1, 2, 3, 4),
          updatedAt: DateTime(2026, 1, 2, 3, 5),
        );

    test('isOpen mientras no esté finalizada', () {
      expect(build(estado: 'EC').isOpen, isTrue);
      expect(build(estado: 'EA').isOpen, isTrue);
      expect(build(estado: 'F').isOpen, isFalse);
    });

    test('displayId y statusLabel', () {
      expect(build().displayId, 'OM-2');
      expect(build(estado: 'EC').statusLabel, 'En Camino');
      expect(build(estado: 'F').statusLabel, 'Finalizada');
    });

    test('copyWith no muta el original', () {
      final a = build(estado: 'EC');
      final b = a.copyWith(estado: 'F');
      expect(a.estado, 'EC');
      expect(b.estado, 'F');
    });

    test('toJson/fromJson roundtrip con tareas y materiales', () {
      final a = build(estado: 'EA').copyWith(
        tasks: [
          ActivityTask(
              id: 't1', description: 'Inspección', createdAt: DateTime(2026)),
        ],
        materials: [
          ActivityMaterial(
              id: 'm1',
              description: 'Filtro',
              quantity: 2,
              createdAt: DateTime(2026)),
        ],
      );
      final back = StartedActivity.fromJson(a.toJson());
      expect(back.docNum, 2);
      expect(back.technicianCode, '1146');
      expect(back.estado, 'EA');
      expect(back.tasks.length, 1);
      expect(back.tasks.first.description, 'Inspección');
      expect(back.materials.length, 1);
      expect(back.materials.first.quantity, 2);
    });
  });
}
