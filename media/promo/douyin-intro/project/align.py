import numpy as np, json
x=np.fromfile('raw.pcm',dtype=np.int16).astype(float)/32768
hop=160; n=len(x)//hop
e=np.array([np.sqrt(np.mean(x[i*hop:(i+1)*hop]**2)+1e-12) for i in range(n)])
db=20*np.log10(e); thr=np.percentile(db,25)+8; sp=db>thr
# segments
segs=[];i=0
while i<n:
  if sp[i]:
    j=i
    while j<n and sp[j]: j+=1
    segs.append([i,j]); i=j
  else: i+=1
m=[]
for s in segs:
  if m and s[0]-m[-1][1]<18: m[-1][1]=s[1]
  else: m.append(s)
m=[s for s in m if s[1]-s[0]>8 and s[0]>30]   # drop leading click
spf=np.zeros(n,bool)
for a,b in m: spf[a:b]=True
pauses=[((m[k][1]+m[k+1][0])/2/100) for k in range(len(m)-1)]
# clauses: (section, text, weight)
C=[(1,"你玩游戏时",5),(1,"NPC 是不是只会说",9),(1,"“当然可以！”",4),(1,"然后什么都不做？",7),
(2,"这个开源项目",6),(2,"OpenGameAgent",5),(2,"让 NPC 真的会想",8),(2,"也真的会做",5),
(3,"你让铁匠修剑",6),(3,"他先检查耐久",6),(3,"再调用修理",5),(3,"游戏确认之后才开口",9),(3,"“修好了。”",3),
(4,"最关键的是",5),(4,"AI 只能提请求",7),(4,"游戏说了算",5),(4,"它想给你 9999 金币？",13),(4,"直接驳回",4),
(5,"Unity、Godot、Unreal 都能接",10),(5,"云端和本地模型都支持",10),(5,"MIT 开源",5),
(6,"做游戏的朋友",6),(6,"收藏这条",4),(6,"去 GitHub 搜 OpenGameAgent",9)]
W=np.cumsum([0]+[c[2] for c in C]); tot=W[-1]
cum=np.cumsum(spf)/100.0; S=cum[-1]
def t_at(u):
  target=u/tot*S
  k=np.searchsorted(cum,target); return k/100
bounds=[t_at(u) for u in W]
# snap inner boundaries to nearest pause within 0.6s
for k in range(1,len(bounds)-1):
  p=min(pauses,key=lambda q:abs(q-bounds[k]))
  if abs(p-bounds[k])<0.6: bounds[k]=p
bounds[0]=m[0][0]/100; bounds[-1]=m[-1][1]/100
out=[dict(sec=c[0],text=c[1],t0=round(bounds[k],2),t1=round(bounds[k+1],2)) for k,c in enumerate(C)]
for o in out: print(o)
# per-frame mouth level at 30fps
fps=30; dur=len(x)/16000; nf=int(dur*fps)+1
lv=[]
for f in range(nf):
  a=int(f/fps*100); seg=db[a:a+4] if a<n else [-99]
  v=(max(seg)-thr)/25; lv.append(round(float(min(1,max(0,v))),2) if spf[min(a,n-1)] else 0)
with open('data.json','w',encoding='utf-8') as f:
  json.dump(dict(clauses=out,mouth=lv,dur=dur),f,ensure_ascii=False)
print('dur',dur,'frames',nf)
