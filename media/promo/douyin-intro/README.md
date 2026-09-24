# OpenGameAgent — Douyin intro video

A 37-second vertical (1080×1920, 30 fps) promo video for Douyin, voiced by a human narrator with an original cartoon host avatar, plus a 38-second looping SVG explainer.

| File | What it is |
| --- | --- |
| `OpenGameAgent-douyin.mp4` | Final cut: H.264 video + AAC audio, loudness-normalized to -14 LUFS |
| `voice-original.m4a` | Original, unprocessed voice recording |
| `project/page.html` | Frame renderer: a deterministic `render(t)` for every scene, subtitles, and the avatar |
| `project/align.py` | Aligns script clauses to speech pauses → `data.json` (subtitle timing + per-frame mouth level) |
| `project/data.json` | Timing data used for the current cut |
| `project/render.py` | Drives headless Chromium frame-by-frame and pipes the frames into ffmpeg |
| `project/build.sh` | Rebuilds the full video from `voice-original.m4a` |
| `svg/OpenGameAgent-intro.svg` | Animated SVG explainer (CSS/SMIL, 960×540) |
| `svg/gen_svg.py` | Generator for the SVG |

## Rebuild

```bash
pip install numpy playwright   # plus ffmpeg and Chromium
./project/build.sh
```

Subtitle timing assumes the narrator read the script in `align.py`, so each clause is placed by proportional alignment snapped to the detected pauses. To fix a line, edit the clause text or its `t0`/`t1` in `data.json` and run only steps 3–5 of `build.sh`.

No background music is included; add a trending sound when you publish on Douyin.
