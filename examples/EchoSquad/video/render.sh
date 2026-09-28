#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p ../build/media
ffmpeg -y -hide_banner -loglevel error -i ../build/gameplay.avi -loop 1 -i cards/intro.png -loop 1 -i cards/order.png -loop 1 -i cards/gate.png -loop 1 -i cards/extract.png -loop 1 -i cards/outro.png -i cards/pulse.wav -filter_complex '[1:v]trim=duration=3,setpts=PTS-STARTPTS,fps=30,format=yuv420p[i];[2:v]trim=duration=4,setpts=PTS-STARTPTS,fps=30[b1];[3:v]trim=duration=6,setpts=PTS-STARTPTS,fps=30[b2];[4:v]trim=duration=10,setpts=PTS-STARTPTS,fps=30[b3];[b1][b2][b3]concat=n=3:v=1:a=0[bg];[0:v]scale=928:580:flags=neighbor,setpts=PTS-STARTPTS[game];[bg][game]overlay=322:70:shortest=1,format=yuv420p[g];[5:v]trim=duration=7,setpts=PTS-STARTPTS,fps=30,format=yuv420p[o];[i][g][o]concat=n=3:v=1:a=0,setsar=1[v]' -map '[v]' -map 6:a -t 30 -c:v libx264 -preset fast -crf 24 -threads 2 -c:a aac -b:a 96k -movflags +faststart ../build/media/echo-squad-trailer.mp4
for pair in '1 0.8' '2 2' '3 5' '4 12' '5 18' '6 19'; do read -r n t <<< "$pair"; ffmpeg -y -hide_banner -loglevel error -ss "$t" -i ../build/gameplay.avi -frames:v 1 -vf scale=640:400 ../build/media/shot-$n.jpg; done
cp ../build/media/shot-3.jpg ../build/media/poster.jpg
ffprobe -v error -show_entries format=duration,size -of json ../build/media/echo-squad-trailer.mp4
