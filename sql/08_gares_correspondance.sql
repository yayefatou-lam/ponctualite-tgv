-- 08 : rapprochement des gares de l'AQST avec le référentiel SNCF

-- Macro de normalisation des noms : majuscules, sans accents, tirets et apostrophes
-- remplacés par des espaces, ST -> SAINT, espaces multiples réduits à un seul
CREATE OR REPLACE MACRO normaliser(nom) AS
    trim(regexp_replace(
        regexp_replace(
            replace(replace(upper(strip_accents(nom)), '-', ' '), '''', ' '),
            '\bST\b', 'SAINT', 'g'),
        '\s+', ' ', 'g'));

-- Référentiel : nom normalisé + latitude et longitude séparées
CREATE OR REPLACE TABLE gares_ref_propre AS
SELECT
    Nom_Gare AS nom_ref,
    normaliser(Nom_Gare) AS nom_norm,
    CAST(trim(split_part("Position géographique", ',', 1)) AS DOUBLE) AS latitude,
    CAST(trim(split_part("Position géographique", ',', 2)) AS DOUBLE) AS longitude
FROM gares_ref;

-- Contrôle : un même nom normalisé ne doit pas renvoyer à deux gares
SELECT nom_norm, COUNT(*) AS n
FROM gares_ref_propre
GROUP BY nom_norm
HAVING COUNT(*) > 1;

-- Nos 59 gares
CREATE OR REPLACE TABLE nos_gares AS
SELECT DISTINCT gare, normaliser(gare) AS nom_norm
FROM (SELECT gare_depart AS gare FROM ponctualite
      UNION
      SELECT gare_arrivee FROM ponctualite);

-- Gares trouvées automatiquement
SELECT COUNT(*) AS trouvees
FROM nos_gares n JOIN gares_ref_propre r USING (nom_norm);

-- Gares sans correspondance : à traiter à la main
SELECT n.gare
FROM nos_gares n
LEFT JOIN gares_ref_propre r USING (nom_norm)
WHERE r.nom_norm IS NULL
ORDER BY n.gare;