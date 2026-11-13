# Contributing

## Workflow

1. Branch from `main`: `feat/...`, `fix/...`, `docs/...`.
2. **Test first.** Write or update the test, watch it fail, then make it pass.
3. `./dev check` (lint + tests) must pass before you push.
4. Open a PR whose **title follows [Conventional Commits](https://www.conventionalcommits.org)**:
   `feat(sim): add charge shots`, `fix(view): ball shadow flicker`,
   `docs: devlog #2`. PRs are squash-merged, so the title becomes the commit
   that the changelog is built from. CI checks the format.
5. Each plan step ships with its **devlog entry** in `docs/devlog/`. Run
   `./dev media` if the footage or charts should change, and
   `./dev docs serve` to preview.

## Commit messages

Conventional Commits, with a short subject and a body that says *why*:

```text
feat(sim): spin-aware bounce

Friction acts on the contact-point slip, so topspin kicks and slice
keeps skidding. Capped at pure rolling for a hollow sphere.
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`, `chore`.

## Rules for the simulation (`src/sim/`)

- No `Node`s, no rendering, no `Time`/`OS` clocks, no global `randf()`.
  Randomness goes through the sim's seeded `RandomNumberGenerator`.
- Same seed + same inputs must give the same result every tick. The
  determinism tests enforce this.
- If you intentionally change physics, rules or bot behaviour, update the
  golden-master test in `test/integration/test_match_sim.gd` and say why
  in the commit.

## Style

`./dev fmt` formats everything (gdformat, 100 columns). Use static types
(`var x: int`, `:=`) everywhere. Document classes and public functions with
`##` doc comments: they show up in Godot's built-in help (F1).
