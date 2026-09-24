---
name: verify
description: Verify a change before it is reported done or goes into a PR. Use before every commit you hand over, before opening or merging a PR, and when the user asks "is it working?" Covers C# code, docs, and generated media such as SVG, video, and audio.
---

# /verify — prove the change works before saying it does

GitHub Actions (`.github/workflows/ci.yml`) runs the automated build, test, format, and package checks on every push and pull request. This skill adds the checks CI does not run, such as rendering media and reading the output, and requires you to run the local gates before pushing and report the evidence. A change is not done until you have checked it and can show the output.

## Rules

1. **Check the artifact, not your intent.** Run it, render it, parse it, or read it back. "The script exited 0" does not show that the output is right.
2. **Look at visual output yourself.** For anything visual, take screenshots at the key moments and read the images. Most layout bugs only show up this way.
3. **Reproduce from the committed files.** Re-run the committed scripts from a clean checkout path and compare byte-for-byte (`cmp`) with what you delivered.
4. **Fix what you find, then re-verify.** Report every fix, even small ones such as an overlap or an off-screen label.
5. **Say what you did not verify.** For example: "full video re-render not re-run", or "subtitle timing assumes the narrator read the script". Never imply more coverage than you have.
6. **A blocker that returns the same result every time is not flaky.** An auth 403 or a missing permission will not change on retry. Stop retrying and hand it to `/need-human`.

## Gate by change type

### C# / runtime code (`src/`, `tests/`, `engines/`, `examples/`, `tools/`)

Run these in order and stop at the first failure:

```powershell
dotnet restore OpenGameAgent.sln
dotnet build OpenGameAgent.sln -c Release --no-restore
dotnet test OpenGameAgent.sln -c Release --no-build --no-restore
dotnet format OpenGameAgent.sln --verify-no-changes --no-restore
```

- Check that the tests `AGENTS.md → Change guidance` requires for this kind of change exist and pass. Examples: tests for duplicate, uncertain-outcome, and recovery cases for state-changing tools; event-order and limit tests for kernel changes.
- If an engine package changed, run its package gate (`engines/*/test-package.ps1`). Also list the real-editor smoke test from `docs/engine-integration.md` that is still owed.
- Re-check the non-negotiable boundaries in `AGENTS.md`. Grep the diff for absolute local paths, credentials, and engine SDK types inside `src/`.

### Docs / README

- If you changed product, version, or compatibility information, confirm that `README.md` and `README.zh-CN.md` were both updated.
- Links: every relative link in the diff must point to a file that exists.

### Animated SVG

- `python3 -c "import xml.dom.minidom as m; m.parse('<file>.svg')"`: must parse. Watch for duplicate attributes, which often come from two `class=` attributes on one element.
- Render key frames with Playwright. Pause all animations at time `t`, for example `document.getAnimations().forEach(a => { a.pause(); a.currentTime = t*1000 })`. Screenshot one frame per scene into a contact sheet, then read the image.
- Check each frame for: overlapping text, elements cut off at the edge, and elements drawn in the wrong place. A CSS `transform` animation overrides a `transform=` attribute on the same element; the fix is to wrap the element in an extra `<g>`.
- Check that CJK text renders (Noto Sans CJK is installed in the cloud sandbox) and that the loop timing matches the scene windows.

### Video (e.g. vertical short-form)

- Specs: `ffprobe -show_entries format=duration,size:stream=codec_name,width,height,r_frame_rate`. Expect H.264 + AAC, the intended resolution (1080×1920 for vertical), 30 fps, and the expected duration.
- Loudness: `ffmpeg -i out.mp4 -af ebur128 -f null -`. Target about -14 LUFS integrated.
- Frames: extract frames with `ffmpeg -ss <t> -frames:v 1` at several timestamps across all sections. Read them and check subtitles, overlap, and the platform safe zones (keep clear of the right-side buttons and the bottom caption area).
- Sync: if subtitles were aligned by assumption rather than by speech recognition, say so and ask the user to spot-check.
- Reproducibility: the committed `build.sh` must rebuild the output from the committed source audio. At minimum, re-run the alignment step and `cmp` its `data.json` against the delivered one.

### Git / PR delivery

- `git status --short` (uncommitted and untracked files) and `git diff --stat <target-branch>...HEAD` (every commit in the PR): exactly the intended files, and no scratch files (frames, `raw.pcm`, `page_built.html`).
- Binary types (`*.mp4`, `*.m4a`) are marked `binary` in `.gitattributes`. Flag any addition over about 10 MB as repository-size debt.
- After the push, list the PR's files through the GitHub connector and confirm the count and paths. After the merge, read the target path on `main` and confirm the files exist.

## Report format

Finish with a short block:

```
Verified:
- <check> → <result>   (one line each, with the command or method)
Fixed during verification:
- <issue> → <fix>
Not verified:
- <gap and why>
```
