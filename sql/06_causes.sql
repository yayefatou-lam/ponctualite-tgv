-- 06_causes.sql
-- Table des causes au format « long » : une ligne par liaison, par mois et par cause
CREATE OR REPLACE TABLE causes AS
SELECT mois,
       service,
       liaison,
       cause,
       pct                                AS pct_cause,
       pct / 100 * nb_retards_15min       AS nb_retards_cause   -- nombre de trains en retard (> 15 min) attribués à cette cause
FROM (
    UNPIVOT ponctualite
    ON pct_cause_externe        AS 'Causes externes (météo, obstacles, malveillance…)',
       pct_cause_infrastructure AS 'Infrastructure (voies, signalisation, travaux)',
       pct_cause_gestion_trafic AS 'Gestion du trafic',
       pct_cause_materiel       AS 'Matériel roulant',
       pct_cause_gare           AS 'Gestion en gare et réutilisation de matériel',
       pct_cause_voyageurs      AS 'Prise en compte des voyageurs'
    INTO NAME cause VALUE pct
);

-- Contrôles : 6 causes par ligne ayant des causes connues (12 834 - 199 = 12 635 lignes, soit 75 810)
SELECT COUNT(*) AS nb_lignes, COUNT(DISTINCT cause) AS nb_causes FROM causes;

-- Part de chaque cause sur toute la période, pondérée par le nombre de trains en retard
SELECT cause,
       round(100 * SUM(nb_retards_cause) / SUM(SUM(nb_retards_cause)) OVER (), 1) AS part_pct
FROM causes
GROUP BY cause
ORDER BY part_pct DESC;

-- Export pour Tableau
INSTALL excel;
LOAD excel;
COPY causes TO 'data/causes.xlsx' WITH (FORMAT xlsx, HEADER true);