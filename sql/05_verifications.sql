-- 05_verifications.sql
-- Combien de liaisons se sont dégradées entre 2019 et 2025 ?
WITH evolution AS (
    SELECT liaison,
           SUM(nb_retards_15min) FILTER (WHERE year(mois) = 2019)
         / SUM(nb_trains_partis) FILTER (WHERE year(mois) = 2019) AS taux_2019,
           SUM(nb_retards_15min) FILTER (WHERE year(mois) = 2025)
         / SUM(nb_trains_partis) FILTER (WHERE year(mois) = 2025) AS taux_2025
    FROM ponctualite
    GROUP BY liaison
)
SELECT COUNT(*)                                     AS nb_liaisons_comparables,  -- présentes en 2019 et en 2025
       COUNT(*) FILTER (WHERE taux_2025 > taux_2019) AS nb_liaisons_degradees
FROM evolution
WHERE taux_2019 IS NOT NULL AND taux_2025 IS NOT NULL;