-- 04_export.sql
-- Export de la table propre pour Tableau
INSTALL excel;
LOAD excel;
COPY ponctualite TO 'data/ponctualite_propre.xlsx' WITH (FORMAT xlsx, HEADER true);