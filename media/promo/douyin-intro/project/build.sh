#!/usr/bin/env bash
# Rebuild OpenGameAgent-douyin.mp4 from voice-original.m4a.
# Requires: python3, numpy, playwright (chromium), ffmpeg.
set -euo pipefail
cd "$(dirname "$0")"
SRC=../voice-original.m4a
ffmpeg -v error -y -i "$SRC" -ac 1 -ar 16000 -f s16le raw.pcm          # 1. PCM for alignment
python3 align.py                                                        # 2. subtitle timing + mouth levels -> data.json
ffmpeg -v error -y -i "$SRC" -t 37 \
  -af "highpass=f=80,afftdn=nf=-25,loudnorm=I=-14:TP=-1.5:LRA=11,afade=t=out:st=36.3:d=0.7" \
  -ar 48000 -ac 2 voice_clean.wav                                       # 3. clean + normalize voice
python3 render.py full 37                                               # 4. render 1080x1920@30 frames -> silent.mp4
ffmpeg -v error -y -i silent.mp4 -i voice_clean.wav -c:v copy -c:a aac -b:a 192k \
  -shortest -movflags +faststart ../OpenGameAgent-douyin.mp4            # 5. mux
rm -f raw.pcm voice_clean.wav silent.mp4 page_built.html
echo "done -> ../OpenGameAgent-douyin.mp4"
