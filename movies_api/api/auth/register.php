<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Preflight CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../../config/database.php';

$database = new Database();
$db = $database->getConnection();

// Lire les données reçues (JSON)
$data = json_decode(file_get_contents("php://input"));

if(!empty($data->pseudo) && !empty($data->email) && !empty($data->password)) {
    
    // Requête SQL
    $query = "INSERT INTO utilisateurs (pseudo, email, password) VALUES (:p, :e, :pass)";
    $stmt = $db->prepare($query);

    // Sécurité : Hachage du mot de passe
    $password_hash = password_hash($data->password, PASSWORD_BCRYPT);

    try {
        if($stmt->execute([
            ':p' => $data->pseudo, 
            ':e' => $data->email, 
            ':pass' => $password_hash
        ])) {
            http_response_code(201);
            echo json_encode(["message" => "Utilisateur créé avec succès !"]);
        }
    } catch (PDOException $e) {
        http_response_code(400);
        // Souvent une erreur si le pseudo ou l'email existe déjà (UNIQUE en BDD)
        echo json_encode(["message" => "Erreur : Pseudo ou Email déjà utilisé."]);
    }
} else {
    http_response_code(400);
    echo json_encode(["message" => "Données incomplètes."]);
}