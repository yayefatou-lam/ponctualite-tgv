-- 12 : un point par gare (hors Paris), ponctualité 2025 des TGV qui la desservent

CREATE OR REPLACE TABLE carte_gares AS
WITH trains_par_gare AS (
    -- chaque train compte pour sa gare de départ ET sa gare d'arrivée
    SELECT gare_depart AS gare, nb_retards_15min, nb_trains_partis
    FROM ponctualite WHERE year(mois) = 2025
    UNION ALL
    SELECT gare_arrivee, nb_retards_15min, nb_trains_partis
    FROM ponctualite WHERE year(mois) = 2025
)
SELECT
    t.gare, c.nom_ref, c.latitude, c.longitude,
    SUM(t.nb_retards_15min) AS nb_retards_15min,
    SUM(t.nb_trains_partis) AS nb_trains_partis
FROM trains_par_gare t
JOIN gares_coord c USING (gare)
WHERE t.gare NOT LIKE 'PARIS %'
GROUP BY ALL;

-- Contrôle : 53 gares attendues (Madrid n'a pas de train en 2025)
SELECT COUNT(*) AS nb_gares FROM carte_gares;

-- Aperçu : les 5 moins ponctuelles (Stuttgart 39,0 % en tête attendu)
SELECT gare, ROUND(100 * nb_retards_15min / nb_trains_partis, 1) AS taux_pct
FROM carte_gares ORDER BY taux_pct DESC LIMIT 5;

INSTALL excel; LOAD excel;
COPY carte_gares TO 'data/carte_gares.xlsx' WITH (FORMAT xlsx, HEADER true);