# Battle Chess Revival

A playable 3D Battle Chess-inspired game built with **Godot 4.7.2**.

## Current release status

**Release Candidate 1** is verified in CI.

The game includes:
- complete standard chess legality;
- deterministic Black AI;
- mouse-driven piece selection and legal-move highlights;
- full-board 3/4 gameplay camera;
- separate cinematic battle camera for captures;
- six production character families on both sides;
- Skeleton3D authored animation sets for every family;
- six signature capture cinematics;
- production cathedral environment with stained-glass lighting;
- production HUD, pause/settings, check/checkmate and endgame presentation;
- cathedral ambience and gameplay/capture SFX;
- Windows x86_64 export.

## Controls

- **Left Mouse Button** — select a piece / choose a destination.
- **Esc** — pause / settings.
- **R** — start a new match.
- **A** — toggle Black AI for local two-player testing.
- **1–6** — developer preview of the six signature capture cinematics when debug preview input is available.

### Gameplay rules

White starts. With AI enabled, the player controls White and Black replies automatically.

The chess layer supports:
- check and checkmate;
- stalemate;
- castling;
- en passant;
- automatic Queen promotion;
- 50-move draw;
- insufficient-material draw.

## Signature capture cinematics

1. Pawn — Toe Stab.
2. Knight — Double Hind Kick.
3. Bishop — Ram Charge.
4. Rook — Jump Crush.
5. Queen — Transformation Spell.
6. King — Trapdoor Command.

## Audio settings

Pause with **Esc** to adjust:
- Master volume;
- Ambience;
- SFX.

## Camera rule

Gameplay uses a fixed **3/4 side angle** that keeps the complete board visible. Capture sequences switch to a separate cinematic battle camera.

## Project / source

Engine target: **Godot 4.7.2 stable**.

Production source includes:
- GDScript gameplay and chess logic;
- Blender asset generators;
- production GLB build pipeline;
- rig/animation generation scripts;
- automated chess, capture, UI, audio, presentation and release audits;
- automated gameplay/battle rendering and Visual QA.

See `DEVELOPMENT_PLAN.md` for the milestone history and checkpoint policy.
