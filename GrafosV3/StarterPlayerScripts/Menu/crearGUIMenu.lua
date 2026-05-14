-- crearGUIMenu.lua
-- Crea la estructura de la GUI del menú EDA Quest.
-- Las tarjetas de nivel NO se generan aquí — MenuController las construye
-- dinámicamente después de recibir los datos del servidor via GetPlayerProgress.
-- Las tarjetas de logros TAMPOCO se generan aquí — ControladorMenu las crea
-- dinámicamente al abrir el panel de logros.

-- Evitar ejecución múltiple
if _G.EDAQuestMenuCreado then
	print("[EDA Quest] GUI ya fue creada, omitiendo ejecución duplicada")
	return
end
_G.EDAQuestMenuCreado = true

local SG = game:GetService("StarterGui")
local Players = game:GetService("Players")

-- Verificar si ya existe en StarterGui
local ex = SG:FindFirstChild("EDAQuestMenu")
if ex then ex:Destroy() end

-- Verificar si ya existe en PlayerGui del jugador local (evitar duplicados)
local player = Players.LocalPlayer
if player then
	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui and playerGui:FindFirstChild("EDAQuestMenu") then
		print("[EDA Quest] GUI ya existe en PlayerGui, omitiendo creación")
		return
	end
end

local C = {
	bg=Color3.fromRGB(5,8,16), surface=Color3.fromRGB(12,18,32),
	panel=Color3.fromRGB(17,25,39), border=Color3.fromRGB(30,45,66),
	borderHi=Color3.fromRGB(46,74,106), accent=Color3.fromRGB(0,212,255),
	accent2=Color3.fromRGB(124,58,237), accent3=Color3.fromRGB(16,185,129),
	danger=Color3.fromRGB(239,68,68), text=Color3.fromRGB(226,232,240),
	muted=Color3.fromRGB(100,116,139), dim=Color3.fromRGB(51,65,85),
	gold=Color3.fromRGB(245,158,11), black=Color3.fromRGB(0,0,0),
}
local F = { title=Enum.Font.GothamBlack, mono=Enum.Font.RobotoMono, body=Enum.Font.Gotham, bold=Enum.Font.GothamBold }

local function n(cls, p, par)
	local o = Instance.new(cls)
	for k,v in pairs(p) do o[k]=v end
	if par then o.Parent=par end
	return o
end
local function corner(r,p) n("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function stroke(col,th,p) n("UIStroke",{Color=col,Thickness=th},p) end
local function pad(t,b,l,r,p) n("UIPadding",{PaddingTop=UDim.new(0,t),PaddingBottom=UDim.new(0,b),PaddingLeft=UDim.new(0,l),PaddingRight=UDim.new(0,r)},p) end

local function xBtn(parent, zIdx)
	local btn=n("TextButton",{Name="CloseBtn",Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,-42,0.5,-15),BackgroundColor3=C.panel,Text="X",TextColor3=C.muted,Font=F.bold,TextSize=14,BorderSizePixel=0,ZIndex=zIdx},parent)
	corner(6,btn) stroke(C.border,1,btn)
	return btn
end

local function modalBox(parent, w, h, borderCol)
	local box=n("Frame",{Size=UDim2.new(0,w,0,h),Position=UDim2.new(0.5,-w/2,0.5,-h/2),BackgroundColor3=C.surface,BorderSizePixel=0,ZIndex=51},parent)
	corner(12,box) stroke(borderCol or C.borderHi,1,box)
	return box
end

local function modalHdr(box, icon, title)
	local hdr=n("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=52},box)
	corner(12,hdr)
	n("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=52},hdr)
	n("TextLabel",{Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,20,0,0),BackgroundTransparency=1,Text=icon.."  "..title,TextColor3=C.text,Font=F.bold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=53},hdr)
	xBtn(hdr,53)
	return hdr
end

local root = n("ScreenGui",{Name="EDAQuestMenu",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true},SG)

-- ════════════════════════════════════════════
-- FRAME 1: MENÚ PRINCIPAL
-- ════════════════════════════════════════════
local S1 = n("Frame",{Name="FrameMenu",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Visible=true},root)

local logoArea=n("Frame",{Name="LogoArea",Size=UDim2.new(0,380,0,280),Position=UDim2.new(0,56,0.5,-140),BackgroundTransparency=1,ZIndex=5},S1)
local logoBg=n("Frame",{Size=UDim2.new(1,24,1,24),Position=UDim2.new(0,-12,0,-12),BackgroundColor3=Color3.fromRGB(3,5,10),BackgroundTransparency=0.25,BorderSizePixel=0,ZIndex=4},logoArea) corner(16,logoBg)

n("TextLabel",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,0),BackgroundTransparency=1,Text="Juego Serio · Aprendizaje Interactivo",TextColor3=Color3.fromRGB(140,95,205),Font=F.mono,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},logoArea)
n("TextLabel",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,20),BackgroundTransparency=1,Text="ESTRUCTURA DE DATOS Y ALGORITMOS",TextColor3=Color3.fromRGB(0,145,172),Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},logoArea)
n("TextLabel",{Name="Title",Size=UDim2.new(1,0,0,80),Position=UDim2.new(0,0,0,42),BackgroundTransparency=1,Text="EDA\nQuest",TextColor3=Color3.fromRGB(210,228,248),Font=F.title,TextSize=42,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},logoArea)
n("TextLabel",{Size=UDim2.new(1,0,0,36),Position=UDim2.new(0,0,0,128),BackgroundTransparency=1,Text="Aprende grafos dirigidos y no dirigidos\na través de desafíos de conexión de redes",TextColor3=Color3.fromRGB(105,122,142),Font=F.body,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=6},logoArea)

