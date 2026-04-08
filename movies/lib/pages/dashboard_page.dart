import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_card.dart';
import '../widgets/movie_card.dart';
import '../widgets/activity_item.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const DashboardPage({super.key, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> _stats = {};
  // Cache: imdbId -> OMDB movie data
  final Map<String, Map<String, dynamic>> _movieCache = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ApiService.getStats();
      // Pre-fetch OMDB details for popular movies
      final popular = (stats['popular_movies'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final m in popular) {
        final imdbId = m['imdb_id'] as String? ?? '';
        if (imdbId.isNotEmpty && !_movieCache.containsKey(imdbId)) {
          final details = await ApiService.getMovie(imdbId);
          if (details != null) {
            _movieCache[imdbId] = details;
          }
        }
      }
      // Also fetch details for recent activity
      final recent = (stats['recent_activity'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final r in recent) {
        final imdbId = r['imdb_id'] as String? ?? '';
        if (imdbId.isNotEmpty && !_movieCache.containsKey(imdbId)) {
          final details = await ApiService.getMovie(imdbId);
          if (details != null) {
            _movieCache[imdbId] = details;
          }
        }
      }
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
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
            Text('Impossible de charger les donnees', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () { setState(() { _loading = true; _error = null; }); _loadStats(); },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    return ResponsiveLayout(
      builder: (context, screenType) {
        final isDesktop = screenType == ScreenType.desktop;
        final crossAxisCount = isDesktop ? 4 : (screenType == ScreenType.tablet ? 2 : 1);
        final padding = isDesktop ? AppSpacing.xl : AppSpacing.md;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKpiGrid(crossAxisCount),
                const SizedBox(height: AppSpacing.lg),
                if (isDesktop)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildMoviesSection()),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(flex: 2, child: _buildActivitySection()),
                      ],
                    ),
                  )
                else ...[
                  _buildMoviesSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildActivitySection(),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (isDesktop)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRatingsDistribution()),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(child: _buildPopularGenres()),
                      ],
                    ),
                  )
                else ...[
                  _buildRatingsDistribution(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPopularGenres(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(int crossAxisCount) {
    final totalUsers = _stats['total_users']?.toString() ?? '0';
    final totalMovies = _stats['total_movies']?.toString() ?? '0';
    final totalNotes = _stats['total_notes']?.toString() ?? '0';
    final avgGlobal = _stats['avg_global']?.toString() ?? '0';

    final kpis = [
      (Icons.people_outline_rounded, 'Utilisateurs', totalUsers),
      (Icons.movie_outlined, 'Films notes', totalMovies),
      (Icons.rate_review_outlined, 'Notes', totalNotes),
      (Icons.star_outline_rounded, 'Note moyenne', avgGlobal),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.6,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final (icon, label, value) = kpis[index];
        return KpiCard(
          icon: icon,
          label: label,
          value: value,
          iconBgColor: AppColors.surfaceSecondary,
        );
      },
    );
  }

  Widget _buildMoviesSection() {
    final popular = ((_stats['popular_movies'] as List?) ?? []).cast<Map<String, dynamic>>();

    return SectionCard(
      title: 'Films les plus notes',
      titleIcon: Icons.local_fire_department_outlined,
      actionLabel: 'Voir tout',
      onAction: () => widget.onNavigate?.call(2),
      child: popular.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('Aucun film note pour le moment.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            )
          : Column(
              children: [
                for (int i = 0; i < popular.length; i++) ...[
                  _buildPopularMovieRow(popular[i]),
                  if (i < popular.length - 1) const Divider(),
                ],
              ],
            ),
    );
  }

  Widget _buildPopularMovieRow(Map<String, dynamic> movie) {
    final imdbId = movie['imdb_id'] as String? ?? '';
    final details = _movieCache[imdbId];
    final title = details?['Title'] ?? imdbId;
    final year = details?['Year'] ?? '';
    final genre = details?['Genre'] ?? '';
    final poster = details?['Poster'];
    final posterUrl = (poster != null && poster != 'N/A') ? poster as String : null;
    final avgRating = double.tryParse(movie['avg_rating']?.toString() ?? '0') ?? 0;
    final reviewCount = int.tryParse(movie['review_count']?.toString() ?? '0') ?? 0;

    return MovieTableRow(
      title: title,
      year: year,
      genre: genre,
      rating: avgRating,
      reviewCount: reviewCount,
      posterUrl: posterUrl,
    );
  }

  Widget _buildActivitySection() {
    final recent = ((_stats['recent_activity'] as List?) ?? []).cast<Map<String, dynamic>>();

    return SectionCard(
      title: 'Activite recente',
      titleIcon: Icons.history_rounded,
      actionLabel: 'Voir tout',
      onAction: () => widget.onNavigate?.call(3),
      child: recent.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('Aucune activite recente.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            )
          : Column(
              children: recent.map((r) {
                final pseudo = r['pseudo'] ?? 'Inconnu';
                final imdbId = r['imdb_id'] ?? '';
                final movieTitle = _movieCache[imdbId]?['Title'] ?? imdbId;
                final scenario = double.tryParse(r['scenario']?.toString() ?? '0') ?? 0;
                final jeu = double.tryParse(r['jeu_acteur']?.toString() ?? '0') ?? 0;
                final av = double.tryParse(r['qualite_av']?.toString() ?? '0') ?? 0;
                final avg = ((scenario + jeu + av) / 3).toStringAsFixed(1);

                return ActivityItem(
                  icon: Icons.rate_review_outlined,
                  iconColor: AppColors.primary,
                  title: 'Note de $pseudo',
                  subtitle: '$movieTitle - $avg/5',
                  time: '',
                );
              }).toList(),
            ),
    );
  }

  Widget _buildRatingsDistribution() {
    final dist = _stats['distribution'] as Map<String, dynamic>? ?? {};
    final totalNotes = int.tryParse(_stats['total_notes']?.toString() ?? '0') ?? 0;

    final bars = [
      ('5 etoiles', int.tryParse(dist['5']?.toString() ?? '0') ?? 0, AppColors.success),
      ('4 etoiles', int.tryParse(dist['4']?.toString() ?? '0') ?? 0, AppColors.primary),
      ('3 etoiles', int.tryParse(dist['3']?.toString() ?? '0') ?? 0, AppColors.accent),
      ('2 etoiles', int.tryParse(dist['2']?.toString() ?? '0') ?? 0, AppColors.warning),
      ('1 etoile', int.tryParse(dist['1']?.toString() ?? '0') ?? 0, AppColors.error),
    ];

    return SectionCard(
      title: 'Repartition des evaluations',
      titleIcon: Icons.bar_chart_rounded,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: totalNotes == 0
            ? const Text('Aucune note enregistree.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
            : Column(
                children: bars.map((b) {
                  final (label, count, color) = b;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _RatingBar(label: label, count: count, total: totalNotes, color: color),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildPopularGenres() {
    // Extract genres from cached movie data
    final genreCount = <String, int>{};
    for (final details in _movieCache.values) {
      final genreStr = details['Genre'] as String? ?? '';
      for (final g in genreStr.split(',')) {
        final trimmed = g.trim();
        if (trimmed.isNotEmpty) {
          genreCount[trimmed] = (genreCount[trimmed] ?? 0) + 1;
        }
      }
    }
    final sorted = genreCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final genreIcons = <String, IconData>{
      'Action': Icons.flash_on_outlined,
      'Sci-Fi': Icons.rocket_launch_outlined,
      'Drama': Icons.theater_comedy_outlined,
      'Thriller': Icons.psychology_outlined,
      'Comedy': Icons.sentiment_very_satisfied_outlined,
      'Adventure': Icons.explore_outlined,
      'Crime': Icons.gavel_outlined,
      'Romance': Icons.favorite_outline,
      'Horror': Icons.visibility_outlined,
      'Animation': Icons.animation_outlined,
      'Mystery': Icons.search_outlined,
      'Fantasy': Icons.auto_awesome_outlined,
    };

    return SectionCard(
      title: 'Genres populaires',
      titleIcon: Icons.category_outlined,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: sorted.isEmpty
            ? const Text('Aucun genre disponible.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
            : Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: sorted.take(8).map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(genreIcons[e.key] ?? Icons.label_outline, size: 16, color: AppColors.accent),
                        const SizedBox(width: AppSpacing.sm),
                        Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(width: AppSpacing.sm),
                        Text('${e.value}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _RatingBar({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(width: 50, child: Text('$count', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      ],
    );
  }
}
