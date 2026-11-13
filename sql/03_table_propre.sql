-- 03_table_propre.sql
-- Table d'analyse : applique toutes les décisions du journal de nettoyage (NETTOYAGE.md)
CREATE OR REPLACE TABLE ponctualite AS
WITH causes AS (
    -- somme des 6 causes, pour repérer les lignes où elles valent toutes 0
    SELECT *,
           "Prct retard pour causes externes" + "Prct retard pour cause infrastructure"
         + "Prct retard pour cause gestion trafic" + "Prct retard pour cause matériel roulant"
         + "Prct retard pour cause gestion en gare et réutilisation de matériel"
         + "Prct retard pour cause prise en compte voyageurs (affluence, gestions PSH, correspondances)" AS somme_causes
    FROM brut
)
SELECT
    -- Identification d'une ligne : mois + service + liaison (décisions 1 et 2)
    CAST("Date" || '-01' AS DATE)                         AS mois,
    "Service"                                             AS service,
    "Gare de départ"                                      AS gare_depart,
    "Gare d'arrivée"                                      AS gare_arrivee,
    "Gare de départ" || ' - ' || "Gare d'arrivée"         AS liaison,
    "Durée moyenne du trajet"                             AS duree_moyenne_min,

    -- Volumes
    "Nombre de circulations prévues"                      AS nb_trains_prevus,
    "Nombre de trains annulés"                            AS nb_trains_annules,
    "Nombre de circulations prévues" - "Nombre de trains annulés" AS nb_trains_partis,

    -- Retards au départ
    "Nombre de trains en retard au départ"                AS nb_retards_depart,
    "Retard moyen des trains en retard au départ"         AS retard_moy_depart_en_retard,
    "Retard moyen de tous les trains au départ"           AS retard_moy_depart_tous,

    -- Retards à l'arrivée
    "Nombre de trains en retard à l'arrivée"              AS nb_retards_arrivee,
    CASE WHEN "Retard moyen des trains en retard à l'arrivée" < 0 THEN NULL             -- décision 13
         ELSE "Retard moyen des trains en retard à l'arrivée" END AS retard_moy_arrivee_en_retard,
    "Retard moyen de tous les trains à l'arrivée"         AS retard_moy_arrivee_tous,   -- négatif possible : décision 14
    "Nombre trains en retard > 15min"                     AS nb_retards_15min,
    CASE WHEN "Date" BETWEEN '2025-01' AND '2025-03' THEN NULL                          -- décision 12
         ELSE "Nombre trains en retard > 30min" END       AS nb_retards_30min,
    CASE WHEN "Date" BETWEEN '2025-01' AND '2025-03' THEN NULL
         ELSE "Nombre trains en retard > 60min" END       AS nb_retards_60min,

    -- Causes des retards de plus de 15 min, en % (NULL quand elles valent toutes 0 : décisions 6 et 7)
    CASE WHEN somme_causes = 0 THEN NULL ELSE "Prct retard pour causes externes" END                       AS pct_cause_externe,
    CASE WHEN somme_causes = 0 THEN NULL ELSE "Prct retard pour cause infrastructure" END                  AS pct_cause_infrastructure,
    CASE WHEN somme_causes = 0 THEN NULL ELSE "Prct retard pour cause gestion trafic" END                  AS pct_cause_gestion_trafic,
    CASE WHEN somme_causes = 0 THEN NULL ELSE "Prct retard pour cause matériel roulant" END                AS pct_cause_materiel,
    CASE WHEN somme_causes = 0 THEN NULL ELSE "Prct retard pour cause gestion en gare et réutilisation de matériel" END AS pct_cause_gare,
    CASE WHEN somme_causes = 0 THEN NULL
         ELSE "Prct retard pour cause prise en compte voyageurs (affluence, gestions PSH, correspondances)" END    AS pct_cause_voyageurs,

    -- Commentaire sur les incidents du mois (décision 9 : les deux autres colonnes, vides, sont retirées)
    "Commentaire retards à l'arrivée"                     AS commentaire_incidents
FROM causes
WHERE "Nombre de circulations prévues" > 0;                                             -- décision 5


-- Contrôles après nettoyage
SELECT COUNT(*)                                          AS nb_lignes,           -- attendu : 12 907 - 73 = 12 834
       COUNT(*) FILTER (WHERE pct_cause_externe IS NULL) AS causes_vides,        -- attendu : 119 + 80 = 199
       COUNT(*) FILTER (WHERE nb_retards_30min IS NULL)  AS retards30_vides,     -- attendu : 363
       MIN(mois) AS premier_mois, MAX(mois) AS dernier_mois
FROM ponctualite;