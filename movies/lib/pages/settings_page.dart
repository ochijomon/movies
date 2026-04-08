import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/app_button.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? _apiConnected;
  bool _testing = false;

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    try {
      final stats = await ApiService.getStats();
      if (mounted) setState(() { _apiConnected = stats.isNotEmpty; _testing = false; });
    } catch (_) {
      if (mounted) setState(() { _apiConnected = false; _testing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, screenType) {
        final padding = screenType == ScreenType.desktop ? AppSpacing.xl : AppSpacing.md;
        final isDesktop = screenType == ScreenType.desktop;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildGeneralSettings(context)),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: _buildApiSettings(context)),
                ])
              else ...[
                _buildGeneralSettings(context),
                const SizedBox(height: AppSpacing.lg),
                _buildApiSettings(context),
              ],
              const SizedBox(height: AppSpacing.lg),
              _buildDangerZone(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeneralSettings(BuildContext context) {
    return SectionCard(
      title: 'General',
      titleIcon: Icons.tune_rounded,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(children: [
          const _SettingsField(label: 'Nom de l\'application', value: 'MOVIES'),
          const SizedBox(height: AppSpacing.md),
          const _SettingsField(label: 'Langue', value: 'Francais'),
          const SizedBox(height: AppSpacing.md),
          const _SettingsField(label: 'Fuseau horaire', value: 'Europe/Paris (UTC+1)'),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(label: 'Sauvegarder', icon: Icons.save_outlined, onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Parametres sauvegardes'), backgroundColor: AppColors.primary, duration: Duration(seconds: 1)),
                );
            }),
          ),
        ]),
      ),
    );
  }

  Widget _buildApiSettings(BuildContext context) {
    return SectionCard(
      title: 'Configuration API',
      titleIcon: Icons.api_rounded,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(children: [
          const _SettingsField(label: 'URL Backend', value: 'http://localhost/movies_api/api'),
          const SizedBox(height: AppSpacing.md),
          const _SettingsField(label: 'Cle API OMDB', value: '(variable systeme IMDB_API_KEY)'),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Statut de connexion', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                if (_testing)
                  const Row(children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    SizedBox(width: 8),
                    Text('Test en cours...', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ])
                else if (_apiConnected == true)
                  const Row(children: [
                    Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                    SizedBox(width: 6),
                    Text('Connecte', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ])
                else if (_apiConnected == false)
                  const Row(children: [
                    Icon(Icons.error_outline, size: 16, color: AppColors.error),
                    SizedBox(width: 6),
                    Text('Echec de connexion', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
                  ])
                else
                  const Text('Non teste', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ]),
            ),
            AppButton(label: 'Tester', icon: Icons.refresh_rounded, isOutlined: true, isSmall: true, onPressed: _testConnection),
          ]),
        ]),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        boxShadow: AppShadows.soft,
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Zone dangereuse', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.error)),
            SizedBox(height: 2),
            Text('Reinitialiser la base de donnees ou supprimer toutes les notes.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(width: AppSpacing.md),
        OutlinedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Confirmer la reinitialisation'),
                content: const Text('Cette action est irreversible. Toutes les notes seront supprimees.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalite non implementee cote serveur'), backgroundColor: AppColors.warning),
                      );
                    },
                    child: const Text('Confirmer'),
                  ),
                ],
              ),
            );
          },
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
          child: const Text('Reinitialiser'),
        ),
      ]),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final String value;
  const _SettingsField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: AppSpacing.xs),
      TextFormField(initialValue: value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
    ]);
  }
}
