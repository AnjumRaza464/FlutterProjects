import 'package:material_ui/material_ui.dart';

import '../data/sindh_districts.dart';
import '../l10n/app_strings.dart';
import '../theme/app_palette.dart';

/// A labelled "pick your district" field that matches [AccountField]'s look: a
/// label above a rounded, tappable box that opens a bottom-sheet list of the
/// Sindh districts. Returns the chosen district through [onChanged].
///
/// District is picked from one shared, canonical list (never free text), so a
/// farmer's district and a dealer's district can be compared exactly — this is
/// what lets "Find a Dealer" match a grower to the dealers in their district.
class DistrictPickerField extends StatelessWidget {
  const DistrictPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.leading = '📍',
  });

  /// The chosen district, or '' when none is picked yet.
  final String value;
  final ValueChanged<String> onChanged;
  final String? label;
  final String leading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? s.districtLabel,
          style: TextStyle(
            color: c.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final chosen =
                await showDistrictPicker(context, current: value.isEmpty ? null : value);
            if (chosen != null) onChanged(chosen);
          },
          child: Container(
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.line),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                if (leading.isNotEmpty) ...[
                  Text(leading, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    value.isEmpty ? s.chooseYourDistrict : s.data(value),
                    style: TextStyle(
                      color: value.isEmpty ? c.muted : c.ink,
                      fontSize: 15,
                      fontWeight:
                          value.isEmpty ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: c.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Opens a bottom sheet listing the Sindh districts and returns the chosen one
/// (or null if dismissed). Shared by the registration forms and Find a Dealer.
Future<String?> showDistrictPicker(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _DistrictSheet(current: current),
  );
}

class _DistrictSheet extends StatelessWidget {
  const _DistrictSheet({this.current});

  final String? current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.s;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(s.chooseYourDistrict,
                    style: TextStyle(
                        color: c.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sindhDistricts.length,
                itemBuilder: (context, i) {
                  final d = sindhDistricts[i];
                  final selected = d == current;
                  return ListTile(
                    title: Text(s.data(d),
                        style: TextStyle(
                            color: c.ink,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w500)),
                    trailing:
                        selected ? Icon(Icons.check, color: c.green) : null,
                    onTap: () => Navigator.of(context).pop(d),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
