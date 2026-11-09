# Design review — optical illusion, spatial density, and independent art identity

Date: 2026-11-09. Applies to the next revision of Chapter I. The playable five-district build is a development milestone, **not** the final interaction or art template.

## Core diagnosis from actual player testing

The current game is too linear and shallow. Players manipulate a few handles, then repeatedly walk from one short path to the next. Much of the large-looking environment is unused. Most mechanisms are ordinary changes in route connectivity, not perceptual ambiguity. The camera is fixed per district, so perspective is a passive backdrop rather than a puzzle instrument. The visual design is too close to *Monument Valley*.

Do not answer this by adding more scenery, more districts, longer corridors, or simply renaming hinges as visual illusions.

## 1. Functional density: no inert architectural filler

**Every conspicuous building or architectural feature should earn its place.** A visible piece should enable direct manipulation, constrain or redirect movement, mask/reveal a perceptual phenomenon, provide a clue/landmark needed for inference, or carry indispensable storytelling. Architectural elements with no gameplay, perception, legibility or narrative job should be removed, consolidated, or made consequential.

Prefer a smaller interconnected environment with layered uses over a large empty diorama. Reuse the same manipulable object in multiple surprising geometric states, instead of creating five disconnected walkways with one trick each.

This does *not* mean every single mesh must be draggable. Structural supports, negative space, framing, and background art can be static when they actively support a puzzle or visual reading. The ban is on **decorative construction masquerading as gameplay space**, not on visual atmosphere.

Perform an **architectural relevance audit**: for each major visible structure describe what the player can do with it, what it visually conceals/reveals, what navigation deduction it enables, or why the story needs it. If nothing applies, delete or redesign it.

## 2. Optical illusion must be the causal puzzle mechanic

Perspective coincidence of two gold circles is an already-solved basic trick; more of it is not a new game mechanic. The player needs to doubt an apparent object/route/space and discover by manipulating **view, object, mirror, light, occlusion or topology** that its appearance has changed meaning.

Allow meaningful **continuous view exploration** or camera gestures where the phenomenon requires it—not just four fixed camera presets. Provide camera constraints only when justified by composition and the illusion itself.

Introduce at least one demonstrably different perceptual principle that has measurable behavior and affects the *solution*. Possibilities: the same asymmetric object appears as different structures in a mirror; moving light generates two alternate shadow identities; view-dependent or anamorphic textures reveal an address/path; a locally consistent but globally impossible walkway changes traversable topology. Keep exact puzzle design author-owned.

For each new perceptual mechanism, document (a) the source/inspiration, (b) geometric or rendering construction, (c) how to make the perceptual change visible during direct player interaction, and (d) what spatial deduction a player must make. A scenic optical effect without gameplay consequence does not count.

## 3. Distinct visual identity — not Monument Valley with new colors

Do not imitate its signature aesthetic of pastel/isometric floating temple architecture, repetitive slender towers and stairs, simplified princess-like figures, and perfectly symmetrical ornamental portals. The current ivory-and-teal floating platforms and towers are too adjacent to that visual language. Merely changing the palette will not suffice.

**Build the art direction from the game's own premise**: an undeliverable letter, ambiguous address, optical transformation and altered reading. Possible (optional, not mandatory) directions: risograph/overprint and registration marks, kinetic typography and postal machinery, layered acetate and lenses, cut-paper collage, impossible printed maps, photochemical or industrial-optical devices. Develop a materially and compositionally distinctive style and silhouette, not just more elaborate floating architecture.

Generated illustrations must be integrated coherently with the interactive world. The gameplay should resemble the opening/ending comics in intentionality and detail. Use original assets and give credits; don't copy reference imagery or character designs.

## 4. Complexity without busywork or forced linearity

Reconsider the rigid five-district conveyor belt. The user still does not want to revisit completed areas for fetch quests; however, within a chapter, give real choice of which objects to investigate, how to manipulate them, and more than one meaningful intermediate state. Multiple clues and mechanics should interact within a compact shared space.

Use optional local routes or alternative orderings when they deepen exploration; keep progression forward once a spatial problem is resolved. Avoid padded walking, slow transitions and repeated identical gestures.

The goal is a layered inference problem, not merely a longer scripted solution. The same geometry can provide a clue first, become an obstacle later, and finally reveal a connection. Evaluate difficulty by blind-play evidence: can players identify controls and goal, formulate hypotheses and experience an actual 'I was wrong about what I saw' moment?

## 5. Recent research leads — verify and explore, don't just cite

- **Mirror Illusion Art / AutoMIA**, CVPR 2026, Xiaopei Zhu et al.: one 3D object designed to present distinct front and mirror images, with joint shape/color optimization. https://arxiv.org/abs/2607.02015 — potentially a double-identity interactive puzzle (do not attempt to replicate its full training pipeline).
- **LookingGlass: Generative Anamorphoses via Laplacian Pyramid Warping**, CVPR 2025: readable but different image under an anamorphic transform. https://openaccess.thecvf.com/content/CVPR2025/html/Chang_LookingGlass_Generative_Anamorphoses_via_Laplacian_Pyramid_Warping_CVPR_2025_paper.html — layered print/hidden-address puzzles via projected or reflected surfaces.
- **Neural Shadow Art**, Pacific Graphics 2025: the same sculpture can form target shadow images under controlled illumination. https://diglib.eg.org/items/0c4bbf47-8cc8-4c54-a2b9-b8853ee60fcc — use moving light/object and shadow as game-readable alternatives.
- **Meschers: Geometry Processing of Impossible Objects**, SIGGRAPH 2025: locally consistent, globally impossible 2.5D geometry. https://scenerepresentations.org/publications/meschers/ — use explicit local sheet and depth-transition models rather than just screen-overlapping platforms.
- **Anomalous Mirror Reflections Created by Symmetries**, Kokichi Sugihara, 2025: shapes change or reverse under reflection. https://www.jstage.jst.go.jp/article/ipsjjip/33/0/33_974/_article/-char/en

These are **starting points for further targeted paper searches** into less commonly used optical-perception mathematics. Evaluate novelty, implementability in Godot, and actual player-perceivable illusion. Select the best ideas independently. A paper citation, decorative rendered effect, or ordinary mechanic with new terminology is not evidence of novel gameplay.

## Suggested next implementation strategy

1. Re-explore the research domain and select a genuinely compelling new illusion principle; prototype its perceptual reveal with player-controlled viewpoints or light/object manipulation.
2. Rework the chapter as a **compact, interaction-rich spatial composition**, removing structures that contribute nothing. Decide where branching local investigation genuinely helps.
3. Establish an art direction and visual language that stands apart from *Monument Valley*, grounded in Chapter I's own narrative. Replace the existing architectural vocabulary where necessary.
4. Implement the new optical mechanic as an indispensable part of a complex, comprehensible puzzle. Then integrate the comics, atmosphere and sound.
5. Test with a new player without procedural hints. Build downloadable Windows/Linux artifacts, and provide real video/screenshots. Preserve draft/unmerged status until review.

Do not merely add cosmetic props or more scripted stages. The next PR should demonstrate the new core perceptual interaction and a denser level, not additional test counts. Keep the project modular and cross-platform.
