-- 13 : un point par gare (hors Paris) et par année, avec la moyenne nationale de l'année

CREATE OR REPLACE TABLE carte_gares_annees AS
WITH trains_par_gare AS (
    -- chaque train compte pour sa gare de départ ET sa gare d'arrivée
    SELECT year(mois) AS annee, gare_depart AS gare, nb_retards_15min, nb_trains_partis
    FROM ponctualite
    UNION ALL
    SELECT year(mois), gare_arrivee, nb_retards_15min, nb_trains_partis
    FROM ponctualite
),
national AS (
    -- moyenne nationale : chaque train compté une seule fois
    SELECT year(mois) AS annee,
           SUM(nb_retards_15min) / SUM(nb_trains_partis) AS taux_national
    FROM ponctualite
    GROUP BY 1
)
SELECT
    t.annee, t.gare, c.nom_ref, c.latitude, c.longitude,
    SUM(t.nb_retards_15min) AS nb_retards_15min,
    SUM(t.nb_trains_partis) AS nb_trains_partis,
    n.taux_national
FROM trains_par_gare t
JOIN gares_coord c USING (gare)
JOIN national n USING (annee)
WHERE t.gare NOT LIKE 'PARIS %'
GROUP BY ALL;

-- Contrôle 1 : nombre de gares par année (53 ou 54 attendues)
SELECT annee, COUNT(*) AS nb_gares, ROUND(100 * ANY_VALUE(taux_national), 1) AS national_pct
FROM carte_gares_annees GROUP BY annee ORDER BY annee;

-- Contrôle 2 : 2025 doit redonner les chiffres de la carte actuelle (Nice 19,2 %, national 11,3 %)
SELECT gare, ROUND(100 * nb_retards_15min / nb_trains_partis, 1) AS taux_pct
FROM carte_gares_annees
WHERE annee = 2025 AND gare IN ('NICE VILLE', 'RENNES', 'STUTTGART');

INSTALL excel; LOAD excel;
COPY carte_gares_annees TO 'data/carte_gares_annees.xlsx' WITH (FORMAT xlsx, HEADER true);