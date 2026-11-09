# Asset provenance

- `observatory.png`: original image generated for this project with OpenAI's image-generation tool on 2026-11-08. Curated and inspected, used as the painted celestial backdrop behind the interactive 3D scene and opening. No external artist or game assets were supplied as references. It is artwork, not gameplay or an AI gameplay service.
- `audio/*.wav`: original offline additive-synthesis sound design made for this project: quiet C-major celestial pad, orbit tone, alignment chime, footsteps, and final cadence. No samples or third-party recordings.
- `fonts/DisplaySerif.ttf`: DejaVu Serif. The upstream copyright and redistribution terms are reproduced in `fonts/LICENSE.txt`.
- Architecture, character, lens ornaments, particles, UI decorations and animations are original procedural geometry/code.

## Image generation prompt

Use case: stylized-concept. Create an original landscape 16:9 atmospheric backdrop texture for an elegant geometric illusion puzzle game called The Folded Observatory. No lettering. Dark midnight navy and deep petrol teal sky, subtle fine-grained hand-painted paper texture, tiny distant warm gold celestial specks, a delicate engraved astronomical orbital arc along the far right and top edges, faint coral dusk glow at bottom. The central 75 percent must remain very calm and low contrast empty negative space because a real interactive ivory and teal 3D architectural sculpture will be rendered on top. Premium restrained art direction, contemplative mysterious quiet observatory night, subtly luminous and beautiful. Not a screenshot, no building, no character, no UI, no text, no watermark.

## Chapter I narrative comics

- `chapter_opening.png` and `chapter_ending.png`: original wordless four-panel illustrations generated with OpenAI's built-in image-generation tool on 2026-11-09 for *A Letter to Nowhere*. Both are RGB PNG, 2172 × 724 pixels. Visually inspected for story continuity, legibility, palette, and absence of text. The opening was generated without supplied reference imagery; the ending used only this project's newly generated opening as its character/material reference. No external game artwork or artist references were supplied. These are static narrative assets, not an AI gameplay service. Each strip uses four equal 543-pixel cells, including ivory gutters, suitable for full-strip display or AtlasTexture regions.

### Opening prompt

Use case: illustration-story. Create an original, polished wordless opening comic for a contemplative geometric puzzle game. One wide landscape image, EXACTLY FOUR equal-width panels in a single horizontal row, separated by narrow warm-ivory gutters, no outer frame. Each panel has generous clean composition with beautifully crafted editorial papercut illustration: folded ivory paper architecture, muted deep petrol teal shadows/backgrounds, tiny brushed gold accents, soft atmospheric gradients and subtly fibrous paper texture. Same tiny anonymous messenger throughout, rounded deep teal hood and cloak, tiny gold circular face with no features, no hat. Panel 1: closeup of a pristine unaddressed ivory envelope held by small teal-cloaked hands, a little circular gold wax seal, nothing written on it. Panel 2: wide view of the tiny messenger standing at the edge of a suspended ivory paper landing holding the envelope, empty teal air all around. Panel 3: expansive impossible floating kirigami city of ivory stairways and folded facades, delicate gold hinge lines, the messenger tiny at foreground edge; striking beautiful perspective composition. Panel 4: the messenger looks upward toward a distant tall narrow tower with a warm gold lit aperture at its summit, a long folded street leading toward it. Restrained elegant visual storytelling, readable silhouettes and quiet mysterious mood. This is original art, not fan art of any existing game. Absolutely NO words, letters, numbers, captions, signage, speech bubbles, logos or watermarks.

### Ending prompt

