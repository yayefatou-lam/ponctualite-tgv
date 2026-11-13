# Journal de nettoyage

Données : « Régularité mensuelle TGV par liaisons » (SNCF, AQST), janvier 2018 à septembre 2026.
Import brut : 12 907 lignes, 26 colonnes, table `brut` conservée intacte.
Fichiers : `sql/01_import.sql` à `sql/05_verifications.sql`.

| # | Problème constaté | Comment je l'ai vérifié | Décision | Lignes concernées |
|---|---|---|---|---|
| 1 | `Date` importée en texte (« 2018-01 ») | `DESCRIBE brut` | convertir en date (1er jour du mois) | toutes |
| 2 | 42 « doublons » apparents (même mois, même liaison), tous entre juillet et septembre 2025 | regroupement par date et liaison, puis comparaison des lignes | pas de vrais doublons : un flux National et un flux International sur la même liaison. Lignes conservées ; la clé d'une ligne est date + service + gare de départ + gare d'arrivée | 84 lignes (42 paires) |
| 3 | Espaces en trop ou orthographes différentes dans les noms de gares ? | comparaison avec `trim()`, liste des 59 gares | rien à corriger. Seule incohérence : « SAINT » et « ST » selon les gares, conservée car elle n'empêche pas l'analyse (aucune gare en double) | aucune |
| 4 | `ITALIE` n'est pas une gare mais un regroupement de destinations | liste des gares | conservé, signalé comme destination regroupée | 202 |
| 5 | Liaisons sans aucun train prévu (0 circulation) | filtre sur le nombre de circulations prévues, puis répartition par mois | retirées de la table d'analyse : aucune ponctualité à mesurer, taux impossibles à calculer (division par zéro). Correspondent au premier confinement (50 liaisons en avril 2020) puis à des liaisons restées suspendues fin 2020 (Marseille – Madrid) | 73 |
| 6 | Causes de retard à 0 % alors qu'aucun train n'a eu plus de 15 min de retard | somme des 6 causes, croisée avec le nombre de trains en retard | causes mises à `NULL` (aucune cause à répartir) : un 0 fausserait les moyennes | 119 |
| 7 | Causes de retard à 0 % alors que des trains ont eu plus de 15 min de retard | même requête | causes mises à `NULL` (information manquante) | 80 |
| 8 | Somme des causes entre 84,6 et 99,1 % au lieu de 100 % | même requête, filtrée sur 0 < somme < 100 | conservées telles quelles et signalées : uniquement juin à septembre 2026, données probablement provisoires. Pas de correction, pour ne pas inventer de valeurs | 10 |
| 9 | Commentaires sur les annulations et les retards au départ toujours vides | comptage des valeurs vides | colonnes retirées | toutes |
| 10 | Colonne « Retard moyen trains en retard > 15 (si liaison concurrencée par vol) » ambiguë, identique à une autre colonne dans 17 % des lignes | comparaison des deux colonnes | colonne retirée : sens incertain, inutile pour l'analyse | toutes |
| 11 | Plus d'annulations que de trains prévus, ou plus de retards que de trains partis | contrôles de cohérence (`CASE WHEN`) | mêmes 63 lignes, toutes d'avril à juin 2020 avec 0 train prévu : déjà retirées (décision 5) | 63 |
| 12 | Janvier à mars 2025 : trains en retard de plus de 30 min négatifs, et plus de 60 min supérieur à plus de 30 min | contrôles de cohérence, puis totaux mois par mois | colonnes « > 30 min » et « > 60 min » mises à `NULL` pour ces trois mois (colonnes visiblement mélangées, correction impossible à vérifier) | 363 |
| 13 | Retard moyen des trains en retard à l'arrivée négatif | recherche des valeurs négatives | mis à `NULL` : un train en retard ne peut pas avoir un retard négatif | 2 |
| 14 | Retard moyen de tous les trains à l'arrivée négatif | même requête | conservé : les trains en avance comptent en négatif, une moyenne négative est possible | 122 |
| 15 | Plus de trains en retard de plus de 15 min que de trains en retard à l'arrivée (2018-2020), ou plus de 30 min que de 15 min | contrôles de cohérence | conservé et signalé : écarts faibles, probablement des règles de comptage différentes | 31 + 3 |

## Résultat

Table d'analyse `ponctualite` : 12 834 lignes (12 907 - 73 liaisons sans train), 25 colonnes, janvier 2018 à septembre 2026.

Contrôles après nettoyage, tous conformes aux valeurs attendues :
- 12 834 lignes ;
- 199 lignes sans causes de retard (119 + 80, décisions 6 et 7) ;
- 363 lignes sans retards de plus de 30 et 60 min (janvier à mars 2025, décision 12) ;
- aucune ligne en double sur la clé mois + service + liaison.

Point d'attention pour l'analyse : les causes de retard portent sur les trains arrivés avec plus de 15 minutes de retard.

## Table des causes

Fichier : `sql/06_causes.sql`.

