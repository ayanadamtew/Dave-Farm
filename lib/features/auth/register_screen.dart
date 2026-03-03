import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_controller.dart';
import 'package:dave_farm/l10n/app_localizations.dart';

const _storage = FlutterSecureStorage();
const _jwtKey = 'dave_farm_jwt';

class RegisterScreen extends StatefulWidget {
  final SettingsController settingsController;

  const RegisterScreen({super.key, required this.settingsController});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _farmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _farmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'password': _passCtrl.text,
          'farm_name': _farmCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await _storage.write(key: _jwtKey, value: data['access_token']);
        if (mounted) _goToDashboard();
      } else {
        final data = jsonDecode(res.body);
        setState(() => _errorMsg = data['detail'] ?? 'Registration failed.');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Cannot reach server. Check your internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          settingsController: widget.settingsController,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleRegister)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.labelWelcomeBack.replaceAll(l10n.labelWelcomeBack, "Join Dave Farm"),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Create an account to sync your farm data to the cloud.",
                    style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _farmCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.fieldFarmName,
                    prefixIcon: const Icon(Icons.agriculture_rounded),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? l10n.errRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.fieldEmail,
                    prefixIcon: const Icon(Icons.email_rounded),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? l10n.errRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: l10n.fieldPassword,
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v != null && v.length < 6) ? "Password too short (min 6)" : null,
                ),
                const SizedBox(height: 24),
                if (_errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_errorMsg!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.btnRegister),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
