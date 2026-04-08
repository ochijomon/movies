<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

require_once '../../config/constants.php';
require_once '../../config/database.php';
require_once '../../src/Models/Movie.php';

$database = new Database();
$db = $database->getConnection();
$movie = new Movie($db);

// On récupère le texte tapé par l'utilisateur (ex: search.php?s=Inception)
$keywords = isset($_GET['s']) ? $_GET['s'] : "";

if(!empty($keywords)){
    $results = $movie->search($keywords); // On va créer cette méthode dans Movie.php
    
    if(isset($results['Search'])){
        http_response_code(200);
        echo json_encode($results['Search']);
    } else {
        http_response_code(404);
        echo json_encode(["message" => "Aucun film trouvé pour : " . $keywords]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Veuillez saisir un titre de film."]);
}