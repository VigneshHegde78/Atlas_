import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _hasError = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin += digit;
        _hasError = false;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _hasError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final success = await SecurityService.instance.authenticateWithPin(
      _enteredPin,
    );
    if (success) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
      });
      _shakeController.forward(from: 0.0);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _enteredPin = '';
          });
        }
      });
    }
  }

  void _simulateBiometric() async {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Biometric authentication verified.'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 1),
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        SecurityService.instance.unlockApp();
        widget.onUnlocked();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).top -
                  MediaQuery.paddingOf(context).bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 24.0,
                ),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Logo & App Name
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icons/app_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ATLAS SECURE VAULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hasError
                          ? 'Incorrect PIN. Try again (Default: 0000)'
                          : 'Enter 4-digit PIN to access memories',
                      style: TextStyle(
                        color: _hasError
                            ? AtlasColors.rose
                            : const Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // PIN Indicator Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isFilled = index < _enteredPin.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled
                                ? (_hasError
                                      ? AtlasColors.rose
                                      : const Color(0xFF2563EB))
                                : Colors.transparent,
                            border: Border.all(
                              color: _hasError
                                  ? AtlasColors.rose
                                  : (isFilled
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF475569)),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                    const Spacer(flex: 3),

                    // Numeric Keypad
                    Column(
                      children: [
                        _buildKeypadRow(['1', '2', '3']),
                        const SizedBox(height: 20),
                        _buildKeypadRow(['4', '5', '6']),
                        const SizedBox(height: 20),
                        _buildKeypadRow(['7', '8', '9']),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              icon: Icons.fingerprint_rounded,
                              onTap: _simulateBiometric,
                            ),
                            _buildKeypadButton('0'),
                            _buildActionButton(
                              icon: Icons.backspace_rounded,
                              onTap: _onDelete,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKeypadButton(d)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return InkWell(
      onTap: () => _onKeyPress(digit),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: const Color(0xFF94A3B8), size: 28),
        ),
      ),
    );
  }
}
