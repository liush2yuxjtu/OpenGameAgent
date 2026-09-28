# @game/loop-scene

Project-owned Hypit component for a portrait memory-loop game trailer.

Typed inputs: timeline, canvas, temporal window, exact FontArtifact, source image BlobArtifact, ordered Message values. Each Message owns its semantic instant (`at`). The component compiles a VisualTrack with exact-font children, declared image resources and a deterministic `render(frame)` program. No file reads, network calls, wall-clock timing or random state occur inside producers.

Edit dialogue and beat timing in `production.svml`. Edit layout, circles and transitions in `src/render.ts`. Build with `npm run component:build` at the project root. No opaque generated footage is required; every label and beat can be edited.

This is an authored gameplay illustration tied to the fixed tutorial, not a recording of live AI inference.
