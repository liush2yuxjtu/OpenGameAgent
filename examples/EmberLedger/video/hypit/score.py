"""Original chip score: low volume, moment-specific cues. No sampled third-party audio."""
import wave,numpy as np
from pathlib import Path
sr=48000;dur=36;y=np.zeros(sr*dur)
def note(at,f,d,a=.09,shape='sine'):
 n=int(sr*d);t=np.arange(n)/sr
 if shape=='pulse':v=np.tanh(3*np.sin(2*np.pi*f*t))*.7
 else:v=np.sin(2*np.pi*f*t)
 env=np.minimum(1,t/.012)*np.maximum(0,1-t/d)**1.8
 i=int(at*sr);k=min(n,len(y)-i)
 if k>0:y[i:i+k]+=a*v[:k]*env[:k]
seq=[293.66,349.23,440,523.25,440,349.23,329.63,261.63]
for j in range(63):
 t=j*4/7
 if 15.7<t<18 or 24.7<t<27.6:continue
 note(t,seq[j%8],.42,.042,'pulse')
 if j%4==0:note(t,146.83 if j%8<4 else 130.81,.8,.058)
for at in [5.55,18.65,21.7,22.65]:
 note(at,880,.13,.11,'pulse');note(at+.1,1174.66,.18,.095,'pulse')
for at in [0,16,25]:
 for f,a in [(146.83,.12),(293.66,.06),(587.32,.025)]:note(at,f,2,a)
for j,f in enumerate([293.66,349.23,440,587.32]):note(28+j*.22,f,1,.055)
y[-sr:]*=np.linspace(1,0,sr);y=np.clip(y,-.92,.92);st=np.repeat(y[:,None],2,axis=1)
p=Path(__file__).parent/'assets/score.wav'
with wave.open(str(p),'wb') as w:w.setnchannels(2);w.setsampwidth(2);w.setframerate(sr);w.writeframes((st*32767).astype('<i2').tobytes())
print('Original score',p,'peak',float(abs(y).max()))
