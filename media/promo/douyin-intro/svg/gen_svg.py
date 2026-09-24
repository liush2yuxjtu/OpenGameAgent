T = 38.0  # total loop seconds
kf = []
cls_n = [0]

def pct(s):
    return f"{max(0,min(100,s/T*100)):.3f}%"

def show(t_in, t_out, dy=12, fade=0.45):
    """Return a class name that fades/slides in at t_in and out at t_out (seconds)."""
    cls_n[0] += 1
    n = f"a{cls_n[0]}"
    frames = []
    if t_in > 0:
        frames.append(f"0%,{pct(t_in)}{{opacity:0;transform:translateY({dy}px)}}")
    frames.append(f"{pct(t_in+fade)},{pct(t_out-fade)}{{opacity:1;transform:translateY(0)}}")
    if t_out < T:
        frames.append(f"{pct(t_out)},100%{{opacity:0;transform:translateY(0)}}")
    kf.append(f"@keyframes k{n}{{{''.join(frames)}}}.{n}{{animation:k{n} {T}s linear infinite both;transform-box:fill-box}}")
    return n

def pulse(t_in, t_out, color_from, color_to):
    cls_n[0] += 1
    n = f"a{cls_n[0]}"
    kf.append(f"@keyframes k{n}{{0%,{pct(t_in)}{{fill:{color_from}}}{pct(t_in+0.3)},{pct(t_out)}{{fill:{color_to}}}{pct(t_out+0.3)},100%{{fill:{color_from}}}}}.{n}{{animation:k{n} {T}s linear infinite}}")
    return n

FONT = "'PingFang SC','Noto Sans CJK SC','Microsoft YaHei',system-ui,sans-serif"
MONO = "'JetBrains Mono','SFMono-Regular',Menlo,Consolas,monospace"
body = []
A = body.append

# ---------- Scene windows ----------
S1 = (0, 5.5)
S2 = (5.5, 12)
S3 = (12, 23.5)
S4 = (23.5, 29.5)
S5 = (29.5, 34.5)
S6 = (34.5, 38)

# ---------- Scene 1: Title ----------
g = show(*S1, dy=0)
A(f'<g class="{g}">')
A(f'<g transform="translate(480 190)"><g class="{show(0.2, S1[1], dy=0)}">'
  '<g class="spin"><polygon points="0,-58 50,-29 50,29 0,58 -50,29 -50,-29" fill="none" stroke="var(--acc)" stroke-width="3"/></g>'
  '<circle r="18" fill="var(--acc)"/><circle r="30" fill="none" stroke="var(--acc2)" stroke-width="2" stroke-dasharray="4 6" class="spinr"/></g></g>')
A(f'<text class="{show(0.6, S1[1])} h1" x="480" y="310" text-anchor="middle">OpenGameAgent</text>')
A(f'<text class="{show(1.2, S1[1])} sub" x="480" y="355" text-anchor="middle">开源 C# Agent 运行时 · 让 NPC 和游戏内 Agent 真正“会思考、会行动”</text>')
A(f'<g class="{show(2.0, S1[1])}">'
  + ''.join(f'<rect x="{x}" y="385" width="{w}" height="30" rx="15" class="chip"/><text x="{x+w/2}" y="405" text-anchor="middle" class="chipt">{t}</text>'
            for x, w, t in [(250, 130, "结构化上下文"), (392, 120, "ReAct 工具循环"), (524, 110, "复杂任务规划"), (646, 80, "记忆"), (738, 110, "可靠动作")])
  + '</g>')
A(f'<text class="{show(2.8, S1[1])} note" x="480" y="460" text-anchor="middle">注意：它不是写代码的 AI，也不是游戏生成器 —— 它是跑在游戏里的角色大脑</text>')
A('</g>')

