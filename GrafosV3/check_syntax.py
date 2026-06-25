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
    # Sistemas centrales de efectos
    "StarterPlayerScripts/SistemasGameplay/GestorEfectos.lua",
    "StarterPlayerScripts/SistemasGameplay/OrquestadorModos.lua",
    "StarterPlayerScripts/SistemasGameplay/ControladorEfectos.client.lua",
    "StarterPlayerScripts/SistemasGameplay/ParticulasConexion.client.lua",
    "StarterPlayerScripts/SistemasGameplay/AudioGameplay.client.lua",

    # HUD y modos
    "StarterPlayerScripts/HUD/ControladorHUD.client.lua",
    "StarterPlayerScripts/HUD/ModulosHUD/SelectorModosHUD.lua",
    "StarterPlayerScripts/HUD/ModulosHUD/ModuloMapa.lua",
    "StarterPlayerScripts/HUD/ModulosHUD/EfectosMapa.lua",
    "StarterPlayerScripts/HUD/ModulosHUD/Minimap.lua",
    "StarterPlayerScripts/HUD/ModulosHUD/ModuloMatriz.lua",
    "StarterPlayerScripts/HUD/ModulosHUD/ModuloAnalisis.lua",
    "StarterPlayerScripts/HUD/ModulosHUD/EjecutorAlgoritmo3D.lua",
    "StarterPlayerScripts/HUD/ModulosHUD/EstadoConexiones.lua",

    # Bibliotecas de efectos
    "ReplicatedStorage/Efectos/EfectosDano.lua",
    "ReplicatedStorage/Efectos/EfectosHighlight.lua",
    "ReplicatedStorage/Efectos/BillboardNombres.lua",
    "ReplicatedStorage/Efectos/EfectosDialogo.lua",
    "ReplicatedStorage/Efectos/EfectosNodo.lua",
    "ReplicatedStorage/Efectos/EfectosVideo.lua",

    # Diálogos
    "StarterPlayerScripts/Dialogo/ControladorDialogo.client.lua",
    "StarterPlayerScripts/Dialogo/DialogoJugadorController.lua",

    # Referencias servidor
    "ServerScriptService/SistemasGameplay/ServicioPuntaje.lua",
    "ServerScriptService/Servicios/CargadorNiveles.lua",
    "ServerScriptService/SistemasGameplay/ConectarCables.lua",
]

ok_all = True
for f in files:
    if not check(f):
        ok_all = False
sys.exit(0 if ok_all else 1)
