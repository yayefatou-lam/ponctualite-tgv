-- 09 : candidats du référentiel pour les gares sans correspondance automatique
WITH recherches(gare, motif) AS (
    VALUES
    ('BELLEGARDE (AIN)',               'BELLEGARDE%'),
    ('DIJON VILLE',                    'DIJON%'),
    ('LA ROCHELLE VILLE',              'LA ROCHELLE%'),
    ('LE CREUSOT MONTCEAU MONTCHANIN', '%CREUSOT%'),
    ('LILLE',                          'LILLE EUROPE'),
    ('MACON LOCHE',                    'MACON%'),
    ('MARNE LA VALLEE',                'MARNE LA VALLEE%'),
    ('MONTPELLIER',                    'MONTPELLIER%'),
    ('MULHOUSE VILLE',                 'MULHOUSE%'),
    ('NICE VILLE',                     'NICE%'),
    ('PARIS LYON',                     'PARIS GARE DE LYON'),
    ('PARIS NORD',                     'PARIS GARE DU NORD'),
    ('PARIS VAUGIRARD',                'PARIS MONTPARNASSE'),
    ('VALENCE ALIXAN TGV',             'VALENCE%'),
    ('GENEVE',                         'GENEVE%')
)
SELECT r.gare, g.nom_ref, g.latitude, g.longitude
FROM recherches r
LEFT JOIN gares_ref_propre g ON g.nom_norm LIKE r.motif
ORDER BY r.gare, g.nom_ref;