# ---------- Scene 2: dialogue vs agent ----------
A(f'<g class="{show(*S2, dy=0)}">')
A(f'<text class="{show(S2[0], S2[1])} h2" x="480" y="70" text-anchor="middle">从“会说话”到“会做事”</text>')
# left card
A(f'<g class="{show(S2[0]+0.4, S2[1])}"><rect x="70" y="105" width="380" height="370" rx="18" class="card dim"/>'
  '<text x="260" y="145" text-anchor="middle" class="ct muted">对话型 NPC</text>'
  '<rect x="110" y="175" width="300" height="46" rx="12" class="bub"/><text x="130" y="204" class="bt">玩家：能帮我修剑吗？</text>'
  '<rect x="110" y="235" width="300" height="46" rx="12" class="bub2"/><text x="130" y="264" class="bt">NPC：当然！（然后什么也没发生）</text>')
for i, t in enumerate(["只读最新一句对话", "输出一行文字就结束", "没有任务、没有时间感", "超时重试可能重复写入"]):
    A(f'<text x="120" y="{325+i*34}" class="li muted">✕  {t}</text>')
A('</g>')
# right card
A(f'<g class="{show(S2[0]+1.6, S2[1])}"><rect x="510" y="105" width="380" height="370" rx="18" class="card hl"/>'
  '<text x="700" y="145" text-anchor="middle" class="ct acc">Agent 驱动的 NPC</text>')
items = ["观察结构化 JSON：对话 / 世界 / 事件 / 截图", "有界 ReAct 循环：推理 → 工具 → 结果", "拆解复杂目标，持久计划可动态重规划",
         "游戏时间线、存档、角色身份与记忆", "多 NPC 并发：单角色串行，跨角色并行", "意图日志 + 权威回执，失败不重复执行"]
for i, t in enumerate(items):
    A(f'<text class="{show(S2[0]+2.0+i*0.45, S2[1], dy=0)} li" x="535" y="{190+i*46}"><tspan class="ok">✓</tspan>  {t}</text>')
A('</g></g>')

# ---------- Scene 3: ReAct loop w/ blacksmith ----------
s3 = S3
A(f'<g class="{show(*s3, dy=0)}">')
A(f'<text class="{show(s3[0], s3[1])} h2" x="480" y="60" text-anchor="middle">一个循环搞定一切：消息就结束，工具就继续</text>')
# loop diagram on left
cx, cy, R = 250, 290, 140
nodes = [("GameInput", "观察", -90), ("Model", "推理", -18), ("Tool Call", "请求动作", 54), ("Game 校验", "权威执行", 126), ("Result", "结构化结果", 198)]
import math
A(f'<g class="{show(s3[0]+0.3, s3[1])}">')
A(f'<circle cx="{cx}" cy="{cy}" r="{R}" fill="none" stroke="var(--line)" stroke-width="2" stroke-dasharray="3 7"/>')
A(f'<path id="loop" d="M {cx} {cy-R} a {R} {R} 0 1 1 -0.01 0" fill="none"/>')
A('<circle r="7" fill="var(--acc)" filter="url(#glow)"><animateMotion dur="3s" repeatCount="indefinite" rotate="auto"><mpath href="#loop"/></animateMotion></circle>')
for i, (a, b, ang) in enumerate(nodes):
    x = cx + R*math.cos(math.radians(ang)); y = cy + R*math.sin(math.radians(ang))
    A(f'<g transform="translate({x:.1f} {y:.1f})"><rect x="-58" y="-26" width="116" height="52" rx="12" class="node"/>'
      f'<text y="-3" text-anchor="middle" class="nt">{a}</text><text y="16" text-anchor="middle" class="ns">{b}</text></g>')
