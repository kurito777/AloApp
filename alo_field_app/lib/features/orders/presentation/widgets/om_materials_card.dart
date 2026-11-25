import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/order_model.dart';
import 'om_card.dart';
import 'om_section_header.dart';

/// Tarjeta con los materiales registrados en la OM.
class OmMaterialsCard extends StatelessWidget {
  final OrderModel order;
  final bool editable;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<OrderDetailLine> onDelete;

  const OmMaterialsCard({
    super.key,
    required this.order,
    required this.editable,
    required this.busy,
    required this.onAdd,
    required this.onDelete,
  });

  List<Widget> _rows() {
    final materials = order.visibleMaterials;
    final rows = <Widget>[];
    for (var i = 0; i < materials.length; i++) {
      if (i > 0) {
        rows.add(const Divider(height: 1, color: AppColors.divider));
      }
      rows.add(
        _MaterialRow(
          material: materials[i],
          editable: editable,
          busy: busy,
          onDelete: onDelete,
        ),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return OmCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OmSectionHeader(
              icon: Icons.inventory_2_outlined,
              title: 'Materiales (${order.materialCount})',
              showAdd: editable,
              onAdd: busy ? null : onAdd,
            ),
            const SizedBox(height: 10),
            if (order.visibleMaterials.isEmpty)
              const OmEmptyNote(text: 'Sin materiales registrados.')
            else
              ..._rows(),
          ],
        ),
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  final OrderDetailLine material;
  final bool editable;
  final bool busy;
  final ValueChanged<OrderDetailLine> onDelete;

  const _MaterialRow({
    required this.material,
    required this.editable,
    required this.busy,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              material.itemDescription ?? material.itemCode ?? 'Material',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'x${material.quantity?.toStringAsFixed(0) ?? '1'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (editable)
            IconButton(
              onPressed: busy ? null : () => onDelete(material),
              color: AppColors.error,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(Icons.delete_outline_rounded, size: 22),
            ),
        ],
      ),
    );
  }
}