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

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$imdbId = isset($_GET['imdb_id']) ? $_GET['imdb_id'] : "";

if ($userId <= 0) {
    http_response_code(400);
    echo json_encode(["message" => "Parametre user_id manquant."]);
    exit;
}

// Si imdb_id fourni, verifier si l'utilisateur a deja note ce film
if (!empty($imdbId)) {
    $stmt = $db->prepare("SELECT id, scenario, jeu_acteur, qualite_av, commentaire FROM notes_films WHERE id_utilisateur = :uid AND imdb_id = :mid");
    $stmt->execute([':uid' => $userId, ':mid' => $imdbId]);
    $existing = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($existing) {
        http_response_code(200);
        echo json_encode(["already_rated" => true, "rating" => $existing]);
    } else {
        http_response_code(200);
        echo json_encode(["already_rated" => false]);
    }
    exit;
}

// Sinon, retourner toutes les notes de l'utilisateur
$stmt = $db->prepare("SELECT id, imdb_id, scenario, jeu_acteur, qualite_av, commentaire, date_notation FROM notes_films WHERE id_utilisateur = :uid ORDER BY id DESC");
$stmt->execute([':uid' => $userId]);
$ratings = $stmt->fetchAll(PDO::FETCH_ASSOC);

http_response_code(200);
echo json_encode($ratings);
