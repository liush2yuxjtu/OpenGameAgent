"""Prepare a real Godot web export for static hosts with per-file size limits."""
from pathlib import Path
import gzip
root = Path(__file__).resolve().parents[1] / 'build' / 'web'
wasm = root / 'index.wasm'
if wasm.exists():
    (root / 'index.wasm.gz').write_bytes(gzip.compress(wasm.read_bytes(), compresslevel=9, mtime=0))
    wasm.unlink()
html = root / 'index.html'
s = html.read_text().replace('"ensureCrossOriginIsolationHeaders":true', '"ensureCrossOriginIsolationHeaders":false')
loader = '''<script id="echo-wasm-loader">
const originalFetch = window.fetch.bind(window);
window.fetch = async (resource, init) => {
 const url = typeof resource === 'string' ? resource : resource.url;
 if (url && new URL(url, location.href).pathname.endsWith('/index.wasm')) {
  const response = await originalFetch(url + '.gz', init);
  if (!response.ok) throw new Error('Could not load game engine: ' + response.status);
  return new Response(response.body.pipeThrough(new DecompressionStream('gzip')), {headers:{'Content-Type':'application/wasm'}});
 }
 return originalFetch(resource, init);
};
</script>'''
if 'echo-wasm-loader' not in s:
    s = s.replace('<script src="index.js"></script>', loader + '<script src="index.js"></script>')
    s = s.replace('const GODOT_THREADS_ENABLED = false;', "if(new URLSearchParams(location.search).has('demo')) GODOT_CONFIG.args=['--','--demo'];\nconst GODOT_THREADS_ENABLED = false;")
html.write_text(s)
print('Web build ready:', root)
