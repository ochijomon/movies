<?php
class Rating {
    private $conn;
    private $table_name = "notes_films";

    public $imdb_id;
    public $id_utilisateur;
    public $scenario;
    public $jeu_acteur;
    public $qualite_av;
    public $commentaire;

    public function __construct($db) {
        $this->conn = $db;
    }

    // Créer une note
    public function create() {
        // 1. Vérifier si l'utilisateur a déjà noté ce film (Contrainte Source 10)
        $checkQuery = "SELECT id FROM " . $this->table_name . " WHERE imdb_id = :imdb_id AND id_utilisateur = :id_user";
        $checkStmt = $this->conn->prepare($checkQuery);
        $checkStmt->execute([':imdb_id' => $this->imdb_id, ':id_user' => $this->id_utilisateur]);

        if($checkStmt->rowCount() > 0) {
            return "already_rated";
        }

        // 2. Insertion de la note
        $query = "INSERT INTO " . $this->table_name . " 
                SET imdb_id=:imdb_id, id_utilisateur=:id_user, scenario=:scen, jeu_acteur=:jeu, qualite_av=:qav, commentaire=:comm";

        $stmt = $this->conn->prepare($query);

        return $stmt->execute([
            ':imdb_id' => $this->imdb_id,
            ':id_user' => $this->id_utilisateur,
            ':scen'    => $this->scenario,
            ':jeu'     => $this->jeu_acteur,
            ':qav'     => $this->qualite_av,
            ':comm'    => $this->commentaire
        ]);
    }
}
?>