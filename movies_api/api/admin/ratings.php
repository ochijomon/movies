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

$query = "
    SELECT nf.id, nf.imdb_id, nf.scenario, nf.jeu_acteur, nf.qualite_av, nf.commentaire,
           u.pseudo
    FROM notes_films nf
    JOIN utilisateurs u ON u.id = nf.id_utilisateur
    ORDER BY nf.id DESC
";

$stmt = $db->prepare($query);
$stmt->execute();
$ratings = $stmt->fetchAll(PDO::FETCH_ASSOC);

http_response_code(200);
echo json_encode($ratings);
