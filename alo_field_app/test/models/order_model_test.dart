import 'package:flutter_test/flutter_test.dart';
import 'package:alo_field_app/features/orders/data/models/order_model.dart';

void main() {
  group('OrderModel.fromJson (VID_MTOM)', () {
    final json = <String, dynamic>{
      'DocEntry': 100,
      'DocNum': 61590,
      'Status': 'O',
      'U_Estado': 'L',
      'U_Cliente': 'Cliente X',
      'U_Equipo': '160W',
      'U_EquipoN': '160W - ALO LIFT',
      'U_UsrRes': '1146',
      'U_UsrResN': 'OSCAR VERGARA',
      'U_Superv': '114',
      'VID_MTOMTACollection': [
        {
          'LineId': 1,
          'U_Name': 'Tarea 1',
          'U_Code': '001',
          'U_Estado': 'T',
          'U_UsrResp': '1146',
          'U_UsrRespN': 'OSCAR',
        },
        {
          'LineId': 2,
          'U_Name': 'Cambiar filtro',
          'U_Code': '002',
          'U_Estado': 'N',
          'U_UsrResp': '',
          'U_UsrRespN': '',
        },
        {'LineId': 3, 'U_Name': 'Revisar', 'U_Estado': 'P'},
      ],
      'VID_MTOMMACollection': [
        // Línea fantasma vacía que trae SAP → debe filtrarse.
        {'U_ItemName': '', 'U_ItemCode': '', 'U_Cantidad': 0},
        {'U_ItemName': 'FILTRO', 'U_ItemCode': 'FIL1', 'U_Cantidad': 2},
      ],
    };

    final om = OrderModel.fromJson(json);

    test('parsea identificadores y estado', () {
      expect(om.docNum, 61590);
      expect(om.docEntry, 100);
      expect(om.estado, 'L');
      expect(om.displayId, 'OM-61590');
    });

    test('displayStatus usa el catálogo real de la OM', () {
      expect(om.displayStatus, 'Liberada');
    });

    test('isEditable es true para Liberada', () {
      expect(om.isEditable, isTrue);
    });

    test('parsea tareas de VID_MTOMTACollection', () {
      expect(om.tasksTotal, 3);
      expect(om.tasks.first.displayName, 'Tarea 1');
      expect(om.tasks.first.tecnicoCode, '1146');
    });

    test('cuenta pendientes (N y P) y terminadas (T)', () {
      expect(om.tasksPending, 2);
      expect(om.tasksDone, 1);
    });

    test('visibleMaterials excluye la línea vacía', () {
      expect(om.detailLines.length, 2);
      expect(om.visibleMaterials.length, 1);
      expect(om.materialCount, 1);
      expect(om.visibleMaterials.first.itemDescription, 'FILTRO');
    });
  });

  group('OrderModel.isEditable', () {
    test('Cerrada (C) no editable', () {
      expect(const OrderModel(estado: 'C').isEditable, isFalse);
    });
    test('Cancelada (X) no editable', () {
      expect(const OrderModel(estado: 'X').isEditable, isFalse);
    });
    test('null/desconocido editable', () {
      expect(const OrderModel(estado: null).isEditable, isTrue);
      expect(const OrderModel(estado: 'L').isEditable, isTrue);
    });
  });

  group('OrderTask', () {
    test('isPending para N y P, no para T', () {
      expect(const OrderTask(estado: 'N').isPending, isTrue);
      expect(const OrderTask(estado: 'P').isPending, isTrue);
      expect(const OrderTask(estado: 'T').isPending, isFalse);
    });
    test('statusLabel', () {
      expect(const OrderTask(estado: 'T').statusLabel, 'Terminada');
      expect(const OrderTask(estado: 'N').statusLabel, 'Pendiente');
    });
    test('displayName cae al código o al lineId', () {
      expect(const OrderTask(lineId: 5).displayName, 'Tarea 5');
      expect(
        const OrderTask(description: 'Cambiar aceite').displayName,
        'Cambiar aceite',
      );
    });
  });
}
