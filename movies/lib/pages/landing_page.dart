import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Public landing page shown before authentication.
class LandingPage extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const LandingPage({super.key, required this.onLogin, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 80 : 24,
                vertical: isWide ? 80 : 48,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEEF8F1), Color(0xFFF6FCF8), Color(0xFFF8F5EF)],
                ),
              ),
              child: isWide
                  ? Row(
                      children: [
                        Expanded(child: _buildHeroText(context)),
                        const SizedBox(width: 60),
                        Expanded(child: _buildHeroVisual()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildHeroText(context),
                        const SizedBox(height: 40),
                        _buildHeroVisual(),
                      ],
                    ),
            ),
            // Features section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 80 : 24,
                vertical: 60,
              ),
              child: Column(
                children: [
                  const Text(
                    'Pourquoi MOVIES ?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Une plateforme simple pour decouvrir, noter et partager vos avis sur les films.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: const [
                      _FeatureCard(
                        icon: Icons.search_rounded,
                        title: 'Recherche de films',
                        desc: 'Explorez des milliers de films via la base OMDB.',
                      ),
                      _FeatureCard(
                        icon: Icons.rate_review_outlined,
                        title: 'Notez vos films',
                        desc: 'Scenario, jeu d\'acteur, audio-visuel : notez chaque aspect.',
                      ),
                      _FeatureCard(
                        icon: Icons.people_outline_rounded,
                        title: 'Avis de la communaute',
                        desc: 'Consultez les notes et commentaires des autres utilisateurs.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // CTA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              color: AppColors.surfaceSecondary,
              child: Column(
                children: [
                  const Text(
                    'Pret a commencer ?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Creez un compte gratuitement et commencez a noter vos films preferes.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: onRegister,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Creer un compte'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: onLogin,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Se connecter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.movie_filter_outlined, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('MOVIES', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 1.5)),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Decouvrez, notez\net partagez vos\nfilms preferes.',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2),
        ),
        const SizedBox(height: 16),
        const Text(
          'Recherchez n\'importe quel film, laissez votre avis detaille et decouvrez ce que la communaute en pense.',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Se connecter'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('S\'inscrire'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroVisual() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.medium,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_movies_outlined, size: 80, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('Votre cinema personnel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Icon(icon, color: AppColors.accent, size: 22),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
