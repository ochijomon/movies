import 'dart:convert';
import 'package:http/http.dart' as http;

/// Central API service connecting to the PHP backend.
class ApiService {
  // Base URL relative - works when Flutter web is served from the same Apache server
  static const String _baseUrl = '/movies/movies_api/api';

  // ─── AUTH ───

  /// Login: POST /auth/login.php
  /// Returns {message, id, pseudo} on success.
  static Future<Map<String, dynamic>> login(String pseudo, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pseudo': pseudo, 'password': password}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Register: POST /auth/register.php
  static Future<Map<String, dynamic>> register(String pseudo, String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pseudo': pseudo, 'email': email, 'password': password}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── MOVIES ───

  /// Search movies via OMDB: GET /movies/search.php?s=query
  /// Returns List of {Title, Year, imdbID, Type, Poster}.
  static Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movies/search.php?s=${Uri.encodeComponent(query)}'),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  /// Get single movie details: GET /movies/read.php?id=imdbId
  /// Returns OMDB data + local_ratings {avg_scenario, avg_acting, avg_visual, total_reviews}.
  static Future<Map<String, dynamic>?> getMovie(String imdbId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movies/read.php?id=$imdbId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Rate a movie: POST /movies/rate.php
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

  // ─── ADMIN ───

  /// Check if user already rated a movie: GET /movies/user_ratings.php?user_id=X&imdb_id=Y
  static Future<Map<String, dynamic>> checkUserRating(int userId, String imdbId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movies/user_ratings.php?user_id=$userId&imdb_id=$imdbId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {};
  }

  /// Get all ratings by a user: GET /movies/user_ratings.php?user_id=X
  static Future<List<Map<String, dynamic>>> getUserRatings(int userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/movies/user_ratings.php?user_id=$userId'),
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  // ─── ADMIN ENDPOINTS ───

  /// Dashboard stats: GET /admin/stats.php
  /// Returns {total_users, total_notes, total_movies, avg_global, distribution, recent_activity, popular_movies}.
  static Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/stats.php'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {};
  }

  /// All users: GET /admin/users.php
  /// Returns List of {id, pseudo, email, notes_count}.
  static Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/users.php'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  /// All ratings: GET /admin/ratings.php
  /// Returns List of {id, imdb_id, scenario, jeu_acteur, qualite_av, commentaire, pseudo}.
  static Future<List<Map<String, dynamic>>> getRatings() async {
    final response = await http.get(Uri.parse('$_baseUrl/admin/ratings.php'));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }
}
