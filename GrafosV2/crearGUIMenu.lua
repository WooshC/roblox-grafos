local SG = game:GetService("StarterGui")
local ex = SG:FindFirstChild("EDAQuestMenu")
if ex then ex:Destroy() end

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
	local btn=n("TextButton",{Name="CloseBtn",Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,-42,0.5,-15),BackgroundColor3=C.panel,Text="✕",TextColor3=C.muted,Font=F.bold,TextSize=14,BorderSizePixel=0,ZIndex=zIdx},parent)
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

local function modalFooter(box, showSave)
	local f=n("Frame",{Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,1,-50),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=52},box)
	stroke(C.border,1,f)
	if showSave then
		local bc=n("TextButton",{Size=UDim2.new(0,110,0,34),Position=UDim2.new(1,-258,0.5,-17),BackgroundColor3=C.panel,Text="Cancelar",TextColor3=C.muted,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=53},f) corner(6,bc) stroke(C.border,1,bc)
		local bs=n("TextButton",{Name="SaveBtn",Size=UDim2.new(0,132,0,34),Position=UDim2.new(1,-136,0.5,-17),BackgroundColor3=C.accent,Text="Guardar cambios",TextColor3=C.black,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=53},f) corner(6,bs)
	else
		local bc=n("TextButton",{Name="OkBtn",Size=UDim2.new(0,100,0,34),Position=UDim2.new(1,-116,0.5,-17),BackgroundColor3=C.accent,Text="Cerrar",TextColor3=C.black,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=53},f) corner(6,bc)
	end
	return f
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
	if sub~="" then n("TextLabel",{Name="Sub",Size=UDim2.new(1,-80,0,14),Position=UDim2.new(0,50,0,isPlay and 38 or 32),BackgroundTransparency=1,Text=sub,TextColor3=C.muted,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7},btn) end
	n("TextLabel",{Size=UDim2.new(0,18,1,0),Position=UDim2.new(1,-24,0,0),BackgroundTransparency=1,Text="›",TextColor3=C.dim,Font=F.bold,TextSize=20,ZIndex=7},btn)
end

menuBtn("BtnPlay",    "▶","JUGAR",   "Seleccionar nivel",           C.accent3,true, 1)
menuDivider(2)
menuBtn("BtnSettings","⚙","AJUSTES", "Dificultad · Colores · Audio",C.accent, false,3)
menuBtn("BtnCredits", "ℹ","CRÉDITOS","Equipo y herramientas",        C.accent2,false,4)
menuDivider(5)
menuBtn("BtnExit",    "✕","SALIR",   "",                             C.danger, false,6)
n("TextLabel",{Name="Version",Size=UDim2.new(0,100,0,18),Position=UDim2.new(1,-116,1,-24),BackgroundTransparency=1,Text="BUILD 2.0.0",TextColor3=C.dim,Font=F.mono,TextSize=10,ZIndex=5},S1)

-- ════════════════════════════════════════════
-- FRAME 2: SELECTOR DE NIVELES
-- ════════════════════════════════════════════
local S2=n("Frame",{Name="FrameLevels",Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(4,7,14),BackgroundTransparency=0.05,BorderSizePixel=0,Visible=false},root)