| # | Transformation | Pourquoi | Contrôle |
|---|---|---|---|
| 16 | Les 6 colonnes de causes passées en format long (`UNPIVOT`) : une ligne par liaison, mois et cause | format adapté aux graphiques par catégorie | 75 810 lignes = 12 635 × 6 |
| 17 | Chaque pourcentage converti en nombre de trains en retard attribués à la cause (pourcentage × trains en retard de plus de 15 min) | calculer des parts pondérées : une liaison avec 500 trains en retard pèse plus qu'une liaison qui en a 5 | parts sur toute la période : externes 23,4 %, infrastructure 20,3 %, trafic 20,0 %, matériel 19,1 %, gare 9,2 %, voyageurs 8,0 % |

## Coordonnées des gares

Les données AQST ne donnent que des noms de gares, sans coordonnées. Je les ai rapprochées du référentiel « Gares de voyageurs » de SNCF Gares & Connexions (data.gouv.fr, 2 792 gares), qui contient la latitude et la longitude de chaque gare. Fichiers : `sql/07_gares_import.sql` à `sql/10_gares_coordonnees.sql`.

| # | Problème constaté | Comment je l'ai vérifié | Décision | Lignes concernées |
|---|---|---|---|---|
| 18 | Les noms ne s'écrivent pas pareil dans les deux sources (`BORDEAUX ST JEAN` / « Bordeaux Saint-Jean ») | Comparaison des deux listes | Normalisation des deux côtés : majuscules, sans accents ni tirets, ST → SAINT, puis jointure sur le nom normalisé | 37 gares sur 59 rapprochées automatiquement |
| 19 | La position est une seule colonne de texte « latitude, longitude » | `DESCRIBE` et aperçu du référentiel | Découpage en deux colonnes numériques | toutes |
| 20 | Risque qu'un nom normalisé renvoie à deux gares | Recherche des noms normalisés en double dans le référentiel | Aucun doublon | 0 |
| 21 | 14 gares françaises ont un nom différent dans le référentiel (`PARIS LYON` / « Paris Gare de Lyon », `MACON LOCHE` / « Mâcon Loché TGV »…) | Recherche des candidats par motif (`sql/09_gares_candidats.sql`) | Choix à la main de la gare desservie par les TGV : gare TGV plutôt que gare de centre-ville quand les deux existent (Mâcon, Le Creusot, Valence) | 14 |
| 22 | `PARIS VAUGIRARD` n'existe pas dans le référentiel | Recherche par motif | Coordonnées de Paris Montparnasse, dont Vaugirard est un hall | 1 |
| 23 | `LILLE` est ambigu : Lille Europe et Lille Flandres | Liste des liaisons concernées : toutes province-province | Lille Europe ; Flandres est à 300 m, la différence est invisible sur la carte | 1 |
| 24 | `MONTPELLIER` est ambigu : Saint-Roch et Sud de France (ouverte fin 2018) | Les données AQST ne distinguent pas les deux gares | Saint-Roch, la gare historique ; écart de 4 km, invisible à l'échelle de la carte | 1 |
| 25 | 7 gares étrangères absentes du référentiel SNCF (Barcelone, Madrid, Francfort, Stuttgart, Genève, Lausanne, Zurich) | Recherche par motif : aucun résultat | Coordonnées de la gare principale saisies à la main (précision d'environ 100 m) | 7 |
| 26 | `ITALIE` n'est pas une gare : c'est un regroupement fait par l'AQST | Valeur unique sans équivalent | Placée à Turin Porta Susa, premier grand arrêt italien des TGV Paris – Milan | 1 |

Contrôles (`sql/10_gares_coordonnees.sql`) : 59 lignes pour 59 gares distinctes, aucune gare oubliée, répartition 37 automatiques / 14 manuelles dans le référentiel / 8 hors référentiel.

## Carte

Fichiers : `sql/11_carte.sql` à `sql/13_carte_gares_annees.sql`.

| # | Problème constaté | Comment je l'ai vérifié | Décision | Lignes concernées |
|---|---|---|---|---|
| 27 | Sur une carte, les deux sens d'une liaison (A → B et B → A) se superposent exactement | 121 liaisons en 2025, mais seulement 61 paires de gares | Regroupement par axe : taux recalculé sur le total des trains des deux sens. Le détail par sens reste dans les classements | 121 liaisons → 61 axes |
| 28 | Avec des traits, 51 axes sur 61 partent de Paris : la carte forme une étoile illisible | Essai de la carte par axes | Remplacée par un cercle par gare. La table `carte_axes` est conservée mais n'est pas utilisée | 61 axes → 53 gares |
| 29 | Les 5 gares parisiennes se superposeraient et écraseraient l'échelle des tailles (158 000 trains à Paris Gare de Lyon contre 52 000 à Lyon Part-Dieu) | Comparaison des volumes par gare | Gares parisiennes exclues de la carte, ce que précise le sous-titre | 5 gares |
| 30 | Un même train relie deux gares : à laquelle attribuer son retard ? | — | Il compte pour ses deux gares. La carte mesure la ponctualité des TGV qui desservent la gare, pas la responsabilité de la gare | toutes |
| 31 | Pour comparer les années entre elles, un seuil fixe n'a pas de sens (la moyenne nationale va de 8,2 % à 14,4 %) | Moyennes nationales par année identiques au graphique Évolution | Couleur = écart à la moyenne nationale de la même année, en points | toutes |