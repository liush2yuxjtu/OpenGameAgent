import json, sys, subprocess, os
from playwright.sync_api import sync_playwright
data=json.load(open('data.json'))
html=open('page.html').read().replace('<script>','<script>window.__DATA__='+json.dumps(data,ensure_ascii=False)+';',1)
open('page_built.html','w').write(html)
mode=sys.argv[1]
with sync_playwright() as p:
    b=p.chromium.launch(); pg=b.new_page(viewport={'width':1080,'height':1920})
    pg.goto('file://'+os.path.abspath('page_built.html')); pg.wait_for_timeout(500)
    if mode=='test':
        for t in [float(x) for x in sys.argv[2:]]:
            pg.evaluate(f'render({t})'); pg.screenshot(path=f'frame_{t}.png')
    else:
        dur=float(sys.argv[2]); fps=30; n=int(dur*fps)
        ff=subprocess.Popen(['ffmpeg','-y','-v','error','-f','image2pipe','-framerate',str(fps),'-c:v','mjpeg','-i','-',
            '-c:v','libx264','-pix_fmt','yuv420p','-crf','18','-preset','medium','silent.mp4'],stdin=subprocess.PIPE)
        for i in range(n):
            pg.evaluate(f'render({i/fps})'); ff.stdin.write(pg.screenshot(type='jpeg',quality=92))
            if i%150==0: print(i,flush=True)
        ff.stdin.close(); ff.wait()
    b.close()
