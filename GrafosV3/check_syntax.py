import sys, glob
from luaparser import ast

def check(path):
    with open(path, 'r', encoding='utf-8') as f:
        src = f.read()
    # Roblox LuaU 'continue' keyword is not supported by luaparser; mask it.
    src_masked = src.replace('continue', '--[[continue]]')
    try:
        ast.parse(src_masked)
        print(f"OK  {path}")
        return True
    except Exception as e:
        print(f"ERR {path}: {e}")
        return False

files = [
    "ServerScriptService/SistemasGameplay/ServicioPuntaje.lua",
    "ServerScriptService/Servicios/CargadorNiveles.lua",
    "StarterPlayerScripts/HUD/ModulosHUD/ModuloMatriz.lua",
    "ServerScriptService/SistemasGameplay/ConectarCables.lua",
]
ok_all = True
for f in files:
    if not check(f):
        ok_all = False
sys.exit(0 if ok_all else 1)
