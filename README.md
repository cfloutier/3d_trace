# trace_3d

Sketch Processing pour generer un champ de Box3D projete en 2D (wireframe), avec camera orbitale, projection Ortho/Perspective, HLR logiciel (z-buffer), et export SVG direct.

## Objectif

- Produire des traces 2D propres a partir d une scene 3D simple.
- Garder une interaction fluide avec un grand nombre de meshes.
- Permettre des exports vectoriels fiables (affichage et export coherents).

## Demarrage rapide

1. Ouvrir trace_3d.pde dans Processing.
2. Lancer le sketch.
3. Ajuster les parametres via les onglets:
- Meshes
- Camera
- Occlusion
- Style
- Files

Au demarrage, les valeurs sont chargees depuis Settings/default.json.

## Interaction utilisateur

- Drag souris sur le canvas: orbite camera (yaw, pitch).
- Drag clic droit sur le canvas: deplace la cible camera (pan).
- Molette souris sur le canvas:
- Perspective: agit sur target_distance.
- Ortho: agit sur ortho_zoom.
- Boutons Camera: Front, Back, Left, Right, Iso, Top.

Important: les interactions camera sont desactivees si la souris est au-dessus de la GUI.

## Parametres Meshes

L onglet Meshes pilote la distribution des Box3D via un mode actif:
- distribution_mode: Grid ou Tube.
- random_seed: seed global partage par toutes les distributions.

Mode Grid:
- count
- spacing
- box_height

Mode Tube (aleatoire):
- radial_count
- levels
- radius_min / radius_max
- base_y_min / base_y_max
- box_length_min / box_length_max
- spacing (section X/Z des boxes)

La geometrie 3D est mise en cache dans meshList et n est reconstruite que si Meshes change.

## Occlusion (HLR)

Quand Occlusion.enabled est actif, le rendu passe par:
1. Projection des sommets 3D.
2. Rasterization des faces dans un depth buffer.
3. Echantillonnage des aretes pour ne garder que les segments visibles.

Parametres:
- zbuffer_scale: resolution relative du z-buffer.
- sample_step_px: pas d echantillonnage des aretes.
- depth_bias: tolerance de comparaison profondeur.
- min_visible_segment_px: seuil anti-segments parasites.

Notes:
- En perspective, la profondeur des aretes est echantillonnee en interpolation 1/z (plus stable sur longues lignes).
- Avec clipping actif, les echantillons hors domaine de clipping sont traites comme non visibles.

## Export SVG

Deux options existent dans l onglet Files:
- SVG direct (recommande): writer custom, plus fiable pour le plotter.
- SVG (Processing): fallback legacy via renderer Processing.

Le writer direct:
- applique le clipping dans l espace dessin,
- centre ensuite l export,
- utilise une bbox coherente avec l etat de clipping.

## Architecture du code

Fichiers principaux:
- trace_3d.pde: boucle principale, orchestration recalculs/rendu.
- LineBuilder.pde: generation des lignes 2D (normal + occlusion).
- MeshDistribution.pde: data+UI du mode Meshes et routing Grid/Tube.
- GridDistribution.pde: generation mode Grid.
- TubeDistribution.pde: generation mode Tube aleatoire.
- DataGlobal.pde: aggregation des chapitres de donnees.
- DataGUI.pde: tabs GUI + interactions souris.
- DataOcclusion.pde: parametres HLR + UI Occlusion.
- xLib_Mesh.pde: abstraction Mesh + primitives projetees.
- xLib_Box3D.pde: decomposition d une box en aretes/faces.
- xLib_Camera3D.pde / xLib_CameraData.pde: projection camera + UI.

Objets de travail:
- meshList: cache des Mesh.
- lineGroup: geometrie 2D finale affichee/exportee.

Regle de recalcul:
- Meshes change: rebuild meshList puis lignes.
- Camera change: rebuild lignes seulement.
- Occlusion change: rebuild lignes seulement.

## Reglages persistes

Fichier principal:
- Settings/default.json

Chapitres JSON attendus:
- Style
- Page
- Camera
- Boxes
- Occlusion

Si un champ est absent, la valeur par defaut du code est utilisee.

## Notes xLib

Le projet embarque des fichiers xLib_*.pde copies localement. Les evolutions globales xLib se gerent via le workflow de synchronisation du depot processing_xlib.

## TODO

- Gerer correctement les intersections entre boxes en ajoutant des edges supplementaires pour decouper les lignes aux zones d intersection.
