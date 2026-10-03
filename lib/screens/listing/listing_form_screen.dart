import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/listing.dart';
import '../../services/image_service.dart';
import '../../services/listing_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/errors.dart';
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
          const SnackBar(content: Text('تعذّر معالجة الصور المختارة')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingImages = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneCtrl.text.trim();
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
          contactPhone: phone.isEmpty ? null : phone,
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
          contactPhone: phone.isEmpty ? null : phone,
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
            content: Text(_isEdit ? 'تم حفظ التعديلات' : 'تم نشر الإعلان بنجاح'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _newImages ?? (_isEdit ? _existingImages : const <String>[]);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل الإعلان' : 'إضافة إعلان جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'عنوان الإعلان',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'أدخل عنواناً واضحاً' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                maxLength: 800,
                decoration: const InputDecoration(
                  labelText: 'الوصف',
                  hintText: 'اذكر حالة الغرض وملاحظات مهمة...',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 5) ? 'أدخل وصفاً مختصراً' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'التصنيف',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: kCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'اختر التصنيف' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _condition,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'الحالة',
                  prefixIcon: Icon(Icons.star_outline),
                ),
                items: kConditions
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _condition = v),
                validator: (v) => v == null ? 'اختر الحالة' : null,
              ),
              const SizedBox(height: 16),
              WilayaCommuneFields(
                wilaya: _wilaya,
                commune: _commune,
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
                decoration: const InputDecoration(
                  labelText: 'رقم هاتف للتواصل (اختياري)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  helperText: 'يظهر لمن يرغب بالتواصل معك فقط عند الضغط على زر',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('الصور',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Text(
                    '(${images.length}/5)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_loadingImages)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                if (images.isNotEmpty)
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Base64Image(
                            data: images[i],
                            width: 90,
                            height: 90,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: images.length >= 5 ? null : _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(images.isEmpty
                      ? 'إضافة صور (حتى 5)'
                      : 'تغيير الصور'),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'حفظ التعديلات' : 'نشر الإعلان'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