local lsTop=n("Frame",{Size=UDim2.new(1,0,0,60),BackgroundColor3=Color3.fromRGB(6,10,20),BackgroundTransparency=0.05,BorderSizePixel=0,ZIndex=2},S2)
stroke(C.border,1,lsTop)
local backBtn=n("TextButton",{Name="BackBtn",Size=UDim2.new(0,110,0,36),Position=UDim2.new(0,20,0.5,-18),BackgroundColor3=C.panel,Text="← VOLVER",TextColor3=C.muted,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=3},lsTop)
corner(6,backBtn) stroke(C.border,1,backBtn)
n("TextLabel",{Size=UDim2.new(0,80,1,0),Position=UDim2.new(0,148,0,0),BackgroundTransparency=1,Text="EDA Quest",TextColor3=C.muted,Font=F.mono,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},lsTop)
n("TextLabel",{Size=UDim2.new(0,14,1,0),Position=UDim2.new(0,232,0,0),BackgroundTransparency=1,Text="›",TextColor3=C.dim,Font=F.bold,TextSize=14,ZIndex=3},lsTop)
n("TextLabel",{Size=UDim2.new(0,180,1,0),Position=UDim2.new(0,252,0,0),BackgroundTransparency=1,Text="Selección de Nivel",TextColor3=C.text,Font=F.mono,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},lsTop)
local ptag=n("Frame",{Size=UDim2.new(0,140,0,34),Position=UDim2.new(1,-156,0.5,-17),BackgroundColor3=Color3.fromRGB(0,20,30),BorderSizePixel=0,ZIndex=3},lsTop)
corner(17,ptag) stroke(Color3.fromRGB(0,70,90),1,ptag)
local pav=n("Frame",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0,6,0.5,-11),BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=4},ptag) corner(11,pav)
n("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="P",TextColor3=C.bg,Font=F.bold,TextSize=12,ZIndex=5},pav)
n("TextLabel",{Size=UDim2.new(1,-36,1,0),Position=UDim2.new(0,32,0,0),BackgroundTransparency=1,Text="Jugador_01",TextColor3=C.accent,Font=F.body,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4},ptag)

local lsMain=n("Frame",{Size=UDim2.new(1,0,1,-60),Position=UDim2.new(0,0,0,60),BackgroundTransparency=1,ZIndex=2},S2)
local sidebar=n("Frame",{Size=UDim2.new(0,320,1,0),BackgroundColor3=Color3.fromRGB(6,10,20),BackgroundTransparency=0.05,BorderSizePixel=0,ZIndex=3},lsMain)
stroke(C.border,1,sidebar)

local sideHead=n("Frame",{Size=UDim2.new(1,0,0,56),BackgroundTransparency=1,ZIndex=4},sidebar) stroke(C.border,1,sideHead)
n("TextLabel",{Size=UDim2.new(1,-40,0,20),Position=UDim2.new(0,20,0,10),BackgroundTransparency=1,Text="INFORMACIÓN",TextColor3=C.text,Font=F.bold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},sideHead)
n("TextLabel",{Size=UDim2.new(1,-40,0,16),Position=UDim2.new(0,20,0,32),BackgroundTransparency=1,Text="Selecciona un nivel para ver detalles",TextColor3=C.muted,Font=F.body,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},sideHead)

local placeholder=n("Frame",{Name="Placeholder",Size=UDim2.new(1,0,1,-130),Position=UDim2.new(0,0,0,56),BackgroundTransparency=1,Visible=true,ZIndex=4},sidebar)
n("TextLabel",{Size=UDim2.new(1,0,0,44),Position=UDim2.new(0,0,0.38,0),BackgroundTransparency=1,Text="🗺️",Font=F.body,TextSize=40,ZIndex=5},placeholder)
n("TextLabel",{Size=UDim2.new(1,-40,0,56),Position=UDim2.new(0,20,0.45,0),BackgroundTransparency=1,Text="Selecciona una tarjeta de nivel\npara ver su información y comenzar.",TextColor3=C.muted,Font=F.body,TextSize=12,TextXAlignment=Enum.TextXAlignment.Center,TextWrapped=true,ZIndex=5},placeholder)

local infoContent=n("Frame",{Name="InfoContent",Size=UDim2.new(1,0,1,-130),Position=UDim2.new(0,0,0,56),BackgroundTransparency=1,Visible=false,ZIndex=4},sidebar)
local hero=n("Frame",{Name="Hero",Size=UDim2.new(1,0,0,140),BackgroundColor3=Color3.fromRGB(8,14,26),BorderSizePixel=0,ZIndex=5},infoContent)
local heroGlow=n("Frame",{Size=UDim2.new(0,110,0,110),Position=UDim2.new(0.5,-55,0.5,-55),BackgroundColor3=C.accent,BackgroundTransparency=0.72,BorderSizePixel=0,ZIndex=5},hero) corner(55,heroGlow)
n("TextLabel",{Name="HeroEmoji",Size=UDim2.new(0,60,0,60),Position=UDim2.new(0.5,-30,0.5,-30),BackgroundTransparency=1,Text="🧪",Font=F.body,TextSize=50,ZIndex=6},hero)
local heroBadge=n("Frame",{Name="HeroBadge",Size=UDim2.new(0,110,0,22),Position=UDim2.new(1,-118,0,10),BackgroundColor3=Color3.fromRGB(4,26,18),BorderSizePixel=0,ZIndex=6},hero)
corner(3,heroBadge) stroke(C.accent3,1,heroBadge)
n("TextLabel",{Name="HeroBadgeText",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="◆ DISPONIBLE",TextColor3=C.accent3,Font=F.mono,TextSize=9,ZIndex=7},heroBadge)

local infoBody=n("ScrollingFrame",{Name="InfoBody",Size=UDim2.new(1,0,1,-140),Position=UDim2.new(0,0,0,140),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.border,CanvasSize=UDim2.new(0,0,0,440),BorderSizePixel=0,ZIndex=5},infoContent)
pad(16,16,20,20,infoBody)
n("UIListLayout",{Padding=UDim.new(0,12),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder},infoBody)
n("TextLabel",{Name="InfoTag",Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="NIVEL 0 · FUNDAMENTOS",TextColor3=C.accent,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1},infoBody)
n("TextLabel",{Name="InfoName",Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,Text="Laboratorio de Grafos",TextColor3=C.text,Font=F.bold,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=2},infoBody)
n("TextLabel",{Name="InfoDesc",Size=UDim2.new(1,0,0,64),BackgroundTransparency=1,Text="Descripción del nivel...",TextColor3=C.muted,Font=F.body,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,LayoutOrder=3},infoBody)

local starsFrame=n("Frame",{Name="Stars",Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,LayoutOrder=4},infoBody)
n("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center},starsFrame)
for i=1,3 do n("TextLabel",{Name="Star"..i,Size=UDim2.new(0,22,1,0),BackgroundTransparency=1,Text="⭐",Font=F.body,TextSize=18,TextTransparency=i==1 and 0 or 0.7},starsFrame) end

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
	n("TextLabel",{Name="Val",Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,8,0,24),BackgroundTransparency=1,Text="—",TextColor3=sd.col,Font=F.mono,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7},box)
end
n("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="CONCEPTOS",TextColor3=C.muted,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=6},infoBody)
local tagsFrame=n("Frame",{Name="Tags",Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,LayoutOrder=7},infoBody)
n("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center,Wraps=true},tagsFrame)
for _,t in ipairs({"Nodos","Aristas","Adyacencia"}) do
	local tb=n("TextButton",{Size=UDim2.new(0,0,0,22),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=Color3.fromRGB(0,20,30),Text=t,TextColor3=Color3.fromRGB(0,138,170),Font=F.mono,TextSize=9,BorderSizePixel=0},tagsFrame)
	corner(3,tb) stroke(Color3.fromRGB(0,62,90),1,tb) pad(3,3,8,8,tb)
end

local playArea=n("Frame",{Name="PlayArea",Size=UDim2.new(1,0,0,72),Position=UDim2.new(0,0,1,-72),BackgroundTransparency=1,ZIndex=4},sidebar)
stroke(C.border,1,playArea)
local playBtn=n("TextButton",{Name="PlayButton",Size=UDim2.new(1,-44,0,44),Position=UDim2.new(0,22,0.5,-22),BackgroundColor3=C.panel,Text="🔒  SELECCIONA UN NIVEL",TextColor3=C.muted,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=5},playArea)
corner(8,playBtn) stroke(C.border,1,playBtn)

local gridScroll=n("ScrollingFrame",{Name="GridArea",Size=UDim2.new(1,-320,1,0),Position=UDim2.new(0,320,0,0),BackgroundTransparency=1,ScrollBarThickness=4,ScrollBarImageColor3=C.border,CanvasSize=UDim2.new(0,0,0,980),BorderSizePixel=0,ZIndex=3},lsMain)
pad(28,28,32,32,gridScroll)
n("UIListLayout",{Padding=UDim.new(0,0),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder},gridScroll)

local progWrap=n("Frame",{Size=UDim2.new(1,0,0,60),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=4,LayoutOrder=1},gridScroll)
corner(8,progWrap) stroke(C.border,1,progWrap)
n("TextLabel",{Size=UDim2.new(0,60,0,26),Position=UDim2.new(0,16,0,7),BackgroundTransparency=1,Text="2 / 5",TextColor3=C.text,Font=F.title,TextSize=20,ZIndex=5},progWrap)
n("TextLabel",{Size=UDim2.new(0,140,0,16),Position=UDim2.new(0,16,0,36),BackgroundTransparency=1,Text="Niveles completados",TextColor3=C.muted,Font=F.mono,TextSize=9,ZIndex=5},progWrap)
local bt=n("Frame",{Size=UDim2.new(1,-220,0,6),Position=UDim2.new(0,165,0.5,-3),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=5},progWrap) corner(3,bt)
local bf=n("Frame",{Name="Fill",Size=UDim2.new(0.4,0,1,0),BackgroundColor3=C.accent3,BorderSizePixel=0,ZIndex=6},bt) corner(3,bf)
n("TextLabel",{Size=UDim2.new(0,44,1,0),Position=UDim2.new(1,-46,0,0),BackgroundTransparency=1,Text="40%",TextColor3=C.accent3,Font=F.mono,TextSize=11,ZIndex=5},progWrap)
n("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,LayoutOrder=2},gridScroll)

local function sectionHead(title,count,order)
	local sh=n("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,ZIndex=4,LayoutOrder=order},gridScroll)
	n("TextLabel",{Size=UDim2.new(0,210,1,0),BackgroundTransparency=1,Text=title,TextColor3=C.muted,Font=F.bold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},sh)
	n("Frame",{Size=UDim2.new(1,-230,0,1),Position=UDim2.new(0,220,0.5,0),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=5},sh)
	n("TextLabel",{Size=UDim2.new(0,80,1,0),Position=UDim2.new(1,-80,0,0),BackgroundTransparency=1,Text=count.." niveles",TextColor3=C.dim,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=5},sh)
end

local function levelCard(lv,xi,cont)
	local sC={completado=C.gold,disponible=C.accent3,bloqueado=C.muted}
	local sT={completado="✓ COMPLETADO",disponible="DISPONIBLE",bloqueado="🔒 BLOQUEADO"}
	local sc=sC[lv.status]
	local card=n("TextButton",{Name="Card"..lv.id,Size=UDim2.new(0,200,0,165),Position=UDim2.new(0,xi*214,0,0),BackgroundColor3=C.panel,Text="",AutoButtonColor=false,BorderSizePixel=0,ZIndex=4},cont)
	corner(10,card) stroke(lv.status=="completado" and C.gold or C.border,1,card)
	n("TextLabel",{Size=UDim2.new(0,60,0,14),Position=UDim2.new(0,12,0,10),BackgroundTransparency=1,Text="Nivel "..lv.id,TextColor3=C.accent,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},card)
	local sbg=n("Frame",{Name="StatusBadge",Size=UDim2.new(0,90,0,16),Position=UDim2.new(1,-98,0,9),BackgroundColor3=sc,BackgroundTransparency=0.88,BorderSizePixel=0,ZIndex=5},card) corner(3,sbg) stroke(sc,1,sbg)
	n("TextLabel",{Name="StatusText",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=sT[lv.status],TextColor3=sc,Font=F.mono,TextSize=8,ZIndex=6},sbg)
	n("TextLabel",{Size=UDim2.new(1,0,0,40),Position=UDim2.new(0,0,0,26),BackgroundTransparency=1,Text=lv.emoji,Font=F.body,TextSize=28,ZIndex=5},card)
	n("TextLabel",{Size=UDim2.new(1,-24,0,32),Position=UDim2.new(0,12,0,68),BackgroundTransparency=1,Text=lv.name,TextColor3=lv.status=="bloqueado" and C.muted or C.text,Font=F.bold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=5},card)
	n("TextLabel",{Size=UDim2.new(1,-24,0,14),Position=UDim2.new(0,12,0,102),BackgroundTransparency=1,Text="· "..lv.algo,TextColor3=C.muted,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5},card)
	local ft=n("Frame",{Name="CardFooter",Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,1,-28),BackgroundTransparency=1,ZIndex=5},card) stroke(C.border,1,ft)
	local ss="" for i=1,3 do ss=ss..(i<=lv.stars and "★" or "☆") end
	n("TextLabel",{Name="CardStars",Size=UDim2.new(0,56,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text=ss,TextColor3=C.gold,Font=F.body,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},ft)
	n("TextLabel",{Name="CardScore",Size=UDim2.new(0,70,1,0),Position=UDim2.new(1,-78,0,0),BackgroundTransparency=1,Text=lv.score>0 and lv.score.." pts" or "—",TextColor3=C.gold,Font=F.mono,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=6},ft)
	if lv.status=="bloqueado" then
		local ov=n("Frame",{Name="LockOverlay",Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(4,6,12),BackgroundTransparency=0.45,BorderSizePixel=0,ZIndex=7},card) corner(10,ov)
		n("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="🔒",Font=F.body,TextSize=26,ZIndex=8},ov)
	end
end

local lvls={
	{id=0,name="Laboratorio de Grafos", emoji="🧪",algo="Grafos No Dirigidos",status="completado",stars=3,score=1480},
	{id=1,name="La Red Desconectada",   emoji="🏙️",algo="Conectividad",        status="completado",stars=2,score=960},
	{id=2,name="La Fábrica de Señales", emoji="🏭",algo="BFS · DFS",            status="disponible",stars=0,score=0},
	{id=3,name="El Puente Roto",        emoji="🌉",algo="Grafos Dirigidos",      status="bloqueado", stars=0,score=0},
	{id=4,name="Ruta Mínima",           emoji="🗺️",algo="Dijkstra",             status="bloqueado", stars=0,score=0},
}
sectionHead("INTRODUCCIÓN A GRAFOS",2,3)
local gI=n("Frame",{Size=UDim2.new(1,0,0,165),BackgroundTransparency=1,ZIndex=4,LayoutOrder=4},gridScroll)
for i,lv in ipairs({lvls[1],lvls[2]}) do levelCard(lv,i-1,gI) end
n("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=5},gridScroll)
sectionHead("ALGORITMOS DE BÚSQUEDA",2,6)
local gB=n("Frame",{Size=UDim2.new(1,0,0,165),BackgroundTransparency=1,ZIndex=4,LayoutOrder=7},gridScroll)
for i,lv in ipairs({lvls[3],lvls[4]}) do levelCard(lv,i-1,gB) end
n("Frame",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,LayoutOrder=8},gridScroll)
sectionHead("RUTAS ÓPTIMAS",1,9)
local gR=n("Frame",{Size=UDim2.new(1,0,0,165),BackgroundTransparency=1,ZIndex=4,LayoutOrder=10},gridScroll)
levelCard(lvls[5],0,gR)

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

-- Dificultad
sLabel("🎯","DIFICULTAD",1)
local dG=n("Frame",{Size=UDim2.new(1,0,0,168),BackgroundTransparency=1,LayoutOrder=2},sScroll)
n("UIListLayout",{Padding=UDim.new(0,6),FillDirection=Enum.FillDirection.Vertical},dG)
for _,d in ipairs({{"Normal","Niveles como diseñados · Guía visual activa",true},{"Difícil","+30% nodos · Presupuesto −20% · Límite 10 min",false},{"Experto","+60% nodos · Sin guía · Sin pistas · Límite 5 min",false}}) do
	local r=n("Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=C.panel,BorderSizePixel=0},dG) corner(6,r) stroke(d[3] and C.accent or C.border,1,r)
	local dot=n("Frame",{Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,12,0.5,-6),BackgroundColor3=d[3] and C.accent or C.panel,BorderSizePixel=0},r) corner(6,dot) stroke(d[3] and C.accent or C.border,2,dot)
	n("TextLabel",{Size=UDim2.new(1,-40,0,18),Position=UDim2.new(0,34,0,8),BackgroundTransparency=1,Text=d[1],TextColor3=d[3] and C.text or C.muted,Font=F.bold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},r)
	n("TextLabel",{Size=UDim2.new(1,-40,0,14),Position=UDim2.new(0,34,0,28),BackgroundTransparency=1,Text=d[2],TextColor3=C.muted,Font=F.mono,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},r)
end

-- Color de Cables
sLabel("🔌","COLOR DE CABLES",3)
local cG=n("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,LayoutOrder=4},sScroll)
n("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),VerticalAlignment=Enum.VerticalAlignment.Center},cG)
for i,sw in ipairs({
	{Color3.fromRGB(0,212,255), true},  -- Clásico cyan (activo)
	{Color3.fromRGB(16,185,129),false}, -- Verde
	{Color3.fromRGB(249,115,22),false}, -- Naranja
	{Color3.fromRGB(168,85,247),false}, -- Violeta
	{Color3.fromRGB(239,68,68), false}, -- Rojo
	{Color3.fromRGB(245,158,11),false}, -- Dorado
}) do
	local s=n("TextButton",{Size=UDim2.new(0,30,0,30),BackgroundColor3=sw[1],Text="",BorderSizePixel=0,ZIndex=53},cG)
	corner(6,s) stroke(sw[2] and Color3.fromRGB(255,255,255) or Color3.fromRGB(30,30,30),sw[2] and 2.5 or 1,s)
end

-- Indicadores Visuales
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
	Color3.fromRGB(0,212,255),  -- cyan
	Color3.fromRGB(245,158,11), -- gold
	Color3.fromRGB(16,185,129), -- green
	Color3.fromRGB(168,85,247), -- violet
}
colorPickRow("Nodo seleccionado", indColors, 2, iG)
colorPickRow("Nodo Adyacente",    indColors, 1, iG)

-- Audio
sLabel("🔊","AUDIO",7)
local aG=n("Frame",{Size=UDim2.new(1,0,0,72),BackgroundTransparency=1,LayoutOrder=8},sScroll)
n("UIListLayout",{Padding=UDim.new(0,12),FillDirection=Enum.FillDirection.Vertical},aG)
for i,aud in ipairs({{"Música ambiente","70%",0.7},{"Efectos de sonido","85%",0.85}}) do
	local sliderName = i==1 and "AmbientSlider" or "SFXSlider"
	local ar=n("Frame",{Name=sliderName,Size=UDim2.new(1,0,0,28),BackgroundTransparency=1},aG)
	n("TextLabel",{Size=UDim2.new(0,130,1,0),BackgroundTransparency=1,Text=aud[1],TextColor3=C.muted,Font=F.body,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left},ar)
	local st=n("TextButton",{Name="Track",Text="",AutoButtonColor=false,Size=UDim2.new(1,-180,0,10),Position=UDim2.new(0,140,0.5,-5),BackgroundColor3=C.border,BorderSizePixel=0,ZIndex=53},ar) corner(5,st)
	local sf2=n("Frame",{Name="Fill",Size=UDim2.new(aud[3],0,1,0),BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=54},st) corner(5,sf2)
	n("TextLabel",{Name="Pct",Size=UDim2.new(0,38,1,0),Position=UDim2.new(1,-38,0,0),BackgroundTransparency=1,Text=aud[2],TextColor3=C.accent,Font=F.mono,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right},ar)
end

local sF=n("Frame",{Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,1,-50),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=52},sBox) stroke(C.border,1,sF)
local sCan=n("TextButton",{Name="CancelBtn",Size=UDim2.new(0,110,0,34),Position=UDim2.new(1,-258,0.5,-17),BackgroundColor3=C.panel,Text="Cancelar",TextColor3=C.muted,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=53},sF) corner(6,sCan) stroke(C.border,1,sCan)
local sSav=n("TextButton",{Name="SaveBtn",Size=UDim2.new(0,132,0,34),Position=UDim2.new(1,-136,0.5,-17),BackgroundColor3=C.accent,Text="Guardar cambios",TextColor3=C.black,Font=F.mono,TextSize=11,BorderSizePixel=0,ZIndex=53},sF) corner(6,sSav)

-- ════════════════════════════════════════════
-- FRAME 4: CRÉDITOS
-- ════════════════════════════════════════════
local S4=n("Frame",{Name="FrameCredits",Size=UDim2.new(1,0,1,0),BackgroundColor3=C.black,BackgroundTransparency=0.4,BorderSizePixel=0,Visible=false},root)
local cBox=modalBox(S4,480,416)
modalHdr(cBox,"ℹ","CRÉDITOS")
local cBody=n("Frame",{Size=UDim2.new(1,-48,0,306),Position=UDim2.new(0,24,0,60),BackgroundTransparency=1,ZIndex=52},cBox)
n("UIListLayout",{Padding=UDim.new(0,10),FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder},cBody)
for i,cr in ipairs({
	{"👨‍💻","Desarrollo","Diseño e implementación del sistema de juego serio, arquitectura de servicios y mecánicas de grafos."},
	{"🔧","Herramientas","Roblox Studio · Lua 5.1 · BFS, DFS, Dijkstra · DataStore"},
	{"📚","Marco Educativo","Diseñado para el aprendizaje de EDA. Basado en metodologías de juegos serios."},
	{"💡","Inspiración","Teoría de grafos clásica · Cormen et al. · Comunidad educativa de Roblox"},
}) do
	local card=n("Frame",{Size=UDim2.new(1,0,0,62),BackgroundColor3=C.panel,BorderSizePixel=0,LayoutOrder=i},cBody)
	corner(8,card) stroke(C.border,1,card)
	n("TextLabel",{Size=UDim2.new(0,42,1,0),BackgroundTransparency=1,Text=cr[1],Font=F.body,TextSize=24,ZIndex=53},card)
	n("TextLabel",{Size=UDim2.new(1,-56,0,20),Position=UDim2.new(0,48,0,10),BackgroundTransparency=1,Text=cr[2],TextColor3=C.text,Font=F.bold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=53},card)
	n("TextLabel",{Size=UDim2.new(1,-56,0,28),Position=UDim2.new(0,48,0,32),BackgroundTransparency=1,Text=cr[3],TextColor3=C.muted,Font=F.body,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=53},card)
end
local cF=n("Frame",{Size=UDim2.new(1,0,0,50),Position=UDim2.new(0,0,1,-50),BackgroundColor3=C.panel,BorderSizePixel=0,ZIndex=52},cBox) stroke(C.border,1,cF)
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

print("[EDA Quest] ✅ GUI v5 — FrameMenu · FrameLevels · FrameSettings · FrameCredits · FrameExit")