"""HTTP + provider SSE integration test. Uses a local fixture, never a paid model."""
import os,json,threading,socket,subprocess,time,urllib.request,urllib.error
from http.server import ThreadingHTTPServer,BaseHTTPRequestHandler
from pathlib import Path
class Fixture(BaseHTTPRequestHandler):
    def log_message(self,*args): pass
    def do_POST(self):
        request=json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        assert request['stream'] is True
        arguments=json.dumps({'mode':'plate','reason':'Local SSE fixture proposal.'})
        frames=[{'id':'fixture','object':'chat.completion.chunk','choices':[{'index':0,'delta':{'role':'assistant','tool_calls':[{'index':0,'id':'order-1','type':'function','function':{'name':'propose_order','arguments':arguments}}]},'finish_reason':None}]},{'id':'fixture','object':'chat.completion.chunk','choices':[{'index':0,'delta':{},'finish_reason':'tool_calls'}],'usage':{'prompt_tokens':10,'completion_tokens':10,'total_tokens':20}}]
        b=(''.join('data: '+json.dumps(f)+'\n\n' for f in frames)+'data: [DONE]\n\n').encode()
        self.send_response(200);self.send_header('Content-Type','text/event-stream');self.send_header('Content-Length',str(len(b)));self.end_headers();self.wfile.write(b)
fixture=ThreadingHTTPServer(('127.0.0.1',0),Fixture);threading.Thread(target=fixture.serve_forever,daemon=True).start()
with socket.socket() as s:s.bind(('127.0.0.1',0));port=s.getsockname()[1]
env=os.environ.copy();env.update(ECHO_ENABLE_MODEL='1',ECHO_MODEL_ENDPOINT=f'http://127.0.0.1:{fixture.server_port}/v1/chat/completions',ECHO_MODEL='local-fixture',ECHO_MODEL_KEY='',ECHO_AGENT_PORT=str(port),DOTNET_CLI_TELEMETRY_OPTOUT='1')
root=Path(__file__).parent
proc=subprocess.Popen([env.get('ECHO_DOTNET','dotnet'),'run','--project',str(root),'-c','Release','--no-build'],env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
base=f'http://127.0.0.1:{port}'
def call(data,headers=None):
    try:
        with urllib.request.urlopen(urllib.request.Request(base+'/decide',json.dumps(data).encode(),{'Content-Type':'application/json',**(headers or {})}),timeout=20) as r:return r.status,json.loads(r.read())
    except urllib.error.HTTPError as e:return e.code,None
try:
    for _ in range(100):
        try:
            urllib.request.urlopen(base+'/health',timeout=.2).close();break
        except (urllib.error.URLError,TimeoutError):time.sleep(.1)
    data={'request':'hold south plate','epoch':4,'run_id':'http-fixture','world':{'gate_open':False}}
    assert call(data,{'Origin':'https://untrusted.example'})[0]==403
    assert call({**data,'request':'x'*241})[0]==400
    status,result=call(data)
    assert status==200,(status,result)
    assert result['mode']=='plate' and result['epoch']==4 and result['run_id']=='http-fixture',result
    print('ECHO_HTTP_TEST PASS: browser origin blocked, invalid input rejected, real OpenAI-compatible SSE transport -> runtime tool -> JSON intent. No external model.')
finally:
    proc.terminate();proc.wait(timeout=10);fixture.shutdown();fixture.server_close()
