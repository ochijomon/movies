<?php
class Movie {
    private $conn;
    private $apiKey;

    public function __construct($db) {
        $this->conn = $db;
        $this->apiKey = getenv('IMDB_API_KEY');
    }

    public function search($title) {
        $url = "http://www.omdbapi.com/?s=" . urlencode($title) . "&apikey=" . $this->apiKey;
        return $this->httpCall($url);
    }

    public function getOne($imdbId) {
        // 1. Récupérer les infos IMDB
        $url = "http://www.omdbapi.com/?i=" . $imdbId . "&apikey=" . $this->apiKey;
        $movieData = $this->httpCall($url);

        if (!$movieData || $movieData['Response'] == 'False') return $movieData;

        // 2. Calculer les moyennes locales (SQL)
        $query = "SELECT 
                    AVG(scenario) as avg_scenario, 
                    AVG(jeu_acteur) as avg_jeu, 
                    AVG(qualite_av) as avg_av, 
                    COUNT(*) as total_reviews 
                  FROM notes_films 
                  WHERE imdb_id = :id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute([':id' => $imdbId]);
        $stats = $stmt->fetch(PDO::FETCH_ASSOC);

        // 3. Fusionner les stats dans l'objet final
        $movieData['local_ratings'] = [
            "avg_scenario" => round($stats['avg_scenario'] ?? 0, 1),
            "avg_acting" => round($stats['avg_jeu'] ?? 0, 1),
            "avg_visual" => round($stats['avg_av'] ?? 0, 1),
            "total_reviews" => $stats['total_reviews']
        ];

        return $movieData;
    }

    private function httpCall($url) {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        $response = curl_exec($ch);
        curl_close($ch);
        return json_decode($response, true);
    }
}