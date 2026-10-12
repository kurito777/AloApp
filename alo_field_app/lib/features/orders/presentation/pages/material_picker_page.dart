import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/catalog_service.dart';
import '../../../../core/services/service_locator.dart';

/// Resultado de elegir un material: código, nombre y cantidad.
typedef MaterialSelection = ({String code, String name, double quantity});

/// Buscador de materiales contra el maestro OITM de SAP.
///
/// El técnico busca por nombre o código, elige un artículo, indica la cantidad
/// y confirma. Devuelve un [MaterialSelection] a la pantalla anterior.
class MaterialPickerPage extends StatefulWidget {
  const MaterialPickerPage({super.key});

  @override
  State<MaterialPickerPage> createState() => _MaterialPickerPageState();
}

class _MaterialPickerPageState extends State<MaterialPickerPage> {
  final CatalogService _catalog = getIt<CatalogService>();
  final _searchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  Timer? _debounce;

  List<CatalogItem> _results = const [];
  CatalogItem? _selected;
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() {
        _results = const [];
        _searched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(v));
  }

  Future<void> _search(String v) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _catalog.searchItems(v);
      if (!mounted) return;
      setState(() {
        _results = res;
        _loading = false;
        _searched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo buscar en SAP. Reintenta.';
        _loading = false;
        _searched = true;
      });
    }
  }

  void _confirm() {
    final item = _selected;
    if (item == null) return;
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.')) ?? 1;
    Navigator.of(context).pop<MaterialSelection>(
      (code: item.code, name: item.name, quantity: qty <= 0 ? 1.0 : qty),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1C24),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Buscar material',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Nombre o código del material...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _resultsView()),
          if (_selected != null) _bottomBar(),
        ],
      ),
    );
  }

  Widget _resultsView() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _hint(Icons.cloud_off_outlined, _error!);
    }
    if (!_searched) {
      return _hint(Icons.inventory_2_outlined,
          'Escribe al menos 2 caracteres para buscar en el catálogo.');
    }
    if (_results.isEmpty) {
      return _hint(Icons.search_off, 'Sin resultados. Prueba otro término.');
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final it = _results[i];
        final selected = _selected?.code == it.code;
        return ListTile(
          selected: selected,
          selectedTileColor: const Color(0xFFFFF7D6),
          leading: Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? const Color(0xFF00A650) : Colors.grey,
          ),
          title: Text(it.name, style: const TextStyle(fontSize: 14)),
          subtitle: Text(it.code,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          onTap: () => setState(() => _selected = it),
        );
      },
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selected!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(_selected!.code,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 64,
              child: TextField(
                controller: _qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Cant.',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCE00),
                foregroundColor: const Color(0xFF1A1C24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hint(IconData icon, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
}
