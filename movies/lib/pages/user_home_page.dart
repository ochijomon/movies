import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../widgets/rating_badge.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

/// User home page after login: search, community ranking, my ratings, profile.
class UserHomePage extends StatefulWidget {
  final int userId;
  final String pseudo;
  final VoidCallback onLogout;
  final bool isAdmin;
  final VoidCallback? onSwitchToAdmin;

  const UserHomePage({super.key, required this.userId, required this.pseudo, required this.onLogout, this.isAdmin = false, this.onSwitchToAdmin});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _tabIndex = 0;
  late String _pseudo;
  // Favorites stored locally (imdbID set)
  final Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _pseudo = widget.pseudo;
  }

  void _onPseudoChanged(String newPseudo) {
    setState(() => _pseudo = newPseudo);
  }

  void _toggleFavorite(String imdbId) {
    setState(() {
      if (_favorites.contains(imdbId)) {
        _favorites.remove(imdbId);
      } else {
        _favorites.add(imdbId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _UserTopBar(pseudo: _pseudo, onLogout: widget.onLogout, isAdmin: widget.isAdmin, onSwitchToAdmin: widget.onSwitchToAdmin),
          Container(
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TabBtn(label: 'Rechercher', icon: Icons.search_rounded, active: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
                  _TabBtn(label: 'Classement', icon: Icons.emoji_events_outlined, active: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
                  _TabBtn(label: 'Favoris', icon: Icons.favorite_outline, active: _tabIndex == 2, onTap: () => setState(() => _tabIndex = 2)),
                  _TabBtn(label: 'Mes notes', icon: Icons.rate_review_outlined, active: _tabIndex == 3, onTap: () => setState(() => _tabIndex = 3)),
                  _TabBtn(label: 'Mon profil', icon: Icons.person_outline, active: _tabIndex == 4, onTap: () => setState(() => _tabIndex = 4)),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildTab()),
        ],
      ),
    );
  }

  Widget _buildTab() {
    switch (_tabIndex) {
      case 0:
        return _SearchTab(userId: widget.userId, favorites: _favorites, onToggleFavorite: _toggleFavorite);
      case 1:
        return _CommunityRankingTab(userId: widget.userId, favorites: _favorites, onToggleFavorite: _toggleFavorite);
      case 2:
        return _FavoritesTab(userId: widget.userId, favorites: _favorites, onToggleFavorite: _toggleFavorite);
      case 3:
        return _MyRatingsTab(userId: widget.userId);
      case 4:
        return _ProfileTab(userId: widget.userId, pseudo: _pseudo, onPseudoChanged: _onPseudoChanged);
      default:
        return _SearchTab(userId: widget.userId, favorites: _favorites, onToggleFavorite: _toggleFavorite);
    }
  }
}

// ─── TOP BAR ───

class _UserTopBar extends StatelessWidget {
  final String pseudo;
  final VoidCallback onLogout;
  final bool isAdmin;
  final VoidCallback? onSwitchToAdmin;
  const _UserTopBar({required this.pseudo, required this.onLogout, this.isAdmin = false, this.onSwitchToAdmin});

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
          if (isAdmin && onSwitchToAdmin != null)
            TextButton.icon(
              onPressed: onSwitchToAdmin,
              icon: const Icon(Icons.admin_panel_settings_outlined, size: 16, color: AppColors.accent),
              label: const Text('Vue admin', style: TextStyle(fontSize: 12, color: AppColors.accent)),
            ),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(pseudo.isNotEmpty ? pseudo[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: active ? AppColors.primary : Colors.transparent, width: 2.5))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? AppColors.primary : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── SEARCH TAB ───

class _SearchTab extends StatefulWidget {
  final int userId;
  final Set<String> favorites;
  final ValueChanged<String> onToggleFavorite;
  const _SearchTab({required this.userId, required this.favorites, required this.onToggleFavorite});

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
    setState(() => _loading = true);
    final allResults = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    for (final q in _defaultQueries) {
      try {
        final results = await ApiService.searchMovies(q);
        for (final m in results) {
          final id = m['imdbID'] ?? '';
          if (id.isNotEmpty && seenIds.add(id)) allResults.add(m);
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
  void dispose() { _debounce?.cancel(); _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (context, screenType) {
        final gridCols = screenType == ScreenType.desktop ? 5 : (screenType == ScreenType.tablet ? 3 : 2);
        final pad = screenType == ScreenType.desktop ? AppSpacing.xl : AppSpacing.md;

        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(children: [
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
                        ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { _ctrl.clear(); _loadInitialMovies(); })
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
                  child: Align(alignment: Alignment.centerLeft, child: Text('Films populaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
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
                  final imdbId = m['imdbID'] ?? '';
                  return _MovieGridCard(
                    title: m['Title'] ?? '',
                    year: m['Year'] ?? '',
                    type: m['Type'] ?? '',
                    posterUrl: (poster != null && poster != 'N/A') ? poster : null,
                    isFavorite: widget.favorites.contains(imdbId),
                    onFavorite: () => widget.onToggleFavorite(imdbId),
                    onTap: () => _openDetail(imdbId),
                  );
                },
              ),
            ],
          ]),
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
  final bool isFavorite;
  final VoidCallback? onFavorite;
  const _MovieGridCard({required this.title, required this.year, required this.type, this.posterUrl, required this.onTap, this.isFavorite = false, this.onFavorite});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: posterUrl != null
                  ? Image.network(posterUrl!, fit: BoxFit.cover, width: double.infinity)
                  : Container(color: AppColors.surfaceSecondary, child: const Center(child: Icon(Icons.local_movies_outlined, size: 40, color: AppColors.textSecondary))),
            ),
            if (onFavorite != null)
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: onFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFavorite ? AppColors.coral : Colors.white,
                    ),
                  ),
                ),
              ),
          ]),
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

