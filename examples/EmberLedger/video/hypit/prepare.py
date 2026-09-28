from pathlib import Path
import subprocess,json,wave,math,struct,shutil
root=Path(__file__).resolve().parent
ff=shutil.which('ffmpeg'); probe=shutil.which('ffprobe')
shots=[(35.7,3),(2.5,4),(6.5,4),(16,4),(28,5),(35,8),(43,4),(47,4)]
filters=[]
for i,(start,dur) in enumerate(shots): filters.append(f'[0:v]trim=start={start}:duration={dur},setpts=PTS-STARTPTS,setsar=1[v{i}]')
filters.append(''.join(f'[v{i}]' for i in range(len(shots)))+'concat=n=8:v=1:a=0[out]')
subprocess.run([ff,'-y','-loglevel','error','-i',str(root/'../../build/gameplay.avi'),'-filter_complex',';'.join(filters),'-map','[out]','-c:v','libx264','-preset','veryfast','-crf','18','-pix_fmt','yuv420p','-an',str(root/'assets/edit.mp4')],check=True)
lines=['宗门招的不是弟子，是炼丹材料。','第一世，信了师父。免费丹药，换掉一条命。','重来一次，带回的不是战力，是记忆。','出门的通行牌，竟然也是回收凭据。','第三世，我翻开名册。上面有我，也有他。','这次，烧掉他们的规矩。剑阵破围，护体扛伤，闪身躲阵。','少一点血，多一个活人。我们一起走。','如果重来，你会先记住哪一个谎？']
starts=[0,3,7,11,15,20,28,32];durations=[3,4,4,4,5,8,4,4]
inputs=[];audio_filters=[]
for i,line in enumerate(lines):
 p=root/f'assets/voice{i}.aiff';subprocess.run(['say','-v','Tingting','-r','260','-o',str(p),line],check=True)
 d=float(subprocess.check_output([probe,'-v','error','-show_entries','format=duration','-of','default=nw=1:nk=1',str(p)]))
 speed=max(1,d/(durations[i]-.2));inputs+=['-i',str(p)]
 audio_filters.append(f'[{i}:a]atempo={speed:.5f},volume=1.3,adelay={starts[i]*1000}|{starts[i]*1000}[a{i}]')
# Original minimal pentatonic chip score, no external audio samples.
sr=48000
with wave.open(str(root/'assets/score.wav'),'wb') as w:
 w.setparams((1,2,sr,0,'NONE','not compressed'))
 for n in range(sr*36):
  t=n/sr; beat=t%0.4; freq=[146.83,174.61,220,261.63,220,174.61,164.81,130.81][int(t/.4)%8]
  pulse=(1 if math.sin(2*math.pi*freq*t)>0 else -1)*.026*max(0,1-beat/.22)
  bass=math.sin(2*math.pi*73.42*t)*.025
  val=(pulse+bass)*min(1,t/.3,max(0,(36-t)/1))
  w.writeframesraw(struct.pack('<h',int(val*32767)))
inputs+=['-i',str(root/'assets/score.wav')];audio_filters.append('[8:a]volume=0.8[a8]')
audio_filters.append(''.join(f'[a{i}]' for i in range(9))+'amix=inputs=9:duration=longest:normalize=0,alimiter=limit=0.9,apad,atrim=duration=36[mix]')
subprocess.run([ff,'-y','-loglevel','error',*inputs,'-filter_complex',';'.join(audio_filters),'-map','[mix]','-ar','48000','-ac','2',str(root/'assets/mix.wav')],check=True)
print('MEDIA_READY')
