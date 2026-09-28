# ECHO SQUAD / 回声小队

A playable Godot 4.5 pixel action prototype built around one visible cooperation problem: **one player cannot hold two pressure plates**. Order NOVA to the south plate, take the north plate, recover the core, and extract together.

## Play now

Open `game/project.godot` in Godot 4.5.1 standard edition and press F6 on `Main.tscn` (or F5). No model, API key, .NET, imported art, or network access is needed for offline play.

| Input | Action |
|---|---|
| WASD / arrows | Move |
| Mouse + left button | Aim and shoot |
| Space | Shoot at nearest enemy |
| 1 / FOLLOW | NOVA follows you |
| 2 / HOLD | NOVA holds its current position |
| 3 / COVER | NOVA trails farther behind and fires |
| 4 / SOUTH PLATE | NOVA navigates to plate B |
| E | Collect the core when nearby |
| Enter | Send a natural-language order to the optional local agent |
| R | Restart |

Both plates must remain occupied for 1.2 seconds. The door then stays open. After collecting the core, use FOLLOW and return to the left extraction zone with NOVA. The run ends after 1.5 seconds together, player death, or 150 seconds. NOVA is invulnerable in this first prototype. Cover and follow both auto-fire; they differ in formation distance. Winning stores only a win count and last successful `plate` order in Godot's local user data. This is not semantic memory or autonomous learning.

The web build uses the same GDScript and scene. It provides offline orders; the browser does not carry a model key or connect to a local sidecar. Touch controls provide movement/fire; approaching the core collects it on touch devices.

## Connect OpenGameAgent (native game)

The sidecar references this repository's actual `OpenGameAgent` and `OpenGameAgent.Providers.OpenAICompatible` projects. It runs the bounded runtime/tool loop, receives an intent proposal, and returns it to Godot. Godot validates the mode, run ID and epoch before applying it. The model cannot teleport actors, set health, unlock the gate, award victory, or run shell commands.

First run the free deterministic integration test with .NET 8:

```sh
dotnet run --project examples/EchoSquad/agent -- --self-test
```

To deliberately enable real model calls, configure your own OpenAI-compatible endpoint that supports tool calls. Set these variables in the sidecar terminal (do not commit secrets):

```sh
export ECHO_ENABLE_MODEL=1
export ECHO_MODEL_ENDPOINT='https://YOUR_PROVIDER/v1/chat/completions'
export ECHO_MODEL='YOUR_TOOL_CAPABLE_MODEL'
# Set ECHO_MODEL_KEY securely in your shell environment if the provider requires it.
dotnet run --project examples/EchoSquad/agent
```

In the native game's terminal:

```sh
ECHO_AGENT_URL=http://127.0.0.1:8787 godot --path examples/EchoSquad/game
```

Press Enter and try “守住南边的机关板” or “跟我撤离”. The world pauses during the request. Failure applies no action; explicit 1–4 orders still work. Calls are opt-in, one at a time, with 15-second deadlines, 8 KiB requests, a 50-request process budget, 2 runtime turns, 256 maximum output tokens per model call, and four allowed intents. The HTTP server binds loopback only and rejects browser-origin requests. Do not expose it as a public service.

**Validation boundary:** deterministic fixture tests exercise the real OpenGameAgent runtime and tool dispatch. No paid or live language model was used for this prototype's validation or trailer. Provider-specific end-to-end language behavior still needs a configured model.

## Verify and export

```sh
godot --headless --path examples/EchoSquad/game --editor --import --quit
godot --headless --path examples/EchoSquad/game -- --self-test
godot --headless --path examples/EchoSquad/game --fixed-fps 60 --quit-after 2400 -- --demo
dotnet build examples/EchoSquad/agent -c Release
dotnet run --project examples/EchoSquad/agent -c Release --no-build -- --self-test
python3 examples/EchoSquad/agent/check_http.py
```

The Godot checks cover invalid orders, gate collision, pickup, reset, stale responses, and movement collision. The demo traverses the full objective loop with the same rules as a player and prints `ECHO_WIN`; it does not skip enemies or unlock the gate by script. `--demo` explicitly labels itself offline rehearsal and does not change saved memory.

Install Godot's **4.5.1 web export template**, then:

```sh
mkdir -p examples/EchoSquad/build/web
godot --headless --path examples/EchoSquad/game --export-release Web
python3 examples/EchoSquad/tools/pack_web.py
python3 -m http.server --directory examples/EchoSquad/build/web 8000
```

The packer compresses the 36 MiB WebAssembly file and adds a local decompression loader so the static asset stays below a 25 MiB hosting limit. A modern browser with WebGL 2 and `DecompressionStream` is required. No cross-origin isolation or worker threads are needed. Add `?demo=1` for a labelled browser rehearsal.

## Reproduce the 30-second trailer

Capture actual rendered game frames (a display is required; headless uses a dummy renderer):

```sh
mkdir -p examples/EchoSquad/build
godot --path examples/EchoSquad/game --resolution 1280x800 --write-movie "$PWD/examples/EchoSquad/build/gameplay.avi" --fixed-fps 30 --disable-vsync --quit-after 600 -- --demo
python3 examples/EchoSquad/video/make_cards.py
bash examples/EchoSquad/video/render.sh
```

Requires Python/Pillow, a CJK font (`ECHO_FONT` may specify one), and FFmpeg with libx264. The title cards, pixel sprites, and procedural pulse soundtrack are original code-authored assets. Trailer structure: 3-second hook, 20 seconds of continuous gameplay with three chapter labels, and a 7-second closing card. This recording demonstrates offline orders, not model reasoning. Generated engine state and media are excluded from Git.

The accompanying design app preserves infinite-canvas pan/zoom, draggable shot cards, rough/storyboard/fine views, coarse presets overriding all finer settings, parameter sliders, JSON export, copy-to-chat and import. Editing those settings updates the design, not an already exported MP4.
