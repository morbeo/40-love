# 40 love

A minimalist, procedurally generated arcade tennis game for the browser, with a
deep, fighting-game-like shot system inspired by *Mario Tennis Aces*. Same
spirit, our own characters and look. It's built in **Godot 4** and documented
step by step as a way to learn the engine.

## How to read this devlog

Each entry matches one small pull request. Every entry has:

- **Read the code in this order**: the files in that PR, and what to look for.
- **Design**: what we decided, what else we considered, and why.
- **Godot**: the engine features used, how to reach them in the editor, and
  why Godot works that way.
- **Visuals**: diagrams, charts and footage. Charts and footage are generated
  from the real game, so they never go stale.
- **Try it yourself**: small experiments to poke at what the entry built.

## Step 1: the foundation

| # | Entry |
|---|---|
| 0 | [Setting up the workshop](devlog/000-setup.md) |
| 1 | [The court and its coordinates](devlog/001-court.md) |
| 2 | [The ball: flight, bounce and net](devlog/002-ball.md) |
| 3 | [Aiming: the shot solver](devlog/003-shot-solver.md) |
| 4 | [The rules: referee and scoring](devlog/004-rules.md) |

## The plan

| Step | What |
|---|---|
| 1 | Foundation: project, tested simulation core, viewer, CI/CD, devlog |
| 2 | Camera spike: fake-3D vs real 3D, keyboard + gamepad |
| 3 | Shot system: full shot matrix, meter, trick/zone/special shots, training mode |
| 4 | Playable match: procedural characters, CPU, match presets, procedural look and sound |
| later | Court surfaces, wind, mobile |

## Ground rules

- **Zero imported assets.** Meshes, colours, and later sounds are all generated
  in code.
- **The simulation is pure and deterministic.** Same seed + same inputs = same
  match, every time. That makes it testable and replayable.
- **Test first.** Every rule of tennis and every mechanic gets a test before it
  gets a feature.