A(f'<text x="{cx}" y="{cy-4}" text-anchor="middle" class="nt acc">ReAct</text><text x="{cx}" y="{cy+18}" text-anchor="middle" class="ns">有界 · 可流式 · 可打断</text>')
A('</g>')
# transcript on right
lines = [
    (0.8, "in",  "GameInput", '{"intent":"repair","item":"sword"}'),
    (2.2, "llm", "Model →",   "tool_call  inspect_item(sword)"),
    (3.6, "game","Game ←",    "durability = 0.35 · 材料充足"),
    (5.0, "llm", "Model →",   "tool_call  repair(sword)"),
    (6.4, "game","Game ←",    "✓ committed · receipt #9001"),
    (7.8, "npc", "铁匠 NPC",   "“修好了，比新的还结实。”"),
]
A(f'<rect class="{show(s3[0]+0.5, s3[1])} card" x="450" y="100" width="470" height="385" rx="16"/>')
A(f'<text class="{show(s3[0]+0.5, s3[1])} ns" x="472" y="128">npc-blacksmith · main-world · tick 18840</text>')
for i, (dt, kind, who, txt) in enumerate(lines):
    y = 150 + i*56
    c = show(s3[0]+dt, s3[1], dy=10)
    A(f'<g class="{c}"><rect x="470" y="{y}" width="430" height="46" rx="10" class="row {kind}"/>'
      f'<text x="486" y="{y+19}" class="who {kind}">{who}</text><text x="486" y="{y+37}" class="code">{txt}</text></g>')
A(f'<text class="{show(s3[0]+8.8, s3[1])} note" x="685" y="515" text-anchor="middle">没有复杂度分类器：模型直接回答，循环立刻结束</text>')
A('</g>')

# ---------- Scene 4: authority ----------
s4 = S4
A(f'<g class="{show(*s4, dy=0)}">')
A(f'<text class="{show(s4[0], s4[1])} h2" x="480" y="70" text-anchor="middle">游戏永远是权威：模型只能“请求”，不能“改写”世界</text>')
A(f'<g class="{show(s4[0]+0.4, s4[1])}"><rect x="90" y="200" width="200" height="110" rx="16" class="node"/>'
  '<text x="190" y="248" text-anchor="middle" class="nt">模型</text><text x="190" y="274" text-anchor="middle" class="ns">任意云端 / 本地 API</text></g>')
A(f'<g class="{show(s4[0]+0.4, s4[1])}"><rect x="670" y="200" width="200" height="110" rx="16" class="node hlnode"/>'
  '<text x="770" y="248" text-anchor="middle" class="nt">游戏代码</text><text x="770" y="274" text-anchor="middle" class="ns">规则 · 权限 · 版本</text></g>')
# shield
A(f'<g transform="translate(480 255)"><g class="{show(s4[0]+0.8, s4[1])}"><path d="M0,-70 L55,-48 L55,5 C55,40 25,62 0,72 C-25,62 -55,40 -55,5 L-55,-48 Z" class="shield"/>'
  '<text y="8" text-anchor="middle" class="nt">校验</text></g></g>')
# request packets
A(f'<g class="{show(s4[0]+1.2, s4[1], dy=0)}"><g class="pk1"><rect x="-80" y="-16" width="160" height="32" rx="8" class="pkt"/><text y="6" text-anchor="middle" class="code">repair(sword)</text></g></g>')
A(f'<g class="{show(s4[0]+2.6, s4[1], dy=0)}"><g class="pk2"><rect x="-90" y="-16" width="180" height="32" rx="8" class="pkt bad"/><text y="6" text-anchor="middle" class="code">give_gold(9999)</text></g></g>')
A(f'<text class="{show(s4[0]+2.2, s4[1])} ok big" x="770" y="395" text-anchor="middle">✓ 已提交</text>')
A(f'<text class="{show(s4[0]+3.8, s4[1])} bad big" x="480" y="370" text-anchor="middle">✕ 拒绝：违反经济规则</text>')
A(f'<g class="{show(s4[0]+4.2, s4[1])}">'
  '<text x="480" y="420" text-anchor="middle" class="li">高风险工具需一次性审批 · 写操作先记意图日志</text>'
  '<text x="480" y="450" text-anchor="middle" class="li muted">超时不盲目重试，先核对游戏回执再决定</text></g>')
A('</g>')

