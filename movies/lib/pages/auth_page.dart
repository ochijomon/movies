import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../services/api_service.dart';

/// Authentication page with login and register tabs.
class AuthPage extends StatefulWidget {
  /// Called on successful login with {id, pseudo}.
  final void Function(int userId, String pseudo) onLoginSuccess;
  final VoidCallback onBack;
  final bool startOnRegister;

  const AuthPage({
    super.key,
    required this.onLoginSuccess,
    required this.onBack,
    this.startOnRegister = false,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _loginPseudo = TextEditingController();
  final _loginPass = TextEditingController();
  final _regPseudo = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: widget.startOnRegister ? 1 : 0);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginPseudo.dispose();
    _loginPass.dispose();
    _regPseudo.dispose();
    _regEmail.dispose();
    _regPass.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (_loginPseudo.text.isEmpty || _loginPass.text.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.login(_loginPseudo.text, _loginPass.text);
      if (result.containsKey('id')) {
        widget.onLoginSuccess(result['id'] as int, result['pseudo'] as String);
      } else {
        setState(() { _error = result['message'] ?? 'Erreur de connexion'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Impossible de contacter le serveur'; _loading = false; });
    }
  }

  Future<void> _doRegister() async {
    if (_regPseudo.text.isEmpty || _regEmail.text.isEmpty || _regPass.text.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.register(_regPseudo.text, _regEmail.text, _regPass.text);
      if (result['message']?.toString().contains('succes') == true || result['message']?.toString().contains('succès') == true) {
        // Auto-login after register
        final loginResult = await ApiService.login(_regPseudo.text, _regPass.text);
        if (loginResult.containsKey('id')) {
          widget.onLoginSuccess(loginResult['id'] as int, loginResult['pseudo'] as String);
          return;
        }
      }
      setState(() { _error = result['message'] ?? 'Erreur'; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Impossible de contacter le serveur'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: isWide ? 440 : double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.medium,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back button + logo
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                      onPressed: widget.onBack,
                      tooltip: 'Retour',
                    ),
                    const Spacer(),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.movie_filter_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('MOVIES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 1.5)),
                    const Spacer(),
                    const SizedBox(width: 48), // balance the back button
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    dividerHeight: 0,
                    tabs: const [
                      Tab(text: 'Connexion'),
                      Tab(text: 'Inscription'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Error
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  ),
                // Tab content
                SizedBox(
                  height: _tabCtrl.index == 1 ? 300 : 240,
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildLoginForm(),
                      _buildRegisterForm(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _loginPseudo,
          decoration: const InputDecoration(hintText: 'Pseudo', prefixIcon: Icon(Icons.person_outline, size: 20)),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _loginPass,
          decoration: const InputDecoration(hintText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline, size: 20)),
          obscureText: true,
          onSubmitted: (_) => _doLogin(),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _doLogin,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Se connecter'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        TextField(
          controller: _regPseudo,
          decoration: const InputDecoration(hintText: 'Pseudo', prefixIcon: Icon(Icons.person_outline, size: 20)),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _regEmail,
          decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 20)),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _regPass,
          decoration: const InputDecoration(hintText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline, size: 20)),
          obscureText: true,
          onSubmitted: (_) => _doRegister(),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _doRegister,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Creer mon compte'),
          ),
        ),
      ],
    );
  }
}
