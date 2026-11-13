-- 02_diagnostic.sql
-- Diagnostic de la table brute : chaque requête correspond à une ligne de NETTOYAGE.md

-- Décision 1 : types des colonnes (Date importée en texte)
DESCRIBE brut;

-- Décision 2 : doublons apparents sur mois + liaison
SELECT "Date", COUNT(*) AS nb_liaisons_en_double
FROM (
    SELECT "Date", trim("Gare de départ") AS depart, trim("Gare d'arrivée") AS arrivee
    FROM brut
    GROUP BY "Date", depart, arrivee
    HAVING COUNT(*) > 1
)
GROUP BY "Date"
ORDER BY "Date";

-- Exemple : les deux lignes diffèrent par le service (National / International)
SELECT "Date", "Service", "Gare de départ", "Gare d'arrivée",
       "Nombre de circulations prévues", "Nombre de trains en retard à l'arrivée"
FROM brut
WHERE "Date" = '2025-07'
  AND "Gare de départ" = 'BELLEGARDE (AIN)'
  AND "Gare d'arrivée" = 'PARIS LYON';

-- Vérification : avec le service dans la clé, plus aucun doublon (attendu : 0 ligne)
SELECT "Date", "Service", "Gare de départ", "Gare d'arrivée", COUNT(*) AS nb_lignes
FROM brut
GROUP BY ALL
HAVING COUNT(*) > 1;

-- Décisions 3 et 4 : noms de gares (espaces en trop, orthographes différentes)
SELECT COUNT(*) AS nb_noms_mal_formes
FROM brut
WHERE "Gare de départ" <> trim("Gare de départ")
   OR "Gare d'arrivée" <> trim("Gare d'arrivée");

SELECT gare, COUNT(*) AS nb_lignes
FROM (
    SELECT "Gare de départ" AS gare FROM brut
    UNION ALL
    SELECT "Gare d'arrivée" FROM brut
)
GROUP BY gare
ORDER BY gare;

-- Décisions 5 à 8 : la somme des 6 causes de retard fait-elle 100 % ?
WITH causes AS (
    SELECT *,
           "Prct retard pour causes externes" + "Prct retard pour cause infrastructure"
         + "Prct retard pour cause gestion trafic" + "Prct retard pour cause matériel roulant"
         + "Prct retard pour cause gestion en gare et réutilisation de matériel"
         + "Prct retard pour cause prise en compte voyageurs (affluence, gestions PSH, correspondances)" AS somme_causes
    FROM brut
)
SELECT round(somme_causes, 1) AS somme_causes, COUNT(*) AS nb_lignes
FROM causes
GROUP BY ALL
ORDER BY somme_causes;

-- Lignes à 0 % : y avait-il des retards ? des trains ?
WITH causes AS (
    SELECT *,
           "Prct retard pour causes externes" + "Prct retard pour cause infrastructure"
         + "Prct retard pour cause gestion trafic" + "Prct retard pour cause matériel roulant"
         + "Prct retard pour cause gestion en gare et réutilisation de matériel"
         + "Prct retard pour cause prise en compte voyageurs (affluence, gestions PSH, correspondances)" AS somme_causes
    FROM brut
)
SELECT ("Nombre trains en retard > 15min" > 0) AS a_des_retards_15min,
       ("Nombre de circulations prévues" = 0)  AS aucun_train_prevu,
       COUNT(*) AS nb_lignes
FROM causes
WHERE somme_causes = 0
GROUP BY ALL
ORDER BY nb_lignes DESC;

-- Liaisons sans aucun train prévu : quels mois ? (premier confinement)
SELECT "Date", COUNT(*) AS nb_liaisons_sans_train
FROM brut
WHERE "Nombre de circulations prévues" = 0
GROUP BY "Date"
ORDER BY "Date";

-- Décisions 11 à 15 : cohérence entre les colonnes
SELECT
    SUM(CASE WHEN "Nombre de trains annulés" > "Nombre de circulations prévues" THEN 1 ELSE 0 END) AS annules_sup_prevus,
    SUM(CASE WHEN "Nombre de trains en retard à l'arrivée"
                  > "Nombre de circulations prévues" - "Nombre de trains annulés" THEN 1 ELSE 0 END) AS retards_sup_trains_partis,
    SUM(CASE WHEN "Nombre trains en retard > 15min" > "Nombre de trains en retard à l'arrivée" THEN 1 ELSE 0 END) AS retards15_sup_retards,
    SUM(CASE WHEN "Nombre trains en retard > 30min" > "Nombre trains en retard > 15min" THEN 1 ELSE 0 END) AS retards30_sup_retards15,
    SUM(CASE WHEN "Nombre trains en retard > 60min" > "Nombre trains en retard > 30min" THEN 1 ELSE 0 END) AS retards60_sup_retards30
FROM brut;

-- Gros retards mois par mois autour de début 2025
SELECT "Date",
       SUM("Nombre trains en retard > 15min") AS retards_15,
       SUM("Nombre trains en retard > 30min") AS retards_30,
       SUM("Nombre trains en retard > 60min") AS retards_60
FROM brut
WHERE "Date" BETWEEN '2024-10' AND '2025-06'
GROUP BY "Date"
ORDER BY "Date";

-- Valeurs négatives
SELECT
    SUM(CASE WHEN "Nombre trains en retard > 30min" < 0 THEN 1 ELSE 0 END)                 AS neg_retards_30,
    SUM(CASE WHEN "Retard moyen des trains en retard à l'arrivée" < 0 THEN 1 ELSE 0 END)  AS neg_retard_moyen_en_retard,
    SUM(CASE WHEN "Retard moyen de tous les trains à l'arrivée" < 0 THEN 1 ELSE 0 END)    AS neg_retard_moyen_tous
FROM brut;