# Battle Chess Revival

A playable 3D Battle Chess-inspired game built with **Godot 4.7.2**.

## Current status

The project is in **G3 final public release freeze**. The latest verified checkpoint is G2, and the final public build pipeline is being hardened with persistent settings and scalable graphics quality presets.

## Core features

- complete legal chess layer;
- AI and local 2-player modes;
- deterministic Black AI with Easy / Normal / Hard difficulties;
- move history and Undo;
- last-move and check-danger board feedback;
- castling, en passant and promotion choice to Queen / Rook / Bishop / Knight;
- threefold repetition, 50-move and insufficient-material draws;
- full-board 3/4 gameplay camera;
- separate cinematic battle camera;
- six production character families on both sides;
- Skeleton3D authored animation sets for every family;
- six signature capture cinematics with impact VFX, audio and camera feedback;
- production cathedral environment with stained-glass lighting;
- production HUD, pause/settings, move-history, check/checkmate and endgame presentation;
- persistent game/audio/graphics settings;
- Low / Medium / High graphics quality presets;
- Windows x86_64 export.

## Controls

- **Left Mouse Button** — select a piece / choose a destination.
- **Esc** — pause, settings and full move history.
- **U** — Undo. In local mode it reverts one ply; against AI it reverts the player's move plus the AI reply.
- **R** — start a new match / rematch.
- **A** — toggle AI / local mode.
- **1–6** — developer preview of the six signature capture cinematics when debug preview input is available.

## Chess rules

White starts. In AI mode the player controls White and Black replies automatically.

Supported rules:
- check and checkmate;
- stalemate;
- castling;
- en passant;
- promotion choice: Queen / Rook / Bishop / Knight;
- threefold repetition;
- 50-move draw;
- insufficient-material draw.

## Signature capture cinematics

1. Pawn — Toe Stab.
2. Knight — Double Hind Kick.
3. Bishop — Ram Charge.
4. Rook — Jump Crush.
5. Queen — Transformation Spell.
6. King — Trapdoor Command.

## Settings

Pause with **Esc** to adjust:
- game mode;
- AI difficulty;
- graphics quality;
- Master volume;
- Ambience;
- SFX.

These settings persist between launches.

## Camera rule

Gameplay uses a fixed **3/4 side angle** that keeps the complete board visible. Capture sequences switch to a separate cinematic battle camera.

## Project / source

Engine target: **Godot 4.7.2 stable**.

Production source includes:
- GDScript gameplay and chess logic;
- Blender asset generators;
- production GLB build pipeline;
- rig/animation generation scripts;
- automated chess, AI, undo, promotion, UI, audio, presentation and release audits;
- automated gameplay/battle rendering and Visual QA.

See `DEVELOPMENT_PLAN.md` and `PROJECT_STATE.md` for milestone history, verified checkpoints and rollback policy.
