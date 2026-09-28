# ASH LEDGER / 烬籍：魔门余生

A playable Godot 4.5 dark-cultivation survival vignette. This remakes the previous Echo Squad concept around **finite lives, information acquired through failure, active memory selection, and morally costly escape**. It is an original scenario inspired by the publicly available premise of [《苟在初圣魔门当人材》, 鹤守月满池](https://www.qidian.com/book/1043182343/), not an official adaptation, a reconstruction of novel chapters, or a copy of its prose/characters.

Open `game/project.godot` with Godot 4.5.1 and run. The same project exports to a single-threaded WebGL game. The included Chinese font is a renamed Noto Sans CJK subset under the SIL Open Font License (see `game/FONT-LICENSE.txt`). All sprites are original code-authored pixel art.

## Chapter 1: 领丹日

Three linked conflicts inside one courtyard:

1. The herbalist's welcome gift is poisoned. Taking it consumes a life and reveals **甜灰入喉**. Equip that memory to unlock testing the pill; refusing it is also a valid route.
2. The clerk's exit contract carries a hidden recall seal. Using the pass kills the signed disciple and reveals **归炉之印**. Equip it to expose the hidden clause, or investigate without signing.
3. The furnace ledger lists disciples as its consumables. Examining it reveals **活人名册**. The player must equip this fragment before the furnace's escape options become available.

Burning the ledger costs 25 HP and lets both you and A-YAN escape. Removing only your name costs 10 HP but leaves A-YAN behind. Spirits pursue the escape; player and companion use talisman projectiles. These are two distinct endings.

A round begins with four lives. Death consumes a life; there are no automatic stat boosts. After all lives are spent, starting another round is an explicit choice. Up to three discovered fragments and the selected fragment persist locally between launches. The current life, position, round life count and quest flags reset on a new application launch. Exactly one fragment is active. Discovery never auto-equips it. The backpack allows rereading and changing the active fragment. A-YAN is invulnerable in this prototype.

## Controls

- WASD/arrows: move; E: nearby interaction; Space/left mouse: auto-aim talisman attack.
- 1–4: select a dialog option while a dialog is open; otherwise follow/hold/cover/scout companion orders.
- M: memory backpack; click a fragment to read and equip it, then return to the courtyard.
- Enter: optional natural-language companion order; Escape: close a live dialog or cancel text entry.
- Touch: on-screen movement, attack, interact and backpack buttons.

Dialog and model requests pause the world. The UI marks locked memory options. The capture driver (`--demo`) uses ordinary movement, dialog choices, memory selection and consequences: no teleporting, free lives, invisible gate unlocks or skipped costs. It starts with an isolated empty memory inventory and never touches the player's save.

## OpenGameAgent integration

`agent/AshLedger.Agent.csproj` references this repository's actual runtime and OpenAI-compatible provider. The model can propose only `follow`, `hold`, `cover`, or `scout`. It sees the current world and **equipped** memory, not undiscovered or unequipped fragments. Godot validates mode, run ID and epoch; stale responses cannot mutate a new life. The model cannot select story options, sign contracts, equip memories, spend lives or choose an ending.

The web game and trailer use explicit offline rules. No live/paid model calls were used for verification. To enable a tool-capable model in the native game, deliberately set the following environment variables for the sidecar:

```sh
export ASH_ENABLE_MODEL=1
export ASH_MODEL_ENDPOINT='https://YOUR_PROVIDER/v1/chat/completions'
export ASH_MODEL='YOUR_TOOL_CAPABLE_MODEL'
# Set ASH_MODEL_KEY securely in the environment if required; never commit it.
dotnet run --project examples/AshLedger/agent
```

Launch the native game in another terminal:

```sh
ASH_AGENT_URL=http://127.0.0.1:8787 godot --path examples/AshLedger/game
```

The sidecar binds loopback only, rejects browser-origin requests, limits the body to 8 KiB, allows one request at a time, uses a 15-second deadline and a 50-request process budget. Runtime limits: two turns, 2,048 total tokens, 256 output tokens per call. `ASH_AGENT_PORT` can override the port. Provider-specific language understanding remains unverified until a real model is configured.

## Validation and export

```sh
godot --headless --path examples/AshLedger/game --editor --import --quit
godot --headless --path examples/AshLedger/game --quit-after 10 -- --self-test
godot --headless --path examples/AshLedger/game --fixed-fps 60 --quit-after 3600 -- --demo
dotnet build examples/AshLedger/agent -c Release
dotnet run --project examples/AshLedger/agent -c Release --no-build -- --self-test
python3 examples/AshLedger/agent/check_http.py
```

Tests cover discovery without automatic equip, locked/unlocked memory choices, both scripted deaths and life deductions, contract counterplay, both escape costs and rescue-state branches, invalid companion intents, and stale responses across lives. The HTTP test uses a local OpenAI-compatible SSE fixture to exercise real provider transport and runtime tool dispatch, without an external model.

With the Godot 4.5.1 web export template installed:

```sh
mkdir -p examples/AshLedger/build/web
godot --headless --path examples/AshLedger/game --export-release Web
python3 examples/AshLedger/tools/pack_web.py
python3 -m http.server --directory examples/AshLedger/build/web 8000
```

The packer compresses WebAssembly for static hosts with a 25 MiB asset limit. Modern WebGL 2 and `DecompressionStream` are required. `?demo=1` starts an explicitly labelled capture rehearsal, without modifying saved memory.

## Reproduce the new 50-second trailer

```sh
mkdir -p examples/AshLedger/build
godot --path examples/AshLedger/game --resolution 1280x800 --write-movie "$PWD/examples/AshLedger/build/gameplay.avi" --fixed-fps 30 --disable-vsync --quit-after 1500 -- --demo
python3 examples/AshLedger/video/make_cards.py
bash examples/AshLedger/video/render.sh
```

Requires a display, Python/Pillow, a CJK font (`ASH_FONT` can specify it), and FFmpeg with libx264. The film contains a 3-second hook, 40 seconds of continuous real gameplay and a 7-second closing card. Its original pentatonic pulse soundtrack is synthesized by the supplied script; there is no voiceover. No novel prose or official artwork is reused. Generated engine state and media are excluded from Git.

The updated design app retains the infinite canvas, movable shot cards, rough/storyboard/fine views, coarse presets that override finer settings, JSON copy/export/import, and explicit separation between editable plans and the fixed rendered MP4.
