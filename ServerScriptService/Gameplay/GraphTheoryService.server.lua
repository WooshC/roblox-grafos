local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local remotesFolder = eventsFolder:WaitForChild("Remotes")

-- Create RemoteFunction for Matrix Data
local getMatrixFunc = remotesFolder:FindFirstChild("GetAdjacencyMatrix")
if not getMatrixFunc then
	getMatrixFunc = Instance.new("RemoteFunction")
	getMatrixFunc.Name = "GetAdjacencyMatrix"
	getMatrixFunc.Parent = remotesFolder
end

-- Utility to find poles
local function getAllPoles(nivelID)
	local levelName = "Nivel" .. nivelID
	if nivelID == 0 then levelName = "Nivel0_Tutorial" end
	
	local levelModel = workspace:FindFirstChild(levelName)
	if not levelModel then return {} end
	
	local postsFolder = levelModel:FindFirstChild("Objetos") and levelModel.Objetos:FindFirstChild("Postes")
	if not postsFolder then return {} end
	
	local poles = {}
	for _, child in ipairs(postsFolder:GetChildren()) do
		if child:IsA("Model") then
			table.insert(poles, child)
		end
	end
	
	-- Sort alphabetically for consistent matrix
	table.sort(poles, function(a, b) return a.Name < b.Name end)
	
	return poles
end

-- Main function to build matrix
local function buildAdjacencyMatrix(player, nivelID)
	local poles = getAllPoles(nivelID)
	local poleNames = {}
	local matrix = {}
	
	-- 1. Index Poles
	for i, pole in ipairs(poles) do
		poleNames[i] = pole.Name
		matrix[i] = {}
		for j = 1, #poles do
			matrix[i][j] = 0 -- 0 means no connection (or use math.huge for distance logic, but 0 is cleaner for UI)
		end
	end
	
	-- 2. Fill Matrix
	for i, pole in ipairs(poles) do
		local connections = pole:FindFirstChild("Connections")
		if connections then
			for _, conn in ipairs(connections:GetChildren()) do
				if conn:IsA("NumberValue") then
					local targetName = conn.Name
					local weight = conn.Value
					
					-- Find index of target
					for j, name in ipairs(poleNames) do
						if name == targetName then
							matrix[i][j] = weight
							break
						end
					end
				end
			end
		end
	end
	
	return {
		Headers = poleNames,
		Matrix = matrix
	}
end

getMatrixFunc.OnServerInvoke = buildAdjacencyMatrix

print("✅ GraphTheoryService loaded: Matrix Calculation Ready")