Create a companion ENDING comic, using the supplied opening comic ONLY as style and character reference. Exact same refined folded-paper material, warm ivory and petrol teal with gold highlights, rounded deep teal hooded cloak and tiny featureless circular gold face. Produce a wide landscape strip of EXACTLY FOUR equal-width panels in one horizontal row, narrow ivory gutters. Completely NEW scenes, an emotionally quiet narrative reveal: Panel 1: on top of the tall paper tower, the small messenger stands beside an empty ivory pedestal under a tall glowing gold aperture, setting the unaddressed sealed envelope onto the pedestal. Panel 2: intimate close-up of the envelope on pedestal, golden wax seal now broken and triangular paper flap lifting itself, an amber light glowing out of the empty interior, messenger observing. Panel 3: the envelope opens and UNFOLDS INTO A MINIATURE VERSION OF THE IVORY FLOATING CITY, architectural pop-up card structures of towers, impossible stairs, tiny arched bridges growing directly from the envelope's paper. This is the key reveal, show the entire envelope and obvious tiny city physically emerging from it. Panel 4: wide contemplative view, the messenger small at left holding the now open paper city gently in both hands; beyond them the original enormous city is dissolving quietly into a few drifting paper polygons against deep teal air. Gold light from the tiny preserved city, a sense of home and memory. Original cinematic storybook illustration. Clear visual storytelling. No words, lettering, numbers, captions, bubbles, signage, logos or watermarks whatsoever.

## Chapter I gameplay sky

- `chapter_sky.png`: original RGB PNG (1586 × 992, approximately 16:10), generated with OpenAI's built-in image-generation tool on 2026-11-09. No supplied reference assets. Visually inspected: central field remains empty and low contrast for interactive geometry, while tiny paper architecture and layered clouds occupy only outer edges. Warm upper-right light and gold dust echo the chapter comics.

### Gameplay sky prompt

Use case: stylized-concept. Asset type: original 16:10 landscape backdrop for an elegant folded-paper geometric puzzle game. Painterly cut-paper atmosphere matching warm ivory architecture, petrol teal and tiny muted gold accents. The center 80 percent of image must be empty low contrast deep muted teal negative space, smoothly graded with very subtle fibrous paper texture, because interactive 3D platforms will be drawn over it. Only along far left and right edges and bottom corners: a few VERY SMALL, distant hazy floating ivory folded-paper buildings and tiny fragments, softly fading into mist; these must be atmospheric not foreground subjects. Airy translucent soft teal cloud layers confined to lower outer edges; restrained scattered gold dust at outer edges. Quiet mysterious warm glow at extreme upper right, never bright in center. Sophisticated handcrafted paper relief quality, softly diffused ambient light. No foreground path, no characters, no stairs or buildings anywhere in central eighty percent. No words, symbols, signage, borders, captions, watermarks or UI. This is a calm background texture not a level illustration.

## Chapter I sampled audio revision

The chapter no longer plays the original synthesized ambience/align WAV cues.
Its interaction sounds are samples from **Kenney Interface Sounds**, by Kenney,
https://kenney.nl/assets/interface-sounds (CC0 1.0). Redistributed files:
click_001, click_005, select_001, glass_001, glass_004, glass_005,
confirmation_001 (OGG). Acquisition mirror:
https://github.com/hipdiscovery/Free-Sound-Effects/tree/main/audio/kenney-interface.
Original license copied to assets/audio/licenses/KENNEY_CC0.txt.

Quiet milestone notes use the recorded **Meta Open Sound Piano** low-velocity
C4/E4/G4/C5 samples, from Meta's official collection:
https://github.com/facebookincubator/Meta-open-sound/tree/main/systems/instruments/meta-piano.
Files INSPiano_Vel01_{C4,E4,G4,C5}_01.ogg, CC0 1.0, original license in
assets/audio/licenses/META_CC0.txt. Both CC0 licenses allow commercial use,
modification and redistribution, including these samples in source and builds.
Attribution is supplied voluntarily. Godot applies conservative gain, low-pass
and a small room reverb at playback; Kenney files are unchanged; Meta Opus-in-OGG samples are transcoded to Vorbis-in-OGG for Godot compatibility, with no pitch or timing change.

Material foley uses unchanged Kenney CC0 recordings from **Impact Sounds**
(footstep_wood_000/001/002) and **RPG Audio** (bookFlip2, bookPlace1, cloth1,
creak1, creak2): https://kenney.nl/assets/impact-sounds and
https://kenney.nl/assets/rpg-audio. Acquisition mirror:
https://github.com/receptron/mulmocast-media/tree/main/soundeffects/kenney.
Original licenses are retained as KENNEY_IMPACT_CC0.txt and KENNEY_RPG_CC0.txt.
Footsteps follow actual physics travel, not attempted movement into a wall;
mechanical sounds are sparse, quiet one-shots rather than a synthetic loop.
