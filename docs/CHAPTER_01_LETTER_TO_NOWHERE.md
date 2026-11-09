> **Playtest review (2026-11-09):** [Optical illusion, functional architecture, and independent art identity](REVIEW_OPTICAL_IDENTITY_2026-11-09.md). The player's critical feedback takes precedence over the old scripted five-district structure: significantly reduce unused scenery, make visual illusions causally necessary, let players meaningfully manipulate viewpoints and geometry, and establish a visual language independent of *Monument Valley*.

# Chapter I — A Letter to Nowhere / 寄往不存在之地的信

Status: creative + engineering brief for the **next major playable chapter**, following the completed Folded Observatory demo in PR #1. This is a new production target, not a claim that the chapter exists.

## Narrative image

An astronomer-turned-messenger carries a letter without an address into a floating paper city. Streets, buildings, and courtyards are made from hinged surfaces that change their adjacency when folded. The letter's destination cannot be found on an ordinary map. At the end, the envelope opens into a view of the city itself: the letter is addressed to the disappearing place. The closing image is open to subtle interpretation; avoid explanatory exposition.

**Chapter motif:** paper, letters, addresses, hinge lines, unfinished places. Preserve the existing game's contemplative ivory/teal/gold aesthetic if useful; create original imagery and characters for the new chapter. This is a distinct chapter rather than four disconnected copies of the current bridge puzzle.

## Narrative form and onboarding

- Begin with 3–5 short, preferably wordless comic panels: an unaddressed envelope, a small messenger, a folded city, a distant illuminated delivery point. End with 3–5 comic panels revealing where the letter arrives.
- During gameplay, use visual affordances and animation instead of repeated text instruction: a moving crease, reachable tile glow, character gaze, soft path preview and animated camera framing. A discreet optional hint icon and accessibility/help controls are fine; no constantly present tutorial paragraphs or stage labels.
- Ensure a blind player can infer both **the next objective** and **what can be manipulated** from the scene. Less text is not permission for ambiguity.

## Core inputs: direct manipulation, not button-driven level animation

- **Drag a selectable piece of architecture** to fold/rotate/slide it. The manipulated object follows the drag with clear limits, resistance/snap and a visible pivot. Other drags can orbit the viewpoint only where appropriate. The player must directly cause the geometry to change.
- **Click or tap a reachable destination** to direct the character along an actual currently valid route. Do not require free-roaming WASD. Do not reduce each puzzle to a single 'Walk the fold' button that automatically completes an entire stage.
- Input arbitration: a short pointer gesture is a click, a drag exceeding a threshold manipulates the picked handle; tapping UI never rotates the scene. Support mouse first and consider touch screen sizing for a later Web build.
- On invalid destinations, show gentle, immediate visual feedback rather than a modal paragraph. Do not initiate movement through a disconnected path.

## One large, linear chapter (provisional beats, not a mandatory set of exact puzzles)

1. **Prologue / The blank address.** A quiet opening comic; the messenger stands at the edge of a paper city. A visibly movable architectural element teaches drag-to-reconfigure without text. Click-to-walk is introduced by a short reachable destination.
2. **Folded streets.** Hinged tiles rotate and physically change which routes connect. The player chooses where to stand and which assembly to fold; a single unfolded configuration need not expose every road. The first real architectural manipulation gives access to the next district.
3. **The false façade.** A mirror, silhouette, or impossible-geometry seam transforms an apparent obstruction into a route when seen or rearranged appropriately. This is a genuinely different deduction from simply selecting the correct camera angle.
4. **The undeliverable tower.** Combine at least two earlier ideas (e.g. hinge deployment plus projection seam, or geometry lock plus ambiguous silhouette) into a multi-step but locally contained puzzle. The player works with real scene objects and can reason visually about the necessary sequence.
5. **Delivery / Epilogue.** The letter is delivered; comic ending/reveal makes the chapter's imagery pay off and provides a reason to continue to the next independent chapter.

