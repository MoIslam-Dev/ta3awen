import 'package:flutter/material.dart';
import '../../l10n/ext.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/errors.dart';
import '../../utils/google_auth.dart';
import '../../widgets/social_sign_in_button.dart';
import '../../widgets/wilaya_commune_fields.dart';
import '../auth_gate.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthService();
  final _users = UserService();
  String? _wilaya;
  String? _commune;
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await _auth.register(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
      await _users.createAppUser(
        uid: cred.user!.id,
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        wilaya: _wilaya!,
        commune: _commune!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.accountCreated)),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(authErrorMessage(context, e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    await handleGoogleSignIn(context);
    if (mounted) setState(() => _googleLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.registerTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.registerHelp,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              SocialSignInButton(
                label: l.signInWithGoogle,
                loading: _googleLoading,
                onPressed: _loading ? null : _google,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: OrDivider(label: l.orLabel),
              ),
              Form(
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
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: l.email,
                        prefixIcon: const Icon(Icons.mail_outline),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? l.invalidEmailMsg : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: l.passwordMin,
                        helperText: l.passwordHelper,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? l.weakPasswordMsg : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      textDirection: TextDirection.ltr,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: l.passwordConfirm,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) =>
                          (v != _passwordCtrl.text) ? l.passwordMismatch : null,
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
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.createAccount),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}