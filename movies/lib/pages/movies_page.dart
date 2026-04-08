import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../widgets/movie_card.dart';
import '../widgets/rating_badge.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage({super.key});

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  bool _isGridView = true;
  List<Map<String, dynamic>> _movies = [];
  bool _loading = false;
  bool _hasSearched = false;
  String? _errorMsg;
  final _searchController = TextEditingController();
  final Map<String, Map<String, dynamic>> _detailsCache = {};
  Timer? _debounce;

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _doSearch(query.trim());
    });
  }

  void _onSearchSubmitted(String query) {
    _debounce?.cancel();
    if (query.trim().isNotEmpty) _doSearch(query.trim());
  }

  Future<void> _doSearch(String query) async {
    setState(() { _loading = true; _hasSearched = true; _errorMsg = null; });
    try {
      final results = await ApiService.searchMovies(query);
      if (results.isEmpty) {
        if (mounted) setState(() { _movies = []; _loading = false; });
        return;
      }
      // Fetch details for each result (local ratings)
      for (final m in results) {
        final imdbId = m['imdbID'] as String? ?? '';
        if (imdbId.isNotEmpty && !_detailsCache.containsKey(imdbId)) {
          try {
            final details = await ApiService.getMovie(imdbId);
            if (details != null) _detailsCache[imdbId] = details;
          } catch (_) {}
        }
      }
      if (mounted) setState(() { _movies = results; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _movies = []; _loading = false; _errorMsg = e.toString(); });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showMovieDetail(String imdbId) {
    final details = _detailsCache[imdbId];
    if (details == null) return;
    final lr = details['local_ratings'] as Map<String, dynamic>? ?? {};
    final title = details['Title'] ?? '';
    final year = details['Year'] ?? '';
    final genre = details['Genre'] ?? '';
    final plot = details['Plot'] ?? '';
    final director = details['Director'] ?? '';
    final actors = details['Actors'] ?? '';
    final poster = details['Poster'];
    final imdbRating = details['imdbRating'] ?? 'N/A';
    final avgS = lr['avg_scenario']?.toString() ?? '0';
    final avgA = lr['avg_acting']?.toString() ?? '0';
    final avgV = lr['avg_visual']?.toString() ?? '0';
    final total = lr['total_reviews']?.toString() ?? '0';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (poster != null && poster != 'N/A')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.network(poster, width: 120, height: 180, fit: BoxFit.cover),
                    ),
                  if (poster != null && poster != 'N/A') const SizedBox(width: AppSpacing.lg),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('$year  |  $genre', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Realisateur : $director', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text('Acteurs : $actors', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.md),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text('IMDB: $imdbRating', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ]),
                  ])),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ]),
                const SizedBox(height: AppSpacing.md),
                Text(plot, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                Text('Notes locales ($total avis)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  _LocalRatingChip(label: 'Scenario', value: avgS),
                  const SizedBox(width: AppSpacing.sm),
                  _LocalRatingChip(label: 'Acteurs', value: avgA),
                  const SizedBox(width: AppSpacing.sm),
                  _LocalRatingChip(label: 'Audio-Visuel', value: avgV),
                ]),
                const SizedBox(height: AppSpacing.lg),
                // Bouton noter
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showRateDialog(imdbId, title);
                    },
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: const Text('Noter ce film'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRateDialog(String imdbId, String movieTitle) {
    final userIdCtrl = TextEditingController();
    double scenario = 3, acteur = 3, av = 3;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          title: Text('Noter : $movieTitle', style: const TextStyle(fontSize: 16)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: userIdCtrl, decoration: const InputDecoration(hintText: 'Votre ID utilisateur'), keyboardType: TextInputType.number),
            const SizedBox(height: AppSpacing.md),
            _SliderRow(label: 'Scenario', value: scenario, onChanged: (v) => setDialogState(() => scenario = v)),
            _SliderRow(label: 'Jeu d\'acteur', value: acteur, onChanged: (v) => setDialogState(() => acteur = v)),
            _SliderRow(label: 'Audio-Visuel', value: av, onChanged: (v) => setDialogState(() => av = v)),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: commentCtrl, decoration: const InputDecoration(hintText: 'Commentaire (optionnel)'), maxLines: 2),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final userId = int.tryParse(userIdCtrl.text);
                if (userId == null) return;
                final result = await ApiService.rateMovie(
                  imdbId: imdbId, userId: userId,
                  scenario: scenario.round(), jeuActeur: acteur.round(), qualiteAv: av.round(),
                  commentaire: commentCtrl.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'OK'), backgroundColor: AppColors.primary),
                  );
                }
              },
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, screenType) {
        final padding = screenType == ScreenType.desktop ? AppSpacing.xl : AppSpacing.md;
        final gridCols = screenType == ScreenType.desktop ? 5 : (screenType == ScreenType.tablet ? 3 : 2);

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar with button
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un film...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () { _searchController.clear(); setState(() { _movies = []; _hasSearched = false; }); },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: () => _onSearchSubmitted(_searchController.text),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Rechercher'),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _ViewToggle(icon: Icons.grid_view_rounded, isActive: _isGridView, onTap: () => setState(() => _isGridView = true)),
                    _ViewToggle(icon: Icons.view_list_rounded, isActive: !_isGridView, onTap: () => setState(() => _isGridView = false)),
                  ]),
                ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              // Error
              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text('Erreur: $_errorMsg', style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              // Content
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: CircularProgressIndicator(color: AppColors.primary)))
              else if (!_hasSearched)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: AppSpacing.md),
                      const Text('Recherchez un film par titre', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.xs),
                      const Text('Les resultats proviennent de la base OMDB', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                  ),
                )
              else if (_movies.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Text('Aucun film trouve.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ),
                )
              else if (_isGridView)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCols, crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md, childAspectRatio: 0.55,
                  ),
                  itemCount: _movies.length,
                  itemBuilder: (context, index) {
                    final m = _movies[index];
                    final imdbId = m['imdbID'] ?? '';
                    final details = _detailsCache[imdbId];
                    final lr = details?['local_ratings'] as Map<String, dynamic>? ?? {};
                    final avgR = _calcAvg(lr);
                    final reviews = int.tryParse(lr['total_reviews']?.toString() ?? '0') ?? 0;
                    final poster = m['Poster'];
                    return MovieCard(
                      title: m['Title'] ?? '', year: m['Year'] ?? '',
                      genre: details?['Genre'] ?? m['Type'] ?? '',
                      rating: avgR, reviewCount: reviews,
                      posterUrl: (poster != null && poster != 'N/A') ? poster : null,
                      onTap: () => _showMovieDetail(imdbId),
                    );
                  },
                )
              else
                Container(
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      decoration: const BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.only(topLeft: Radius.circular(AppRadius.card), topRight: Radius.circular(AppRadius.card))),
                      child: const Row(children: [
                        SizedBox(width: 60),
                        Expanded(flex: 3, child: Text('Film', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                        SizedBox(width: 60, child: Text('Annee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                        SizedBox(width: 70, child: Text('Note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                        SizedBox(width: 60, child: Text('Avis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                        SizedBox(width: 48),
                      ]),
                    ),
                    ..._movies.map((m) {
                      final imdbId = m['imdbID'] ?? '';
                      final details = _detailsCache[imdbId];
                      final lr = details?['local_ratings'] as Map<String, dynamic>? ?? {};
                      final avgR = _calcAvg(lr);
                      final reviews = int.tryParse(lr['total_reviews']?.toString() ?? '0') ?? 0;
                      final poster = m['Poster'];
                      return Column(children: [
                        MovieTableRow(
                          title: m['Title'] ?? '', year: m['Year'] ?? '',
                          genre: details?['Genre'] ?? m['Type'] ?? '',
                          rating: avgR, reviewCount: reviews,
                          posterUrl: (poster != null && poster != 'N/A') ? poster : null,
                          onTap: () => _showMovieDetail(imdbId),
                        ),
                        const Divider(),
                      ]);
                    }),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }

  double _calcAvg(Map<String, dynamic> lr) {
    final s = double.tryParse(lr['avg_scenario']?.toString() ?? '0') ?? 0;
    final a = double.tryParse(lr['avg_acting']?.toString() ?? '0') ?? 0;
    final v = double.tryParse(lr['avg_visual']?.toString() ?? '0') ?? 0;
    final total = int.tryParse(lr['total_reviews']?.toString() ?? '0') ?? 0;
    if (total == 0) return 0;
    return (s + a + v) / 3;
  }
}

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  const _ViewToggle({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isActive ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Icon(icon, size: 18, color: isActive ? Colors.white : AppColors.textSecondary),
      ),
    );
  }
}

class _LocalRatingChip extends StatelessWidget {
  final String label;
  final String value;
  const _LocalRatingChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final v = double.tryParse(value) ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        RatingBadge(rating: v),
      ]),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const _SliderRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
        Expanded(
          child: Slider(value: value, min: 1, max: 5, divisions: 4, label: value.round().toString(),
            activeColor: AppColors.primary, onChanged: onChanged),
        ),
        Text('${value.round()}/5', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    );
  }
}
