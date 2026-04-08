import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/search_field.dart';
import '../widgets/rating_badge.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

class RatingsPage extends StatefulWidget {
  const RatingsPage({super.key});

  @override
  State<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage> {
  List<Map<String, dynamic>> _ratings = [];
  List<Map<String, dynamic>> _filtered = [];
  final Map<String, String> _movieTitles = {};
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRatings() async {
    try {
      final ratings = await ApiService.getRatings();
      // Fetch movie titles for each unique imdb_id
      final imdbIds = ratings.map((r) => r['imdb_id']?.toString() ?? '').toSet();
      for (final id in imdbIds) {
        if (id.isNotEmpty && !_movieTitles.containsKey(id)) {
          final details = await ApiService.getMovie(id);
          if (details != null) {
            _movieTitles[id] = details['Title'] ?? id;
          }
        }
      }
      if (mounted) {
        setState(() {
          _ratings = ratings;
          _filtered = ratings;
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
      _filtered = _ratings.where((r) {
        final pseudo = (r['pseudo'] ?? '').toString().toLowerCase();
        final imdbId = r['imdb_id'] ?? '';
        final movieTitle = (_movieTitles[imdbId] ?? imdbId).toLowerCase();
        final comment = (r['commentaire'] ?? '').toString().toLowerCase();
        return pseudo.contains(q) || movieTitle.contains(q) || comment.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () { setState(() { _loading = true; _error = null; }); _loadRatings(); },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reessayer'),
          ),
        ]),
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
              SizedBox(
                width: 400,
                child: AppSearchField(
                  hint: 'Rechercher une note...',
                  controller: _searchController,
                  onChanged: _onSearch,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: 'Notes et avis (${_filtered.length})',
                titleIcon: Icons.rate_review_outlined,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      color: AppColors.surfaceSecondary,
                      child: const Row(children: [
                        Expanded(flex: 2, child: Text('Utilisateur', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text('Film', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                        Expanded(flex: 1, child: Text('Scenario', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                        Expanded(flex: 1, child: Text('Acteurs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                        Expanded(flex: 1, child: Text('Audio-Visuel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                        Expanded(flex: 1, child: Text('Globale', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                        Expanded(flex: 3, child: Text('Commentaire', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                      ]),
                    ),
                    if (_filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Text('Aucune note trouvee.', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    else
                      ..._filtered.map((r) => _RatingRow(data: r, movieTitles: _movieTitles)),
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

class _RatingRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final Map<String, String> movieTitles;
  const _RatingRow({required this.data, required this.movieTitles});

  @override
  Widget build(BuildContext context) {
    final pseudo = data['pseudo']?.toString() ?? '';
    final imdbId = data['imdb_id']?.toString() ?? '';
    final movieTitle = movieTitles[imdbId] ?? imdbId;
    final scenario = double.tryParse(data['scenario']?.toString() ?? '0') ?? 0;
    final acting = double.tryParse(data['jeu_acteur']?.toString() ?? '0') ?? 0;
    final audioVisual = double.tryParse(data['qualite_av']?.toString() ?? '0') ?? 0;
    final global = (scenario + acting + audioVisual) / 3;
    final comment = data['commentaire']?.toString() ?? '';

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(children: [
          Expanded(
            flex: 2,
            child: Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(pseudo.isNotEmpty ? pseudo[0].toUpperCase() : '?', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(pseudo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
            ]),
          ),
          Expanded(flex: 2, child: Text(movieTitle, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 1, child: RatingBadge(rating: scenario)),
          Expanded(flex: 1, child: RatingBadge(rating: acting)),
          Expanded(flex: 1, child: RatingBadge(rating: audioVisual)),
          Expanded(flex: 1, child: RatingBadge(rating: global, fontSize: 13)),
          Expanded(flex: 3, child: Text(comment, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
      const Divider(),
    ]);
  }
}
