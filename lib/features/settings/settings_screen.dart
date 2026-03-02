import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.labelLogOut),
        content: Text(l10n.msgLogOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.btnCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.labelLogOut),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'dave_farm_jwt');
      await storage.delete(key: 'dave_farm_offline');
      
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(settingsController: widget.controller),
        ),
        (route) => false,
      );
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'am':
        return 'Amharic (አማርኛ)';
      case 'om':
        return 'Oromo (Afaan Oromoo)';
      case 'en':
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocaleCode = widget.controller.locale?.languageCode ?? 'en';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSettings)),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => ListView(
          children: [
            const SizedBox(height: 16),
            // --- Profile Section ---
            _SectionHeader(l10n.sectionAccount),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.white12,
                child: Icon(Icons.person_outline_rounded, color: Colors.blueAccent),
              ),
              title: Text(l10n.labelEditProfile),
              subtitle: Text(widget.controller.farmName ?? l10n.labelEditProfileSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(controller: widget.controller),
                  ),
                );
              },
            ),
            const Divider(height: 32),

            // --- App Settings Section ---
            _SectionHeader(l10n.sectionPreferences),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.white12,
                child: Icon(Icons.language_rounded, color: Colors.green),
              ),
              title: Text(l10n.labelLanguage),
              subtitle: Text(_getLanguageName(currentLocaleCode)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            l10n.labelSelectLanguage,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          title: const Text('English'),
                          trailing: currentLocaleCode == 'en'
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            widget.controller.updateLocale(const Locale('en'));
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('አማርኛ (Amharic)'),
                          trailing: currentLocaleCode == 'am'
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            widget.controller.updateLocale(const Locale('am'));
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('Afaan Oromoo (Oromo)'),
                          trailing: currentLocaleCode == 'om'
                               ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            widget.controller.updateLocale(const Locale('om'));
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.white12,
                child: Icon(Icons.dark_mode_outlined, color: Colors.orange),
              ),
              title: Text(l10n.labelTheme),
              subtitle: Text(l10n.labelDarkMode),
              trailing: Switch(
                value: widget.controller.themeMode == ThemeMode.dark,
                onChanged: (val) {
                  widget.controller.updateThemeMode(
                    val ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
            ),
            const Divider(height: 32),
            
            // --- Developer Section ---
            _SectionHeader(l10n.sectionDeveloper),
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.white12,
                child: Icon(Icons.code_rounded, color: Colors.purpleAccent),
              ),
              title: Text('Ayana Damtew'),
              subtitle: Text('Developer'),
            ),
            const ListTile(
              leading: Icon(Icons.email_outlined, size: 20, color: Colors.white38),
              title: Text('ayanadamtew@gmail.com', style: TextStyle(fontSize: 14)),
              dense: true,
            ),
            const ListTile(
              leading: Icon(Icons.phone_outlined, size: 20, color: Colors.white38),
              title: Text('0973395537', style: TextStyle(fontSize: 14)),
              dense: true,
            ),
            const Divider(height: 32),

            // --- Danger Zone ---
            _SectionHeader(l10n.sectionDangerZone, color: Colors.redAccent),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.redAccent.withOpacity(0.15),
                child: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              ),
              title: Text(l10n.labelLogOut, style: const TextStyle(color: Colors.redAccent)),
              subtitle: Text(l10n.labelLogOutSubtitle),
              onTap: _logout,
            ),
            const SizedBox(height: 60),
            
            // App Version
            Center(
              child: Text(
                '${AppLocalizations.of(context)!.appTitle} v1.0.0',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionHeader(this.title, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color ?? Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