// ─── COMMUNITY RANKING TAB ───

class _CommunityRankingTab extends StatefulWidget {
  final int userId;
  final Set<String> favorites;
  final ValueChanged<String> onToggleFavorite;
  const _CommunityRankingTab({required this.userId, required this.favorites, required this.onToggleFavorite});

  @override
  State<_CommunityRankingTab> createState() => _CommunityRankingTabState();
}

class _CommunityRankingTabState extends State<_CommunityRankingTab> {
  List<Map<String, dynamic>> _ranked = [];
  final Map<String, Map<String, dynamic>> _movieCache = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stats = await ApiService.getStats();
      final popular = (stats['popular_movies'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final m in popular) {
        final imdbId = m['imdb_id'] as String? ?? '';
        if (imdbId.isNotEmpty && !_movieCache.containsKey(imdbId)) {
          final details = await ApiService.getMovie(imdbId);
          if (details != null) _movieCache[imdbId] = details;
        }
      }
      // Sort by avg_rating descending
      popular.sort((a, b) {
        final ra = double.tryParse(a['avg_rating']?.toString() ?? '0') ?? 0;
        final rb = double.tryParse(b['avg_rating']?.toString() ?? '0') ?? 0;
        return rb.compareTo(ra);
      });
      if (mounted) setState(() { _ranked = popular; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_ranked.isEmpty) {
      return const Center(child: Text('Aucun film note par la communaute.', style: TextStyle(color: AppColors.textSecondary)));
    }

    return ResponsiveLayout(
      builder: (context, screenType) {
        final pad = screenType == ScreenType.desktop ? AppSpacing.xl : AppSpacing.md;
        return ListView.builder(
          padding: EdgeInsets.all(pad),
          itemCount: _ranked.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('Classement communautaire', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              );
            }
            final m = _ranked[i - 1];
            final imdbId = m['imdb_id'] as String? ?? '';
            final details = _movieCache[imdbId];
            final title = details?['Title'] ?? imdbId;
            final year = details?['Year'] ?? '';
            final genre = details?['Genre'] ?? '';
            final poster = details?['Poster'];
            final posterUrl = (poster != null && poster != 'N/A') ? poster as String : null;
            final avgRating = double.tryParse(m['avg_rating']?.toString() ?? '0') ?? 0;
            final reviewCount = int.tryParse(m['review_count']?.toString() ?? '0') ?? 0;
            final isFav = widget.favorites.contains(imdbId);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GestureDetector(
                onTap: () {
                  if (imdbId.isNotEmpty) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => _MovieDetailPage(imdbId: imdbId, userId: widget.userId),
                    ));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
                  child: Row(children: [
                    // Rank number
                    SizedBox(
                      width: 36,
                      child: Text('#$i', style: TextStyle(
                        fontSize: i <= 3 ? 20 : 16,
                        fontWeight: FontWeight.w700,
                        color: i == 1 ? AppColors.warning : (i <= 3 ? AppColors.primary : AppColors.textSecondary),
                      )),
                    ),
                    // Poster
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: posterUrl != null
                          ? Image.network(posterUrl, width: 50, height: 75, fit: BoxFit.cover)
                          : Container(width: 50, height: 75, color: AppColors.surfaceSecondary, child: const Icon(Icons.movie_outlined, size: 24, color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Info
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('$year  |  $genre', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('$reviewCount avis', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ])),
                    // Rating + fav
                    Column(children: [
                      RatingBadge(rating: avgRating, fontSize: 14),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => widget.onToggleFavorite(imdbId),
                        child: Icon(isFav ? Icons.favorite : Icons.favorite_border, size: 20, color: isFav ? AppColors.coral : AppColors.textSecondary),
                      ),
                    ]),
                  ]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── FAVORITES TAB ───

class _FavoritesTab extends StatefulWidget {
  final int userId;
  final Set<String> favorites;
  final ValueChanged<String> onToggleFavorite;
  const _FavoritesTab({required this.userId, required this.favorites, required this.onToggleFavorite});

  @override
  State<_FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<_FavoritesTab> {
  final Map<String, Map<String, dynamic>> _cache = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void didUpdateWidget(covariant _FavoritesTab old) {
    super.didUpdateWidget(old);
    if (widget.favorites.length != old.favorites.length) _loadDetails();
  }

  Future<void> _loadDetails() async {
    final toFetch = widget.favorites.where((id) => !_cache.containsKey(id)).toList();
    if (toFetch.isEmpty) return;
    setState(() => _loading = true);
    for (final id in toFetch) {
      final details = await ApiService.getMovie(id);
      if (details != null) _cache[id] = details;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.favorites.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.favorite_outline, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text('Aucun favori pour le moment.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Appuyez sur le coeur d\'un film pour l\'ajouter.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ]),
      );
    }

    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return ResponsiveLayout(
      builder: (context, screenType) {
        final gridCols = screenType == ScreenType.desktop ? 5 : (screenType == ScreenType.tablet ? 3 : 2);
        final pad = screenType == ScreenType.desktop ? AppSpacing.xl : AppSpacing.md;
        final favList = widget.favorites.toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mes favoris (${favList.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridCols, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 0.55,
              ),
              itemCount: favList.length,
              itemBuilder: (context, i) {
                final imdbId = favList[i];
                final details = _cache[imdbId];
                final title = details?['Title'] ?? imdbId;
                final year = details?['Year'] ?? '';
                final poster = details?['Poster'];
                final posterUrl = (poster != null && poster != 'N/A') ? poster as String : null;

                return _MovieGridCard(
                  title: title,
                  year: year,
                  type: details?['Type'] ?? '',
                  posterUrl: posterUrl,
                  isFavorite: true,
                  onFavorite: () => widget.onToggleFavorite(imdbId),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => _MovieDetailPage(imdbId: imdbId, userId: widget.userId),
                    ));
                  },
                );
              },
            ),
          ]),
        );
      },
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
                    if (isWide)
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _buildPoster(),
                        const SizedBox(width: 32),
                        Expanded(child: _buildInfo()),
                      ])
                    else
                      Column(children: [_buildPoster(), const SizedBox(height: 20), _buildInfo()]),
                    const SizedBox(height: 32),
                    _buildLocalRatings(),
                    const SizedBox(height: 32),
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
            const Expanded(child: Text('Vous avez deja note ce film', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary))),
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
  double _scenario = 5, _acteur = 5, _av = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await ApiService.rateMovie(
        imdbId: widget.imdbId, userId: widget.userId,
        scenario: _scenario.round(), jeuActeur: _acteur.round(), qualiteAv: _av.round(),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'envoi'), backgroundColor: AppColors.error));
        setState(() => _submitting = false);
      }
    }
  }

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

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
        TextField(controller: _commentCtrl, decoration: const InputDecoration(hintText: 'Votre commentaire (optionnel)'), maxLines: 3),
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
        Expanded(child: Slider(value: value, min: 1, max: 10, divisions: 9, label: '${value.round()}', activeColor: AppColors.primary, onChanged: onChanged)),
        Text('${value.round()}/10', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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

enum _RatingSortField { title, avg, date }

class _MyRatingsTabState extends State<_MyRatingsTab> {
  List<Map<String, dynamic>> _ratings = [];
  List<Map<String, dynamic>> _filtered = [];
  final Map<String, Map<String, dynamic>> _movieDetails = {};
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  _RatingSortField _sortField = _RatingSortField.date;
  bool _sortAsc = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final ratings = await ApiService.getUserRatings(widget.userId);
      for (final r in ratings) {
        final id = r['imdb_id']?.toString() ?? '';
        if (id.isNotEmpty && !_movieDetails.containsKey(id)) {
          final details = await ApiService.getMovie(id);
          if (details != null) _movieDetails[id] = details;
        }
      }
      if (mounted) {
        setState(() { _ratings = ratings; _loading = false; });
        _applyFilters();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase();
    var list = _ratings.where((r) {
      final imdbId = r['imdb_id']?.toString() ?? '';
      final title = (_movieDetails[imdbId]?['Title'] ?? '').toString().toLowerCase();
      final comment = (r['commentaire'] ?? '').toString().toLowerCase();
      return title.contains(q) || comment.contains(q);
    }).toList();

    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case _RatingSortField.title:
          final ta = (_movieDetails[a['imdb_id']?.toString() ?? '']?['Title'] ?? '').toString();
          final tb = (_movieDetails[b['imdb_id']?.toString() ?? '']?['Title'] ?? '').toString();
          cmp = ta.compareTo(tb);
        case _RatingSortField.avg:
          final aa = _avg(a);
          final ab = _avg(b);
          cmp = aa.compareTo(ab);
        case _RatingSortField.date:
          final da = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
          final db = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
          cmp = da.compareTo(db);
      }
      return _sortAsc ? cmp : -cmp;
    });

    setState(() => _filtered = list);
  }

  double _avg(Map<String, dynamic> r) {
    final s = double.tryParse(r['scenario']?.toString() ?? '0') ?? 0;
    final a = double.tryParse(r['jeu_acteur']?.toString() ?? '0') ?? 0;
    final v = double.tryParse(r['qualite_av']?.toString() ?? '0') ?? 0;
    return (s + a + v) / 3;
  }

  // Stats
  double get _globalAvg {
    if (_ratings.isEmpty) return 0;
    return _ratings.map(_avg).reduce((a, b) => a + b) / _ratings.length;
  }

  String get _favoriteGenre {
    final genreCount = <String, int>{};
    for (final r in _ratings) {
      final imdbId = r['imdb_id']?.toString() ?? '';
      final genre = _movieDetails[imdbId]?['Genre']?.toString() ?? '';
      for (final g in genre.split(',')) {
        final trimmed = g.trim();
        if (trimmed.isNotEmpty) genreCount[trimmed] = (genreCount[trimmed] ?? 0) + 1;
      }
    }
    if (genreCount.isEmpty) return '-';
    final sorted = genreCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
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

    return ResponsiveLayout(
      builder: (context, screenType) {
        final gridCols = screenType == ScreenType.desktop ? 4 : (screenType == ScreenType.tablet ? 3 : 2);
        final pad = screenType == ScreenType.desktop ? AppSpacing.xl : AppSpacing.md;

        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Personal stats
            _buildStats(),
            const SizedBox(height: AppSpacing.lg),
            // Search + sort
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans mes notes...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { _searchCtrl.clear(); _applyFilters(); })
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PopupMenuButton<_RatingSortField>(
                icon: const Icon(Icons.sort_rounded, color: AppColors.textSecondary),
                tooltip: 'Trier',
                onSelected: (field) {
                  setState(() {
                    if (_sortField == field) { _sortAsc = !_sortAsc; } else { _sortField = field; _sortAsc = true; }
                  });
                  _applyFilters();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: _RatingSortField.title, child: Row(children: [
                    Icon(_sortField == _RatingSortField.title ? (_sortAsc ? Icons.arrow_upward : Icons.arrow_downward) : Icons.sort_by_alpha, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8), const Text('Par titre'),
                  ])),
                  PopupMenuItem(value: _RatingSortField.avg, child: Row(children: [
                    Icon(_sortField == _RatingSortField.avg ? (_sortAsc ? Icons.arrow_upward : Icons.arrow_downward) : Icons.star_outline, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8), const Text('Par note'),
                  ])),
                  PopupMenuItem(value: _RatingSortField.date, child: Row(children: [
                    Icon(_sortField == _RatingSortField.date ? (_sortAsc ? Icons.arrow_upward : Icons.arrow_downward) : Icons.access_time, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8), const Text('Par date'),
                  ])),
                ],
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            Text('Mes notes (${_filtered.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridCols, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 0.38,
              ),
              itemCount: _filtered.length,
              itemBuilder: (context, i) => _buildRatingCard(_filtered[i]),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
      child: Row(children: [
        Expanded(child: _StatItem(icon: Icons.movie_outlined, label: 'Films notes', value: '${_ratings.length}')),
        Container(width: 1, height: 40, color: AppColors.divider),
        Expanded(child: _StatItem(icon: Icons.star_outline_rounded, label: 'Note moyenne', value: _globalAvg.toStringAsFixed(1))),
        Container(width: 1, height: 40, color: AppColors.divider),
        Expanded(child: _StatItem(icon: Icons.category_outlined, label: 'Genre prefere', value: _favoriteGenre)),
      ]),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> r) {
    final imdbId = r['imdb_id']?.toString() ?? '';
    final details = _movieDetails[imdbId];
    final title = details?['Title'] ?? imdbId;
    final year = details?['Year'] ?? '';
    final poster = details?['Poster'];
    final posterUrl = (poster != null && poster != 'N/A') ? poster as String : null;
    final s = double.tryParse(r['scenario']?.toString() ?? '0') ?? 0;
    final a = double.tryParse(r['jeu_acteur']?.toString() ?? '0') ?? 0;
    final v = double.tryParse(r['qualite_av']?.toString() ?? '0') ?? 0;
    final avg = (s + a + v) / 3;
    final comment = r['commentaire']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        if (imdbId.isNotEmpty) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => _MovieDetailPage(imdbId: imdbId, userId: widget.userId),
          ));
        }
      },
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: posterUrl != null
                ? Image.network(posterUrl, fit: BoxFit.cover, width: double.infinity)
                : Container(color: AppColors.surfaceSecondary, child: const Center(child: Icon(Icons.local_movies_outlined, size: 40, color: AppColors.textSecondary))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (year.isNotEmpty) Text(year, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(children: [RatingBadge(rating: avg), const Spacer()]),
                const SizedBox(height: 4),
                _MiniRating('Scenario', s),
                _MiniRating('Acteurs', a),
                _MiniRating('Audio-V.', v),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(comment, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 22, color: AppColors.primary),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
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
      Text('${value.round()}/10', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ]);
  }
}

