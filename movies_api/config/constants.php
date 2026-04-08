<?php

// On récupère la clé directement depuis Windows
$sysApiKey = getenv('IMDB_API_KEY');

if (!$sysApiKey) {
    $sysApiKey = $_SERVER['IMDB_API_KEY'] ?? null;
}

// Fallback : clé en dur si la variable d'environnement n'est pas accessible par Apache
if (!$sysApiKey) {
    $sysApiKey = 'c7051e7b';
}

// Définition des constantes
define('IMDB_API_KEY', $sysApiKey);
define('IMDB_API_URL', 'http://www.omdbapi.com/');

// Vérification de sécurité pour ton dossier de maintenance
if (empty(IMDB_API_KEY)) {
    error_log("ALERTE MAINTENANCE : Clé API introuvable dans le système.");
}

define('APP_NAME', 'Books & Movies API');
?>