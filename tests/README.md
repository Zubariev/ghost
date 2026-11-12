# Test Infrastructure

**Engine**: Godot 4.7.2
**Test Framework**: GdUnit4 (v6.2.x)
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-11-12

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
```

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> **Manual evidence lives under `production/qa/evidence/`, not `tests/`** — that
> is where every consumer reads it.

## Installing GdUnit4

1. Open Godot → Asset Store (AssetLib before Godot 4.7) → search "GdUnit4" → install it
2. Enable the plugin: Project → Project Settings → Plugins → GdUnit4 ✓
3. Restart the editor
4. Verify: `res://addons/gdUnit4/bin/GdUnitCmdTool.gd` exists (capital U)

Commit `addons/gdUnit4/`: CI runs the committed copy (`version: 'installed'`).

## Running Tests

Godot is not on PATH on this machine; use the full path (`engine.path` in `project.yaml`):

```bash
/home/ther0/Games/godot --headless --path . --import
/home/ther0/Games/godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

Run the import first: without a `.godot/` class cache the runner fails to load and
exits 1 having run nothing.

Exit codes: **0** all passed · **100** a test failed · **101** all passed but nodes
leaked (warning) · **103/104** gdUnit4 could not run · **105** a test script does not
parse. Two `ERROR:` lines about the remote port `127.0.0.1:0` are expected.
`No test cases found` with exit 0 is **not** a pass.

## Test Naming

Names follow the engine's language (`.claude/rules/test-standards.md`):
- **Godot**: file `[system]_[feature]_test.gd`, function `test_[scenario]_[expected]`
  — `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Retained screenshot of each screen touched | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging.
