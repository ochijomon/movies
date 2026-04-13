import 'dart:convert';
import 'package:http/http.dart' as http;

/// Central API service connecting to the PHP backend.
class ApiService {
  // Construit l'URL depuis le premier segment du path (ex: /Books_Moovies/)
  // Fonctionne peu importe le sous-dossier (web_app, movies, etc.)
  static String get _baseUrl {
    final origin = Uri.base.origin;
    final path = Uri.base.path;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    final base = segments.isNotEmpty ? '/${segments.first}/' : '/';
    return '$origin${base}movies_api/api';
  }

  // ─── AUTH ───

  static Future<Map<String, dynamic>> login(String pseudo, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pseudo': pseudo, 'password': password}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> register(String pseudo, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pseudo': pseudo, 'email': email, 'password': password}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── MOVIES ───

  static Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movies/search.php?s=${Uri.encodeComponent(query)}'),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getMovie(String imdbId) async {
    final response = await http.get(Uri.parse('$_baseUrl/movies/read.php?id=$imdbId'));
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    return null;
  }

  static Future<Map<String, dynamic>> rateMovie({
    required String imdbId,
    required int userId,
    required int scenario,
    required int jeuActeur,
    required int qualiteAv,
    String commentaire = '',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/movies/rate.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'imdb_id': imdbId,
        'id_utilisateur': userId,
        'scenario': scenario,
        'jeu_acteur': jeuActeur,
        'qualite_av': qualiteAv,
        'commentaire': commentaire,
      }),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── USER ───

  static Future<Map<String, dynamic>> checkUserRating(int userId, String imdbId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movies/user_ratings.php?user_id=$userId&imdb_id=$imdbId'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    return {};
  }

  static Future<List<Map<String, dynamic>>> getUserRatings(int userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/movies/user_ratings.php?user_id=$userId'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ─── ADMIN ───

  static Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/stats.php'));
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    return {};
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/users.php'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getRatings() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/ratings.php'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
