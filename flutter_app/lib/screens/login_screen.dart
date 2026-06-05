import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isLogin) async {
    final auth = context.read<AuthProvider>();
    bool ok;
    if (isLogin) {
      ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    } else {
      ok = await auth.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text);
    }
    if (ok && mounted) {
      await context.read<DashboardProvider>().load();
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF130720),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.chat_bubble_outline, color: Color(0xFFa78bfa), size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Nativa', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white)),
              const Text('AI Language Tutor', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              TabBar(
                controller: _tabs,
                tabs: const [Tab(text: 'Login'), Tab(text: 'Register')],
                indicatorColor: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 260,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _LoginForm(emailCtrl: _emailCtrl, passCtrl: _passCtrl,
                        loading: auth.isLoading, error: auth.error, onSubmit: () => _submit(true)),
                    _RegisterForm(nameCtrl: _nameCtrl, emailCtrl: _emailCtrl, passCtrl: _passCtrl,
                        loading: auth.isLoading, error: auth.error, onSubmit: () => _submit(false)),
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

class _LoginForm extends StatelessWidget {
  final TextEditingController emailCtrl, passCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;
  const _LoginForm({required this.emailCtrl, required this.passCtrl, required this.loading, required this.error, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 12),
      TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
      const SizedBox(height: 16),
      if (error != null) Text(error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: loading ? null : onSubmit,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.symmetric(vertical: 14)),
        child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Login'),
      )),
    ]);
  }
}

class _RegisterForm extends StatelessWidget {
  final TextEditingController nameCtrl, emailCtrl, passCtrl;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;
  const _RegisterForm({required this.nameCtrl, required this.emailCtrl, required this.passCtrl, required this.loading, required this.error, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
      const SizedBox(height: 8),
      TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 8),
      TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
      const SizedBox(height: 12),
      if (error != null) Text(error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
      const SizedBox(height: 4),
      SizedBox(width: double.infinity, child: ElevatedButton(
        onPressed: loading ? null : onSubmit,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.symmetric(vertical: 14)),
        child: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create account'),
      )),
    ]);
  }
}
