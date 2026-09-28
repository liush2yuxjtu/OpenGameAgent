from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import math,wave,struct,os
root=Path(__file__).parent;out=root/'cards';out.mkdir(exist_ok=True)
candidates=[os.getenv('ASH_FONT',''),str(Path.home()/'.local/share/fonts/NotoSansCJKsc-Regular.otf'),'/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc','/System/Library/Fonts/STHeiti Medium.ttc']
font=next((p for p in candidates if p and Path(p).exists()),None)
if not font:raise SystemExit('Set ASH_FONT to a CJK font file.')
def card(name,kicker,lines,sub,full=False):
 im=Image.new('RGB',(1280,720),'#101820');d=ImageDraw.Draw(im)
 for x in range(0,1280,32):
  for y in range(0,720,32):d.rectangle((x,y,x+1,y+1),fill='#293233')
 d.rectangle((28,28,1252,692),outline='#6e614e',width=1)
 x=80 if full else 46
 def text(x,y,s,size,color='#e9d8b7'):d.text((x,y),s,font=ImageFont.truetype(font,size),fill=color)
 text(x,74,kicker,14,'#a39780')
 for i,line in enumerate(lines):text(x,(196 if full else 214)+i*(86 if full else 56),line,66 if full else 37,'#c98883' if i==len(lines)-1 else '#ead9b9')
 for i,line in enumerate(sub):text(x,(480 if full else 450)+i*26,line,19 if full else 14,'#a9b8b0')
 text(x,644,'ASH LEDGER / 烬籍',13,'#a39780')
 if full:text(960,644,'GODOT / PIXEL SURVIVAL',12,'#a39780')
 im.save(out/f'{name}.png')
card('intro','魔门余生 / 第一章 · 领丹日',['他们在招徒。','还是，在进货？'],['四次命数。三枚记忆。一次看穿规则的机会。'],True)
card('first','第一世 / 善意的价钱',['这颗赠丹，','要你的命。'],['死亡 → 记忆碎片','下一世，先学会试药。'])
card('second','第二世 / 规矩的背面',['躲过赠药。','还有契纸。'],['出门牌，是回收凭据。','每层好意，都有落款。'])
card('memory','第三世 / 主动记起',['记得，','还不够。'],['打开背包 → 装配碎片','亲手改变同一个选择。'])
card('escape','破局 / 两人的余生',['烧掉名册。','带他走。'],['气血 -25 / 两人离宗','也可以，只救自己。'])
card('outro','原创剧情 / 有限重开 × 主动记忆',['烬籍：魔门余生','下一世，别白活。'],['立即试玩 · Godot × OpenGameAgent','灵感参考《苟在初圣魔门当人材》，非官方改编。','实机画面为离线规则演练，未连接语言模型。'],True)
sr=24000;duration=50;notes=[146.83,164.81,196,220,293.66,220,196,164.81]
with wave.open(str(out/'ash-pulse.wav'),'wb') as w:
 w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr);buf=bytearray()
 for i in range(sr*duration):
  t=i/sr;beat=t*1.6;part=beat%1;freq=notes[int(beat)%8]
  pluck=(math.sin(2*math.pi*freq*t)+.28*math.sin(2*math.pi*freq*2*t))*.15*math.exp(-part*7)
  pulse=math.sin(2*math.pi*55*t)*.065*math.exp(-part*20)
  drone=math.sin(2*math.pi*73.415*t)*.025
  envelope=min(1,t/2,(duration-t)/3)
  buf.extend(struct.pack('<h',int(max(-1,min(1,(pluck+pulse+drone)*envelope))*32767)))
 w.writeframes(buf)
print('Original title cards and pentatonic pulse soundtrack ready')