Target a meaningful chapter-sized experience, approximately 12–20 minutes for a first-time player **if playtesting supports that length**. Complexity should come from interactions and deduction, not slow camera animations, extended walking, or compulsory text.

## Progression invariant — no backtracking

Each district is a **forward-moving puzzle module**. After completion, its effects are committed, the camera leads to the next district, and the player never has to walk back to a solved section or reopen its apparatus to advance. Each module has a checkpoint and locally reversible experimentation prior to completion. Existing parts can appear in the distance for narrative continuity; they must not become errands.

Structure the implementation so each district can be loaded, tested, and visually reviewed independently. The final module combines learned concepts without revisiting earlier locations.

## Geometric mechanic candidates

- **Hinged kirigami architecture:** rotational deployment of rigid polygonal tiles. Use a small validated hinge graph with adjustable one-parameter fold states; render actual changing geometry and update walkable connectivity.
- **Projection seam / impossible local space:** two disconnected 3D path endpoints align in the active projection. When a valid seam is committed, the character can traverse a visually continuous, intentionally non-Euclidean connection. This should be one tool in a broader spatial system, not the repeated sole puzzle.
- **Ambiguous silhouette or mirrored identity:** one physical object reveals two distinct meaningful shapes from different views or through a reflection. The player manipulates the object to reveal a required architectural function.
- **Selective rigidity:** locking/unlocking a facet changes which connected pieces are permitted to move, enabling a different deployment. Use sparingly only if legible in play.

These are **research-inspired game mechanisms**, not instructions to implement every mathematical paper or to copy a reference algorithm. Choose a coherent subset and build one excellent compound payoff.

## Engineering interfaces and module boundaries

- InputRouter: click-vs-drag discrimination, object picking, gesture capture, mouse/touch mapping; no hidden button-only core path.
- SpatialMechanism: transform state, bounds/snap, animation and occupancy/actor safety.
- WalkableGraph: nodes/segments/seam links with dynamic availability, world-space and projected state; click destination resolves only currently reachable route and supplies pathfinding/animation.
- ChapterModule: isolated scene, puzzle state, entry/exit anchors, completion checkpoint, local restart; no dependencies on earlier areas after completion.
- NarrativePanels: optional cinematic comics with accessibility controls to skip/revisit, without blocking gameplay once seen.
- GameFlow: saves chapter progress, advances camera/cutscene forward only, replay and restart.

For orthographic projection an aligned displacement may lie along the view ray; validate screen-space endpoints using Camera3D.unproject_position and a sensible visibility/occlusion policy. Test the *actual* transform, not a canned view index. With moving geometry, update path connectivity after all relevant transform changes. Prevent dragging a loaded structure out from under the player without an authored transition; attach the character to a moving platform or inhibit that motion. Validate every stage from clean start and from checkpoint.

Prefer data-driven reusable scene components rather than a second 1000-line monolithic main.gd. No generalized real-time impossible-mesh solver is required.

## Completion standard

- A stranger can begin and finish the chapter without reading a manual or relying on large text hints; at least two blind players should be observed if possible.
- Each interaction is direct: dragging changes architecture, clicking directs character motion, and geometry visibly determines connectivity.
- One cohesive narrative chapter with opening and ending comics, at least two distinct spatial mechanic families, one compound puzzle, and no required backtracking.
- A consistent art/sound/transition language with generated original 2D assets where useful; credits and licenses accompany shipped assets.
- Actual graphical test and playable Windows (tested on Windows) and/or Linux releases, followed by a Web/itch.io build when supported; capture genuine screenshots and video.
- Preserve the successful Observatory demo as a traceable earlier revision, but prioritize the new chapter, not backward compatibility with old controls or structure.

Research notes: [GEOMETRIC_MECHANICS_REFERENCES.md](GEOMETRIC_MECHANICS_REFERENCES.md).