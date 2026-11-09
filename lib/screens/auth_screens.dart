import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            const Expanded(
              flex: 61,
              child: ColoredBox(
                color: Colors.white,
                child: Center(child: _WelcomeLogo()),
              ),
            ),
            Expanded(
              flex: 39,
              child: Container(
                key: const ValueKey('welcome-panel'),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome',
                                style: AppText.heading(24, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mulai perjalanan hidup sehatmu bersama kami. '
                                'Pantau perkembangan, nikmati fasilitas gym, '
                                'dan capai target kebugaranmu dengan lebih mudah.',
                                style: AppText.body(
                                  12,
                                  color: Colors.white,
                                ).copyWith(height: 1.4),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Center(
                              child: FractionallySizedBox(
                                widthFactor: 0.84,
                                child: Column(
                                  children: [
                                    _WelcomeButton(
                                      label: 'Login',
                                      color: Colors.black,
                                      textColor: Colors.white,
                                      onPressed: () => context.go('/login'),
                                    ),
                                    const SizedBox(height: 8),
                                    _WelcomeButton(
                                      label: 'Registrasi',
                                      color: Colors.white,
                                      textColor: Colors.black,
                                      onPressed: () => context.go('/register'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeLogo extends StatelessWidget {
  const _WelcomeLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFE9ECEF)],
            ),
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 18,
                bottom: 34,
                child: Icon(
                  Icons.fitness_center,
                  size: 88,
                  color: Color(0xFF15232A),
                ),
              ),
              Positioned(
                right: 20,
                top: 24,
                child: Icon(Icons.bolt, size: 54, color: Color(0xFFC8421F)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('GYMKU', style: AppText.logo(24)),
      ],
    );
  }
}

class _WelcomeButton extends StatelessWidget {
  const _WelcomeButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text(label, style: AppText.heading(16, color: textColor)),
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.teal,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 70,
                color: Color(0xFFC8421F),
              ),
            ),
            const SizedBox(height: 12),
            Text('GYMKU', style: AppText.logo(32)),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(40, 22, 40, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Color(0x40000000), blurRadius: 20),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: AppText.heading(27)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: AppText.label(18)),
                      const SizedBox(height: 22),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _pw = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _pw.dispose();
    super.dispose();
  }

  void _submit() {
    final err = context.read<AppState>().login(_name.text, _pw.text);
    if (err != null) toast(context, err);
  }

  void _showForgotPasswordHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: const Text(
          'Fitur reset password belum tersedia karena aplikasi belum '
          'terhubung ke backend. Silakan hubungi admin gym untuk bantuan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Masuk untuk melanjutkan',
      children: [
        PillField(controller: _name, hint: 'Nama'),
        const SizedBox(height: 18),
        PillField(controller: _pw, hint: 'Password', obscure: true),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _showForgotPasswordHelp,
          style: TextButton.styleFrom(
            foregroundColor: Colors.black45,
            minimumSize: const Size(double.infinity, 44),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            'Lupa Password?',
            style: AppText.body(15, color: Colors.black45),
          ),
        ),
        const SizedBox(height: 36),
        PrimaryButton('Masuk', onPressed: _submit),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Belum punya akun? ',
              style: AppText.body(15, color: Colors.black45),
            ),
            GestureDetector(
              onTap: () => context.go('/register'),
              child: Text(
                'Daftar sekarang',
                style: AppText.body(15, color: AppColors.teal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Demo: Naufal Badu / Gymku123 (member) • Tamu Baru / Gymku123 (belum member) • admin / admin123',
          textAlign: TextAlign.center,
          style: AppText.body(10.5, color: Colors.black38),
        ),
      ],
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final err = context.read<AppState>().register(
      _name.text,
      _email.text,
      _pw.text,
      _confirm.text,
    );
    if (err != null) toast(context, err);
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: 'Selamat datang',
      subtitle: 'Daftar untuk melanjutkan',
      children: [
        PillField(controller: _name, hint: 'Nama'),
        const SizedBox(height: 14),
        PillField(
          controller: _email,
          hint: 'Email',
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        PillField(controller: _pw, hint: 'Password', obscure: true),
        const SizedBox(height: 14),
        PillField(
          controller: _confirm,
          hint: 'Konfirmasi password',
          obscure: true,
        ),
        const SizedBox(height: 26),
        PrimaryButton('Daftar', onPressed: _submit),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sudah punya akun? ',
              style: AppText.body(15, color: Colors.black45),
            ),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Text(
                'Login sekarang',
                style: AppText.body(15, color: AppColors.teal),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
