-- 07 : import du référentiel des gares SNCF (Gares & Connexions, data.gouv.fr)
CREATE OR REPLACE TABLE gares_ref AS
SELECT * FROM read_csv('data/gares-de-voyageurs.csv', delim = ';', header = true);

DESCRIBE gares_ref;
SELECT * FROM gares_ref LIMIT 5;
SELECT COUNT(*) AS nb_gares FROM gares_ref;