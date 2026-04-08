import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/search_field.dart';
import '../widgets/app_button.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await ApiService.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _filtered = users;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _users.where((u) {
        final pseudo = (u['pseudo'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return pseudo.contains(q) || email.contains(q);
      }).toList();
    });
  }

  void _showRegisterDialog() {
    final pseudoCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Ajouter un utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: pseudoCtrl, decoration: const InputDecoration(hintText: 'Pseudo')),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'Email')),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: passCtrl, decoration: const InputDecoration(hintText: 'Mot de passe'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (pseudoCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
              final result = await ApiService.register(pseudoCtrl.text, emailCtrl.text, passCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? 'OK'), backgroundColor: AppColors.primary),
                );
                setState(() => _loading = true);
                _loadUsers();
              }
            },
            child: const Text('Creer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () { setState(() { _loading = true; _error = null; }); _loadUsers(); },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    return ResponsiveLayout(
      builder: (context, screenType) {
        final padding = screenType == ScreenType.desktop ? AppSpacing.xl : AppSpacing.md;
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      width: 300,
                      child: AppSearchField(
                        hint: 'Rechercher un utilisateur...',
                        controller: _searchController,
                        onChanged: _onSearch,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AppButton(label: 'Ajouter', icon: Icons.person_add_outlined, onPressed: _showRegisterDialog),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: 'Utilisateurs (${_filtered.length})',
                titleIcon: Icons.people_outline_rounded,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      color: AppColors.surfaceSecondary,
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Utilisateur', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                          Expanded(flex: 3, child: Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                          Expanded(flex: 1, child: Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                          SizedBox(width: 48),
                        ],
                      ),
                    ),
                    if (_filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text('Aucun utilisateur trouve.', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    else
                      ..._filtered.map((u) => _UserRow(user: u)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserRow({required this.user});

  static const _avatarColors = [AppColors.primary, AppColors.accent, AppColors.coral];

  @override
  Widget build(BuildContext context) {
    final pseudo = user['pseudo']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final notesCount = int.tryParse(user['notes_count']?.toString() ?? '0') ?? 0;
    final id = int.tryParse(user['id']?.toString() ?? '0') ?? 0;
    final color = _avatarColors[id % _avatarColors.length];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(
                        pseudo.isNotEmpty ? pseudo[0].toUpperCase() : '?',
                        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(pseudo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Text('$notesCount', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}