// ─── PROFILE TAB ───

class _ProfileTab extends StatefulWidget {
  final int userId;
  final String pseudo;
  final ValueChanged<String> onPseudoChanged;
  const _ProfileTab({required this.userId, required this.pseudo, required this.onPseudoChanged});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  bool _loading = true;
  String? _currentEmail;
  int _totalRatings = 0;
  double _avgRating = 0;
  String _favoriteGenre = '-';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final ratings = await ApiService.getUserRatings(widget.userId);
      double sum = 0;
      final genreCount = <String, int>{};
      for (final r in ratings) {
        final s = double.tryParse(r['scenario']?.toString() ?? '0') ?? 0;
        final a = double.tryParse(r['jeu_acteur']?.toString() ?? '0') ?? 0;
        final v = double.tryParse(r['qualite_av']?.toString() ?? '0') ?? 0;
        sum += (s + a + v) / 3;
        // Fetch genre
        final imdbId = r['imdb_id']?.toString() ?? '';
        if (imdbId.isNotEmpty) {
          final details = await ApiService.getMovie(imdbId);
          if (details != null) {
            final genre = details['Genre']?.toString() ?? '';
            for (final g in genre.split(',')) {
              final trimmed = g.trim();
              if (trimmed.isNotEmpty) genreCount[trimmed] = (genreCount[trimmed] ?? 0) + 1;
            }
          }
        }
      }
      // Get email
      final users = await ApiService.getUsers();
      final me = users.where((u) => u['id']?.toString() == widget.userId.toString()).toList();
      if (me.isNotEmpty) _currentEmail = me.first['email']?.toString() ?? '';
      // Favorite genre
      if (genreCount.isNotEmpty) {
        final sorted = genreCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        _favoriteGenre = sorted.first.key;
      }
      if (mounted) {
        setState(() {
          _totalRatings = ratings.length;
          _avgRating = ratings.isEmpty ? 0 : sum / ratings.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return ResponsiveLayout(
      builder: (context, screenType) {
        final pad = screenType == ScreenType.desktop ? AppSpacing.xl : AppSpacing.md;
        final maxWidth = screenType == ScreenType.desktop ? 500.0 : double.infinity;

        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
                child: Column(children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      widget.pseudo.isNotEmpty ? widget.pseudo[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.pseudo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(_currentEmail ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _ProfileStat(value: '$_totalRatings', label: 'Films notes'),
                    const SizedBox(width: 32),
                    _ProfileStat(value: _avgRating.toStringAsFixed(1), label: 'Note moyenne'),
                    const SizedBox(width: 32),
                    _ProfileStat(value: _favoriteGenre, label: 'Genre prefere'),
                  ]),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    ]);
  }
}
