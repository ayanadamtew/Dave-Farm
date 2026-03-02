import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dave_farm/l10n/app_localizations.dart';

const _storage = FlutterSecureStorage();
const _pinKey = 'dave_farm_pin';

/// PIN lock screen — shows on every foreground resume when a PIN is set.
class PinScreen extends StatefulWidget {
  const PinScreen({super.key, this.onUnlocked, this.isSetup = false});

  /// Called after successful verification.
  final VoidCallback? onUnlocked;

  /// If true, user is creating a PIN for the first time.
  final bool isSetup;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false; // second step during setup
  bool _error = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: 12.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onKey(String d) {
    if (d == '<') {
      setState(() {
        if (widget.isSetup && _confirming) {
          if (_confirmPin.isNotEmpty) {
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          }
        } else {
          if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
        }
        _error = false;
      });
      return;
    }

    if (widget.isSetup && _confirming) {
      if (_confirmPin.length >= 4) return;
      _confirmPin += d;
    } else {
      if (_pin.length >= 4) return;
      _pin += d;
    }
    setState(() {});

    final current = (widget.isSetup && _confirming) ? _confirmPin : _pin;
    if (current.length == 4) _evaluate();
  }

  Future<void> _evaluate() async {
    if (widget.isSetup) {
      if (!_confirming) {
        setState(() => _confirming = true);
        return;
      }
      // Confirm step
      if (_pin == _confirmPin) {
        await _storage.write(key: _pinKey, value: _pin);
        widget.onUnlocked?.call();
      } else {
        setState(() {
          _error = true;
          _confirmPin = '';
        });
        _shakeCtrl.forward(from: 0);
      }
    } else {
      final stored = await _storage.read(key: _pinKey);
      if (_pin == stored) {
        widget.onUnlocked?.call();
      } else {
        setState(() { _error = true; _pin = ''; });
        _shakeCtrl.forward(from: 0);
        HapticFeedback.vibrate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = (widget.isSetup && _confirming) ? _confirmPin : _pin;
    final title = widget.isSetup
        ? (_confirming ? AppLocalizations.of(context)!.labelConfirmPin : AppLocalizations.of(context)!.labelSetPinTitle)
        : AppLocalizations.of(context)!.labelPinTitle;
    final subtitle = widget.isSetup
        ? (_confirming ? AppLocalizations.of(context)!.labelConfirmPinSubtitle : AppLocalizations.of(context)!.labelSetPinSubtitle)
        : AppLocalizations.of(context)!.labelLockedSubtitle;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded,
                  size: 48, color: Color(0xFF2E7D32)),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(subtitle,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 40),

              // PIN dots
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_shakeAnim.value, 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < current.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _error
                            ? Colors.redAccent
                            : filled
                                ? const Color(0xFF2E7D32)
                                : Colors.white24,
                      ),
                    );
                  }),
                ),
              ),
              if (_error)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    widget.isSetup ? AppLocalizations.of(context)!.errPinMismatch : AppLocalizations.of(context)!.errIncorrectPin,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              const SizedBox(height: 48),

              // Keypad
              SizedBox(
                width: 280,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: 12,
                  itemBuilder: (_, i) {
                    final labels = [
                      '1','2','3','4','5','6','7','8','9','','0','<'
                    ];
                    final label = labels[i];
                    if (label.isEmpty) return const SizedBox();
                    return Material(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _onKey(label),
                        child: Center(
                          child: label == '<'
                              ? const Icon(Icons.backspace_outlined,
                                  color: Colors.white70)
                              : Text(label,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mixin to add PIN lock on app resume.
/// Apply to StatefulWidget states: `class _MyState extends State<MyWidget>
/// with WidgetsBindingObserver, PinLockMixin<MyWidget>`
mixin PinLockMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  bool _locked = false;

  void initPinLock() {
    WidgetsBinding.instance.addObserver(this);
  }

  void disposePinLock() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_locked) {
      _checkPin();
    }
  }

  Future<void> _checkPin() async {
    const storage = FlutterSecureStorage();
    final pin = await storage.read(key: _pinKey);
    if (pin != null && pin.isNotEmpty && mounted) {
      setState(() => _locked = true);
      await Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PinScreen(
          onUnlocked: () {
            Navigator.of(context).pop();
            if (mounted) setState(() => _locked = false);
          },
        ),
      ));
    }
  }
}
