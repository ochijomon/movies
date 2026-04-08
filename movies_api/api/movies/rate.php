<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");

require_once '../../config/database.php';
require_once '../../src/Models/Rating.php';

$database = new Database();
$db = $database->getConnection();
$rating = new Rating($db);

// On récupère les données envoyées (JSON)
$data = json_decode(file_get_contents("php://input"));

if(!empty($data->imdb_id) && !empty($data->id_utilisateur)) {
    $rating->imdb_id = $data->imdb_id;
    $rating->id_utilisateur = $data->id_utilisateur;
    $rating->scenario = $data->scenario;
    $rating->jeu_acteur = $data->jeu_acteur;
    $rating->qualite_av = $data->qualite_av;
    $rating->commentaire = $data->commentaire ?? "";

    $result = $rating->create();

    if($result === true) {
        http_response_code(201);
        echo json_encode(["message" => "Note enregistrée avec succès !"]);
    } elseif($result === "already_rated") {
        http_response_code(403);
        echo json_encode(["message" => "Vous avez déjà noté ce film."]);
    } else {
        http_response_code(503);
        echo json_encode(["message" => "Erreur lors de l'enregistrement."]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes."]);
}
?>