#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p ../build/media
ffmpeg -y -hide_banner -loglevel error -i ../build/gameplay.avi -loop 1 -i cards/intro.png -loop 1 -i cards/first.png -loop 1 -i cards/second.png -loop 1 -i cards/memory.png -loop 1 -i cards/escape.png -loop 1 -i cards/outro.png -i cards/ash-pulse.wav -filter_complex '[1:v]trim=duration=3,setpts=PTS-STARTPTS,fps=30,format=yuv420p[i];[2:v]trim=duration=7,setpts=PTS-STARTPTS,fps=30[b1];[3:v]trim=duration=14,setpts=PTS-STARTPTS,fps=30[b2];[4:v]trim=duration=12,setpts=PTS-STARTPTS,fps=30[b3];[5:v]trim=duration=7,setpts=PTS-STARTPTS,fps=30[b4];[b1][b2][b3][b4]concat=n=4:v=1:a=0[bg];[0:v]trim=duration=40,scale=928:580:flags=neighbor,setpts=PTS-STARTPTS[game];[bg][game]overlay=322:70:shortest=1,format=yuv420p[g];[6:v]trim=duration=7,setpts=PTS-STARTPTS,fps=30,format=yuv420p[o];[i][g][o]concat=n=3:v=1:a=0,setsar=1[v]' -map '[v]' -map 7:a -t 50 -c:v libx264 -preset fast -crf 22 -threads 2 -c:a aac -b:a 96k -movflags +faststart ../build/media/ash-ledger-trailer.mp4
for pair in '1 0.2' '2 3' '3 17' '4 30' '5 36' '6 39'; do read -r n t <<< "$pair"; ffmpeg -y -hide_banner -loglevel error -ss "$t" -i ../build/gameplay.avi -frames:v 1 -vf scale=960:600 ../build/media/shot-$n.jpg; done
cp ../build/media/shot-1.jpg ../build/media/poster.jpg
ffprobe -v error -show_entries format=duration,size -of json ../build/media/ash-ledger-trailer.mp4
