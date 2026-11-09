# Chapter I — collision, puzzle and sampled-audio revision

This record supersedes the earlier three-district development preview. The PR
remains draft. A passing test is not a claim that every possible defect is fixed.

## Automated physics and input

Godot 4.6.3.stable.official.7d41c59c4, normal simulation timescale, fixed 60 fps:

- `tests/chapter_playthrough.gd`: **145/145 checks pass**.
- `tests/route_walker_collision.gd`: **17/17 checks pass**.
- `tests/chapter_stress.gd`: **82/82 checks pass**, repeated twice.
- Pointer-router demonstration completes all five districts.
- All final runs exit 0 without script errors or warnings. Audio-check plays all
  12 sample cues and exits cleanly after draining the audio thread.

Coverage includes real wall collision and blocked-route timeout; collision masks
remaining enabled; all five transform-derived routes; carried lift/shuttle and
counterweight motion; capsule clearance during intermediate manipulation;
mandatory pin constraints; supported/clear portal destinations; reset during
walking, release snap and both portal phases; focus loss, Escape, repeated clicks,
and projected gestures at 960×600 and 1280×800. The drag threshold preserves the
entire initial displacement. Immediate clicks during a release snap are rejected.

Walking tests use CharacterBody3D/move_and_slide. They do not teleport the actor
to simulate successful ordinary traversal. Explicit camera-aligned portals are
separate from normal walking and require a clear supported destination.

## Problems actually found and corrected

Real collision testing exposed geometry problems that the old tween movement
had hidden: lift riders struck upper slabs/support piers; a descending
counterweight crossed the cart's channel; a corner gate post blocked departure;
and a lift rail obstructed an upper turn. The layouts, docking clearances, phase
coupling and gate orientation were changed. Collision bodies were not removed
to make the routes pass. Regressions now complete these routes physically.

GUI testing also found excessive repeated dragging of the cart. Input now uses
the grabbed object's actual projected tangent instead of an arbitrary horizontal
angle scale. One natural gesture carries the lift or moves the cart its full span.

## Graphical inspection

Cloud Linux desktop, Godot Compatibility renderer, Mesa llvmpipe:

- All five districts manually completed through normal pointer controls.
- Occupied lifts, shuttle, counterweight, pins, explicit portals and reset during
  movement observed. No physical blockage or ordinary walk-through-solid was
  observed in this pass.
- First two revised puzzle sequences inferred from the visuals before consulting
  solutions. Remaining inspection was informed QA, **not a blind-player study**.
- Final visual delta (letter stacks, sampled foley, mailbox delivery and wordless
  ending) verified by the final rendered pointer-router walkthrough.
- Recorded **2,416 frames, 80.533 seconds, 1280×800, 30 fps**. AVI converted to
  H.264/AAC MP4, preserving gameplay frames. Screenshots are real viewport captures,
  JPEG-compressed only. The driver uses ordinary router gestures and physics.
- This offline recording is not a hardware GPU or real-time frame-rate benchmark.
  The desktop has no audible ALSA output; the movie contains the engine's audio.
  Final movie mix measures −9.7 dBFS peak and −34.4 dBFS mean, without clipping.
  Per-sample gain compensates for the quiet piano recordings.

## Packaged runtime and actual audio output

On **xiaArch / Arch Linux**, with Intel Mesa OpenGL 4.6:

- Native Linux package: exit 0, `AUDIO_CHECK_COMPLETE sampled_cues=12`.
- Windows EXE under **Wine 11.20**, fresh temporary prefix: exit 0, same marker.
- Initial NVIDIA device probing warned, then successfully selected Intel graphics.
- Both checks routed only the game to an isolated PulseAudio sink and recorded
  that sink's monitor. No microphone or unrelated desktop audio was captured.
- Stereo 48 kHz output: Linux 16.0 s, peak **−9.75 dBFS**; Wine 16.5 s,
  peak **−9.09 dBFS**. Both have nonzero audio and **zero clipped PCM samples**.
- Temporary sinks and test Wine services were removed/stopped afterward.

This verifies runtime initialization, sample playback and actual output capture.
It is **not native Windows testing**, manual Windows control verification, or a
claim of subjective listening quality. Peak checks establish headroom, not ideal
loudness or pleasantness. The recordings remain local to the test computer;
the delivered gameplay video also contains the revised sound mix.

## Packaging

Linux/Windows x86_64 exports use SHA-512-verified official Godot 4.6.3 templates.
ZIP CRCs and packaged-file hashes are checked. Packages contain exact source
revision/dirty-state metadata and all audio/art/engine license information.
Windows builds are unsigned. Native Windows remains unverified.

## Remaining limits

Five distinct forward districts now require actual boarding, position changes,
counterweight reasoning, successive braces and a compound final sequence. This
is a substantial revision of the simpler preview, but a measured 12–20 minute
first-time experience and two independent blind players are still unverified.
Touch hardware, broad accessibility and hardware performance need further work.
The mechanisms are authored spatial puzzles, not general kirigami/rigid-body
solvers. Projection transfers deliberately change topology rather than pretending
that a physically obstructed straight path is traversable.
