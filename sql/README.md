# Scripts SQL

Scripts DuckDB, à lancer dans l'ordre depuis la racine du projet (`duckdb ponctualite.duckdb`, puis `.read sql/01_import.sql`, etc.). Les décisions prises dans chaque script sont détaillées dans le [journal de nettoyage](../NETTOYAGE.md).

| Script | Rôle | Crée |
|---|---|---|
| `01_import.sql` | import du fichier brut, sans modification | `brut` |
| `02_diagnostic.sql` | diagnostic : doublons, valeurs manquantes, incohérences | (lecture seule) |
| `03_table_propre.sql` | table d'analyse nettoyée | `ponctualite` |
| `04_export.sql` | export pour Tableau | `data/ponctualite_propre.xlsx` |
| `05_verifications.sql` | liaisons comparables et dégradées entre 2019 et 2025 | (lecture seule) |
| `06_causes.sql` | causes de retard en format long, pondérées | `causes`, `data/causes.xlsx` |
| `07_gares_import.sql` | import du référentiel des gares SNCF | `gares_ref` |
| `08_gares_correspondance.sql` | normalisation des noms et rapprochement automatique | `gares_ref_propre`, `nos_gares` |
| `09_gares_candidats.sql` | candidats pour les gares non rapprochées | (lecture seule) |
| `10_gares_coordonnees.sql` | coordonnées des 59 gares | `gares_coord` |
| `11_carte.sql` | essai de carte par axe (non retenu) | `carte_axes` |
| `12_carte_gares.sql` | un point par gare, 2025 | `carte_gares` |
| `13_carte_gares_annees.sql` | un point par gare et par année, avec la moyenne nationale | `carte_gares_annees` |