# ---------- Scene 5: where it runs ----------
s5 = S5
A(f'<g class="{show(*s5, dy=0)}">')
A(f'<text class="{show(s5[0], s5[1])} h2" x="480" y="70" text-anchor="middle">跑在你的引擎里，接你想用的模型</text>')
engines = [("Godot 4.7", ".NET 进程内"), ("Unity 6", "UPM 包"), ("Unreal 5.8", "C++ sidecar 插件"), (".NET 服务器", "HTTP / SSE")]
for i, (a, b) in enumerate(engines):
    x = 95 + i*200
    A(f'<g class="{show(s5[0]+0.3+i*0.3, s5[1])}"><rect x="{x}" y="120" width="170" height="100" rx="16" class="node"/>'
      f'<text x="{x+85}" y="165" text-anchor="middle" class="nt">{a}</text><text x="{x+85}" y="192" text-anchor="middle" class="ns">{b}</text></g>')
A(f'<g class="{show(s5[0]+1.6, s5[1])}"><line x1="480" y1="232" x2="480" y2="268" stroke="var(--acc)" stroke-width="2"/>'
  '<rect x="300" y="270" width="360" height="54" rx="27" class="chip"/><text x="480" y="303" text-anchor="middle" class="nt acc">GameAgentRuntime · netstandard2.1</text>'
  '<line x1="480" y1="326" x2="480" y2="360" stroke="var(--acc)" stroke-width="2"/></g>')
provs = ["OpenAI", "Anthropic", "Gemini", "Bedrock", "Mistral", "Ollama", "LM Studio", "vLLM", "llama.cpp"]
ws=[18+len(p)*8.6 for p in provs]; xs = 480-(sum(ws)+10*(len(ws)-1))/2
for i, p in enumerate(provs):
    w = ws[i]
    A(f'<g class="{show(s5[0]+2.0+i*0.15, s5[1], dy=6)}"><rect x="{xs:.0f}" y="368" width="{w:.0f}" height="32" rx="16" class="pchip"/><text x="{xs+w/2:.0f}" y="389" text-anchor="middle" class="ns fg">{p}</text></g>')
    xs += w + 10
A(f'<text class="{show(s5[0]+3.2, s5[1])} note" x="480" y="450" text-anchor="middle">不捆绑模型 · 27 个 provider 定义 · 记忆 / 语音 / 图像输入 / 生成资产皆为可选扩展</text>')
A('</g>')

# ---------- Scene 6: outro ----------
s6 = S6
A(f'<g class="{show(*s6, dy=0)}">')
A(f'<text class="{show(s6[0]+0.2, s6[1])} h1" x="480" y="230" text-anchor="middle">OpenGameAgent</text>')
A(f'<text class="{show(s6[0]+0.6, s6[1])} sub" x="480" y="275" text-anchor="middle">AI 负责想，游戏负责定。</text>')
A(f'<g class="{show(s6[0]+1.0, s6[1])}">'
  '<rect x="300" y="310" width="110" height="30" rx="15" class="chip"/><text x="355" y="330" text-anchor="middle" class="chipt">MIT 开源</text>'
  '<rect x="420" y="310" width="120" height="30" rx="15" class="chip warnc"/><text x="480" y="330" text-anchor="middle" class="chipt">0.3.0-alpha.4</text>'
  '<rect x="550" y="310" width="110" height="30" rx="15" class="chip"/><text x="605" y="330" text-anchor="middle" class="chipt">C# · .NET 8</text></g>')
A(f'<text class="{show(s6[0]+1.4, s6[1])} ns" x="480" y="385" text-anchor="middle">github.com/liush2yuxjtu/OpenGameAgent · opengameagent.com</text>')
A('</g>')

# progress bar
prog = f"@keyframes prog{{from{{transform:scaleX(0)}}to{{transform:scaleX(1)}}}}.prog{{animation:prog {T}s linear infinite;transform-origin:0 0}}"

# packet paths scene 4
t0 = S4[0]
pk = (f"@keyframes pk1{{0%,{pct(t0+1.2)}{{transform:translate(190px,255px)}}{pct(t0+1.9)}{{transform:translate(770px,255px)}}{pct(t0+2.2)},100%{{transform:translate(770px,345px)}}}}"
      f".pk1{{animation:pk1 {T}s ease-in-out infinite}}"
      f"@keyframes pk2{{0%,{pct(t0+2.6)}{{transform:translate(190px,255px)}}{pct(t0+3.4)}{{transform:translate(400px,255px)}}{pct(t0+3.8)},100%{{transform:translate(420px,318px) rotate(-8deg)}}}}"
      f".pk2{{animation:pk2 {T}s ease-in infinite}}")

