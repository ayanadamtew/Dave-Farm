import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_controller.dart';
import 'register_screen.dart';
import 'package:dave_farm/l10n/app_localizations.dart';

const _storage = FlutterSecureStorage();
const _jwtKey = 'dave_farm_jwt';

class LoginScreen extends StatefulWidget {
  final SettingsController settingsController;

  const LoginScreen({super.key, required this.settingsController});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'password': _passCtrl.text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await _storage.write(key: _jwtKey, value: data['access_token']);
        if (mounted) _goToDashboard();
      } else {
        setState(() => _errorMsg = 'Login failed. Check your credentials.');
      }
    } catch (_) {
      // Offline — proceed if backend unreachable but no local data matters
      setState(() => _errorMsg =
          'Cannot reach server. Check your internet connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          settingsController: widget.settingsController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Logo
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.egg_alt_rounded,
                      color: Color(0xFF2E7D32), size: 36),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.appTitle,
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800)),
                    Text(AppLocalizations.of(context)!.labelPoultryManagement,
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ]),
              const SizedBox(height: 48),
               Text(AppLocalizations.of(context)!.labelWelcomeBack,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
               Text(AppLocalizations.of(context)!.labelSignInSubtitle,
                  style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.fieldEmail,
                        prefixIcon: const Icon(Icons.email_rounded),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? AppLocalizations.of(context)!.errRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.fieldPassword,
                        prefixIcon: const Icon(Icons.lock_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                               ? Icons.visibility_off_rounded
                               : Icons.visibility_rounded),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? AppLocalizations.of(context)!.errRequired : null,
                    ),
                    const SizedBox(height: 8),
                    if (_errorMsg != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_errorMsg!,
                                  style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13))),
                        ]),
                      ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.login_rounded),
                      label: Text(_loading ? AppLocalizations.of(context)!.msgSigningIn : AppLocalizations.of(context)!.btnLogin),
                    ),
                    const SizedBox(height: 16),
                    // Offline-first hint
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _storage.write(key: 'dave_farm_offline', value: 'true');
                        if (mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => DashboardScreen(
                                settingsController: widget.settingsController,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.wifi_off_rounded,
                          color: Colors.white54),
                      label: Text(AppLocalizations.of(context)!.btnContinueOffline,
                          style: const TextStyle(color: Colors.white54)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(
                              settingsController: widget.settingsController,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context)!.titleRegister,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
