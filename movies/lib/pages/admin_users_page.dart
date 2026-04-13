import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../widgets/section_card.dart';
import '../widgets/search_field.dart';
import '../widgets/kpi_card.dart';
import '../widgets/rating_badge.dart';
import '../widgets/app_button.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

/// Unified admin page: user management + inline ratings.
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

enum _SortField { pseudo, email, notesCount }
enum _SortOrder { asc, desc }

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _allRatings = [];
  final Map<String, String> _movieTitles = {};
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  final Set<int> _expandedUsers = {};
  _SortField _sortField = _SortField.pseudo;
  _SortOrder _sortOrder = _SortOrder.asc;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final users = await ApiService.getUsers();
      final ratings = await ApiService.getRatings();
      // Fetch movie titles
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
          _users = users;
          _allRatings = ratings;
          _loading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> _ratingsForUser(String pseudo) {
    return _allRatings.where((r) => r['pseudo']?.toString() == pseudo).toList();
  }

  double _avgRatingForUser(String pseudo) {
    final userRatings = _ratingsForUser(pseudo);
    if (userRatings.isEmpty) return 0;
    double sum = 0;
    for (final r in userRatings) {
      final s = double.tryParse(r['scenario']?.toString() ?? '0') ?? 0;
      final a = double.tryParse(r['jeu_acteur']?.toString() ?? '0') ?? 0;
      final v = double.tryParse(r['qualite_av']?.toString() ?? '0') ?? 0;
      sum += (s + a + v) / 3;
    }
    return sum / userRatings.length;
  }

  void _applyFilters() {
    final q = _searchController.text.toLowerCase();
    var list = _users.where((u) {
      final pseudo = (u['pseudo'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return pseudo.contains(q) || email.contains(q);
    }).toList();

    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case _SortField.pseudo:
          cmp = (a['pseudo']?.toString() ?? '').compareTo(b['pseudo']?.toString() ?? '');
        case _SortField.email:
          cmp = (a['email']?.toString() ?? '').compareTo(b['email']?.toString() ?? '');
        case _SortField.notesCount:
          final ca = int.tryParse(a['notes_count']?.toString() ?? '0') ?? 0;
          final cb = int.tryParse(b['notes_count']?.toString() ?? '0') ?? 0;
          cmp = ca.compareTo(cb);
      }
      return _sortOrder == _SortOrder.asc ? cmp : -cmp;
    });

    setState(() => _filtered = list);
  }

  void _onSearch(String query) => _applyFilters();

  void _toggleSort(_SortField field) {
    setState(() {
      if (_sortField == field) {
        _sortOrder = _sortOrder == _SortOrder.asc ? _SortOrder.desc : _SortOrder.asc;
      } else {
        _sortField = field;
        _sortOrder = _SortOrder.asc;
      }
    });
    _applyFilters();
  }

  void _toggleExpand(int userId) {
    setState(() {
      if (_expandedUsers.contains(userId)) {
        _expandedUsers.remove(userId);
      } else {
        _expandedUsers.add(userId);
      }
    });
  }

  Future<void> _deleteUser(int userId, String pseudo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Supprimer l\'utilisateur'),
        content: Text('Voulez-vous vraiment supprimer "$pseudo" et toutes ses notes ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await ApiService.deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$pseudo" supprime'), backgroundColor: AppColors.primary),
        );
        setState(() => _loading = true);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _showEditDialog(Map<String, dynamic> user) {
    final pseudoCtrl = TextEditingController(text: user['pseudo']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: user['email']?.toString() ?? '');
    final userId = int.tryParse(user['id']?.toString() ?? '0') ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Modifier l\'utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: pseudoCtrl, decoration: const InputDecoration(labelText: 'Pseudo')),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (pseudoCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
              try {
                await ApiService.updateUser(userId, pseudo: pseudoCtrl.text, email: emailCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Utilisateur mis a jour'), backgroundColor: AppColors.primary),
                  );
                  setState(() => _loading = true);
                  _loadData();
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
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
                _loadData();
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () { setState(() { _loading = true; _error = null; }); _loadData(); },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reessayer'),
          ),
        ]),
      );
    }

    // KPI calculations
    final totalUsers = _users.length;
    final totalRatings = _allRatings.length;
    final activeUsers = _users.where((u) {
      final count = int.tryParse(u['notes_count']?.toString() ?? '0') ?? 0;
      return count > 0;
    }).length;
    final avgRatingsPerUser = totalUsers > 0 ? (totalRatings / totalUsers).toStringAsFixed(1) : '0';

    return ResponsiveLayout(
      builder: (context, screenType) {
        final isDesktop = screenType == ScreenType.desktop;
        final padding = isDesktop ? AppSpacing.xl : AppSpacing.md;
        final crossAxisCount = isDesktop ? 4 : (screenType == ScreenType.tablet ? 2 : 1);

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI cards
                _buildKpiGrid(crossAxisCount, totalUsers, totalRatings, activeUsers, avgRatingsPerUser),
                const SizedBox(height: AppSpacing.lg),
                // Search + actions
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: 400,
                        child: AppSearchField(
                          hint: 'Rechercher un utilisateur...',
                          controller: _searchController,
                          onChanged: _onSearch,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppButton(label: 'Ajouter', icon: Icons.person_add_outlined, onPressed: _showRegisterDialog),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: _expandedUsers.isEmpty ? 'Tout ouvrir' : 'Tout fermer',
                      icon: _expandedUsers.isEmpty ? Icons.unfold_more_rounded : Icons.unfold_less_rounded,
                      isOutlined: true,
                      onPressed: () {
                        setState(() {
                          if (_expandedUsers.isEmpty) {
                            for (final u in _filtered) {
                              final id = int.tryParse(u['id']?.toString() ?? '0') ?? 0;
                              _expandedUsers.add(id);
                            }
                          } else {
                            _expandedUsers.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Users table with inline ratings
                SectionCard(
                  title: 'Utilisateurs & Notes (${_filtered.length})',
                  titleIcon: Icons.admin_panel_settings_outlined,
                  child: Column(
                    children: [
                      _buildTableHeader(),
                      if (_filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Text('Aucun utilisateur trouve.', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      else
                        ..._filtered.map((u) => _buildUserBlock(u)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(int crossAxisCount, int totalUsers, int totalRatings, int activeUsers, String avgPerUser) {
    final kpis = [
      (Icons.people_outline_rounded, 'Utilisateurs', '$totalUsers'),
      (Icons.rate_review_outlined, 'Total notes', '$totalRatings'),
      (Icons.person_pin_outlined, 'Utilisateurs actifs', '$activeUsers'),
      (Icons.analytics_outlined, 'Moy. notes/user', avgPerUser),
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
        return KpiCard(icon: icon, label: label, value: value, iconBgColor: AppColors.surfaceSecondary);
      },
    );
  }

  Widget _buildSortIcon(_SortField field) {
    if (_sortField != field) return const SizedBox.shrink();
    return Icon(
      _sortOrder == _SortOrder.asc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      size: 12,
      color: AppColors.accent,
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      color: AppColors.surfaceSecondary,
      child: Row(children: [
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: () => _toggleSort(_SortField.pseudo),
            child: Row(children: [
              const Text('Utilisateur', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(width: 4),
              _buildSortIcon(_SortField.pseudo),
            ]),
          ),
        ),
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: () => _toggleSort(_SortField.email),
            child: Row(children: [
              const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(width: 4),
              _buildSortIcon(_SortField.email),
            ]),
          ),
        ),
        Expanded(
          flex: 1,
          child: InkWell(
            onTap: () => _toggleSort(_SortField.notesCount),
            child: Row(children: [
              const Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(width: 4),
              _buildSortIcon(_SortField.notesCount),
            ]),
          ),
        ),
        const Expanded(
          flex: 1,
          child: Text('Moy.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 100, child: Text('Actions', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
      ]),
    );
  }

  Widget _buildUserBlock(Map<String, dynamic> user) {
    final pseudo = user['pseudo']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final notesCount = int.tryParse(user['notes_count']?.toString() ?? '0') ?? 0;
    final userId = int.tryParse(user['id']?.toString() ?? '0') ?? 0;
    final isExpanded = _expandedUsers.contains(userId);
    final avgRating = _avgRatingForUser(pseudo);
    final userRatings = _ratingsForUser(pseudo);

    const avatarColors = [AppColors.primary, AppColors.accent, AppColors.coral];
    final color = avatarColors[userId % avatarColors.length];

    return Column(children: [
      // User row
      InkWell(
        onTap: notesCount > 0 ? () => _toggleExpand(userId) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: Row(children: [
                if (notesCount > 0)
                  Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  )
                else
                  const SizedBox(width: 18),
                const SizedBox(width: AppSpacing.sm),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(
                    pseudo.isNotEmpty ? pseudo[0].toUpperCase() : '?',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(pseudo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),
            Expanded(
              flex: 3,
              child: Text(email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Text('$notesCount', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
            ),
            Expanded(
              flex: 1,
              child: notesCount > 0
                  ? RatingBadge(rating: avgRating)
                  : const Text('-', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.accent,
                    tooltip: 'Modifier',
                    onPressed: () => _showEditDialog(user),
                    splashRadius: 18,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.error,
                    tooltip: 'Supprimer',
                    onPressed: () => _deleteUser(userId, pseudo),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
      // Expanded ratings
      if (isExpanded && userRatings.isNotEmpty)
        Container(
          color: AppColors.surfaceSecondary.withValues(alpha: 0.5),
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('Notes de cet utilisateur :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ),
              // Ratings sub-header
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(children: const [
                  Expanded(flex: 3, child: Text('Film', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  Expanded(flex: 1, child: Text('Scenario', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  Expanded(flex: 1, child: Text('Acteurs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  Expanded(flex: 1, child: Text('Audio-V.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  Expanded(flex: 1, child: Text('Moy.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                  Expanded(flex: 3, child: Text('Commentaire', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                ]),
              ),
              ...userRatings.map((r) {
                final imdbId = r['imdb_id']?.toString() ?? '';
                final movieTitle = _movieTitles[imdbId] ?? imdbId;
                final scenario = double.tryParse(r['scenario']?.toString() ?? '0') ?? 0;
                final acting = double.tryParse(r['jeu_acteur']?.toString() ?? '0') ?? 0;
                final audioVisual = double.tryParse(r['qualite_av']?.toString() ?? '0') ?? 0;
                final avg = (scenario + acting + audioVisual) / 3;
                final comment = r['commentaire']?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(children: [
                    Expanded(flex: 3, child: Text(movieTitle, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 1, child: RatingBadge(rating: scenario, fontSize: 11)),
                    Expanded(flex: 1, child: RatingBadge(rating: acting, fontSize: 11)),
                    Expanded(flex: 1, child: RatingBadge(rating: audioVisual, fontSize: 11)),
                    Expanded(flex: 1, child: RatingBadge(rating: avg, fontSize: 11)),
                    Expanded(flex: 3, child: Text(comment, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ]),
                );
              }),
            ],
          ),
        ),
      const Divider(height: 1),
    ]);
  }
}