style = f"""
:root{{--bg:#0d1117;--bg2:#161b22;--fg:#e6edf3;--muted:#8b949e;--line:#30363d;--acc:#58d68d;--acc2:#4fc3f7;--warn:#f0b429;--bad:#ff6b6b}}
text{{font-family:{FONT};fill:var(--fg)}}
.h1{{font-size:56px;font-weight:800;letter-spacing:.5px}}
.h2{{font-size:30px;font-weight:700}}
.sub{{font-size:20px;fill:#c9d1d9}}
.note{{font-size:15px;fill:var(--muted)}}
.chip{{fill:rgba(88,214,141,.10);stroke:var(--acc);stroke-width:1.2}}
.warnc{{fill:rgba(240,180,41,.12);stroke:var(--warn)}}
.chipt{{font-size:14px;fill:var(--fg)}}
.pchip{{fill:var(--bg2);stroke:var(--line)}}
.card{{fill:var(--bg2);stroke:var(--line);stroke-width:1.5}}
.card.dim{{opacity:.85}}
.card.hl{{stroke:var(--acc);stroke-width:2}}
.ct{{font-size:22px;font-weight:700}}
.muted{{fill:var(--muted)}}
.acc{{fill:var(--acc)}}
.ok{{fill:var(--acc);font-weight:700}}
.bad{{fill:var(--bad);font-weight:700}}
.big{{font-size:22px}}
.li{{font-size:16px}}
.bub{{fill:#1f2a37}}.bub2{{fill:#2a2230}}
.bt{{font-size:16px}}
.node{{fill:var(--bg2);stroke:var(--acc2);stroke-width:1.6}}
.hlnode{{stroke:var(--acc)}}
.nt{{font-size:17px;font-weight:700}}
.ns{{font-size:13px;fill:var(--muted)}}
.fg{{fill:var(--fg)}}
.code{{font-family:{MONO};font-size:14px;fill:var(--fg)}}
.row{{fill:#0f1620;stroke:var(--line)}}
.row.llm{{stroke:var(--acc2)}}.row.game{{stroke:var(--acc)}}.row.npc{{stroke:var(--warn)}}
.who{{font-size:12px;font-weight:700;fill:var(--muted)}}
.who.llm{{fill:var(--acc2)}}.who.game{{fill:var(--acc)}}.who.npc{{fill:var(--warn)}}
.shield{{fill:rgba(88,214,141,.10);stroke:var(--acc);stroke-width:2.5}}
.pkt{{fill:#10261a;stroke:var(--acc)}}.pkt.bad{{fill:#2b1416;stroke:var(--bad)}}
.spin{{animation:spin 12s linear infinite;transform-box:fill-box;transform-origin:center}}
.spinr{{animation:spin 6s linear infinite reverse;transform-box:fill-box;transform-origin:center}}
@keyframes spin{{to{{transform:rotate(360deg)}}}}
{prog}
{pk}
{''.join(kf)}
@media (prefers-reduced-motion:reduce){{*{{animation-duration:0s!important}}}}
"""

svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 960 540" width="960" height="540" role="img" aria-label="OpenGameAgent 动画介绍">
<title>OpenGameAgent 动画介绍</title>
<defs><filter id="glow" x="-100%" y="-100%" width="300%" height="300%"><feGaussianBlur stdDeviation="3" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<radialGradient id="bgg" cx="50%" cy="0%" r="90%"><stop offset="0" stop-color="#132a22"/><stop offset="1" stop-color="#0d1117"/></radialGradient></defs>
<style>{style}</style>
<rect width="960" height="540" fill="url(#bgg)"/>
{chr(10).join(body)}
<rect x="0" y="534" width="960" height="6" fill="#161b22"/><rect class="prog" x="0" y="534" width="960" height="6" fill="var(--acc)"/>
</svg>'''
import os

open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "OpenGameAgent-intro.svg"), "w").write(svg)
print(len(svg))
