<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");

require_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->pseudo) && !empty($data->password)) {
    
    // On cherche l'utilisateur par son pseudo
    $query = "SELECT id, pseudo, password FROM utilisateurs WHERE pseudo = :p LIMIT 0,1";
    $stmt = $db->prepare($query);
    $stmt->execute([':p' => $data->pseudo]);
    
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    // Si l'utilisateur existe et que le mot de passe correspond (vérification du hash)
    if($user && password_verify($data->password, $user['password'])) {
        http_response_code(200);
        echo json_encode([
            "message" => "Connexion réussie",
            "id" => $user['id'],
            "pseudo" => $user['pseudo']
        ]);
    } else {
        http_response_code(401);
        echo json_encode(["message" => "Pseudo ou mot de passe incorrect."]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes."]);
}