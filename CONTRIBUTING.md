# Contributing

Short version for PRs. Architecture details: [CLAUDE.md](CLAUDE.md),
[docs/architecture.md](docs/architecture.md).

## Building

```bash
# Desktop (core + simulation, no device needed)
cmake -S . -B build
cmake --build build
./build/src/sim/tml_sim

# iOS (core + bootstrap dylib, needs full Xcode)
./scripts/build-ios.sh
```

## Testing

No automated test framework — the `src/sim/` simulation harness (60 FPS
update loop, fake player/world state) is the test path for core changes.
Order, see [CLAUDE.md](CLAUDE.md#dev-workflow-keep-the-order):

1. Implement the core feature in `src/core/`
2. Test it in the simulation (`src/sim/`) before touching the platform layer
3. Only then: the iOS/Android adapter

For iOS changes there's no simulator substitute for real IL2CPP access —
the test cycle (build → inject via Feather → Console.app logs) is in
[docs/ios-injection.md](docs/ios-injection.md).

## Hard rule: core/platform separation

`src/core/` must **never** know how it gets injected into the game — no
iOS/Android-specific code, no injection details, no offsets, no memory
hacking in the core. Communication only through `GameContext`. PRs that
blur this boundary won't be accepted.

## Honesty over marketing

This project deliberately documents what does **not** work
([docs/technical-limitations.md](docs/technical-limitations.md)), not just
what does. Please, in PRs:

- Don't describe features in a way that implies existing Terraria method
  behavior is being hooked when it's actually just a call/poll.
- New findings about limitations (e.g. another failed hooking attempt)
  belong in `docs/technical-limitations.md`, not quietly dropped.
- Experimental/concluded test code belongs in `experimental/` with a short
  rationale in the README there, not deleted and not left lying around in
  `src/`.

## Misc

- Naming: `PascalCase` for classes, `camelCase` for methods
- Header/source separated (`.hpp`/`.cpp` or `.h`/`.mm`)
- Larger concept/research documents belong in `docs/`, not in `CLAUDE.md`
  (which should stay under ~5k tokens)
