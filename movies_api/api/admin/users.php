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
    SELECT u.id, u.pseudo, u.email,
           COUNT(nf.id) as notes_count
    FROM utilisateurs u
    LEFT JOIN notes_films nf ON nf.id_utilisateur = u.id
    GROUP BY u.id, u.pseudo, u.email
    ORDER BY u.id DESC
";

$stmt = $db->prepare($query);
$stmt->execute();
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);

http_response_code(200);
echo json_encode($users);
