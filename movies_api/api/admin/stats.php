<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

// Total utilisateurs
$stmtUsers = $db->query("SELECT COUNT(*) as total FROM utilisateurs");
$totalUsers = (int)$stmtUsers->fetch(PDO::FETCH_ASSOC)['total'];

// Total notes
$stmtNotes = $db->query("SELECT COUNT(*) as total FROM notes_films");
$totalNotes = (int)$stmtNotes->fetch(PDO::FETCH_ASSOC)['total'];

// Note moyenne globale (moyenne des 3 criteres)
$stmtAvg = $db->query("SELECT AVG((scenario + jeu_acteur + qualite_av) / 3) as avg_global FROM notes_films");
$avgGlobal = round((float)($stmtAvg->fetch(PDO::FETCH_ASSOC)['avg_global'] ?? 0), 1);

// Nombre de films distincts notes
$stmtMovies = $db->query("SELECT COUNT(DISTINCT imdb_id) as total FROM notes_films");
$totalMovies = (int)$stmtMovies->fetch(PDO::FETCH_ASSOC)['total'];

// Distribution des notes (1-5 etoiles basee sur la moyenne des 3 criteres)
$stmtDist = $db->query("
    SELECT 
        FLOOR((scenario + jeu_acteur + qualite_av) / 3) as star,
        COUNT(*) as cnt
    FROM notes_films
    GROUP BY star
    ORDER BY star DESC
");
$distribution = [1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0];
while ($row = $stmtDist->fetch(PDO::FETCH_ASSOC)) {
    $s = max(1, min(5, (int)$row['star']));
    $distribution[$s] += (int)$row['cnt'];
}

// Dernières notes (activite recente)
$stmtRecent = $db->query("
    SELECT nf.id, nf.imdb_id, nf.scenario, nf.jeu_acteur, nf.qualite_av, nf.commentaire,
           u.pseudo
    FROM notes_films nf
    JOIN utilisateurs u ON u.id = nf.id_utilisateur
    ORDER BY nf.id DESC
    LIMIT 10
");
$recentActivity = $stmtRecent->fetchAll(PDO::FETCH_ASSOC);

// Films les plus notes
$stmtPopular = $db->query("
    SELECT imdb_id,
           COUNT(*) as review_count,
           AVG((scenario + jeu_acteur + qualite_av) / 3) as avg_rating
    FROM notes_films
    GROUP BY imdb_id
    ORDER BY review_count DESC
    LIMIT 10
");
$popularMovies = $stmtPopular->fetchAll(PDO::FETCH_ASSOC);

http_response_code(200);
echo json_encode([
    "total_users" => $totalUsers,
    "total_notes" => $totalNotes,
    "total_movies" => $totalMovies,
    "avg_global" => $avgGlobal,
    "distribution" => $distribution,
    "recent_activity" => $recentActivity,
    "popular_movies" => $popularMovies
]);
