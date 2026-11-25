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
  // Lazy so the screen can be built in a widget test without Firebase — the
  // service (and Firestore/Storage) is only created when a save/upload runs.
  late final _admin = ProductAdminService();
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _crop;
  late final TextEditingController _type;
  late final TextEditingController _packSize;
  late final TextEditingController _brandLine;
  late final TextEditingController _printedInfo;
  late final TextEditingController _features;

  late bool _available;
  late bool _isNew;

  static const _maxImages = 6;

  // Each gallery slot is either a photo already uploaded (its URL) or one
  // freshly picked and waiting to upload on save. The first slot is the
  // primary image shown in lists.
  final List<_ImageSlot> _images = [];
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _crop = TextEditingController(text: p?.crop ?? '');
    _type = TextEditingController(text: p?.type ?? '');
    _packSize = TextEditingController(text: p?.packSize ?? '');
    _brandLine = TextEditingController(text: p?.brandLine ?? '');
    _printedInfo = TextEditingController(text: p?.printedInfo ?? '');
    _features = TextEditingController(text: (p?.features ?? []).join('\n'));
    _available = p?.available ?? true;
    _isNew = p?.isNew ?? false;

    // Seed the gallery with the product's existing photos (the new [imageUrls]
    // list, or the single legacy [imageUrl]).
    final existingUrls = (p?.imageUrls.isNotEmpty ?? false)
        ? p!.imageUrls
        : ((p?.imageUrl.isNotEmpty ?? false) ? [p!.imageUrl] : const <String>[]);
    _images.addAll(existingUrls.map(_ImageSlot.existing));
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _crop,
      _type,
      _packSize,
      _brandLine,
      _printedInfo,
      _features,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Pick one or more photos from the gallery and append them (up to
  /// [_maxImages] total). They upload when the form is saved.
  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;
    final picked =
        await _picker.pickMultiImage(maxWidth: 1280, imageQuality: 80);
    if (picked.isEmpty) return;
    final slots = <_ImageSlot>[];
    for (final x in picked.take(remaining)) {
      final bytes = await x.readAsBytes();
      final ct =
          x.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      slots.add(_ImageSlot.picked(bytes, ct));
    }
    if (!mounted) return;
    setState(() => _images.addAll(slots));
  }

  void _removeImage(int i) => setState(() => _images.removeAt(i));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final id = widget.existing?.id ?? _admin.newId();
    try {
      // Upload any newly picked photos, keep existing URLs, in order. The
      // first photo becomes the primary [imageUrl] (used in lists).
      final imageUrls = <String>[];
      for (var i = 0; i < _images.length; i++) {
        final slot = _images[i];
        if (slot.bytes != null) {
          imageUrls.add(await _admin.uploadImage(id, slot.bytes!,
              index: i, contentType: slot.contentType));
        } else if (slot.url != null && slot.url!.isNotEmpty) {
          imageUrls.add(slot.url!);
        }
      }
      final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : '';

      // Crop key (the filter id) is derived from the crop name — there is no
      // manual field for it.
      final cropKey = _crop.text
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
        imageUrls: imageUrls,
        available: _available,
        // No manual field: new products sort at 0; edits keep their place.
        sortOrder: widget.existing?.sortOrder ?? 0,
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
                _field(_type, 'Type (e.g. Hybrid / Selection)'),
                _field(_packSize, 'Pack size (e.g. 10 g)'),
                _field(_brandLine, 'Sub-brand (optional)'),
                _field(_printedInfo, 'Printed info', maxLines: 3),
                _field(_features, 'Features (one per line)', maxLines: 6),
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

  /// The photo gallery editor: a row of thumbnails (first one is the "Main"
  /// image) with a remove button on each and an "Add" tile to pick more.
  Widget _imagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library_outlined,
                size: 18, color: AppColors.green),
            const SizedBox(width: 6),
            Text('Product photos (${_images.length}/$_maxImages)',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.ink)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _images.length; i++) _thumb(i),
            if (_images.length < _maxImages) _addTile(),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Add 3–4 photos of the product. The first photo is the main one '
          'shown in lists. New photos upload when you save.',
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _thumb(int i) {
    final slot = _images[i];
    final Widget img = slot.bytes != null
        ? Image.memory(slot.bytes!, fit: BoxFit.cover)
        : Image.network(slot.url!,
            fit: BoxFit.cover, errorBuilder: (_, _, _) => _imgPlaceholder());

    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.06),
                  border: Border.all(
                      color: i == 0 ? AppColors.green : AppColors.line,
                      width: i == 0 ? 1.6 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: img,
              ),
            ),
          ),
          if (i == 0)
            PositionedDirectional(
              start: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Main',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          PositionedDirectional(
            end: 2,
            top: 2,
            child: GestureDetector(
              onTap: () => _removeImage(i),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xCC000000),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.5)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.green),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(fontSize: 11, color: AppColors.green)),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => const Center(
        child: Icon(Icons.image_outlined, size: 32, color: AppColors.muted),
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

/// One slot in the product photo gallery editor: a photo already uploaded
/// (its [url]) or one freshly picked and waiting to upload (its [bytes]).
class _ImageSlot {
  _ImageSlot.existing(this.url)
      : bytes = null,
        contentType = 'image/jpeg';
  _ImageSlot.picked(this.bytes, this.contentType) : url = null;

  final String? url;
  final Uint8List? bytes;
  final String contentType;
}
