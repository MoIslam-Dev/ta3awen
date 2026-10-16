import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/errors.dart';
import '../../widgets/wilaya_commune_fields.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _users = UserService();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late String? _wilaya;
  late String? _commune;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.fullName);
    _phoneCtrl = TextEditingController(text: widget.user.contactPhone ?? '');
    _wilaya = widget.user.wilaya.isEmpty ? null : widget.user.wilaya;
    _commune = widget.user.commune.isEmpty ? null : widget.user.commune;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final l = context.l10n;
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^0[2-7]\d{8}$').hasMatch(_normalizePhone(value))) {
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
    if (_wilaya == null || _commune == null) return;
    final uid = AuthService.uid;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      final phone = _phoneCtrl.text.trim();
      await _users.updateProfile(
        uid: uid,
        fullName: _nameCtrl.text.trim(),
        wilaya: _wilaya!,
        commune: _commune!,
        contactPhone: phone.isEmpty ? null : _normalizePhone(phone),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.profileUpdated)));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(dataErrorMessage(context, e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.editProfileTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l.fullName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? l.enterFullName
                      : null,
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
                  decoration: InputDecoration(
                    labelText: l.userDetailPhone,
                    hintText: '0550123456',
                    helperText: l.phoneHelper,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
