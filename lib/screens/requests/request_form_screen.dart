import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../models/request_post.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/errors.dart';
import '../../utils/labels.dart';
import '../../utils/request_kind.dart';
import '../../widgets/wilaya_commune_fields.dart';

class RequestFormScreen extends StatefulWidget {
  final RequestPost? existing;

  const RequestFormScreen.create({
    super.key,
    this.initialType,
    this.initialKind = requestKindGeneral,
  }) : existing = null;

  const RequestFormScreen.edit(this.existing, {super.key})
      : initialType = null,
        initialKind = requestKindGeneral;

  /// Preselects the "need" / "offer" chip when creating from the board.
  final String? initialType;

  /// 'blood' opens the blood-donation form (type fixed to need).
  final String initialKind;

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _requestService = RequestService();
  final _userService = UserService();

  String _type = requestTypeNeed;
  String _kind = requestKindGeneral;
  String? _bloodType;
  String? _category;
  String? _wilaya;
  String? _commune;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  bool get _isBlood => _kind == requestKindBlood;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _kind = e.kind;
      _type = e.type;
      _bloodType = e.bloodType;
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _phoneCtrl.text = e.contactPhone ?? '';
      _category = e.category;
      _wilaya = e.wilaya;
      _commune = e.commune;
    } else {
      _kind = widget.initialKind;
      _type = widget.initialType ?? requestTypeNeed;
      if (_isBlood) {
        // Blood posts are always needs with a fixed category.
        _type = requestTypeNeed;
        _category = kBloodCategory;
      } else {
        _category = kCategories.first;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// Same rule as listings: mandatory Algerian phone, no in-app chat.
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = _normalizePhone(_phoneCtrl.text);
    setState(() => _saving = true);
    try {
      // Blood posts are always needs under the fixed blood category.
      final type = _isBlood ? requestTypeNeed : _type;
      final category = _isBlood ? kBloodCategory : _category!;
      if (_isEdit) {
        final e = widget.existing!;
        final draft = RequestPost(
          id: e.id,
          uid: e.uid,
          userName: e.userName,
          type: type,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: category,
          wilaya: _wilaya!,
          commune: _commune!,
          contactPhone: phone,
          status: e.status,
          kind: _kind,
          bloodType: _bloodType,
        );
        await _requestService.update(draft);
      } else {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        String userName = 'مستخدم';
        final user = await _userService.getById(uid);
        if (user != null && user.fullName.isNotEmpty) {
          userName = user.fullName;
        }
        final draft = RequestPost(
          id: '',
          uid: uid,
          userName: userName,
          type: type,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: category,
          wilaya: _wilaya!,
          commune: _commune!,
          contactPhone: phone,
          kind: _kind,
          bloodType: _bloodType,
        );
        await _requestService.create(draft);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? context.l10n.editSaved : context.l10n.reqPublished,
            ),
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
    final l = context.l10n;
    final isNeed = _type == requestTypeNeed;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l.reqEditTitle : l.reqCreateTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isEdit) ...[
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: requestKindGeneral,
                      label: Text(l.reqKindOptionGeneral),
                      icon: const Icon(Icons.forum_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: requestKindBlood,
                      label: Text(l.reqKindOptionBlood),
                      icon: const Icon(Icons.bloodtype_outlined, size: 18),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) {
                    final updated = applyRequestKindSwitch(
                      s.first,
                      previousType: _type,
                      previousCategory: _category,
                    );
                    setState(() {
                      _kind = updated.kind;
                      _type = updated.type;
                      _category = updated.category;
                      _bloodType = updated.bloodType;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (!_isEdit && !_isBlood) ...[
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: requestTypeNeed,
                      label: Text(l.reqTypeNeed),
                      icon: const Icon(Icons.help_outline, size: 18),
                    ),
                    ButtonSegment(
                      value: requestTypeOffer,
                      label: Text(l.reqTypeOffer),
                      icon: const Icon(Icons.volunteer_activism_outlined,
                          size: 18),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 16),
              ],
              if (_isBlood) ...[
                DropdownButtonFormField<String>(
                  value: _bloodType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.reqBloodTypeLabel,
                    prefixIcon: const Icon(Icons.bloodtype_outlined),
                  ),
                  items: kBloodTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _bloodType = v),
                  validator: (v) =>
                      v == null ? l.reqBloodTypeInvalid : null,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: l.listingTitleLabel,
                  hintText: _isBlood
                      ? l.reqBloodTitle
                      : (isNeed ? l.reqTitleNeed : l.reqTitleOffer),
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
                  hintText: _isBlood
                      ? l.reqBloodDesc
                      : (isNeed ? l.reqDescNeed : l.reqDescOffer),
                  prefixIcon: const Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().length < 5)
                    ? l.descriptionInvalid
                    : null,
              ),
              const SizedBox(height: 8),
              if (!_isBlood) ...[
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
              ],
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
