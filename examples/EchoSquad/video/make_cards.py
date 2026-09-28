from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import math,wave,struct,os
root=Path(__file__).parent;out=root/'cards';out.mkdir(exist_ok=True)
candidates=[os.getenv('ECHO_FONT',''),str(Path.home()/'.local/share/fonts/NotoSansCJKsc-Regular.otf'),'/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc','/System/Library/Fonts/STHeiti Medium.ttc']
font=next((p for p in candidates if p and Path(p).exists()),None)
if not font: raise SystemExit('Set ECHO_FONT to a CJK font file.')
bold=font
def card(name,kicker,lines,sub,full=False):
 im=Image.new('RGB',(1280,720),'#101915');d=ImageDraw.Draw(im)
 for x in range(0,1280,32):
  for y in range(0,720,32):d.rectangle((x,y,x+1,y+1),fill='#233226')
 d.rectangle((28,28,1252,692),outline='#41543b',width=1)
 x=80 if full else 48
 def t(x,y,text,size,color='#e6eddf',b=False):d.text((x,y),text,font=ImageFont.truetype(bold if b else font,size),fill=color)
 t(x,74,kicker,14,'#a2b595')
 for i,line in enumerate(lines):t(x,(220 if full else 248)+i*(76 if full else 51),line,64 if full else 37,'#c4ed81' if i==len(lines)-1 else '#edf2e7',True)
 for i,line in enumerate(sub):t(x,(470 if full else 434)+i*25,line,18 if full else 13,'#a7b6a7')
 t(x,643,'GODOT × OPENGAMEAGENT',13,'#8da281')
 if full:t(985,644,'PIXEL CO-OP / 01',12,'#8da281')
 im.save(out/f'{name}.png')
card('intro','ECHO SQUAD / 回声小队',['这扇门，','一个人打不开。'],['两块机关板。一枚核心。两个必须回来的队友。'],True)
card('order','01 / THE ORDER',['你守住','另一边。'],['4 SOUTH PLATE','明确指令 · 实机演练'])
card('gate','02 / THE PAYOFF',['两个位置。','一个目标。'],['双板同时点亮','激光门，真的打开。'])
card('extract','03 / TOGETHER',['带回核心。','也带回队友。'],['1 FOLLOW → 撤离区','一起到达，才算赢。'])
card('outro','GODOT PIXEL CO-OP / PLAYABLE PROTOTYPE',['ECHO SQUAD','下一局，一起。'],['立即试玩  /  OpenGameAgent GitHub 源码','本片：离线指令。自然语言模型尚未连接。'],True)
# Original procedural 8-bit pulse soundtrack; no licensed music or generated speech.
sr=24000;duration=30
with wave.open(str(out/'pulse.wav'),'wb') as w:
 w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr)
 notes=[110,110,146.83,130.81,110,164.81,146.83,98]
 buf=bytearray()
 for i in range(sr*duration):
  t=i/sr;beat=t*2;part=beat%1;freq=notes[int(beat)//2%8]
  bass=(1 if math.sin(2*math.pi*freq*t)>0 else -1)*.07*max(0,1-part*2)
  kick=math.sin(2*math.pi*(54*t+6*(1-math.exp(-part*35))))*.18*math.exp(-part*18)
  arp=math.sin(2*math.pi*freq*4*t)*.045*max(0,1-(t*4%1)*4)
  env=min(1,t/1.5,(duration-t)/2)
  buf.extend(struct.pack('<h',int(max(-1,min(1,(bass+kick+arp)*env))*32767)))
 w.writeframes(buf)
print('cards and original soundtrack ready')
