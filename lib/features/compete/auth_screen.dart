import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/goalverse_logo.dart';
import '../../providers/compete_provider.dart';

/// Inline auth panel: register (with email OTP) or log in.
class AuthPanel extends StatefulWidget {
  const AuthPanel({super.key});

  @override
  State<AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends State<AuthPanel> {
  bool _register = true;
  String? _error;

  final _name = TextEditingController();
  final _eid = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _confirm = TextEditingController();

  final _loginEmail = TextEditingController();
  final _loginPw = TextEditingController();

  final _otp = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _name,
      _eid,
      _email,
      _pw,
      _confirm,
      _loginEmail,
      _loginPw,
      _otp
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _busy = false;

  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
  }

  void _submitRegister() => _run(() => context.read<CompeteProvider>().register(
      _name.text, _eid.text, _email.text, _pw.text, _confirm.text));

  void _submitLogin() => _run(() =>
      context.read<CompeteProvider>().login(_loginEmail.text, _loginPw.text));

  void _submitOtp() =>
      _run(() => context.read<CompeteProvider>().verifyOtp(_otp.text));

  @override
  Widget build(BuildContext context) {
    final compete = context.watch<CompeteProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        const SizedBox(height: 12),
        const Center(child: GoalVerseMark(size: 72)),
        const SizedBox(height: 16),
        Center(
            child: Text('Join the Competition',
                style: context.texts.displaySmall?.copyWith(fontSize: 24))),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Predict matches, climb the leaderboard, earn badges and rule the GoalVerse.',
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium
                ?.copyWith(color: context.semantic.textDim),
          ),
        ),
        const SizedBox(height: 24),
        if (compete.awaitingOtp)
          _otpCard(context, compete)
        else
          _formCard(context),
      ],
    );
  }

  Widget _formCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              _toggle(context, 'Register', _register,
                  () => setState(() {
                        _register = true;
                        _error = null;
                      })),
              const SizedBox(width: 8),
              _toggle(context, 'Login', !_register,
                  () => setState(() {
                        _register = false;
                        _error = null;
                      })),
            ],
          ),
          const SizedBox(height: 16),
          if (_register) ...[
            _field(context, _name, 'Full name', Icons.badge),
            const SizedBox(height: 12),
            _field(context, _eid, 'Employee ID', Icons.tag),
            const SizedBox(height: 12),
            _field(context, _email, 'Email', Icons.email,
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(context, _pw, 'Password', Icons.lock, obscure: true),
            const SizedBox(height: 12),
            _field(context, _confirm, 'Confirm password', Icons.lock_outline,
                obscure: true),
          ] else ...[
            _field(context, _loginEmail, 'Email', Icons.email,
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(context, _loginPw, 'Password', Icons.lock, obscure: true),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            _errorText(context, _error!),
          ],
          const SizedBox(height: 16),
          _primaryButton(context, _register ? 'Register' : 'Log in',
              _register ? _submitRegister : _submitLogin),
        ],
      ),
    );
  }

  Widget _otpCard(BuildContext context, CompeteProvider compete) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mark_email_read, color: context.scheme.primary),
              const SizedBox(width: 8),
              Text('Verify your email', style: context.texts.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit code to ${compete.pendingEmail}. Enter it below to finish creating your account.',
            style: context.texts.bodyMedium
                ?.copyWith(color: context.semantic.textDim),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              filled: true,
              fillColor: context.semantic.bg2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.semantic.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.semantic.border),
              ),
            ),
          ),
          Center(
            child: Text('Demo code: ${CompeteProvider.demoOtp}',
                style: TextStyle(
                    color: context.scheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            _errorText(context, _error!),
          ],
          const SizedBox(height: 16),
          _primaryButton(context, 'Verify & Continue', _submitOtp),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () {
                context.read<CompeteProvider>().cancelOtp();
                setState(() => _error = null);
              },
              child: const Text('Back'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(BuildContext context, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: context.scheme.primary,
          foregroundColor: context.scheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }

  Widget _errorText(BuildContext context, String text) => Text(text,
      style: TextStyle(
          color: context.scheme.error,
          fontWeight: FontWeight.w600,
          fontSize: 12.5));

  Widget _toggle(
      BuildContext context, String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? context.scheme.primary : context.semantic.bg2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? context.scheme.onPrimary
                      : context.semantic.textDim)),
        ),
      ),
    );
  }

  Widget _field(BuildContext context, TextEditingController c, String hint,
      IconData icon,
      {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: context.semantic.bg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.semantic.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.semantic.border),
        ),
      ),
    );
  }
}
