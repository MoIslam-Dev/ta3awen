import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../models/listing.dart';
import '../../services/image_service.dart';
import '../../services/listing_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/errors.dart';
import '../../utils/labels.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/wilaya_commune_fields.dart';

class ListingFormScreen extends StatefulWidget {
  final Listing? existing;

  const ListingFormScreen.create({super.key}) : existing = null;

  const ListingFormScreen.edit(this.existing, {super.key});

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _listingService = ListingService();
  final _imageService = ImageService();
  final _userService = UserService();

  String? _category;
  String? _condition;
  String? _wilaya;
  String? _commune;

  List<String>? _newImages;
  String? _newThumb;
  List<String> _existingImages = [];
  bool _loadingImages = false;
  bool _saving = false;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _phoneCtrl.text = e.contactPhone ?? '';
      _category = e.category;
      _condition = e.condition;
      _wilaya = e.wilaya;
      _commune = e.commune;
      _loadExistingImages(e.id);
    } else {
      _category = kCategories.first;
      _condition = kConditions[2];
    }
  }

  Future<void> _loadExistingImages(String id) async {
    try {
      final images = await _listingService.imagesOf(id);
      if (mounted) setState(() => _existingImages = images);
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// Phone is mandatory: the app has no chat, so contact happens by phone.
  String? _validatePhone(String? value) {
    final l = context.l10n;
    if (_normalizePhone(value ?? '').isEmpty) {
      return l.phoneRequired;
    }
    if (!RegExp(r'^0[2-7]\d{8}$').hasMatch(_normalizePhone(value!))) {
      return l.phoneInvalid;
    }
    return null;
  }

  String _normalizePhone(String value) {
    var p = value.trim().replaceAll(RegExp(r'[\s\-().]'), '');
    if (p.startsWith('+213')) p = '0${p.substring(4)}';
    if (p.startsWith('00213')) p = '0${p.substring(5)}';
    return p;
  }

  Future<void> _pickImages() async {
    try {
      final files = await _imageService.pickImages();
      if (files.isEmpty) return;
      setState(() => _loadingImages = true);
      final processed = await _imageService.process(files);
      if (processed != null && mounted) {
        setState(() {
          _newThumb = processed.thumbB64;
          _newImages = processed.imagesB64;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.processingImages)),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingImages = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _normalizePhone(_phoneCtrl.text);
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final e = widget.existing!;
        final draft = Listing(
          id: e.id,
          ownerId: e.ownerId,
          ownerName: e.ownerName,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _category!,
          wilaya: _wilaya!,
          commune: _commune!,
          condition: _condition!,
          status: e.status,
          contactPhone: phone,
          image0: e.image0,
          imageCount: e.imageCount,
        );
        await _listingService.update(
          draft: draft,
          newImagesB64: _newImages,
          thumbB64: _newThumb,
        );
      } else {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        String ownerName = 'مستخدم';
        final user = await _userService.getById(uid);
        if (user != null && user.fullName.isNotEmpty) {
          ownerName = user.fullName;
        }
        final draft = Listing(
          id: '',
          ownerId: uid,
          ownerName: ownerName,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _category!,
          wilaya: _wilaya!,
          commune: _commune!,
          condition: _condition!,
          status: statusAvailable,
          contactPhone: phone,
          image0: _newThumb,
          imageCount: _newImages?.length ?? 0,
        );
        await _listingService.create(
          draft: draft,
          imagesB64: _newImages ?? const [],
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? context.l10n.editSaved
                : context.l10n.published),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final images = _newImages ?? (_isEdit ? _existingImages : const <String>[]);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l.editListingTitle : l.createListingTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: l.listingTitleLabel,
                  prefixIcon: const Icon(Icons.title_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? l.titleInvalid : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                maxLength: 800,
                decoration: InputDecoration(
                  labelText: l.descriptionLabel,
                  hintText: l.descriptionHint,
                  prefixIcon: const Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 5) ? l.descriptionInvalid : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.categoryLabel,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: kCategories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(categoryLabel(context, c)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? l.categoryInvalid : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _condition,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l.conditionLabel,
                  prefixIcon: const Icon(Icons.star_outline),
                ),
                items: kConditions
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(conditionLabel(context, c)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _condition = v),
                validator: (v) => v == null ? l.conditionInvalid : null,
              ),
              const SizedBox(height: 16),
              WilayaCommuneFields(
                wilaya: _wilaya,
                commune: _commune,
                wilayaLabel: l.wilaya,
                communeLabel: l.commune,
                onWilaya: (v) => setState(() {
                  _wilaya = v;
                  _commune = null;
                }),
                onCommune: (v) => setState(() => _commune = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                validator: _validatePhone,
                decoration: InputDecoration(
                  labelText: l.phoneLabel,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  helperText: l.phoneHelper,
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(l.images, style: theme.textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Text(
                    l.imagesCount(images.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_loadingImages)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (images.isNotEmpty)
                  SizedBox(
                    height: 96,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsetsDirectional.only(end: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Base64Image(
                            data: images[i],
                            width: 96,
                            height: 96,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: images.length >= 5 ? null : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    images.isEmpty ? l.addImages : l.changeImages,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? l.saveChanges : l.publish),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
