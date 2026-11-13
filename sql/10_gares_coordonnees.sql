-- 10 : table des coordonnées des 59 gares

CREATE OR REPLACE TABLE gares_coord AS
WITH
-- 37 gares rapprochées automatiquement (nom normalisé identique)
auto AS (
    SELECT n.gare, r.nom_ref, r.latitude, r.longitude,
           'automatique' AS methode
    FROM nos_gares n
    JOIN gares_ref_propre r USING (nom_norm)
),
-- 14 gares rapprochées à la main dans le référentiel SNCF
choix(gare, motif) AS (
    VALUES
    ('BELLEGARDE (AIN)',               'BELLEGARDE SUR VALSERINE'),
    ('DIJON VILLE',                    'DIJON'),
    ('LA ROCHELLE VILLE',              'LA ROCHELLE'),
    ('LE CREUSOT MONTCEAU MONTCHANIN', 'LE CREUSOT%TGV'),
    ('LILLE',                          'LILLE EUROPE'),
    ('MACON LOCHE',                    'MACON LOCHE TGV'),
    ('MARNE LA VALLEE',                'MARNE LA VALLEE CHESSY'),
    ('MONTPELLIER',                    'MONTPELLIER SAINT ROCH'),
    ('MULHOUSE VILLE',                 'MULHOUSE'),
    ('NICE VILLE',                     'NICE'),
    ('PARIS LYON',                     'PARIS GARE DE LYON'),
    ('PARIS NORD',                     'PARIS GARE DU NORD'),
    ('PARIS VAUGIRARD',                'PARIS MONTPARNASSE'),
    ('VALENCE ALIXAN TGV',             'VALENCE TGV RHONE ALPES SUD')
),
manuel AS (
    SELECT c.gare, r.nom_ref, r.latitude, r.longitude,
           'manuelle (référentiel SNCF)' AS methode
    FROM choix c
    JOIN gares_ref_propre r ON r.nom_norm LIKE c.motif
),
-- 8 gares hors du référentiel SNCF : coordonnées saisies à la main
etrangeres(gare, nom_ref, latitude, longitude) AS (
    VALUES
    ('BARCELONA', 'Barcelona Sants',            41.3792,  2.1405),
    ('MADRID',    'Madrid Puerta de Atocha',    40.4066, -3.6892),
    ('FRANCFORT', 'Frankfurt (Main) Hbf',       50.1071,  8.6632),
    ('STUTTGART', 'Stuttgart Hbf',              48.7843,  9.1819),
    ('GENEVE',    'Genève Cornavin',            46.2101,  6.1425),
    ('LAUSANNE',  'Lausanne',                   46.5168,  6.6291),
    ('ZURICH',    'Zürich HB',                  47.3782,  8.5402),
    ('ITALIE',    'Torino Porta Susa (choix)',  45.0717,  7.6654)
)
SELECT * FROM auto
UNION ALL
SELECT * FROM manuel
UNION ALL
SELECT gare, nom_ref, latitude, longitude, 'manuelle (hors référentiel)'
FROM etrangeres;

-- Contrôle 1 : 59 lignes et 59 gares distinctes attendues (pas de doublon)
SELECT COUNT(*) AS lignes, COUNT(DISTINCT gare) AS gares FROM gares_coord;

-- Contrôle 2 : aucune gare oubliée (résultat vide attendu)
SELECT gare FROM nos_gares
WHERE gare NOT IN (SELECT gare FROM gares_coord);

-- Contrôle 3 : répartition par méthode (37 / 14 / 8 attendus)
SELECT methode, COUNT(*) AS n FROM gares_coord GROUP BY methode ORDER BY n DESC;