local badgesRow=n("Frame",{Size=UDim2.new(1,0,0,24),Position=UDim2.new(0,0,0,172),BackgroundTransparency=1,ZIndex=6},logoArea)
n("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center},badgesRow)
for _,bd in ipairs({
	{t="Grafos",          c=Color3.fromRGB(0,125,152),  bg=Color3.fromRGB(0,16,22)},
	{t="BFS·DFS·Dijkstra",c=Color3.fromRGB(90,60,165),  bg=Color3.fromRGB(14,8,28)},
	{t="Roblox Edu",      c=Color3.fromRGB(8,112,76),   bg=Color3.fromRGB(3,18,12)},
}) do
	local b=n("TextButton",{Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=bd.bg,Text=bd.t,TextColor3=bd.c,Font=F.mono,TextSize=9,BorderSizePixel=0,ZIndex=7},badgesRow)
	corner(3,b) stroke(bd.c,1,b) pad(3,3,8,8,b)
end

local menuPanel=n("Frame",{Name="MenuPanel",Size=UDim2.new(0,300,0,0),Position=UDim2.new(1,-364,0.5,-155),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=5},S1)
n("UIListLayout",{Padding=UDim.new(0,10),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder},menuPanel)

local function menuDivider(order)
	n("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.dim,BackgroundTransparency=0.5,BorderSizePixel=0,LayoutOrder=order},menuPanel)
end
local function menuBtn(name,icon,label,sub,ac,isPlay,order)
	local h=isPlay and 70 or 58
	local btn=n("TextButton",{Name=name,Size=UDim2.new(1,0,0,h),BackgroundColor3=isPlay and Color3.fromRGB(5,28,18) or Color3.fromRGB(8,14,24),Text="",AutoButtonColor=false,BorderSizePixel=0,ZIndex=6,LayoutOrder=order},menuPanel)
	corner(4,btn) stroke(isPlay and Color3.fromRGB(10,60,40) or C.border,1,btn)
	local bar=n("Frame",{Size=UDim2.new(0,3,0.55,0),Position=UDim2.new(0,0,0.225,0),BackgroundColor3=ac,BorderSizePixel=0,ZIndex=7},btn) corner(2,bar)
	n("TextLabel",{Size=UDim2.new(0,28,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,Text=icon,TextColor3=C.muted,Font=F.body,TextSize=isPlay and 22 or 18,ZIndex=7},btn)
	n("TextLabel",{Name="Label",Size=UDim2.new(1,-80,0,isPlay and 24 or 20),Position=UDim2.new(0,50,0,isPlay and 14 or 10),BackgroundTransparency=1,Text=label,TextColor3=C.text,Font=F.bold,TextSize=isPlay and 15 or 13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7},btn)
	if sub~="" then n("TextLabel",{Name="Subtitulo",Size=UDim2.new(1,-80,0,14),Position=UDim2.new(0,50,0,isPlay and 38 or 32),BackgroundTransparency=1,Text=sub,TextColor3=C.muted,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7},btn) end
	n("TextLabel",{Size=UDim2.new(0,18,1,0),Position=UDim2.new(1,-24,0,0),BackgroundTransparency=1,Text="›",TextColor3=C.dim,Font=F.bold,TextSize=20,ZIndex=7},btn)
end

menuBtn("BtnPlay",    "▶","JUGAR",   "Seleccionar nivel",           C.accent3,true, 1)
menuDivider(2)
menuBtn("BtnSettings","⚙","AJUSTES", "Dificultad · Colores · Audio",C.accent, false,3)
menuBtn("BtnLogros",  "🏆","LOGROS",  "Trofeos y desafíos",          C.gold,   false,4)
menuBtn("BtnCredits", "ℹ","CRÉDITOS","Equipo y herramientas",        C.accent2,false,5)
menuDivider(6)
menuBtn("BtnExit",    "✕","SALIR",   "",                             C.danger, false,7)
n("TextLabel",{Name="Version",Size=UDim2.new(0,100,0,18),Position=UDim2.new(1,-116,1,-24),BackgroundTransparency=1,Text="BUILD 2.0.0",TextColor3=C.dim,Font=F.mono,TextSize=10,ZIndex=5},S1)

-- ════════════════════════════════════════════
-- FRAME 2: SELECTOR DE NIVELES
-- ════════════════════════════════════════════
local S2=n("Frame",{Name="FrameLevels",Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(4,7,14),BackgroundTransparency=0.05,BorderSizePixel=0,Visible=false},root)

local lsTop=n("Frame",{Name="LevelTopBar",Size=UDim2.new(1,0,0,60),BackgroundColor3=Color3.fromRGB(6,10,20),BackgroundTransparency=0.05,BorderSizePixel=0,ZIndex=2},S2)
stroke(C.border,1,lsTop)

-- Contenedor central para el título y navegación
local topCenter=n("Frame",{Name="TopCenter",Size=UDim2.new(0,500,1,0),Position=UDim2.new(0.5,-250,0,0),BackgroundTransparency=1,ZIndex=3},lsTop)
n("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,12),VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Center},topCenter)

local backBtn=n("TextButton",{Name="BackBtn",Size=UDim2.new(0,110,0,36),BackgroundColor3=C.panel,Text="← VOLVER",TextColor3=C.muted,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=3},topCenter)
corner(6,backBtn) stroke(C.border,1,backBtn)

n("TextLabel",{Size=UDim2.new(0,80,0,36),BackgroundTransparency=1,Text="EDA Quest",TextColor3=C.muted,Font=F.mono,TextSize=11,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=3},topCenter)

n("TextLabel",{Size=UDim2.new(0,14,0,36),BackgroundTransparency=1,Text="›",TextColor3=C.dim,Font=F.bold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=3},topCenter)

n("TextLabel",{Size=UDim2.new(0,180,0,36),BackgroundTransparency=1,Text="Selección de Nivel",TextColor3=C.text,Font=F.mono,TextSize=11,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=3},topCenter)

local ptag=n("Frame",{Name="PlayerTagBox",Size=UDim2.new(0,140,0,34),BackgroundColor3=Color3.fromRGB(0,20,30),BorderSizePixel=0,ZIndex=3},topCenter)
corner(17,ptag) stroke(Color3.fromRGB(0,70,90),1,ptag)
local pav=n("Frame",{Name="PlayerAvatar",Size=UDim2.new(0,22,0,22),Position=UDim2.new(0,6,0.5,-11),BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=4},ptag) corner(11,pav)
n("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="P",TextColor3=C.bg,Font=F.bold,TextSize=12,ZIndex=5},pav)
n("TextLabel",{Name="PlayerTag",Size=UDim2.new(1,-36,1,0),Position=UDim2.new(0,32,0,0),BackgroundTransparency=1,Text="Cargando...",TextColor3=C.accent,Font=F.body,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},ptag)
local lsMain=n("Frame",{Name="LevelMainArea",Size=UDim2.new(1,0,1,-60),Position=UDim2.new(0,0,0,60),BackgroundTransparency=1,ZIndex=2},S2)
local sidebar=n("Frame",{Name="LevelSidebar",Size=UDim2.new(0,320,1,0),BackgroundColor3=Color3.fromRGB(6,10,20),BackgroundTransparency=0.05,BorderSizePixel=0,ZIndex=3},lsMain)
stroke(C.border,1,sidebar)

local sideHead=n("Frame",{Name="SidebarHeader",Size=UDim2.new(1,0,0,56),BackgroundTransparency=1,ZIndex=4},sidebar) stroke(C.border,1,sideHead)
n("TextLabel",{Size=UDim2.new(1,-40,0,20),Position=UDim2.new(0,20,0,10),BackgroundTransparency=1,Text="INFORMACIÓN",TextColor3=C.text,Font=F.bold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},sideHead)
n("TextLabel",{Size=UDim2.new(1,-40,0,16),Position=UDim2.new(0,20,0,32),BackgroundTransparency=1,Text="Selecciona un nivel para ver detalles",TextColor3=C.muted,Font=F.body,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},sideHead)

local placeholder=n("Frame",{Name="Placeholder",Size=UDim2.new(1,0,1,-130),Position=UDim2.new(0,0,0,56),BackgroundTransparency=1,Visible=true,ZIndex=4},sidebar)
n("TextLabel",{Size=UDim2.new(1,0,0,44),Position=UDim2.new(0,0,0.38,0),BackgroundTransparency=1,Text="🗺️",Font=F.body,TextSize=40,ZIndex=5},placeholder)
n("TextLabel",{Size=UDim2.new(1,-40,0,56),Position=UDim2.new(0,20,0.45,0),BackgroundTransparency=1,Text="Selecciona una tarjeta de nivel\npara ver su información y comenzar.",TextColor3=C.muted,Font=F.body,TextSize=12,TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=true,ZIndex=5},placeholder)

local infoContent=n("Frame",{Name="InfoContent",Size=UDim2.new(1,0,1,-130),Position=UDim2.new(0,0,0,56),BackgroundTransparency=1,Visible=false,ZIndex=4},sidebar)
local hero=n("Frame",{Name="Hero",Size=UDim2.new(1,0,0,140),BackgroundColor3=Color3.fromRGB(8,14,26),BorderSizePixel=0,ZIndex=5},infoContent)
local heroGlow=n("Frame",{Name="HeroGlow",Size=UDim2.new(0,110,0,110),Position=UDim2.new(0.5,-55,0.5,-55),BackgroundColor3=C.accent,BackgroundTransparency=0.72,BorderSizePixel=0,ZIndex=5},hero) corner(55,heroGlow)
n("TextLabel",{Name="HeroEmoji",Size=UDim2.new(0,60,0,60),Position=UDim2.new(0.5,-30,0.5,-30),BackgroundTransparency=1,Text="🧪",Font=F.body,TextSize=50,ZIndex=6},hero)
local heroBadge=n("Frame",{Name="HeroBadge",Size=UDim2.new(0,110,0,22),Position=UDim2.new(1,-118,0,10),BackgroundColor3=Color3.fromRGB(4,26,18),BorderSizePixel=0,ZIndex=6},hero)
corner(3,heroBadge) stroke(C.accent3,1,heroBadge)
n("TextLabel",{Name="HeroBadgeText",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="◆ DISPONIBLE",TextColor3=C.accent3,Font=F.mono,TextSize=9,ZIndex=7},heroBadge)

local infoBody=n("ScrollingFrame",{Name="InfoBody",Size=UDim2.new(1,0,1,-140),Position=UDim2.new(0,0,0,140),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.border,CanvasSize=UDim2.new(0,0,0,440),BorderSizePixel=0,ZIndex=5},infoContent)
pad(16,16,20,20,infoBody)
n("UIListLayout",{Padding=UDim.new(0,12),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder},infoBody)
n("TextLabel",{Name="InfoTag",Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="",TextColor3=C.accent,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},infoBody)
n("TextLabel",{Name="InfoName",Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,Text="",TextColor3=C.text,Font=F.bold,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=2},infoBody)
n("TextLabel",{Name="InfoDesc",Size=UDim2.new(1,0,0,64),BackgroundTransparency=1,Text="",TextColor3=C.muted,Font=F.body,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=3},infoBody)

local starsFrame=n("Frame",{Name="Stars",Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,LayoutOrder=4},infoBody)
n("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center},starsFrame)
for i=1,3 do n("TextLabel",{Name="Star"..i,Size=UDim2.new(0,22,1,0),BackgroundTransparency=1,Text="⭐",Font=F.body,TextSize=18,TextTransparency=0.7},starsFrame) end

local statsGrid=n("Frame",{Name="StatsGrid",Size=UDim2.new(1,0,0,170),BackgroundTransparency=1,LayoutOrder=5},infoBody)
for i,sd in ipairs({
	{name="StatScore", label="Récord",       col=C.gold},
	{name="StatStatus",label="Estado",       col=C.accent},
	{name="StatAciert",label="Aciertos",     col=C.accent3},
	{name="StatFallos",label="Fallos",       col=C.danger},
	{name="StatTiempo",label="Mejor Tiempo", col=C.accent},
	{name="StatInten", label="Intentos",     col=C.text},
}) do
	local col=(i-1)%2; local row=math.floor((i-1)/2)
	local box=n("Frame",{Name=sd.name,Size=UDim2.new(0.5,-5,0,50),Position=UDim2.new(col==0 and 0 or 0.5,col==1 and 5 or 0,0,row*58),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=6},statsGrid)
	corner(8,box) stroke(C.border,1,box)
	n("TextLabel",{Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,8,0,8),BackgroundTransparency=1,Text=sd.label,TextColor3=C.muted,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7},box)
	n("TextLabel",{Name="Valor",Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,8,0,24),BackgroundTransparency=1,Text="—",TextColor3=sd.col,Font=F.mono,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7},box)
end
n("TextLabel",{Name="ConceptosLabel",Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="CONCEPTOS",TextColor3=C.muted,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=6},infoBody)
local tagsFrame=n("Frame",{Name="Tags",Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,LayoutOrder=7},infoBody)
n("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center,Wraps=true},tagsFrame)

local playArea=n("Frame",{Name="PlayArea",Size=UDim2.new(1,0,0,72),Position=UDim2.new(0,0,1,-72),BackgroundTransparency=1,ZIndex=4},sidebar)
stroke(C.border,1,playArea)
local playBtn=n("TextButton",{Name="PlayButton",Size=UDim2.new(1,-44,0,44),Position=UDim2.new(0,22,0.5,-22),BackgroundColor3=C.panel,Text="🔒  SELECCIONA UN NIVEL",TextColor3=C.muted,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=5},playArea)
corner(8,playBtn) stroke(C.border,1,playBtn)

-- ════════════════════════════════════════════
-- GRID DE NIVELES — contenedor vacío
-- MenuController.client.lua construye las tarjetas dinámicamente
-- al recibir datos de GetPlayerProgress.
-- ════════════════════════════════════════════
local gridScroll=n("ScrollingFrame",{Name="GridArea",Size=UDim2.new(1,-320,1,0),Position=UDim2.new(0,320,0,0),BackgroundTransparency=1,ScrollBarThickness=4,ScrollBarImageColor3=C.border,CanvasSize=UDim2.new(0,0,0,800),BorderSizePixel=0,ZIndex=3},lsMain)
pad(28,28,32,32,gridScroll)
n("UIListLayout",{Name="GridLayout",Padding=UDim.new(0,0),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder},gridScroll)

-- Barra de progreso (se actualiza desde MenuController)
local progWrap=n("Frame",{Name="ProgressBar",Size=UDim2.new(1,0,0,60),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=4,LayoutOrder=1},gridScroll)
corner(8,progWrap) stroke(C.border,1,progWrap)
n("TextLabel",{Name="ProgText",Size=UDim2.new(0,60,0,26),Position=UDim2.new(0,16,0,7),BackgroundTransparency=1,Text="0 / 5",TextColor3=C.text,Font=F.title,TextSize=20,ZIndex=5},progWrap)
n("TextLabel",{Size=UDim2.new(0,140,0,16),Position=UDim2.new(0,16,0,36),BackgroundTransparency=1,Text="Niveles completados",TextColor3=C.muted,Font=F.mono,TextSize=9,ZIndex=5},progWrap)
local bt=n("Frame",{Size=UDim2.new(1,-220,0,6),Position=UDim2.new(0,165,0.5,-3),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=5},progWrap) corner(3,bt)
n("Frame",{Name="ProgFill",Size=UDim2.new(0,0,1,0),BackgroundColor3=C.accent3,BorderSizePixel=0,ZIndex=6},bt) corner(3, bt:FindFirstChild("ProgFill") or bt)
n("TextLabel",{Name="ProgPct",Size=UDim2.new(0,44,1,0),Position=UDim2.new(1,-46,0,0),BackgroundTransparency=1,Text="0%",TextColor3=C.accent3,Font=F.mono,TextSize=11,ZIndex=5},progWrap)
n("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,LayoutOrder=2},gridScroll)

-- Contenedor vacío para las tarjetas — MenuController lo llenará.
-- Se usan múltiples contenedores de sección para que el layout sea ordenado.
-- MenuController crea secciones con sus grupos de tarjetas según los datos del servidor.
-- Un spinner/placeholder indica que se están cargando los datos.
local loadingFrame=n("Frame",{Name="LoadingFrame",Size=UDim2.new(1,0,0,120),BackgroundTransparency=1,ZIndex=4,LayoutOrder=3},gridScroll)
n("TextLabel",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,0.3,0),BackgroundTransparency=1,Text="⏳",Font=F.body,TextSize=28,ZIndex=5},loadingFrame)
n("TextLabel",{Name="LoadingText",Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0.55,0),BackgroundTransparency=1,Text="Cargando niveles...",TextColor3=C.muted,Font=F.mono,TextSize=10,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=5},loadingFrame)

-- ════════════════════════════════════════════
-- FRAME 3: AJUSTES
-- ════════════════════════════════════════════
local S3=n("Frame",{Name="FrameSettings",Size=UDim2.new(1,0,1,0),BackgroundColor3=C.black,BackgroundTransparency=0.4,BorderSizePixel=0,Visible=false},root)
local sBox=modalBox(S3,580,640)
modalHdr(sBox,"⚙","AJUSTES")

local sScroll=n("ScrollingFrame",{Size=UDim2.new(1,-48,0,530),Position=UDim2.new(0,24,0,60),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.border,CanvasSize=UDim2.new(0,0,0,600),BorderSizePixel=0,ZIndex=52},sBox)
n("UIListLayout",{Padding=UDim.new(0,20),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder},sScroll)

local function sLabel(ico,txt,order)
	n("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text=ico.."  "..txt,TextColor3=C.muted,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=order},sScroll)
end

sLabel("🎯","DIFICULTAD",1)
local dG=n("Frame",{Size=UDim2.new(1,0,0,168),BackgroundTransparency=1,LayoutOrder=2},sScroll)
n("UIListLayout",{Padding=UDim.new(0,6),FillDirection=Enum.FillDirection.Vertical},dG)
for _,d in ipairs({{"Normal","Niveles como diseñados · Guía visual activa",true},{"Difícil","+30% nodos · Presupuesto −20% · Límite 10 min",false},{"Experto","+60% nodos · Sin guía · Sin pistas · Límite 5 min",false}}) do
	local r=n("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=C.panel,BorderSizePixel=0},dG) corner(6,r) stroke(d[3] and C.accent or C.border,1,r)
	local dot=n("Frame",{Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,12,0.5,-6),BackgroundColor3=d[3] and C.accent or C.panel,BorderSizePixel=0},r) corner(6,dot) stroke(d[3] and C.accent or C.border,2,dot)
	n("TextLabel",{Size=UDim2.new(1,-40,0,18),Position=UDim2.new(0,34,0,8),BackgroundTransparency=1,Text=d[1],TextColor3=d[3] and C.text or C.muted,Font=F.bold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},r)
	n("TextLabel",{Size=UDim2.new(1,-40,0,14),Position=UDim2.new(0,34,0,28),BackgroundTransparency=1,Text=d[2],TextColor3=C.muted,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},r)
end

sLabel("🔌","COLOR DE CABLES",3)
local cG=n("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,LayoutOrder=4},sScroll)
n("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),VerticalAlignment=Enum.VerticalAlignment.Center},cG)
for i,sw in ipairs({
	{Color3.fromRGB(0,212,255), true},
	{Color3.fromRGB(16,185,129),false},
	{Color3.fromRGB(249,115,22),false},
	{Color3.fromRGB(168,85,247),false},
	{Color3.fromRGB(239,68,68), false},
	{Color3.fromRGB(245,158,11),false},
}) do
	local s=n("TextButton",{Size=UDim2.new(0,30,0,30),BackgroundColor3=sw[1],Text="",BorderSizePixel=0,ZIndex=53},cG)
	corner(6,s) stroke(sw[2] and Color3.fromRGB(255,255,255) or Color3.fromRGB(30,30,30),sw[2] and 2.5 or 1,s)
end

sLabel("🎨","INDICADORES VISUALES",5)
local iG=n("Frame",{Size=UDim2.new(1,0,0,116),BackgroundTransparency=1,LayoutOrder=6},sScroll)
n("UIListLayout",{Padding=UDim.new(0,10),FillDirection=Enum.FillDirection.Vertical},iG)

local function colorPickRow(lbl, swColors, activeIdx, parent)
	local row=n("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=C.panel,BorderSizePixel=0},parent)
	corner(6,row) stroke(C.border,1,row)
	n("TextLabel",{Size=UDim2.new(0,150,0,20),Position=UDim2.new(0,12,0.5,-10),BackgroundTransparency=1,Text=lbl,TextColor3=C.muted,Font=F.body,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},row)
	local sf=n("Frame",{Size=UDim2.new(1,-170,0,26),Position=UDim2.new(0,158,0.5,-13),BackgroundTransparency=1},row)
	n("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,7),VerticalAlignment=Enum.VerticalAlignment.Center},sf)
	for i,sc in ipairs(swColors) do
		local s=n("TextButton",{Size=UDim2.new(0,24,0,24),BackgroundColor3=sc,Text="",BorderSizePixel=0},sf)
		corner(5,s) stroke(i==activeIdx and Color3.fromRGB(255,255,255) or Color3.fromRGB(25,25,25),i==activeIdx and 2.5 or 1,s)
	end
end

local indColors={
	Color3.fromRGB(0,212,255),
	Color3.fromRGB(245,158,11),
	Color3.fromRGB(16,185,129),
	Color3.fromRGB(168,85,247),
}
colorPickRow("Nodo seleccionado", indColors, 2, iG)
colorPickRow("Nodo Adyacente",    indColors, 1, iG)

sLabel("🔊","AUDIO",7)
local aG=n("Frame",{Size=UDim2.new(1,0,0,72),BackgroundTransparency=1,LayoutOrder=8},sScroll)
n("UIListLayout",{Padding=UDim.new(0,12),FillDirection=Enum.FillDirection.Vertical},aG)
for i,aud in ipairs({{"Música ambiente","70%",0.7},{"Efectos de sonido","85%",0.85}}) do
	local sliderName = i==1 and "AmbientSlider" or "SFXSlider"
	local ar=n("Frame",{Name=sliderName,Size=UDim2.new(1,0,0,28),BackgroundTransparency=1},aG)
	n("TextLabel",{Size=UDim2.new(0,130,1,0),BackgroundTransparency=1,Text=aud[1],TextColor3=C.muted,Font=F.body,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},ar)
	local st=n("TextButton",{Name="Track",Text="",AutoButtonColor=false,Size=UDim2.new(1,-180,0,10),Position=UDim2.new(0,140,0.5,-5),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=53},ar) corner(5,st)
	local sf2=n("Frame",{Name="Fill",Size=UDim2.new(aud[3],0,1,0),BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=54},st) corner(5,sf2)
	n("TextLabel",{Name="Porcentaje",Size=UDim2.new(0,38,1,0),Position=UDim2.new(1,-38,0,0),BackgroundTransparency=1,Text=aud[2],TextColor3=C.accent,Font=F.mono,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right},ar)
end

local sF=n("Frame",{Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,1,-50),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=52},sBox) stroke(C.border,1,sF)
local sCan=n("TextButton",{Name="CancelBtn",Size=UDim2.new(0,110,0,34),Position=UDim2.new(1,-258,0.5,-17),BackgroundColor3=C.panel,Text="Cancelar",TextColor3=C.muted,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=53},sF) corner(6,sCan) stroke(C.border,1,sCan)
local sSav=n("TextButton",{Name="SaveBtn",Size=UDim2.new(0,132,0,34),Position=UDim2.new(1,-136,0.5,-17),BackgroundColor3=C.accent,Text="Guardar cambios",TextColor3=C.black,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=53},sF) corner(6,sSav)

-- ════════════════════════════════════════════
-- FRAME 4: CRÉDITOS (MEJORADO)
-- ════════════════════════════════════════════
local S4=n("Frame",{Name="FrameCredits",Size=UDim2.new(1,0,1,0),BackgroundColor3=C.black,BackgroundTransparency=0.4,BorderSizePixel=0,Visible=false},root)
local cBox=modalBox(S4,520,520)
modalHdr(cBox,"ℹ","CRÉDITOS")

local cScroll=n("ScrollingFrame",{Size=UDim2.new(1,-48,0,410),Position=UDim2.new(0,24,0,60),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.border,CanvasSize=UDim2.new(0,0,0,480),BorderSizePixel=0,ZIndex=52},cBox)
n("UIListLayout",{Padding=UDim.new(0,16),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder},cScroll)

-- Función helper para crear secciones de créditos
local function creditSection(title, items, order)
	local section=n("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=order},cScroll)
	
	-- Título de sección
	local hdr=n("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1},section)
	n("TextLabel",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,3),BackgroundTransparency=1,Text=title,TextColor3=C.accent,Font=F.mono,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},hdr)
	n("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,22),BackgroundColor3=C.border,BorderSizePixel=0},hdr)
	
	-- Contenedor de items
	local itemsContainer=n("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,28),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},section)
	n("UIListLayout",{Padding=UDim.new(0,8),FillDirection=Enum.FillDirection.Vertical},itemsContainer)
	
	for _,item in ipairs(items) do
		local card=n("Frame",{Size=UDim2.new(1,0,0,56),BackgroundColor3=C.panel,BorderSizePixel=0},itemsContainer)
		corner(8,card) stroke(C.border,1,card)
		
		-- Icono
		n("TextLabel",{Size=UDim2.new(0,44,1,0),BackgroundTransparency=1,Text=item[1],Font=F.body,TextSize=22,ZIndex=53},card)
		
		-- Contenido
		local content=n("Frame",{Size=UDim2.new(1,-56,1,0),Position=UDim2.new(0,48,0,0),BackgroundTransparency=1},card)
		n("UIListLayout",{Padding=UDim.new(0,2),FillDirection=Enum.FillDirection.Vertical,VerticalAlignment=Enum.VerticalAlignment.Center},content)
		
		n("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=item[2],TextColor3=C.text,Font=F.bold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=53},content)
		if item[3] then
			n("TextLabel",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text=item[3],TextColor3=C.muted,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=53},content)
		end
	end
end

-- SECCIÓN 1: EQUIPO DE DESARROLLO
creditSection("👥 EQUIPO DE DESARROLLO", {
	{"👨‍💻", "Moisés Arequipa", "Desarrollador Principal · Diseño de Sistemas"},
	{"👩‍🏫", "Dra. Mayra Carrión", "Tutora Académica · Dirección del Proyecto"},
}, 1)

-- SECCIÓN 2: METODOLOGÍA
creditSection("📚 METODOLOGÍA", {
	{"🎮", "Aprendizaje Basado en Juegos", "Gamificación de conceptos de EDA"},
	{"🧩", "Diseño de Juegos Serios", "Integración pedagógica en mecánicas de juego"},
	{"🎯", "Evaluación por Competencias", "Medición de habilidades algorítmicas"},
	{"🔬", "Investigación-Acción", "Ciclo iterativo de mejora continua"},
}, 2)

-- SECCIÓN 3: HERRAMIENTAS Y RECURSOS
creditSection("🛠️ HERRAMIENTAS", {
	{"🔧", "Roblox Studio", "Motor de desarrollo y plataforma de distribución"},
	{"📜", "Lua 5.1", "Lenguaje de scripting"},
	{"🎨", "Adobe Illustrator / Figma", "Diseño de interfaz y assets visuales"},
}, 3)

-- SECCIÓN 4: AGRADECIMIENTOS
creditSection("💜 AGRADECIMIENTOS", {
	{"🏫", "Universidad Nacional de Ingeniería", "Facultad de Ingeniería Industrial y de Sistemas"},
	{"👥", "Comunidad Roblox Edu", "Recursos y mejores prácticas educativas"},
}, 4)

-- Footer del modal
local cF=n("Frame",{Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,1,-50),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=52},cBox) stroke(C.border,1,cF)

-- Año y versión
n("TextLabel",{Size=UDim2.new(0,120,0,20),Position=UDim2.new(0,20,0.5,-10),BackgroundTransparency=1,Text="© 2024 EDA Quest",TextColor3=C.dim,Font=F.mono,TextSize=9,ZIndex=53},cF)

local cOk=n("TextButton",{Name="OkBtn",Size=UDim2.new(0,100,0,34),Position=UDim2.new(1,-116,0.5,-17),BackgroundColor3=C.accent,Text="Cerrar",TextColor3=C.black,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=53},cF) corner(6,cOk)

-- ════════════════════════════════════════════
-- FRAME 5: CONFIRMACIÓN SALIR
-- ════════════════════════════════════════════
local S5=n("Frame",{Name="FrameExit",Size=UDim2.new(1,0,1,0),BackgroundColor3=C.black,BackgroundTransparency=0.4,BorderSizePixel=0,Visible=false},root)
local eBox=modalBox(S5,380,210,C.danger)
modalHdr(eBox,"⚠","SALIR DEL JUEGO")
local eBody=n("Frame",{Size=UDim2.new(1,-48,0,102),Position=UDim2.new(0,24,0,60),BackgroundTransparency=1,ZIndex=52},eBox)
n("TextLabel",{Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,Text="👋",Font=F.body,TextSize=34,ZIndex=53},eBody)
n("TextLabel",{Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,0,38),BackgroundTransparency=1,Text="¿Seguro que deseas salir?\nTu progreso ha sido guardado automáticamente.",TextColor3=C.muted,Font=F.body,TextSize=12,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=53},eBody)
local eF=n("Frame",{Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,1,-50),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=52},eBox) stroke(C.border,1,eF)
local eCan=n("TextButton",{Name="CancelBtn",Size=UDim2.new(0,100,0,34),Position=UDim2.new(1,-224,0.5,-17),BackgroundColor3=C.panel,Text="Cancelar",TextColor3=C.muted,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=53},eF) corner(6,eCan) stroke(C.border,1,eCan)
local eConf=n("TextButton",{Name="ConfirmBtn",Size=UDim2.new(0,108,0,34),Position=UDim2.new(1,-112,0.5,-17),BackgroundColor3=C.panel,Text="SALIR",TextColor3=C.danger,Font=F.mono,TextSize=12,BorderSizePixel=0,ZIndex=53},eF) corner(6,eConf) stroke(C.danger,1,eConf)

-- ════════════════════════════════════════════
-- FRAME 6: LOGROS
-- ════════════════════════════════════════════
-- Estructura estática del panel de logros.
-- ControladorMenu.client.lua genera las tarjetas dinámicamente
-- al abrir el modal, usando LogrosConfig y datos del servidor.
-- ════════════════════════════════════════════
local S6 = n("Frame", {
	Name = "FrameLogros",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = C.black,
	BackgroundTransparency = 0.4,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 20,
}, root)

local lBox = n("Frame", {
	Name = "Contenedor",
	Size = UDim2.new(0, 520, 0, 420),
	Position = UDim2.new(0.5, -260, 0.5, -210),
	BackgroundColor3 = C.panel,
	BorderSizePixel = 0,
	ZIndex = 21,
}, S6)
corner(12, lBox)
stroke(C.borderHi, 1, lBox)

-- Header del panel de logros
local lHdr = n("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 50),
	BackgroundTransparency = 1,
	ZIndex = 22,
}, lBox)

n("TextLabel", {
	Name = "Titulo",
	Size = UDim2.new(0, 300, 1, 0),
	Position = UDim2.new(0, 20, 0, 0),
	BackgroundTransparency = 1,
	Text = "🏆  LOGROS",
	TextColor3 = C.text,
	Font = F.bold,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 23,
}, lHdr)

n("TextLabel", {
	Name = "Contador",
	Size = UDim2.new(0, 120, 1, 0),
	Position = UDim2.new(1, -200, 0, 0),
	BackgroundTransparency = 1,
	Text = "0 / 0",
	TextColor3 = C.muted,
	Font = F.mono,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 23,
}, lHdr)

local lClose = n("TextButton", {
	Name = "CloseBtn",
	Size = UDim2.new(0, 32, 0, 32),
	Position = UDim2.new(1, -42, 0, 9),
	BackgroundColor3 = C.fondo,
	Text = "✕",
	TextColor3 = C.muted,
	Font = F.bold,
	TextSize = 14,
	BorderSizePixel = 0,
	ZIndex = 23,
}, lHdr)
corner(6, lClose)
stroke(C.border, 1, lClose)

-- ScrollingFrame para las tarjetas de logros (dinámicas)
local lScroll = n("ScrollingFrame", {
	Name = "Scroll",
	Size = UDim2.new(1, -20, 1, -60),
	Position = UDim2.new(0, 10, 0, 50),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = C.dim,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ZIndex = 22,
}, lBox)
pad(5, 5, 5, 5, lScroll)

n("UIGridLayout", {
	CellSize = UDim2.new(0, 235, 0, 80),
	CellPadding = UDim2.new(0, 10, 0, 10),
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, lScroll)

print("[EDA Quest] ✅ GUI v5 — estructura lista, tarjetas se generarán dinámicamente")
