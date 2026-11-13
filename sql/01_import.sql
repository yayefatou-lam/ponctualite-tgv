-- 01_import.sql
-- Import du fichier brut, sans rien modifier : on garde toujours une copie intacte des données d'origine
CREATE OR REPLACE TABLE brut AS
SELECT *
FROM read_csv('data/regularite-mensuelle-tgv-aqst.csv', delim = ';', header = true);

-- Combien de lignes ?
SELECT COUNT(*) AS nb_lignes FROM brut;