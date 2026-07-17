# trace_3d

Sketch Processing pour générer un champ de Box3D projeté en 2D (wireframe), avec caméra orbitale, mode perspective ou orthographique, et option de masquage des lignes cachées (HLR software z-buffer).

## Objectif

- Produire des tracés 2D propres à partir d une scène 3D simple.
- Garder une interaction fluide même avec beaucoup de boites.
- Permettre un export vectoriel via la pile xLib déjà incluse dans le projet.

## Demarrage rapide

1. Ouvrir trace_3d.pde dans Processing.
2. Lancer le sketch.
3. Ajuster les paramètres via les onglets:
- Boxes
- Camera
- Occlusion
- Style
- Files

Au démarrage, les valeurs sont chargées depuis Settings/default.json.

## Interaction utilisateur

- Drag souris sur le canvas: orbite caméra (yaw, pitch).
- Drag clic droit sur le canvas: déplace la target caméra (pan).
- Molette souris sur le canvas:
- Mode Perspective: agit sur target_distance (distance camera-target).
- Mode Ortho: agit sur ortho_zoom.
- Boutons Camera: Front, Back, Left, Right, Iso, Top.

Important: les interactions caméra sont désactivées si la souris est au-dessus de l interface GUI.

## Paramètres Camera

- target_x, target_y, target_z: position de la cible caméra.
- target_distance: rayon d orbite camera autour de la cible.
- projection_mode:
- 0 = Ortho
- 1 = Perspective
- fov: angle de champ perspective.
- focal_distance: force de perspective (distance focale logicielle).
- ortho_zoom: zoom utilisé uniquement en mode Ortho.

Comportement UI conditionnel:
- En Ortho: affiche ortho_zoom, cache fov et focal_distance.
- En Perspective: affiche fov et focal_distance, cache ortho_zoom.

## Paramètres Boxes

- count: nombre de boites.
- spacing: espacement grille.
- box_height: hauteur de boite.

La géométrie des meshes est mise en cache dans meshList (actuellement des boites) et n est reconstruite que si Boxes change.

## Occlusion (HLR)

Quand Occlusion.enabled est actif, le rendu passe par:
1. Projection des sommets 3D.
2. Rasterization des faces dans un depth buffer.
3. Echantillonnage des arêtes pour ne garder que les segments visibles.

Paramètres:
- zbuffer_scale: résolution relative du z-buffer (qualité/perf).
- sample_step_px: pas d échantillonnage des arêtes.
- depth_bias: tolérance de comparaison profondeur.
- min_visible_segment_px: seuil anti-segments parasites.

## Architecture du code

Fichiers principaux:
- trace_3d.pde: boucle principale, génération grille, pipeline de projection, HLR.
- DataGlobal.pde: agrégation des chapitres de données.
- DataBoxes.pde: paramètres de grille + UI Boxes.
- DataCamera.pde: modèle caméra, projection, sérialisation JSON, UI Camera.
- DataOcclusion.pde: paramètres HLR + UI Occlusion.
- DataGUI.pde: tabs GUI + interactions souris (drag, molette).
- xLib_Box3D.pde: primitive Box3D et wireframe.

Objets de travail:
- meshList: cache des Mesh (actuellement des Box3D).
- lineGroup: géométrie 2D finale affichée/exportée.

Règle de recalcul:
- Boxes change: rebuild meshList puis lignes.
- Camera change: rebuild lignes seulement.
- Occlusion change: rebuild lignes seulement.

## Réglages persistés

Fichier principal:
- Settings/default.json

Chapitres JSON attendus:
- Style
- Page
- Camera
- Boxes
- Occlusion

Si un champ est absent, la valeur par défaut du code est utilisée.

## Guide reprise rapide pour une IA

Contexte minimal à lire en premier:
1. trace_3d.pde
2. DataCamera.pde
3. DataOcclusion.pde
4. DataGUI.pde
5. Settings/default.json

Checklist avant modification:
1. Identifier si le changement touche la géométrie (Boxes) ou seulement la projection (Camera/Occlusion).
2. Respecter le cache meshList, ne pas reconstruire les meshes pour un simple mouvement caméra.
3. Vérifier les flags changed pour éviter les recalculs inutiles.
4. Si un paramètre est ajouté, le brancher dans:
- modèle data
- LoadJson/SaveJson
- UI (slider/toggle)
- Settings/default.json

Zones sensibles:
- DataCamera.pde: cohérence entre fov, focal_distance, target_distance, ortho_zoom.
- trace_3d.pde: précision/performance du HLR.
- DataGUI.pde: ne pas casser la distinction canvas versus GUI pour les interactions souris.

## Notes xLib

Le projet embarque des fichiers xLib_*.pde copiés localement. Les évolutions globales xLib se gèrent via le workflow de synchronisation du dépôt processing_xlib; éviter de modifier le dépôt central directement hors workflow prévu.

## Etat actuel conseillé pour tests

Le preset fourni dans Settings/default.json utilise:
- count élevé (400)
- occlusion active
- projection perspective

C est utile pour tester rapidement qualité HLR et performance.
