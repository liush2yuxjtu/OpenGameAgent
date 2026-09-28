# EMBER LEDGER / 烬籍：夺炉夜

A playable Godot 4.5 dark-cultivation survival vignette. This remakes the previous Echo Squad concept around **finite lives, information acquired through failure, active memory selection, and morally costly escape**. It is an original scenario inspired by the publicly available premise of [《苟在初圣魔门当人材》, 鹤守月满池](https://www.qidian.com/book/1043182343/), not an official adaptation, a reconstruction of novel chapters, or a copy of its prose/characters.

Open `game/project.godot` with Godot 4.5.1 and run. The same project exports to a single-threaded WebGL game. The included Chinese font is a renamed Noto Sans CJK subset under the SIL Open Font License (see `game/FONT-LICENSE.txt`). Actor sprites are original code-authored pixel art; courtyard tiles reuse Kenney Tiny Dungeon under CC0.

## Chapter 1: 领丹日

Three linked conflicts inside one courtyard:

1. The herbalist's welcome gift is poisoned. Taking it consumes a life and reveals **甜灰入喉**. Equip that memory to unlock testing the pill; refusing it is also a valid route.
2. The clerk's exit contract carries a hidden recall seal. Using the pass kills the signed disciple and reveals **归炉之印**. Equip it to expose the hidden clause, or investigate without signing.
3. The furnace ledger lists disciples as its consumables. Examining it reveals **活人名册**. The player must equip this fragment before the furnace's escape options become available.

Burning the ledger costs 25 HP and lets both you and A-YAN escape. Removing only your name costs 10 HP but leaves A-YAN behind. Spirits pursue the escape; player and companion use talisman projectiles. These are two distinct endings.

A round begins with four lives. Death consumes a life; there are no automatic stat boosts. After all lives are spent, starting another round is an explicit choice. Up to three discovered fragments and the selected fragment persist locally between launches. The current life, position, round life count and quest flags reset on a new application launch. Exactly one fragment is active. Discovery never auto-equips it. The backpack allows rereading and changing the active fragment. A-YAN is invulnerable in this prototype.

## Controls

- WASD/arrows: move; E: nearby interaction; automatic talisman attacks. Q: sword ring, F: protective shield, R: dash.
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
dotnet run --project examples/EmberLedger/agent
```

Launch the native game in another terminal:

```sh
ASH_AGENT_URL=http://127.0.0.1:8787 godot --path examples/EmberLedger/game
```

The sidecar binds loopback only, rejects browser-origin requests, limits the body to 8 KiB, allows one request at a time, uses a 15-second deadline and a 50-request process budget. Runtime limits: two turns, 2,048 total tokens, 256 output tokens per call. `ASH_AGENT_PORT` can override the port. Provider-specific language understanding remains unverified until a real model is configured.

## Validation and export

```sh
godot --headless --path examples/EmberLedger/game --editor --import --quit
godot --headless --path examples/EmberLedger/game --quit-after 10 -- --self-test
godot --headless --path examples/EmberLedger/game --fixed-fps 60 --quit-after 3600 -- --demo
dotnet build examples/EmberLedger/agent -c Release
dotnet run --project examples/EmberLedger/agent -c Release --no-build -- --self-test
python3 examples/EmberLedger/agent/check_http.py
```

Tests cover discovery without automatic equip, locked/unlocked memory choices, both scripted deaths and life deductions, contract counterplay, both escape costs and rescue-state branches, invalid companion intents, and stale responses across lives. The HTTP test uses a local OpenAI-compatible SSE fixture to exercise real provider transport and runtime tool dispatch, without an external model.

With the Godot 4.5.1 web export template installed:

```sh
mkdir -p examples/EmberLedger/build/web
godot --headless --path examples/EmberLedger/game --export-release Web
python3 examples/EmberLedger/tools/pack_web.py
python3 -m http.server --directory examples/EmberLedger/build/web 8000
```

The packer compresses WebAssembly for static hosts with a 25 MiB asset limit. Modern WebGL 2 and `DecompressionStream` are required. `?demo=1` starts an explicitly labelled capture rehearsal, without modifying saved memory.

## Reproduce the 36-second Hypit trailer

Capture actual gameplay first (requires Godot and a display):

```sh
mkdir -p examples/EmberLedger/build
godot --path examples/EmberLedger/game --resolution 960x600 --write-movie "$PWD/examples/EmberLedger/build/gameplay.avi" --fixed-fps 30 --disable-vsync --quit-after 1650 -- --demo
cd examples/EmberLedger/video/hypit
npm install
npm run component:build
python3 prepare.py
npx hypit packages install @hyperframes/engine@0.7.101
npx hypit packages install @hyperframes/producer@0.7.101
npm run render
# Export the returned build ID with:
# npx hypit get BUILD_ID --output final.video --workspace . --to ../../build/ember-ledger-douyin.mp4
```

The preparation script requires macOS `say` with the Tingting voice, Python/Pillow and FFmpeg/FFprobe on PATH. Other platforms can replace the generated narration files. The supplied runtime configuration downloads a compatible browser; an installed Chrome can be configured locally. The 36-second film uses real gameplay, original synthesized chip music, Mandarin synthesized narration, and Hypit semantic titles. No novel prose or official artwork is reused. Generated engine state is excluded from Git.

## 2026-09-28 combat cut

Reuses the OpenGameAgent AshLedger Godot example at PR #2. New chapter treatment, circular actor tokens, automatic attacks, Q sword ring, F shield, R dash, visible furnace-area telegraphs, six spirits and a furnace boss. Extraction requires the enemies to be defeated. Kenney Tiny Dungeon CC0 tiles decorate the courtyard; original code-authored actor sprites are retained. Font subset was rebuilt from Noto Sans CJK with all new game and film text.

The playable Web export uses explicit offline companion orders. The C# OpenGameAgent sidecar is retained; this film does not depict live model reasoning. The sidecar was not reconfigured and has no new API spend.

Film source lives in video/hypit (Hypit 0.2.16). Actual Godot movie capture is edited by prepare.py, then imported as normalized media and composed with semantic shot titles and a mixed audio track through Hypit. Mandarin voice is macOS Tingting synthesis, not human recording. All media execution is local. 36 seconds, 720×1280, 30 fps. Virality is a creative objective; distribution performance has not been measured.

Verification: Godot 4.5.1 import and gameplay tests PASS; skill cooldown and AOE damage checks PASS; complete ordinary demo driver wins at 46.69 seconds, life 3, two lives remaining, HP 65, both characters rescued.

The Web build requires HTTPS and WebGL2. The managed cloud preview lacks these, so browser gameplay acceptance is not claimed; native Godot capture and integration fixtures passed. The film contains synthetic Mandarin narration; audio levels are checked by analysis, not a human listening review.
