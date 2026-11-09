# Perspective Crime — Chapter I: A Letter to Nowhere

An offline Godot 4.6.3 spatial puzzle chapter about delivering an unaddressed
letter through a folding paper city. Five connected districts introduce and
combine hinged streets, carried platforms, counterweights, impossible seams,
and selective braces. Original wordless comics frame the delivery.

## Play

Open `project.godot` in Godot 4.6.3 and press F5, or run `godot --path .`.
Main scene: `scenes/chapter.tscn`.

- **Drag brass grips along their visible motion.** The grabbed architecture
  follows the projected pointer direction; release gently snaps to a dock.
- **Click a glowing landing** to walk along the current valid route. Hover a
  landing for a dotted path preview. Dragging is not treated as a click.
- Board level carriages before folding them upward. The courier is carried by
  their actual transform. An empty sorting cart acts as another lift's weight.
- Click a brass pin **while standing beside it** to hold one linked street;
  other sections can then turn independently.
- Top-left controls: local restart, optional help, mute, gentle hint.
  Keyboard: R restarts the district, M toggles audio, Esc dismisses help/gesture.
- Each district entrance is a checkpoint. There is no required walk back into
  an earlier district. Replay is available after the closing comic.

Save format 2 intentionally starts old three-district saves at the new opening:
those old checkpoints do not describe the revised layouts. New saves resume
at their current district. `--no-save` isolates development/test sessions.

## Five spatial sequences

1. **Folded Quay:** join a street, board its level carriage, ride a real folding
   arm upward, and leave through a separately reconfigured upper route.
2. **Sorting House:** carry the courier across on a cart; transfer to the lowered
   lift; send the now-empty cart back as a counterweight. The player stays ahead.
3. **False Facade:** align two projected landing medallions, cross an explicitly
   marked space-fold, then deploy the far-side street and an upper lift.
4. **Hinged Archive:** linked streets cannot all meet their destinations at once.
   Stand at successive landings and pin completed sections before turning others.
5. **Undeliverable Tower:** combine riding, phase-linked streets, a brace, a
   projection seam and a movable receiving street to deliver the letter.

The earlier Observatory demo is preserved at commit
`21fd43954a277ebbe157229f23f387424a636bd3` and `scenes/main.tscn`.

## Collision and movement

Ordinary navigation uses **CharacterBody3D + capsule + move_and_slide**, with
solid floors, walls, gate bars/posts, carriage floors and rails. It is no longer
a tween of the character through scenery. An obstructed route stops and reports
failure rather than ignoring the obstacle. Walking locks architecture movement.

Stationary riders follow level carriage transforms. Each proposed manipulation
is subdivided and checked against the courier capsule; unsafe movement is rolled
back. Dock geometry provides actual overlapping walkable surfaces. This is an
authored puzzle system, not a general rigid-body simulation of folding buildings.

An impossible seam is a deliberate **portal exception**, visibly shrinking and
restoring the courier between aligned medallions. It is not ordinary walking
through a wall. Transfer requires actual camera projection alignment, a clear
capsule destination and a supported landing; collision masks are never disabled.

## Audio and assets

The chapter replaces the old synthetic drone/beeps with licensed **Kenney CC0
Interface/Impact/RPG samples** and **Meta CC0 recorded piano**: wood footsteps,
paper handling, sparse mechanical creaks, restrained interaction cues and warm
milestone notes. Footsteps follow actual physics travel. Licenses, original
sources, conversions and voluntary attribution are in `assets/CREDITS.md` and
`assets/audio/licenses/`. All shipped audio permits commercial redistribution.

Original generated comic/backdrop assets are development assets, not runtime AI.
No network, model service, telemetry, account or external download is needed.

## Architecture

`input_router.gd` handles pointer capture; `chapter_layouts.gd` authors topology;
`spatial_mechanism.gd` and `paper_lift.gd` provide physical moving architecture;
`walkable_graph.gd` derives valid routes; `route_walker.gd` handles collisions;
`projection_seam.gd` validates topology transfers; `chapter_module.gd` composes a
district; `game_flow.gd` coordinates checkpoints, safe manipulation and delivery;
`audio_director.gd`, `chapter_hud.gd` and `narrative_panels.gd` provide presentation.

## Verify and build

```sh
godot --headless --path . --fixed-fps 60 --script tests/chapter_playthrough.gd -- --no-save
godot --headless --path . --script tests/route_walker_collision.gd
godot --headless --path . --fixed-fps 60 --script tests/chapter_stress.gd -- --no-save
godot --headless --path . --fixed-fps 60 --script tests/chapter_capture.gd -- --no-save
python3 tools/build.py --install-templates
```

Use writable HOME/XDG data/config/cache directories. `--audio-check` plays the
sample palette and exits, without reading/writing player progress. The capture
script can run graphically with `--write-movie /outside/repo/chapter.avi` and
`--capture-dir=/outside/repo/evidence` for a real rendered input walkthrough.

Build output: `ALetterToNowhere-linux-x86_64.zip` and
`ALetterToNowhere-windows-x86_64.zip`, with source revision, packaged-file hashes,
licenses and instructions. See `docs/BUILD.md` and `docs/CHAPTER_01_TESTING.md`.

This remains a draft development chapter. The 12–20 minute first-time target,
blind-player difficulty, native Windows runtime, accessibility, and hardware GPU
performance must not be inferred from automated tests or a known-solution video.
