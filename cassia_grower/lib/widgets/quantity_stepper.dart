import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/cart_item.dart';
import '../theme/app_palette.dart';

/// A "− 3 +" control for how many packs of a variety are in the cart.
///
/// At 1 the minus button becomes a bin, so going below one removes the line:
/// [onChanged] is then called with 0. Tapping the number lets the farmer type
/// a quantity directly, which matters for large orders.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  Future<void> _typeQuantity(BuildContext context) async {
    final typed = await showDialog<int>(
      context: context,
      builder: (_) => _QuantityDialog(initial: quantity),
    );
    if (typed != null) onChanged(typed);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    final atMinimum = quantity <= 1;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onChanged(quantity - 1),
            icon: Icon(atMinimum ? Icons.delete_outline : Icons.remove),
            tooltip: atMinimum ? s.remove : s.decrease,
            color: c.green,
            visualDensity: VisualDensity.compact,
          ),
          InkWell(
            onTap: () => _typeQuantity(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minWidth: 34),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              alignment: Alignment.center,
              child: Text(
                '$quantity',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15, color: c.ink),
              ),
            ),
          ),
          IconButton(
            onPressed: quantity >= CartItem.maxQuantity
                ? null
                : () => onChanged(quantity + 1),
            icon: const Icon(Icons.add),
            tooltip: s.increase,
            color: c.green,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Asks for a quantity; pops with the number, or null if cancelled.
class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.initial});
  final int initial;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late final _field = TextEditingController(text: '${widget.initial}');

  @override
  void initState() {
    super.initState();
    // Select the current number so typing replaces it.
    _field.selection =
        TextSelection(baseOffset: 0, extentOffset: _field.text.length);
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _done() {
    final typed = int.tryParse(_field.text);
    // Nothing typed, or zero: leave the cart as it was.
    if (typed == null || typed < 1) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop(CartItem.clampQuantity(typed));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.quantity),
      content: TextField(
        controller: _field,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: InputDecoration(
          labelText: s.numberOfPacks,
          helperText: s.upTo(CartItem.maxQuantity),
        ),
        onSubmitted: (_) => _done(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        FilledButton(onPressed: _done, child: Text(s.ok)),
      ],
    );
  }
}
