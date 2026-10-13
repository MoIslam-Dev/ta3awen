import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/errors.dart';
import '../../widgets/wilaya_commune_fields.dart';
import '../auth_gate.dart';

/// First sign-in via Google has no Ta3awen profile yet, and every profile
/// needs a wilaya/commune (the app is location-centric). This short completion
/// screen creates the `users/{uid}` document from the Google identity.
class SocialSetupScreen extends StatefulWidget {
  const SocialSetupScreen({super.key, required this.user});

  final User user;

  @override
  State<SocialSetupScreen> createState() => _SocialSetupScreenState();
}

class _SocialSetupScreenState extends State<SocialSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.user.displayName ?? '');
  final _users = UserService();
  String? _wilaya;
  String? _commune;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final l = context.l10n;
    try {
      await _users.createAppUser(
        uid: widget.user.uid,
        fullName: _nameCtrl.text.trim(),
        email: widget.user.email ?? '',
        wilaya: _wilaya!,
        commune: _commune!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.accountCreated)),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authErrorMessage(context, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.socialSetupTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.handshake_outlined,
                  size: 44,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  l.socialSetupBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
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
                TextFormField(
                  initialValue: widget.user.email,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: l.email,
                    prefixIcon: const Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.socialSetupSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}