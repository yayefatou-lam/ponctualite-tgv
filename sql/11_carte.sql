-- 11 : table de la carte, un axe par paire de gares (les deux sens regroupés), année 2025

CREATE OR REPLACE TABLE carte_axes AS
WITH paires AS (
    SELECT
        least(gare_depart, gare_arrivee)    AS gare_a,  -- ordre alphabétique :
        greatest(gare_depart, gare_arrivee) AS gare_b,  -- A-B et B-A deviennent le même axe
        SUM(nb_retards_15min) AS nb_retards_15min,
        SUM(nb_trains_partis) AS nb_trains_partis
    FROM ponctualite
    WHERE year(mois) = 2025
    GROUP BY 1, 2
)
SELECT
    p.gare_a || ' - ' || p.gare_b AS axe,
    p.gare_a, a.latitude AS lat_a, a.longitude AS lon_a,
    p.gare_b, b.latitude AS lat_b, b.longitude AS lon_b,
    p.nb_retards_15min,
    p.nb_trains_partis
FROM paires p
JOIN gares_coord a ON a.gare = p.gare_a
JOIN gares_coord b ON b.gare = p.gare_b;

-- Contrôle 1 : 61 axes attendus
SELECT COUNT(*) AS nb_axes FROM carte_axes;

-- Contrôle 2 : aucun axe sans coordonnées (0 attendu)
SELECT COUNT(*) AS sans_coord FROM carte_axes
WHERE lat_a IS NULL OR lat_b IS NULL;

-- Contrôle 3 : mêmes totaux que la table ponctualite pour 2025
-- attendu : 434 624 trains partis et 11,32 % de retards > 15 min
SELECT SUM(nb_trains_partis) AS trains_partis,
       ROUND(100 * SUM(nb_retards_15min) / SUM(nb_trains_partis), 2) AS taux_pct
FROM carte_axes;

-- Export pour Tableau
INSTALL excel; LOAD excel;
COPY carte_axes TO 'data/carte_axes.xlsx' WITH (FORMAT xlsx, HEADER true);