import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../theme/app_colors.dart';
import 'product_admin_service.dart';

/// Add a new product or edit an existing one.
///
/// All catalog fields are editable here, including availability (which drives
/// the app's "Not available yet" overlay) and sort order. An image can be
/// uploaded to Firebase Storage, or an existing image URL kept.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.existing});

  /// Null when adding a new product.
  final Product? existing;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _admin = ProductAdminService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _crop;
  late final TextEditingController _cropKey;
  late final TextEditingController _type;
  late final TextEditingController _packSize;
  late final TextEditingController _brandLine;
  late final TextEditingController _printedInfo;
  late final TextEditingController _features;
  late final TextEditingController _imageUrl;
  late final TextEditingController _sortOrder;

  late bool _available;
  late bool _isNew;

  Uint8List? _pickedBytes; // new image chosen but not yet uploaded
  String _pickedContentType = 'image/jpeg';
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _crop = TextEditingController(text: p?.crop ?? '');
    _cropKey = TextEditingController(text: p?.cropKey ?? '');
    _type = TextEditingController(text: p?.type ?? '');
    _packSize = TextEditingController(text: p?.packSize ?? '');
    _brandLine = TextEditingController(text: p?.brandLine ?? '');
    _printedInfo = TextEditingController(text: p?.printedInfo ?? '');
    _features = TextEditingController(text: (p?.features ?? []).join('\n'));
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _sortOrder = TextEditingController(text: (p?.sortOrder ?? 0).toString());
    _available = p?.available ?? true;
    _isNew = p?.isNew ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _crop,
      _cropKey,
      _type,
      _packSize,
      _brandLine,
      _printedInfo,
      _features,
      _imageUrl,
      _sortOrder,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedBytes = bytes;
      _pickedContentType =
          picked.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final id = widget.existing?.id ?? _admin.newId();
    try {
      // Upload a newly chosen image first, then store its URL on the product.
      var imageUrl = _imageUrl.text.trim();
      if (_pickedBytes != null) {
        imageUrl = await _admin.uploadImage(id, _pickedBytes!,
            contentType: _pickedContentType);
      }

      final cropKey = _cropKey.text.trim().isNotEmpty
          ? _cropKey.text.trim()
          : _crop.text
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
              .replaceAll(RegExp(r'^_+|_+$'), '');

      final product = Product(
        id: id,
        name: _name.text.trim(),
        crop: _crop.text.trim(),
        cropKey: cropKey,
        type: _type.text.trim(),
        packSize: _packSize.text.trim(),
        brandLine: _brandLine.text.trim(),
        printedInfo: _printedInfo.text.trim(),
        imageUrl: imageUrl,
        available: _available,
        sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
        isNew: _isNew,
        features: [
          for (final line in _features.text.split('\n'))
            if (line.trim().isNotEmpty) line.trim(),
        ],
      );

      await _admin.save(id, product);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "${product.name}".')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit product' : 'Add product'),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _imagePicker(),
                const SizedBox(height: 18),
                _field(_name, 'Name *', required: true),
                _field(_crop, 'Crop *', required: true),
                _field(_cropKey, 'Crop key (filter id — auto if blank)'),
                _field(_type, 'Type (e.g. Hybrid / Selection)'),
                _field(_packSize, 'Pack size (e.g. 10 g)'),
                _field(_brandLine, 'Sub-brand (optional)'),
                _field(_printedInfo, 'Printed info', maxLines: 3),
                _field(_features, 'Features (one per line)', maxLines: 6),
                _field(_imageUrl, 'Image URL (set by upload, or paste one)'),
                _field(_sortOrder, 'Sort order (lower = higher up)',
                    number: true),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _available,
                  activeThumbColor: AppColors.green,
                  title: const Text('Available to order'),
                  subtitle: const Text(
                      'Off = shows the "Not available yet" overlay, sorted below'),
                  onChanged: (v) => setState(() => _available = v),
                ),
                SwitchListTile(
                  value: _isNew,
                  activeThumbColor: AppColors.green,
                  title: const Text('Show "NEW" badge'),
                  onChanged: (v) => setState(() => _isNew = v),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving…' : 'Save product'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePicker() {
    final hasPicked = _pickedBytes != null;
    final hasExisting = _imageUrl.text.trim().isNotEmpty;

    return Column(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasPicked
              ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
              : hasExisting
                  ? Image.network(_imageUrl.text.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imgPlaceholder())
                  : _imgPlaceholder(),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload_outlined),
          label: Text(hasPicked ? 'Change image' : 'Upload image'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.green,
            side: const BorderSide(color: AppColors.green),
          ),
        ),
        if (hasPicked)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Will upload when you save',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
          ),
      ],
    );
  }

  Widget _imgPlaceholder() => const Center(
        child: Icon(Icons.image_outlined, size: 40, color: AppColors.muted),
      );

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    bool number = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: number ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}
