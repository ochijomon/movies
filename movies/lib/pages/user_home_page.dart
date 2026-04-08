import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../widgets/rating_badge.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

/// User home page after login: search movies, view details, rate.
class UserHomePage extends StatefulWidget {
  final int userId;
  final String pseudo;
  final VoidCallback onLogout;

  const UserHomePage({super.key, required this.userId, required this.pseudo, required this.onLogout});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _tabIndex = 0; // 0 = search, 1 = my ratings

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top bar
          _UserTopBar(pseudo: widget.pseudo, onLogout: widget.onLogout),
          // Tab bar
          Container(
            color: AppColors.surface,
            child: Row(
              children: [
                _TabBtn(label: 'Rechercher', icon: Icons.search_rounded, active: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
                _TabBtn(label: 'Mes notes', icon: Icons.rate_review_outlined, active: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: _tabIndex == 0
                ? _SearchTab(userId: widget.userId)
                : _MyRatingsTab(userId: widget.userId),
          ),
        ],
      ),
    );
  }
}

// ─── TOP BAR ───

class _UserTopBar extends StatelessWidget {
  final String pseudo;
  final VoidCallback onLogout;
  const _UserTopBar({required this.pseudo, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surface, boxShadow: [
        BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.movie_filter_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('MOVIES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 1.5)),
          const Spacer(),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(pseudo[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Text(pseudo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(width: 12),
          IconButton(icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.textSecondary), onPressed: onLogout, tooltip: 'Deconnexion'),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? AppColors.primary : Colors.transparent, width: 2.5))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? AppColors.primary : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SEARCH TAB ───

class _SearchTab extends StatefulWidget {
  final int userId;
  const _SearchTab({required this.userId});

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;
  bool _searched = false;
  Timer? _debounce;

  static const _defaultQueries = ['Batman', 'Marvel', 'Star Wars', 'Harry Potter', 'Avengers'];

  @override
  void initState() {
    super.initState();
    _loadInitialMovies();
  }

  Future<void> _loadInitialMovies() async {
    // Load movies from multiple popular queries to fill the grid
    setState(() => _loading = true);
    final allResults = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    for (final q in _defaultQueries) {
      try {
        final results = await ApiService.searchMovies(q);
        for (final m in results) {
          final id = m['imdbID'] ?? '';
          if (id.isNotEmpty && seenIds.add(id)) {
            allResults.add(m);
          }
        }
      } catch (_) {}
      if (allResults.length >= 20) break;
    }
    if (mounted) setState(() { _results = allResults; _loading = false; _searched = false; });
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 3) {
      if (q.trim().isEmpty && _searched) {
        // Reset to initial movies when search is cleared
        _loadInitialMovies();
        setState(() => _searched = false);
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _doSearch(q.trim()));
  }

  Future<void> _doSearch(String q) async {
    setState(() { _loading = true; _searched = true; });
    try {
      final results = await ApiService.searchMovies(q);
      if (mounted) setState(() { _results = results; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _results = []; _loading = false; });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, screenType) {
        final gridCols = screenType == ScreenType.desktop ? 5 : (screenType == ScreenType.tablet ? 3 : 2);
        final pad = screenType == ScreenType.desktop ? AppSpacing.xl : AppSpacing.md;

        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(
            children: [
              // Search bar
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onChanged: _onChanged,
                    onSubmitted: (q) { if (q.trim().isNotEmpty) _doSearch(q.trim()); },
                    decoration: InputDecoration(
                      hintText: 'Rechercher un film...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                      suffixIcon: _ctrl.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () {
                              _ctrl.clear();
                              _loadInitialMovies();
                            })
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: () { if (_ctrl.text.trim().isNotEmpty) _doSearch(_ctrl.text.trim()); },
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Rechercher'),
                ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              if (_loading)
                const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.primary))
              else if (_results.isEmpty && _searched)
                const Padding(padding: EdgeInsets.all(40), child: Text('Aucun resultat.', style: TextStyle(color: AppColors.textSecondary)))
              else if (_results.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Text('Chargement...', style: TextStyle(color: AppColors.textSecondary)))
              else ...[
                if (!_searched)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Films populaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCols, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 0.55,
                  ),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final m = _results[i];
                    final poster = m['Poster'];
                    return _MovieGridCard(
                      title: m['Title'] ?? '',
                      year: m['Year'] ?? '',
                      type: m['Type'] ?? '',
                      posterUrl: (poster != null && poster != 'N/A') ? poster : null,
                      onTap: () => _openDetail(m['imdbID'] ?? ''),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openDetail(String imdbId) {
    if (imdbId.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MovieDetailPage(imdbId: imdbId, userId: widget.userId),
    ));
  }
}

class _MovieGridCard extends StatelessWidget {
  final String title, year, type;
  final String? posterUrl;
  final VoidCallback onTap;
  const _MovieGridCard({required this.title, required this.year, required this.type, this.posterUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: posterUrl != null
                ? Image.network(posterUrl!, fit: BoxFit.cover, width: double.infinity)
                : Container(color: AppColors.surfaceSecondary, child: const Center(child: Icon(Icons.local_movies_outlined, size: 40, color: AppColors.textSecondary))),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('$year  |  $type', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── MOVIE DETAIL PAGE ───

class _MovieDetailPage extends StatefulWidget {
  final String imdbId;
  final int userId;
  const _MovieDetailPage({required this.imdbId, required this.userId});

  @override
  State<_MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<_MovieDetailPage> {
  Map<String, dynamic>? _movie;
  bool _loading = true;
  bool _alreadyRated = false;
  Map<String, dynamic>? _existingRating;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final movie = await ApiService.getMovie(widget.imdbId);
      final check = await ApiService.checkUserRating(widget.userId, widget.imdbId);
      if (mounted) {
        setState(() {
          _movie = movie;
          _alreadyRated = check['already_rated'] == true;
          _existingRating = check['rating'] as Map<String, dynamic>?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_movie?['Title'] ?? 'Detail du film'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _movie == null
              ? const Center(child: Text('Film introuvable.'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isWide ? 32 : 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Movie info
                    if (isWide)
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildPoster(),
                        const SizedBox(width: 32),
                        Expanded(child: _buildInfo()),
                      ])
                    else
                      Column(children: [
                        _buildPoster(),
                        const SizedBox(height: 20),
                        _buildInfo(),
                      ]),
                    const SizedBox(height: 32),
                    // Local ratings summary
                    _buildLocalRatings(),
                    const SizedBox(height: 32),
                    // Rate or show existing
                    _buildRateSection(),
                  ]),
                ),
    );
  }

  Widget _buildPoster() {
    final poster = _movie!['Poster'];
    if (poster != null && poster != 'N/A') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Image.network(poster, width: 200, height: 300, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 200, height: 300,
      decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: const Center(child: Icon(Icons.local_movies_outlined, size: 60, color: AppColors.textSecondary)),
    );
  }

  Widget _buildInfo() {
    final m = _movie!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(m['Title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      Text('${m['Year'] ?? ''}  |  ${m['Genre'] ?? ''}  |  ${m['Runtime'] ?? ''}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      const SizedBox(height: 12),
      Text(m['Plot'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
      const SizedBox(height: 16),
      _infoRow('Realisateur', m['Director'] ?? ''),
      _infoRow('Acteurs', m['Actors'] ?? ''),
      _infoRow('Langue', m['Language'] ?? ''),
      const SizedBox(height: 12),
      Row(children: [
        const Icon(Icons.star_rounded, size: 20, color: AppColors.warning),
        const SizedBox(width: 4),
        Text('IMDB : ${m['imdbRating'] ?? 'N/A'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    ]);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(text: TextSpan(children: [
        TextSpan(text: '$label : ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        TextSpan(text: value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ])),
    );
  }

  Widget _buildLocalRatings() {
    final lr = _movie!['local_ratings'] as Map<String, dynamic>? ?? {};
    final total = int.tryParse(lr['total_reviews']?.toString() ?? '0') ?? 0;
    final avgS = double.tryParse(lr['avg_scenario']?.toString() ?? '0') ?? 0;
    final avgA = double.tryParse(lr['avg_acting']?.toString() ?? '0') ?? 0;
    final avgV = double.tryParse(lr['avg_visual']?.toString() ?? '0') ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Notes de la communaute ($total avis)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        if (total == 0)
          const Text('Aucune note pour ce film. Soyez le premier !', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
        else
          Row(children: [
            _RatingChip(label: 'Scenario', value: avgS),
            const SizedBox(width: 12),
            _RatingChip(label: 'Acteurs', value: avgA),
            const SizedBox(width: 12),
            _RatingChip(label: 'Audio-Visuel', value: avgV),
          ]),
      ]),
    );
  }

  Widget _buildRateSection() {
    if (_alreadyRated && _existingRating != null) {
      final s = double.tryParse(_existingRating!['scenario']?.toString() ?? '0') ?? 0;
      final a = double.tryParse(_existingRating!['jeu_acteur']?.toString() ?? '0') ?? 0;
      final v = double.tryParse(_existingRating!['qualite_av']?.toString() ?? '0') ?? 0;
      final c = _existingRating!['commentaire']?.toString() ?? '';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.soft,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text('Vous avez deja note ce film', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _RatingChip(label: 'Scenario', value: s),
            const SizedBox(width: 12),
            _RatingChip(label: 'Acteurs', value: a),
            const SizedBox(width: 12),
            _RatingChip(label: 'Audio-Visuel', value: v),
          ]),
          if (c.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Commentaire : $c', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ],
        ]),
      );
    }

    return _RateForm(imdbId: widget.imdbId, userId: widget.userId, onRated: () {
      setState(() => _loading = true);
      _load();
    });
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final double value;
  const _RatingChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        RatingBadge(rating: value),
      ]),
    );
  }
}

// ─── RATE FORM ───

class _RateForm extends StatefulWidget {
  final String imdbId;
  final int userId;
  final VoidCallback onRated;
  const _RateForm({required this.imdbId, required this.userId, required this.onRated});

  @override
  State<_RateForm> createState() => _RateFormState();
}

class _RateFormState extends State<_RateForm> {
  double _scenario = 3, _acteur = 3, _av = 3;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await ApiService.rateMovie(
        imdbId: widget.imdbId,
        userId: widget.userId,
        scenario: _scenario.round(),
        jeuActeur: _acteur.round(),
        qualiteAv: _av.round(),
        commentaire: _commentCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Note enregistree'), backgroundColor: AppColors.primary),
        );
        widget.onRated();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi'), backgroundColor: AppColors.error),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Laisser une note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        _buildSlider('Scenario', _scenario, (v) => setState(() => _scenario = v)),
        _buildSlider('Jeu d\'acteur', _acteur, (v) => setState(() => _acteur = v)),
        _buildSlider('Audio-Visuel', _av, (v) => setState(() => _av = v)),
        const SizedBox(height: 12),
        TextField(
          controller: _commentCtrl,
          decoration: const InputDecoration(hintText: 'Votre commentaire (optionnel)'),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18),
            label: const Text('Envoyer ma note'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ]),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
        Expanded(
          child: Slider(value: value, min: 1, max: 5, divisions: 4, label: '${value.round()}',
            activeColor: AppColors.primary, onChanged: onChanged),
        ),
        Text('${value.round()}/5', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    );
  }
}

// ─── MY RATINGS TAB ───

class _MyRatingsTab extends StatefulWidget {
  final int userId;
  const _MyRatingsTab({required this.userId});

  @override
  State<_MyRatingsTab> createState() => _MyRatingsTabState();
}

class _MyRatingsTabState extends State<_MyRatingsTab> {
  List<Map<String, dynamic>> _ratings = [];
  final Map<String, String> _titles = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ratings = await ApiService.getUserRatings(widget.userId);
      for (final r in ratings) {
        final id = r['imdb_id']?.toString() ?? '';
        if (id.isNotEmpty && !_titles.containsKey(id)) {
          final details = await ApiService.getMovie(id);
          if (details != null) _titles[id] = details['Title'] ?? id;
        }
      }
      if (mounted) setState(() { _ratings = ratings; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_ratings.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text('Vous n\'avez pas encore note de film.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Recherchez un film et laissez votre avis !', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _ratings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = _ratings[i];
        final imdbId = r['imdb_id']?.toString() ?? '';
        final title = _titles[imdbId] ?? imdbId;
        final s = double.tryParse(r['scenario']?.toString() ?? '0') ?? 0;
        final a = double.tryParse(r['jeu_acteur']?.toString() ?? '0') ?? 0;
        final v = double.tryParse(r['qualite_av']?.toString() ?? '0') ?? 0;
        final avg = (s + a + v) / 3;
        final comment = r['commentaire']?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
              RatingBadge(rating: avg),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _MiniRating('Scenario', s),
              const SizedBox(width: 12),
              _MiniRating('Acteurs', a),
              const SizedBox(width: 12),
              _MiniRating('Audio-Visuel', v),
            ]),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(comment, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
            ],
          ]),
        );
      },
    );
  }
}

class _MiniRating extends StatelessWidget {
  final String label;
  final double value;
  const _MiniRating(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label: ', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      Text('${value.round()}/5', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]);
  }
}
