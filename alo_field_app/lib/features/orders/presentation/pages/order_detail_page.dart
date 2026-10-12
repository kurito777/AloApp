import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order_model.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderModel? order;

  const OrderDetailPage({
    super.key,
    this.order,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool checklistPower = false;
  bool checklistConnection = false;
  bool checklistTesting = false;

  final TextEditingController commentsController = TextEditingController();

  late OrderModel order;

  final List<String> spareParts = [
    'Cable UTP Cat6',
    'Router Cisco',
    'Fuente Poder 12V',
  ];

  @override
  void initState() {
    super.initState();
    
    // Si no se proporciona una orden, crear una por defecto
    order = widget.order ?? const OrderModel(
      docNum: 0,
      cliente: 'Cliente Demo',
      status: 'O',
      prioridad: 'A',
      taller: 'CUR-01',
      supervisorName: 'Supervisor Demo',
    );
  }

  @override
  void dispose() {
    commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C24),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          order.displayId,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información SAP',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            buildInfoCard(),
            const SizedBox(height: 24),
            const Text(
              'Checklist Técnico',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            buildChecklist(),
            const SizedBox(height: 24),
            const Text(
              'Repuestos Utilizados',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            buildSpareParts(),
            const SizedBox(height: 24),
            const Text(
              'Comentarios Técnicos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentsController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe diagnóstico y solución aplicada',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Actividad iniciada')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCE00),
                  foregroundColor: const Color(0xFF1A1C24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.play_arrow,
                  color: Color(0xFF1A1C24),
                ),
                label: const Text(
                  'Iniciar Actividad',
                  style: TextStyle(
                    color: Color(0xFF1A1C24),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cargador de evidencias')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1C24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFFFFCE00),
                ),
                label: const Text(
                  'Subir Evidencias',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Orden técnica finalizada')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.check,
                  color: Colors.white,
                ),
                label: const Text(
                  'Finalizar OT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildInfoRow('Cliente', order.clientDisplayName),
            buildInfoRow('Dirección', order.fullAddress),
            buildInfoRow('Técnico', order.technicianName),
            buildInfoRow('Estado', order.displayStatus),
            buildInfoRow('Prioridad', order.priorityLabel),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget buildChecklist() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: checklistPower,
            title: const Text('Validación eléctrica'),
            onChanged: (value) {
              setState(() {
                checklistPower = value!;
              });
            },
          ),
          CheckboxListTile(
            value: checklistConnection,
            title: const Text('Conectividad de red'),
            onChanged: (value) {
              setState(() {
                checklistConnection = value!;
              });
            },
          ),
          CheckboxListTile(
            value: checklistTesting,
            title: const Text('Pruebas operacionales'),
            onChanged: (value) {
              setState(() {
                checklistTesting = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildSpareParts() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: spareParts.map((part) {
          return ListTile(
            leading: const Icon(Icons.build),
            title: Text(part),
          );
        }).toList(),
      ),
    );
  }
}