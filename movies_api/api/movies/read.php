<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/database.php';
require_once '../../src/Models/Movie.php';

$database = new Database();
$db = $database->getConnection();
$movie = new Movie($db);

$id = isset($_GET['id']) ? $_GET['id'] : "";

if(!empty($id)) {
    $data = $movie->getOne($id);
    if($data && $data['Response'] != "False") {
        http_response_code(200);
        echo json_encode($data);
    } else {
        http_response_code(404);
        echo json_encode(["message" => "Film introuvable."]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Paramètre 'id' manquant."]);
}
?>