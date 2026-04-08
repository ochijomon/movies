<?php
class Movie {
    private $conn;
    private $apiKey;

    public function __construct($db) {
        $this->conn = $db;
        // On récupère ta clé Windows que tu as testée avec succès
        $this->apiKey = getenv('IMDB_API_KEY');
    }

    // Méthode pour chercher sur l'API IMDB (OMDb)
    public function search($title) {
        $url = "http://www.omdbapi.com/?s=" . urlencode($title) . "&apikey=" . $this->apiKey;
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        $response = curl_exec($ch);
        curl_close($ch);

        return json_decode($response, true);
    }

    // Méthode pour avoir les détails d'un film spécifique + TES notes locales
    public function getDetails($imdbId) {
        $url = "http://www.omdbapi.com/?i=" . $imdbId . "&apikey=" . $this->apiKey;
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        $response = curl_exec($ch);
        curl_close($ch);

        $data = json_decode($response, true);

        // Optionnel : Ici tu pourras ajouter une requête SQL pour récupérer 
        // la moyenne des notes (Scenario, Jeu, AV) stockées dans ta BDD.
        
        return $data;
    }
}