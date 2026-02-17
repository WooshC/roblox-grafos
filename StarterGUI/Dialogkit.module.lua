local module = {}
local skins = script.Parent.Skins
local defaultTransparencyValues = {}
local currentDialogue = nil
local currentLayer = nil
local currentContentIndex = nil
local currentSkin = nil
local continueConnection = nil
local typewriterThread = nil
local isTyping = false
local replyConnections = {}
local isShowingReplies = false
local cinematicBars = {}

local inputBeganConnection = nil
local controllerInputBeganConnection = nil

local originalWalkSpeed = nil
local originalCoreGuiState = {Backpack = nil, Chat = nil, PlayerList = nil}
local originalCameraType = nil
local backgroundSoundInstance = nil
local healthChangedConnection = nil
local activeDialogueSound = nil


local DialogueVisibilityManager = nil

-- Intentar cargar el módulo
local success, loaded = pcall(function()
	return require(game:GetService("ReplicatedStorage"):WaitForChild("DialogueVisibilityManager", 3))
end)

if success and loaded then
	DialogueVisibilityManager = loaded
	-- print("✅ [DialogueKit] DialogueVisibilityManager cargado correctamente")
else
	-- warn("⚠️ [DialogueKit] DialogueVisibilityManager no disponible")
end


function parseNodeDialogue(nodeProjectName)
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local dialogueNodeFolder = replicatedStorage:FindFirstChild("Dialogue_node")

	if not dialogueNodeFolder then
		-- warn("Dialogue_node folder not found in ReplicatedStorage")
		return nil
	end

	local nodeFolder = dialogueNodeFolder:FindFirstChild(nodeProjectName)
	if not nodeFolder then
		-- warn("Node project '" .. nodeProjectName .. "' not found")
		return nil
	end

	local nodesFolder = nodeFolder:FindFirstChild("nodes")
	if not nodesFolder then
		-- warn("No 'nodes' folder found in " .. nodeProjectName)
		return nil
	end

	local nodeMap = {}
	local connectorMap = {}

	for _, config in ipairs(nodesFolder:GetChildren()) do
		if config:IsA("Configuration") then
			local nodeType = config:GetAttribute("NodeType")
			nodeMap[config.Name] = {
				config = config,
				nodeType = nodeType,
				connectors = {}
			}

			local connectorCount = config:GetAttribute("ConnectorCount") or 0
			for i = 1, connectorCount do
				local connectorId = config:GetAttribute("Connector" .. i .. "_ID")
				local connectorName = config:GetAttribute("Connector" .. i .. "_Name")
				local connectedTo = config:GetAttribute("Connector" .. i .. "_ConnectedTo")
				local connectedFrom = config:GetAttribute("Connector" .. i .. "_ConnectedFrom")

				if connectorId then
					connectorMap[connectorId] = {
						nodeConfig = config,
						connectorName = connectorName,
						connectedTo = connectedTo,
						connectedFrom = connectedFrom
					}

					nodeMap[config.Name].connectors[connectorName] = {
						id = connectorId,
						connectedTo = connectedTo,
						connectedFrom = connectedFrom
					}
				end
			end
		end
	end

	local configNode = nil
	for nodeName, nodeData in pairs(nodeMap) do
		if nodeData.nodeType == "Config Node" then
			configNode = nodeData
			break
		end
	end

	if not configNode then
		-- warn("No Config Node found in " .. nodeProjectName)
		return nil
	end

	local dialogueStartNode = nil

	local configRightConnector = configNode.connectors["rightConnector"] 
	if configRightConnector and configRightConnector.connectedTo then
		-- print("Found Config right connector with connection: " .. configRightConnector.connectedTo)
		for targetId in string.gmatch(configRightConnector.connectedTo, "[^,]+") do
			local targetConnector = connectorMap[targetId]
			if targetConnector then
				local targetNodeData = nodeMap[targetConnector.nodeConfig.Name]
				-- print("  Config targeting: " .. targetConnector.nodeConfig.Name .. " (" .. (targetNodeData and targetNodeData.nodeType or "nil") .. ") via " .. targetConnector.connectorName)
				if targetNodeData and targetNodeData.nodeType == "Dialogue Start Node" and (targetConnector.connectorName:match("Left") or targetConnector.connectorName:match("left")) then
					dialogueStartNode = targetNodeData
					-- print("Found connected Dialogue Start Node: " .. targetConnector.nodeConfig.Name)
					break
				end
			end
		end
	else
		-- print("No Config right connector found or no connections")
	end

	if not dialogueStartNode then
		-- warn("No Dialogue Start Node connected to Config Node")
		return nil
	end

	local initialLayerNode = nil
	local startRightConnector = dialogueStartNode.connectors["rightConnector"] 
	if startRightConnector and startRightConnector.connectedTo then
		-- print("Found Dialogue Start right connector with connection: " .. startRightConnector.connectedTo)
		for targetId in string.gmatch(startRightConnector.connectedTo, "[^,]+") do
			local targetConnector = connectorMap[targetId]
			if targetConnector then
				local targetNodeData = nodeMap[targetConnector.nodeConfig.Name]
				-- print("  Dialogue Start targeting: " .. targetConnector.nodeConfig.Name .. " (" .. (targetNodeData and targetNodeData.nodeType or "nil") .. ") via " .. targetConnector.connectorName)
				if targetNodeData and targetNodeData.nodeType == "Layer Node" and (targetConnector.connectorName:match("Left") or targetConnector.connectorName:match("left")) then
					initialLayerNode = targetNodeData
					-- print("Found connected Initial Layer Node: " .. targetConnector.nodeConfig.Name)
					break
				end
			end
		end
	else
		-- print("No Dialogue Start right connector found or no connections")
	end

	if not initialLayerNode then
		-- warn("No Layer Node connected to Dialogue Start Node")
		return nil
	end

	local skinName = dialogueStartNode.config:GetAttribute("Param_SkinName") or "DefaultDark"

	local dialogueData = {
		InitialLayer = initialLayerNode.config.Name,
		SkinName = skinName,
		Config = createConfigFromNode(configNode.config),
		Layers = {}
	}

	for nodeName, nodeData in pairs(nodeMap) do
		if nodeData.nodeType == "Layer Node" then
			local layerData = processLayerNode(nodeData, nodeMap, connectorMap)
			dialogueData.Layers[nodeName] = layerData
		end
	end

	return dialogueData
end

function createConfigFromNode(configNode)
	local config = Instance.new("Folder")
	config.Name = "Config"

	local backgroundSound = Instance.new("NumberValue")
	backgroundSound.Name = "BackgroundSound"
	backgroundSound.Value = configNode:GetAttribute("Param_BackgroundSound") or 0
	backgroundSound:SetAttribute("BackgroundSoundPitch", configNode:GetAttribute("Param_BackgroundSoundPitch") or 1)
	backgroundSound:SetAttribute("BackgroundSoundVolume", configNode:GetAttribute("Param_BackgroundSoundVolume") or 0.5)
	backgroundSound.Parent = config

	local cinematicBars = Instance.new("BoolValue")
	cinematicBars.Name = "CinematicBars"
	cinematicBars.Value = configNode:GetAttribute("Param_CinematicBars")
	if cinematicBars.Value == nil then cinematicBars.Value = true end
	cinematicBars:SetAttribute("TweenBars", configNode:GetAttribute("Param_TweenBars") or true)
	cinematicBars.Parent = config

	local continueButton = Instance.new("Configuration")
	continueButton.Name = "ContinueButton"
	continueButton:SetAttribute("FunctionalDuringTypewriter", configNode:GetAttribute("Param_FunctionalDuringTypewriter") or true)
	continueButton:SetAttribute("VisibleDuringReply", configNode:GetAttribute("Param_VisibleDuringReply") or false)
	continueButton:SetAttribute("VisibleDuringTypewriter", configNode:GetAttribute("Param_VisibleDuringTypewriter") or false)
	continueButton:SetAttribute("TransparencyWhenUnclickable", configNode:GetAttribute("Param_TransparencyWhenUnclickable") or 1)
	continueButton.Parent = config

	local coreGui = Instance.new("BoolValue")
	coreGui.Name = "CoreGui"
	coreGui.Value = configNode:GetAttribute("Param_CoreGuiEnabled")
	if coreGui.Value == nil then coreGui.Value = true end
	coreGui:SetAttribute("BackpackEnabled", configNode:GetAttribute("Param_BackpackEnabled") or true)
	coreGui:SetAttribute("ChatEnabled", configNode:GetAttribute("Param_ChatEnabled") or true)
	coreGui:SetAttribute("LeaderboardEnabled", configNode:GetAttribute("Param_LeaderboardEnabled") or true)
	coreGui.Parent = config

	local dialogueCamera = Instance.new("ObjectValue")
	dialogueCamera.Name = "DialogueCamera"
	local cameraPath = configNode:GetAttribute("Param_DialogueCamera") or ""
	if cameraPath ~= "" then
		local success, camera = pcall(function()
			return game:GetService("PathfindingService"):FindFirstChild(cameraPath)
		end)
		if success and camera then
			dialogueCamera.Value = camera
		end
	end
	dialogueCamera.Parent = config

	local walkSpeed = Instance.new("NumberValue")
	walkSpeed.Name = "DialogueWalkSpeed"
	walkSpeed.Value = configNode:GetAttribute("Param_DialogueWalkSpeed") or 0
	walkSpeed:SetAttribute("DefaultWalkSpeed", configNode:GetAttribute("Param_DefaultWalkSpeed") or 16)
	walkSpeed.Parent = config

	local keyCode = Instance.new("StringValue")
	keyCode.Name = "KeyCode"
	keyCode.Value = configNode:GetAttribute("Param_ContinueKey") or "Return"
	keyCode:SetAttribute("ContinueController", configNode:GetAttribute("Param_ContinueController") or "ButtonR1")
	keyCode:SetAttribute("Reply1", configNode:GetAttribute("Param_Reply1Key") or "One")
	keyCode:SetAttribute("Reply2", configNode:GetAttribute("Param_Reply2Key") or "Two")
	keyCode:SetAttribute("Reply3", configNode:GetAttribute("Param_Reply3Key") or "Three")
	keyCode:SetAttribute("Reply4", configNode:GetAttribute("Param_Reply4Key") or "Four")
	keyCode:SetAttribute("Reply1Controller", configNode:GetAttribute("Param_Reply1Controller") or "ButtonX")
	keyCode:SetAttribute("Reply2Controller", configNode:GetAttribute("Param_Reply2Controller") or "ButtonY")
	keyCode:SetAttribute("Reply3Controller", configNode:GetAttribute("Param_Reply3Controller") or "ButtonB")
	keyCode:SetAttribute("Reply4Controller", configNode:GetAttribute("Param_Reply4Controller") or "ButtonA")
	keyCode.Parent = config

	local playerDead = Instance.new("StringValue")
	playerDead.Name = "PlayerDead"
	playerDead.Value = "PlayerDead"
	playerDead:SetAttribute("InteractWhenDead", configNode:GetAttribute("Param_InteractWhenDead") or false)
	playerDead:SetAttribute("StopDialogueOnDeath", configNode:GetAttribute("Param_StopDialogueOnDeath") or true)
	playerDead.Parent = config

	local richText = Instance.new("BoolValue")
	richText.Name = "RichText"
	richText.Value = configNode:GetAttribute("Param_RichTextEnabled")
	if richText.Value == nil then richText.Value = true end
	richText.Parent = config

	local typewriter = Instance.new("BoolValue")
	typewriter.Name = "Typewriter"
	typewriter.Value = configNode:GetAttribute("Param_TypewriterEnabled")
	if typewriter.Value == nil then typewriter.Value = true end
	typewriter:SetAttribute("Sound", configNode:GetAttribute("Param_Sound") or 0)
	typewriter:SetAttribute("SoundPitch", configNode:GetAttribute("Param_SoundPitch") or 1)
	typewriter:SetAttribute("Speed", configNode:GetAttribute("Param_Speed") or 0.01)
	typewriter:SetAttribute("SpeedSpecial", configNode:GetAttribute("Param_SpeedSpecial") or 0.5)
	typewriter.Parent = config

	return config
end

function processLayerNode(layerNode, nodeMap, connectorMap)
	local layerData = {
		Dialogue = {},
		DialogueSounds = {},
		DialogueImage = layerNode.config:GetAttribute("Param_DialogueImage") or "",
		Title = layerNode.config:GetAttribute("Param_DialogueTitle") or "",
		Replies = {}
	}
	local layerData = {
		Dialogue = {},
		DialogueSounds = {},
		DialogueImage = layerNode.config:GetAttribute("Param_DialogueImage") or "",
		Title = layerNode.config:GetAttribute("Param_DialogueTitle") or "",
		Replies = {}
	}

	-- Debug block removed

	local dialogueNodes = {}
	local currentDialogueNode = nil

	-- Debug block removed

	-- print("Looking for DialogueRightConnector or old-style right connectors...")

	local dialogueConnector = layerNode.connectors["DialogueRightConnector"]
	if not dialogueConnector or not dialogueConnector.connectedTo then
		-- print("DialogueRightConnector not found, checking old-style connectors...")
		for connectorName, connector in pairs(layerNode.connectors) do
			if connector.connectedTo and (connectorName:match("right") or connectorName == "rightConnector") then
				-- print("  Checking old-style connector: " .. connectorName)
				for targetId in string.gmatch(connector.connectedTo, "[^,]+") do
					local targetConnector = connectorMap[targetId]
					if targetConnector then
						local targetNodeData = nodeMap[targetConnector.nodeConfig.Name]
						-- print("    Target: " .. targetConnector.nodeConfig.Name .. " (" .. (targetNodeData and targetNodeData.nodeType or "nil") .. ")")
						if targetNodeData and targetNodeData.nodeType == "Dialogue Content Node" and (targetConnector.connectorName:match("Left") or targetConnector.connectorName:match("left")) then
							dialogueConnector = connector  
							-- print("  Found dialogue connection via old-style connector: " .. connectorName)
							break
						end
					end
				end
				if dialogueConnector and dialogueConnector.connectedTo then break end
			end
		end
	end

	if dialogueConnector and dialogueConnector.connectedTo then
		-- print("Found dialogue connector with connection: " .. dialogueConnector.connectedTo)
		for targetId in string.gmatch(dialogueConnector.connectedTo, "[^,]+") do
			-- print("  Checking target ID: " .. targetId)
			local targetConnector = connectorMap[targetId]
			if targetConnector then
				local targetNodeData = nodeMap[targetConnector.nodeConfig.Name]
				-- print("  Target node: " .. targetConnector.nodeConfig.Name .. ", Type: " .. (targetNodeData and targetNodeData.nodeType or "nil"))
				-- print("  Target connector: " .. targetConnector.connectorName)
				if targetNodeData and targetNodeData.nodeType == "Dialogue Content Node" and (targetConnector.connectorName:match("Left") or targetConnector.connectorName:match("left")) then
					currentDialogueNode = targetNodeData
					-- print("Found connected Dialogue Content Node: " .. targetConnector.nodeConfig.Name)
					break
				end
			else
				-- print("  Target connector not found for ID: " .. targetId)
			end
		end
	else
		-- print("No dialogue connector found or no connections")
	end

	while currentDialogueNode do
		table.insert(dialogueNodes, currentDialogueNode)

		local nextDialogueNode = nil

		local contentRightConnector = currentDialogueNode.connectors["ContentRightConnector"]
		if not contentRightConnector or not contentRightConnector.connectedTo then
			contentRightConnector = currentDialogueNode.connectors["rightConnector"]
		end

		if contentRightConnector and contentRightConnector.connectedTo then
			for targetId in string.gmatch(contentRightConnector.connectedTo, "[^,]+") do
				local targetConnector = connectorMap[targetId]
				if targetConnector then
					local targetNodeData = nodeMap[targetConnector.nodeConfig.Name]
					if targetNodeData and (targetNodeData.nodeType == "Dialogue Content Node" or targetNodeData.nodeType == "Dialogue Content Node+") and (targetConnector.connectorName:match("Left") or targetConnector.connectorName:match("left")) then
						nextDialogueNode = targetNodeData
						-- print("Found next Dialogue Content Node: " .. targetConnector.nodeConfig.Name)
						break
					end
				end
			end
		end

		currentDialogueNode = nextDialogueNode
	end

	if #dialogueNodes > 0 then
		for _, dialogueNode in ipairs(dialogueNodes) do
			local content = dialogueNode.config:GetAttribute("Param_Content") or 
				dialogueNode.config:GetAttribute("Param_DialogueContent") or 
				""
			-- print("Extracted content from " .. dialogueNode.config.Name .. " (" .. dialogueNode.nodeType .. "): '" .. content .. "'")
			table.insert(layerData.Dialogue, content)
			table.insert(layerData.DialogueSounds, nil) 
		end
	else
		-- print("No dialogue content nodes found, adding blank entry")
		table.insert(layerData.Dialogue, "")
		table.insert(layerData.DialogueSounds, nil)
	end

	local replyNode = nil

	local repliesConnector = layerNode.connectors["RepliesRightConnector"]
	if not repliesConnector or not repliesConnector.connectedTo then
		-- print("RepliesRightConnector not found, checking old-style connectors for reply connections...")
		for connectorName, connector in pairs(layerNode.connectors) do
			if connector.connectedTo and (connectorName:match("right") or connectorName == "rightConnector") then
				for targetId in string.gmatch(connector.connectedTo, "[^,]+") do
					local targetConnector = connectorMap[targetId]
					if targetConnector then
						local targetNodeData = nodeMap[targetConnector.nodeConfig.Name]
						if targetNodeData and targetNodeData.nodeType == "ReplyNode" and (targetConnector.connectorName:match("Left") or targetConnector.connectorName:match("left")) then
							repliesConnector = connector  
							-- print("Found reply connection via old-style connector: " .. connectorName)
							break
						end
					end
				end
				if repliesConnector and repliesConnector.connectedTo then break end
			end
		end
	end

	if repliesConnector and repliesConnector.connectedTo then
		-- print("Found replies connector with connection: " .. repliesConnector.connectedTo)
		for targetId in string.gmatch(repliesConnector.connectedTo, "[^,]+") do
			local targetConnector = connectorMap[targetId]
			if targetConnector then
				local targetNodeData = nodeMap[targetConnector.nodeConfig.Name]
				if targetNodeData and targetNodeData.nodeType == "ReplyNode" and (targetConnector.connectorName:match("Left") or targetConnector.connectorName:match("left")) then
					replyNode = targetNodeData
					-- print("Found connected Reply Node: " .. targetConnector.nodeConfig.Name)
					break
				end
			end
		end
	else
		-- print("No replies connector found or no connections")
	end

	if replyNode then
		local replyParams = {"Param_Reply1", "Param_Reply2", "Param_Reply3", "Param_Reply4"}

		for i, paramName in ipairs(replyParams) do
			local replyText = replyNode.config:GetAttribute(paramName)
			-- print("Processing " .. paramName .. ": " .. (replyText or "nil"))
			if replyText and replyText ~= "" then
				local replyName = "reply" .. i  

				local targetLayerNode = nil

				local replyConnectorName = "Reply" .. i .. "RightConnector"
				local replyConnector = replyNode.connectors[replyConnectorName]

				if not replyConnector or not replyConnector.connectedTo then
					-- print("  " .. replyConnectorName .. " not found, checking old-style connectors...")
					for connectorName, connector in pairs(replyNode.connectors) do
						if connector.connectedTo and (connectorName:match("right") or connectorName == "rightConnector") then
							for targetId in string.gmatch(connector.connectedTo, "[^,]+") do
								local targetConnector = connectorMap[targetId]
								if targetConnector then
									local targetNodeData = nodeMap[targetConnector.nodeConfig.Name]
									if targetNodeData and targetNodeData.nodeType == "Layer Node" and (targetConnector.connectorName:match("Left") or targetConnector.connectorName:match("left")) then
										replyConnector = connector  
										-- print("  Found reply target via old-style connector: " .. connectorName)
										break
									end
								end
							end
							if replyConnector and replyConnector.connectedTo then break end
						end
					end
				end

				if replyConnector and replyConnector.connectedTo then
					for targetId in string.gmatch(replyConnector.connectedTo, "[^,]+") do
						local targetConnector = connectorMap[targetId]
						if targetConnector then
							local targetNodeData = nodeMap[targetConnector.nodeConfig.Name]
							if targetNodeData and targetNodeData.nodeType == "Layer Node" and (targetConnector.connectorName:match("Left") or targetConnector.connectorName:match("left")) then
								targetLayerNode = targetNodeData
								-- print("Found target Layer Node for reply " .. i .. ": " .. targetConnector.nodeConfig.Name)
								break
							end
						end
					end
				end

				if targetLayerNode then
					layerData.Replies[replyName] = {
						ReplyText = replyText,
						ReplyLayer = targetLayerNode.config.Name
					}
					-- print("Added reply: " .. replyName .. " -> " .. targetLayerNode.config.Name)
				else
					layerData.Replies["_goodbye" .. i] = {  
						ReplyText = replyText
					}
					-- print("Added goodbye reply: _goodbye" .. i)
				end
			end
		end
	end

	-- Debug block removed

	return layerData
end

function module.startNodeDialogue(nodeProjectName)
	local replicatedStorage = game:GetService("ReplicatedStorage")
	local dialogueNodeFolder = replicatedStorage:FindFirstChild("Dialogue_node")

	if not dialogueNodeFolder then
		-- warn("Dialogue_node folder not found in ReplicatedStorage. Node dialogues are not available.")
		return
	end

	local dialogueData = parseNodeDialogue(nodeProjectName)
	if not dialogueData then
		-- warn("Failed to parse node dialogue: " .. nodeProjectName)
		return
	end

	-- print("Starting node dialogue: " .. nodeProjectName)
	-- print("Initial Layer: " .. dialogueData.InitialLayer)
	-- print("Skin: " .. dialogueData.SkinName)

	module.CreateDialogue(dialogueData)
end

function executeLayerFunction(execData)
	if not execData or not execData.Function then
		return
	end

	local success, err = pcall(execData.Function)
	if not success then
		-- warn("Error executing dialogue function: " .. tostring(err))
	end
end

function setupInputHandling(config)
	if not config then return end

	local keyCodeConfig = config:FindFirstChild("KeyCode")
	if not keyCodeConfig or not keyCodeConfig:IsA("StringValue") then return end

	teardownInputHandling()

	local UserInputService = game:GetService("UserInputService")

	inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			if keyCodeConfig.Value ~= "" and Enum.KeyCode[keyCodeConfig.Value] == input.KeyCode then
				local continueButton = skins[currentSkin] and skins[currentSkin].Continue.ContinueButton
				if continueButton and continueButton.Active then
					onContinueButtonClicked()
				end
			end

			if isShowingReplies then
				for i = 1, 4 do
					local replyKeyAttr = keyCodeConfig:GetAttribute("Reply" .. i)
					if replyKeyAttr and replyKeyAttr ~= "" and Enum.KeyCode[replyKeyAttr] == input.KeyCode then
						triggerReplyByIndex(i)
					end
				end
			end
		end
	end)

	controllerInputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.Gamepad1 then
			local continueBtnController = keyCodeConfig:GetAttribute("ContinueController")
			if continueBtnController and continueBtnController ~= "" and Enum.KeyCode[continueBtnController] == input.KeyCode then
				local continueButton = skins[currentSkin] and skins[currentSkin].Continue.ContinueButton
				if continueButton and continueButton.Active then
					onContinueButtonClicked()
				end
			end

			if isShowingReplies then
				for i = 1, 4 do
					local replyKeyAttr = keyCodeConfig:GetAttribute("Reply" .. i .. "Controller")
					if replyKeyAttr and replyKeyAttr ~= "" and Enum.KeyCode[replyKeyAttr] == input.KeyCode then
						triggerReplyByIndex(i)
					end
				end
			end
		end
	end)
end

function teardownInputHandling()
	if inputBeganConnection then
		inputBeganConnection:Disconnect()
		inputBeganConnection = nil
	end

	if controllerInputBeganConnection then
		controllerInputBeganConnection:Disconnect()
		controllerInputBeganConnection = nil
	end
end

function triggerReplyByIndex(index)
	if not currentSkin or not isShowingReplies then return end

	local repliesContainer = skins[currentSkin].Replies
	local visibleReplies = {}

	for _, child in ipairs(repliesContainer:GetChildren()) do
		if child:IsA("Frame") and child:FindFirstChild("ReplyButton") and child.Visible then
			table.insert(visibleReplies, child)
		end
	end

	table.sort(visibleReplies, function(a, b)
		return a.AbsolutePosition.Y < b.AbsolutePosition.Y
	end)

	if index <= #visibleReplies and visibleReplies[index].ReplyButton.Active then
		local replyName = visibleReplies[index].Name
		local layerData = currentDialogue.Layers[currentLayer]
		if layerData and layerData.Replies and layerData.Replies[replyName] then
			onReplyButtonClicked(replyName, layerData.Replies[replyName])
		end
	end
end

function findExecForContent(contentIndex, timing)
	if not currentDialogue or not currentLayer then
		return nil
	end

	local layerData = currentDialogue.Layers[currentLayer]
	if not layerData or not layerData.Exec then
		return nil
	end

	local execsToRun = {}

	for execName, execData in pairs(layerData.Exec) do
		if (execData.ExecContent == "" or tonumber(execData.ExecContent) == contentIndex) and execData.ExecTime == timing then
			table.insert(execsToRun, execData)
		end
	end

	return execsToRun
end

function findExecForContinue(contentIndex)
	if not currentDialogue or not currentLayer then
		return nil
	end

	local layerData = currentDialogue.Layers[currentLayer]
	if not layerData or not layerData.Exec then
		return nil
	end

	local execsToRun = {}
	local continuePattern = "_continue" .. tostring(contentIndex)

	for execName, execData in pairs(layerData.Exec) do
		if execData.ExecContent == continuePattern then
			table.insert(execsToRun, execData)
		end
	end

	return execsToRun
end

function findExecForReply(replyName)
	if not currentDialogue or not currentLayer then
		return nil
	end

	local layerData = currentDialogue.Layers[currentLayer]
	if not layerData or not layerData.Exec then
		return nil
	end

	local execsToRun = {}

	for execName, execData in pairs(layerData.Exec) do
		if execData.ExecContent == replyName then
			table.insert(execsToRun, execData)
		end
	end

	return execsToRun
end

function initializeSkins()
	for _, skin in pairs(skins:GetChildren()) do
		skin.Visible = false
		defaultTransparencyValues[skin.Name] = {}

		for _, descendant in pairs(skin:GetDescendants()) do
			if descendant:IsA("GuiObject") or descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("ImageLabel") or descendant:IsA("UIStroke") then
				local properties = {}

				if descendant:IsA("GuiObject") then
					properties.BackgroundTransparency = descendant.BackgroundTransparency
					descendant.BackgroundTransparency = 1
				end

				if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
					properties.TextTransparency = descendant.TextTransparency
					descendant.TextTransparency = 1
				end

				if descendant:IsA("ImageLabel") then
					properties.ImageTransparency = descendant.ImageTransparency
					descendant.ImageTransparency = 1
				end

				if descendant:IsA("UIStroke") then
					properties.Transparency = descendant.Transparency
					descendant.Transparency = 1
				end

				if descendant:GetAttribute("GroupTransparency") ~= nil then
					properties.GroupTransparency = descendant:GetAttribute("GroupTransparency")
				end

				defaultTransparencyValues[skin.Name][descendant] = properties
			end
		end
	end
end

function tweenPosition(element, targetPosition, easingStyle, easingDirection, tweenTime)
	local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle[easingStyle], Enum.EasingDirection[easingDirection])
	local tween = game:GetService("TweenService"):Create(element, tweenInfo, {Position = targetPosition})
	tween:Play()
	return tween
end

function tweenTransparencyIn(skinName)
	local skin = skins[skinName]
	local tweenInfo = TweenInfo.new(skin:GetAttribute("TweenTime"), Enum.EasingStyle[skin:GetAttribute("EasingStyle")], Enum.EasingDirection[skin:GetAttribute("EasingDirection")])

	for descendant, properties in pairs(defaultTransparencyValues[skinName]) do
		local tweenGoals = {}

		if properties.BackgroundTransparency ~= nil then
			tweenGoals.BackgroundTransparency = properties.BackgroundTransparency
		end

		if properties.TextTransparency ~= nil then
			tweenGoals.TextTransparency = properties.TextTransparency
		end

		if properties.ImageTransparency ~= nil then
			tweenGoals.ImageTransparency = properties.ImageTransparency
		end

		if properties.Transparency ~= nil then
			tweenGoals.Transparency = properties.Transparency
		end

		local tween = game:GetService("TweenService"):Create(descendant, tweenInfo, tweenGoals)
		tween:Play()
	end
end

function tweenTransparencyOut(skinName)
	local skin = skins[skinName]
	local tweenInfo = TweenInfo.new(skin:GetAttribute("TweenTime"), Enum.EasingStyle[skin:GetAttribute("EasingStyle")], Enum.EasingDirection[skin:GetAttribute("EasingDirection")])

	for descendant, _ in pairs(defaultTransparencyValues[skinName]) do
		local tweenGoals = {}

		if descendant:IsA("GuiObject") then
			tweenGoals.BackgroundTransparency = 1
		end

		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			tweenGoals.TextTransparency = 1
		end

		if descendant:IsA("ImageLabel") then
			tweenGoals.ImageTransparency = 1
		end

		if descendant:IsA("UIStroke") then
			tweenGoals.Transparency = 1
		end

		local tween = game:GetService("TweenService"):Create(descendant, tweenInfo, tweenGoals)
		tween:Play()
	end

	return tweenInfo.Time
end

function parseRichText(text)
	local segments = {}
	local currentPosition = 1

	while currentPosition <= #text do
		local tagPatterns = {
			{pattern = '<font color=".-">', closeTag = "</font>", type = "richFormatting"},
			{pattern = '<font transparency=".-">', closeTag = "</font>", type = "richFormatting"},
			{pattern = '<font size=".-">', closeTag = "</font>", type = "richFormatting"},
			{pattern = '<stroke color=".-" thickness=".-">', closeTag = "</stroke>", type = "richFormatting"},
			{pattern = '<stroke thickness=".-" color=".-">', closeTag = "</stroke>", type = "richFormatting"},
			{pattern = '<b>', closeTag = "</b>", type = "richFormatting"},
			{pattern = '<i>', closeTag = "</i>", type = "richFormatting"},
			{pattern = '<u>', closeTag = "</u>", type = "richFormatting"},
			{pattern = '<s>', closeTag = "</s>", type = "richFormatting"},
			{pattern = '<uc>', closeTag = "</uc>", type = "richFormatting"},
			{pattern = '<sc>', closeTag = "</sc>", type = "richFormatting"},
			{pattern = '<br/>', closeTag = "", type = "lineBreak"},
			{pattern = '&lt;', closeTag = "", type = "escape"},
			{pattern = '&gt;', closeTag = "", type = "escape"},
			{pattern = '&quot;', closeTag = "", type = "escape"},
			{pattern = '&apos;', closeTag = "", type = "escape"},
			{pattern = '&amp;', closeTag = "", type = "escape"}
		}

		local foundTag = false
		local tagStart, tagEnd, foundPattern, closeTag, tagType

		for _, tagInfo in ipairs(tagPatterns) do
			local start, ending = string.find(text, tagInfo.pattern, currentPosition)
			if start and (not tagStart or start < tagStart) then
				tagStart = start
				tagEnd = ending
				foundPattern = tagInfo.pattern
				closeTag = tagInfo.closeTag
				tagType = tagInfo.type
				foundTag = true
			end
		end

		if not foundTag then
			if currentPosition <= #text then
				table.insert(segments, {
					type = "text",
					content = string.sub(text, currentPosition)
				})
			end
			break
		end

		if currentPosition < tagStart then
			table.insert(segments, {
				type = "text",
				content = string.sub(text, currentPosition, tagStart - 1)
			})
		end

		if tagType == "lineBreak" or tagType == "escape" then
			table.insert(segments, {
				type = tagType,
				content = string.sub(text, tagStart, tagEnd)
			})
			currentPosition = tagEnd + 1
		else
			local openTag = string.sub(text, tagStart, tagEnd)
			local closeTagStart = string.find(text, closeTag, tagEnd + 1)

			if closeTagStart then
				local tagContent = string.sub(text, tagEnd + 1, closeTagStart - 1)

				table.insert(segments, {
					type = "rich_text",
					openTag = openTag,
					content = tagContent,
					closeTag = closeTag
				})

				currentPosition = closeTagStart + #closeTag
			else
				table.insert(segments, {
					type = "text",
					content = string.sub(text, tagStart)
				})
				break
			end
		end
	end

	return segments
end

function typewriterEffect(textLabel, fullText, config)
	if typewriterThread then
		task.cancel(typewriterThread)
	end

	isTyping = true

	local continueButtonConfig = config:FindFirstChild("ContinueButton")
	local visibleDuringTypewriter = continueButtonConfig and continueButtonConfig:GetAttribute("VisibleDuringTypewriter")
	local functionalDuringTypewriter = continueButtonConfig and continueButtonConfig:GetAttribute("FunctionalDuringTypewriter")

	local continueButton = skins[currentSkin].Continue.ContinueButton

	if visibleDuringTypewriter then
		continueButton.Active = functionalDuringTypewriter
		showContinueButton()
	else
		hideContinueButton()
	end

	local typewriterConfig = config:FindFirstChild("Typewriter")
	local speed = typewriterConfig and typewriterConfig:GetAttribute("Speed") or 0.03
	local speedSpecial = typewriterConfig and typewriterConfig:GetAttribute("SpeedSpecial") or 0.1
	local soundId = typewriterConfig and typewriterConfig:GetAttribute("Sound")
	local soundPitch = typewriterConfig and typewriterConfig:GetAttribute("SoundPitch") or 1

	local dialogueSound = game:GetService("SoundService"):FindFirstChild("DialogueKit")
	local typewriterSound = dialogueSound and dialogueSound:FindFirstChild("TypewriterSound")

	textLabel.Text = ""

	local segments = parseRichText(fullText)

	typewriterThread = task.spawn(function()
		local displayedText = ""

		for segmentIndex, segment in ipairs(segments) do
			if segment.type == "text" then
				for i = 1, #segment.content do
					if not isTyping then break end

					local char = string.sub(segment.content, i, i)
					displayedText = displayedText .. char
					textLabel.Text = displayedText

					if typewriterSound and soundId and soundId ~= 0 then
						typewriterSound.SoundId = "rbxassetid://" .. soundId
						typewriterSound.PlaybackSpeed = soundPitch
						typewriterSound:Play()
					end

					local isLastCharInSegment = (i == #segment.content)
					local isLastSegment = (segmentIndex == #segments)
					local isLastChar = isLastCharInSegment and isLastSegment

					if string.match(char, "[%.,%?!\":]") and not isLastChar then
						task.wait(speedSpecial)
					else
						task.wait(speed)
					end
				end
			elseif segment.type == "rich_text" then
				local partialText = ""

				displayedText = displayedText .. segment.openTag

				for i = 1, #segment.content do
					if not isTyping then break end

					local char = string.sub(segment.content, i, i)
					partialText = partialText .. char

					textLabel.Text = displayedText .. partialText .. segment.closeTag

					if typewriterSound and soundId and soundId ~= 0 then
						typewriterSound.SoundId = "rbxassetid://" .. soundId
						typewriterSound.PlaybackSpeed = soundPitch
						typewriterSound:Play()
					end

					local isLastCharInSegment = (i == #segment.content)
					local isLastSegment = (segmentIndex == #segments)
					local isLastChar = isLastCharInSegment and isLastSegment

					if string.match(char, "[%.,%?!\":]") and not isLastChar then
						task.wait(speedSpecial)
					else
						task.wait(speed)
					end
				end

				displayedText = displayedText .. partialText .. segment.closeTag
			elseif segment.type == "lineBreak" then
				displayedText = displayedText .. segment.content
				textLabel.Text = displayedText
			elseif segment.type == "escape" then
				displayedText = displayedText .. segment.content
				textLabel.Text = displayedText
			end

			if not isTyping then
				break
			end
		end

		if isTyping then
			local layerData = currentDialogue.Layers[currentLayer]
			local isLastContent = currentContentIndex == #layerData.Dialogue
			local hasReplies = layerData.Replies and next(layerData.Replies) ~= nil

			local afterExecs = findExecForContent(currentContentIndex, "After")
			if afterExecs then
				for _, execData in ipairs(afterExecs) do
					executeLayerFunction(execData)
				end
			end

			if isLastContent and hasReplies then
				showReplies()
			else
				showContinueButton()
				continueButton.Active = true
			end

			isTyping = false
		end
	end)
end

function clearReplyConnections()
	for _, connection in ipairs(replyConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	replyConnections = {}
end

function showReplies()
	if isShowingReplies or not currentDialogue or not currentLayer or not currentSkin then
		return
	end

	isShowingReplies = true

	local layerData = currentDialogue.Layers[currentLayer]
	if not layerData or not layerData.Replies or next(layerData.Replies) == nil then
		return
	end

	local skin = skins[currentSkin]
	local repliesContainer = skin.Replies
	local config = currentDialogue.Config

	local continueButtonConfig = config and config:FindFirstChild("ContinueButton")
	local visibleDuringReply = continueButtonConfig and continueButtonConfig:GetAttribute("VisibleDuringReply")

	if not visibleDuringReply then
		local continueButton = skin.Continue.ContinueButton
		local tweenInfo = TweenInfo.new(skin:GetAttribute("TweenTime"), Enum.EasingStyle[skin:GetAttribute("EasingStyle")], Enum.EasingDirection[skin:GetAttribute("EasingDirection")])

		continueButton.Active = false
		game:GetService("TweenService"):Create(continueButton, tweenInfo, {TextTransparency = 1, BackgroundTransparency = 1}):Play()

		for _, descendant in pairs(continueButton:GetDescendants()) do
			if descendant:IsA("UIStroke") then
				game:GetService("TweenService"):Create(descendant, tweenInfo, {Transparency = 1}):Play()
			end
		end
	end

	local replyPosition = skin:GetAttribute("ReplyPosition")
	local easingStyle = skin:GetAttribute("EasingStyle")
	local easingDirection = skin:GetAttribute("EasingDirection")
	local tweenTime = skin:GetAttribute("TweenTime")

	tweenPosition(skin, replyPosition, easingStyle, easingDirection, tweenTime)

	local layoutObjects = {}
	for _, child in ipairs(repliesContainer:GetChildren()) do
		if child:IsA("UIGridLayout") or child:IsA("UIGradient") or child:IsA("UIPadding") or
			not (child:IsA("Frame") or child:IsA("CanvasGroup")) then
			layoutObjects[child.Name] = child
		else
			child:Destroy()
		end
	end

	local replyCount = 0
	local defaultReply = skin.DefaultReply
	local defaultReplyStroke = defaultReply:FindFirstChildOfClass("UIStroke")

	local orderedReplyNames = {"reply1", "reply2", "reply3", "reply4"}

	for _, replyName in ipairs(orderedReplyNames) do
		local replyData = layerData.Replies[replyName]
		if replyData then
			replyCount = replyCount + 1
			if replyCount > 4 then
				break
			end

			local replyClone = defaultReply:Clone()
			replyClone.Name = replyName
			replyClone.Parent = repliesContainer

			local replyButton = replyClone.ReplyButton
			replyButton.Text = replyData.ReplyText

			replyClone.BackgroundTransparency = 1
			replyButton.BackgroundTransparency = 1
			replyButton.TextTransparency = 1

			local replyStroke = replyClone:FindFirstChildOfClass("UIStroke")
			if replyStroke then
				replyStroke.Transparency = 1
			end

			local buttonStroke = replyButton:FindFirstChildOfClass("UIStroke")
			if buttonStroke then
				buttonStroke.Transparency = 1
			end

			for _, descendant in pairs(replyClone:GetDescendants()) do
				if descendant:IsA("UIStroke") then
					descendant.Transparency = 1
				end
			end

			replyClone.Visible = true

			local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle[easingStyle], Enum.EasingDirection[easingDirection])

			local originalCloneBackgroundTransparency = defaultTransparencyValues[currentSkin][defaultReply] 
				and defaultTransparencyValues[currentSkin][defaultReply].BackgroundTransparency or 0

			local originalButtonBackgroundTransparency = defaultTransparencyValues[currentSkin][defaultReply.ReplyButton] 
				and defaultTransparencyValues[currentSkin][defaultReply.ReplyButton].BackgroundTransparency or 0

			local originalButtonTextTransparency = defaultTransparencyValues[currentSkin][defaultReply.ReplyButton] 
				and defaultTransparencyValues[currentSkin][defaultReply.ReplyButton].TextTransparency or 0

			local originalStrokeTransparency = 0
			if defaultReplyStroke then
				originalStrokeTransparency = defaultTransparencyValues[currentSkin][defaultReplyStroke] 
					and defaultTransparencyValues[currentSkin][defaultReplyStroke].Transparency or 0
			end

			local cloneTween = game:GetService("TweenService"):Create(replyClone, tweenInfo, {BackgroundTransparency = originalCloneBackgroundTransparency})
			local buttonTween = game:GetService("TweenService"):Create(replyButton, tweenInfo, {BackgroundTransparency = originalButtonBackgroundTransparency, TextTransparency = originalButtonTextTransparency})

			if replyStroke then
				game:GetService("TweenService"):Create(replyStroke, tweenInfo, {Transparency = originalStrokeTransparency}):Play()
			end

			if buttonStroke then
				game:GetService("TweenService"):Create(buttonStroke, tweenInfo, {Transparency = originalStrokeTransparency}):Play()
			end

			for _, descendant in pairs(replyClone:GetDescendants()) do
				if descendant:IsA("UIStroke") and descendant ~= replyStroke and descendant ~= buttonStroke then
					local originalTransparency = 0
					if defaultTransparencyValues[currentSkin][descendant] then
						originalTransparency = defaultTransparencyValues[currentSkin][descendant].Transparency or 0
					end

					game:GetService("TweenService"):Create(descendant, tweenInfo, {Transparency = originalTransparency}):Play()
				end
			end

			cloneTween:Play()
			buttonTween:Play()

			local connection = replyButton.Activated:Connect(function()
				onReplyButtonClicked(replyName, replyData)
			end)

			table.insert(replyConnections, connection)
		end
	end

	for replyName, replyData in pairs(layerData.Replies) do
		local isOrderedReply = false
		for _, orderedName in ipairs(orderedReplyNames) do
			if replyName == orderedName then
				isOrderedReply = true
				break
			end
		end

		if not isOrderedReply then
			replyCount = replyCount + 1
			if replyCount > 4 then
				break
			end

			local replyClone = defaultReply:Clone()
			replyClone.Name = replyName
			replyClone.Parent = repliesContainer

			local replyButton = replyClone.ReplyButton
			replyButton.Text = replyData.ReplyText

			replyClone.BackgroundTransparency = 1
			replyButton.BackgroundTransparency = 1
			replyButton.TextTransparency = 1

			local replyStroke = replyClone:FindFirstChildOfClass("UIStroke")
			if replyStroke then
				replyStroke.Transparency = 1
			end

			local buttonStroke = replyButton:FindFirstChildOfClass("UIStroke")
			if buttonStroke then
				buttonStroke.Transparency = 1
			end

			for _, descendant in pairs(replyClone:GetDescendants()) do
				if descendant:IsA("UIStroke") then
					descendant.Transparency = 1
				end
			end

			replyClone.Visible = true

			local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle[easingStyle], Enum.EasingDirection[easingDirection])

			local originalCloneBackgroundTransparency = defaultTransparencyValues[currentSkin][defaultReply] 
				and defaultTransparencyValues[currentSkin][defaultReply].BackgroundTransparency or 0

			local originalButtonBackgroundTransparency = defaultTransparencyValues[currentSkin][defaultReply.ReplyButton] 
				and defaultTransparencyValues[currentSkin][defaultReply.ReplyButton].BackgroundTransparency or 0

			local originalButtonTextTransparency = defaultTransparencyValues[currentSkin][defaultReply.ReplyButton] 
				and defaultTransparencyValues[currentSkin][defaultReply.ReplyButton].TextTransparency or 0

			local originalStrokeTransparency = 0
			if defaultReplyStroke then
				originalStrokeTransparency = defaultTransparencyValues[currentSkin][defaultReplyStroke] 
					and defaultTransparencyValues[currentSkin][defaultReplyStroke].Transparency or 0
			end

			local cloneTween = game:GetService("TweenService"):Create(replyClone, tweenInfo, {BackgroundTransparency = originalCloneBackgroundTransparency})
			local buttonTween = game:GetService("TweenService"):Create(replyButton, tweenInfo, {BackgroundTransparency = originalButtonBackgroundTransparency, TextTransparency = originalButtonTextTransparency})

			if replyStroke then
				game:GetService("TweenService"):Create(replyStroke, tweenInfo, {Transparency = originalStrokeTransparency}):Play()
			end

			if buttonStroke then
				game:GetService("TweenService"):Create(buttonStroke, tweenInfo, {Transparency = originalStrokeTransparency}):Play()
			end

			for _, descendant in pairs(replyClone:GetDescendants()) do
				if descendant:IsA("UIStroke") and descendant ~= replyStroke and descendant ~= buttonStroke then
					local originalTransparency = 0
					if defaultTransparencyValues[currentSkin][descendant] then
						originalTransparency = defaultTransparencyValues[currentSkin][descendant].Transparency or 0
					end

					game:GetService("TweenService"):Create(descendant, tweenInfo, {Transparency = originalTransparency}):Play()
				end
			end

			cloneTween:Play()
			buttonTween:Play()

			local connection = replyButton.Activated:Connect(function()
				onReplyButtonClicked(replyName, replyData)
			end)

			table.insert(replyConnections, connection)
		end
	end

	for _, layoutObject in pairs(layoutObjects) do
		layoutObject.Parent = repliesContainer
	end
end

function skipTypewriter()
	if isTyping and typewriterThread then
		isTyping = false
		task.cancel(typewriterThread)

		local dialogueSound = game:GetService("SoundService"):FindFirstChild("DialogueKit")
		if dialogueSound and dialogueSound:FindFirstChild("TypewriterSound") then
			dialogueSound.TypewriterSound:Stop()
		end

		if currentDialogue and currentLayer and currentContentIndex then
			local contentText = currentDialogue.Layers[currentLayer].Dialogue[currentContentIndex]
			local contentLabel = skins[currentSkin].Content.ContentText
			contentLabel.Text = contentText

			local layerData = currentDialogue.Layers[currentLayer]
			local isLastContent = currentContentIndex == #layerData.Dialogue
			local hasReplies = layerData.Replies and next(layerData.Replies) ~= nil

			if isLastContent and hasReplies then
				showReplies()
			else
				local continueButton = skins[currentSkin].Continue.ContinueButton
				continueButton.Active = true
				showContinueButton()
			end
		end
	end
end

function onReplyButtonClicked(replyName, replyData)
	if not currentDialogue or not currentLayer or not currentSkin then
		return
	end

	local replyExecs = findExecForReply(replyName)
	if replyExecs then
		for _, execData in ipairs(replyExecs) do
			executeLayerFunction(execData)
		end
	end

	local repliesContainer = skins[currentSkin].Replies
	for _, child in ipairs(repliesContainer:GetChildren()) do
		if child:IsA("Frame") and child:FindFirstChild("ReplyButton") then
			child.ReplyButton.Active = false
		end
	end

	local skin = skins[currentSkin]
	local easingStyle = skin:GetAttribute("EasingStyle")
	local easingDirection = skin:GetAttribute("EasingDirection")
	local tweenTime = skin:GetAttribute("TweenTime")

	local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle[easingStyle], Enum.EasingDirection[easingDirection])
	local tweensDone = 0
	local totalTweens = 0

	local isGoodbye = replyName == "_goodbye" or replyData.ReplyLayer == nil
	local targetLayer = not isGoodbye and replyData.ReplyLayer
	local isInvalidLayer = targetLayer and not currentDialogue.Layers[targetLayer]

	for _, child in ipairs(repliesContainer:GetChildren()) do
		if child:IsA("Frame") and child:FindFirstChild("ReplyButton") then
			totalTweens = totalTweens + 1

			local frameTween = game:GetService("TweenService"):Create(child, tweenInfo, {BackgroundTransparency = 1})
			local buttonTween = game:GetService("TweenService"):Create(child.ReplyButton, tweenInfo, {BackgroundTransparency = 1, TextTransparency = 1})

			local stroke = child:FindFirstChildOfClass("UIStroke")
			if stroke then
				totalTweens = totalTweens + 1
				local strokeTween = game:GetService("TweenService"):Create(stroke, tweenInfo, {Transparency = 1})
				strokeTween.Completed:Connect(function()
					tweensDone = tweensDone + 1
					if tweensDone >= totalTweens then
						onRepliesTweenComplete(isGoodbye, targetLayer, isInvalidLayer)
					end
				end)
				strokeTween:Play()
			end

			local buttonStroke = child.ReplyButton:FindFirstChildOfClass("UIStroke")
			if buttonStroke then
				totalTweens = totalTweens + 1
				local buttonStrokeTween = game:GetService("TweenService"):Create(buttonStroke, tweenInfo, {Transparency = 1})
				buttonStrokeTween.Completed:Connect(function()
					tweensDone = tweensDone + 1
					if tweensDone >= totalTweens then
						onRepliesTweenComplete(isGoodbye, targetLayer, isInvalidLayer)
					end
				end)
				buttonStrokeTween:Play()
			end

			for _, descendant in pairs(child:GetDescendants()) do
				if descendant:IsA("UIStroke") and descendant ~= stroke and descendant ~= buttonStroke then
					totalTweens = totalTweens + 1
					local descendantStrokeTween = game:GetService("TweenService"):Create(descendant, tweenInfo, {Transparency = 1})
					descendantStrokeTween.Completed:Connect(function()
						tweensDone = tweensDone + 1
						if tweensDone >= totalTweens then
							onRepliesTweenComplete(isGoodbye, targetLayer, isInvalidLayer)
						end
					end)
					descendantStrokeTween:Play()
				end
			end

			frameTween.Completed:Connect(function()
				tweensDone = tweensDone + 1
				if tweensDone >= totalTweens then
					onRepliesTweenComplete(isGoodbye, targetLayer, isInvalidLayer)
				end
			end)

			buttonTween.Completed:Connect(function()
				tweensDone = tweensDone + 1
				if tweensDone >= totalTweens then
					onRepliesTweenComplete(isGoodbye, targetLayer, isInvalidLayer)
				end
			end)

			frameTween:Play()
			buttonTween:Play()
		end
	end

	clearReplyConnections()

	if totalTweens == 0 then
		onRepliesTweenComplete(isGoodbye, targetLayer, isInvalidLayer)
	end
end

function onRepliesTweenComplete(isGoodbye, targetLayer, isInvalidLayer)
	local skin = skins[currentSkin]
	local repliesContainer = skin.Replies

	for _, child in ipairs(repliesContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("CanvasGroup") then
			child:Destroy()
		end
	end

	if isGoodbye then
		isShowingReplies = false
		closeDialogue()
		return
	end

	if isInvalidLayer then
		-- warn("Invalid reply target layer: " .. tostring(targetLayer))
		isShowingReplies = false
		closeDialogue()
		return
	end

	local openPosition = skin:GetAttribute("OpenPosition")
	local easingStyle = skin:GetAttribute("EasingStyle")
	local easingDirection = skin:GetAttribute("EasingDirection")
	local tweenTime = skin:GetAttribute("TweenTime")

	tweenPosition(skin, openPosition, easingStyle, easingDirection, tweenTime)

	task.delay(tweenTime, function()
		currentLayer = targetLayer
		currentContentIndex = 1
		isShowingReplies = false

		displayContent()
	end)
end

function displayContent()
	if not currentDialogue or not currentLayer or not currentContentIndex or not currentSkin then
		return
	end

	local layerData = currentDialogue.Layers[currentLayer]

	if not layerData or not layerData.Dialogue or currentContentIndex > #layerData.Dialogue then
		-- warn("Invalid content index or dialogue data")
		closeDialogue()
		return
	end

	local contentText = layerData.Dialogue[currentContentIndex]
	local dialogueSound = layerData.DialogueSounds and layerData.DialogueSounds[currentContentIndex]

	local contentLabel = skins[currentSkin].Content.ContentText

	local config = currentDialogue.Config

	local richTextEnabled = true
	local richTextValue = config and config:FindFirstChild("RichText")
	if richTextValue ~= nil and richTextValue:IsA("BoolValue") then
		richTextEnabled = richTextValue.Value
	end

	contentLabel.RichText = richTextEnabled

	local typewriterEnabled = config and config:FindFirstChild("Typewriter") and config.Typewriter.Value

	if dialogueSound then
		-- print("🔊 [DialogueKit] Attempting to play sound for content index:", currentContentIndex)
		-- print("🔊 [DialogueKit] Sound ID from data:", dialogueSound)

		if activeDialogueSound then
			activeDialogueSound:Stop()
			activeDialogueSound:Destroy()
			activeDialogueSound = nil
		end

		local soundService = game:GetService("SoundService")
		local dialogueSoundService = soundService:FindFirstChild("DialogueKit")
		
		-- On-demand creation if missing
		if not dialogueSoundService then
			dialogueSoundService = Instance.new("Folder")
			dialogueSoundService.Name = "DialogueKit"
			dialogueSoundService.Parent = soundService
		end

		if dialogueSoundService then
			local templateSound = dialogueSoundService:FindFirstChild("DialogueSound")
			if not templateSound then
				templateSound = Instance.new("Sound")
				templateSound.Name = "DialogueSound"
				templateSound.SoundId = "rbxassetid://12221967" -- Valid obscure sound to prevent errors
				templateSound.Volume = 0.5
				templateSound.Parent = dialogueSoundService
			end
			
			if templateSound then
				activeDialogueSound = templateSound:Clone()
				
				if tostring(dialogueSound):match("^rbxassetid://") then
					activeDialogueSound.SoundId = dialogueSound
				else
					activeDialogueSound.SoundId = "rbxassetid://" .. dialogueSound
				end
				
				local skin = skins[currentSkin]
				if skin then
					activeDialogueSound.Parent = skin
				else
					activeDialogueSound.Parent = script.Parent -- Fallback
				end
				
				activeDialogueSound:Play()
				
				activeDialogueSound.Ended:Connect(function()
					if activeDialogueSound then
						activeDialogueSound:Destroy()
						activeDialogueSound = nil
					end
				end)
			end
		end
	end

	local beforeExecs = findExecForContent(currentContentIndex, "Before")
	if beforeExecs then
		for _, execData in ipairs(beforeExecs) do
			executeLayerFunction(execData)
		end
	end

	local isLastContent = currentContentIndex == #layerData.Dialogue
	local hasReplies = layerData.Replies and next(layerData.Replies) ~= nil

	if typewriterEnabled then
		typewriterEffect(contentLabel, contentText, config)
	else
		contentLabel.Text = contentText

		local afterExecs = findExecForContent(currentContentIndex, "After")
		if afterExecs then
			for _, execData in ipairs(afterExecs) do
				executeLayerFunction(execData)
			end
		end

		if isLastContent and hasReplies then
			showReplies()
		else
			local continueButton = skins[currentSkin].Continue.ContinueButton
			continueButton.Active = true
			showContinueButton()
		end
	end
end

function applyPlayerSettings(config)
	if not config then return end

	local player = game.Players.LocalPlayer
	if not player then return end

	local walkSpeedConfig = config:FindFirstChild("DialogueWalkSpeed")
	if walkSpeedConfig and walkSpeedConfig:IsA("NumberValue") then
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		if humanoid then
			originalWalkSpeed = humanoid.WalkSpeed

			if walkSpeedConfig.Value ~= -1 then
				humanoid.WalkSpeed = walkSpeedConfig.Value
			end
		end
	end

	local coreGuiConfig = config:FindFirstChild("CoreGui")
	if coreGuiConfig and coreGuiConfig:IsA("BoolValue") and coreGuiConfig.Value then
		local StarterGui = game:GetService("StarterGui")

		local backpackEnabled = coreGuiConfig:GetAttribute("BackpackEnabled")
		if backpackEnabled ~= nil then
			originalCoreGuiState.Backpack = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, backpackEnabled)
		end

		local chatEnabled = coreGuiConfig:GetAttribute("ChatEnabled")
		if chatEnabled ~= nil then
			originalCoreGuiState.Chat = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, chatEnabled)
		end

		local leaderboardEnabled = coreGuiConfig:GetAttribute("LeaderboardEnabled")
		if leaderboardEnabled ~= nil then
			originalCoreGuiState.PlayerList = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, leaderboardEnabled)
		end
	end

	local dialogueCameraConfig = config:FindFirstChild("DialogueCamera")
	if dialogueCameraConfig and dialogueCameraConfig:IsA("ObjectValue") and dialogueCameraConfig.Value then
		local camera = workspace.CurrentCamera
		originalCameraType = camera.CameraType
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = dialogueCameraConfig.Value.CFrame
	end

	local backgroundSoundConfig = config:FindFirstChild("BackgroundSound")
	if backgroundSoundConfig and backgroundSoundConfig:IsA("NumberValue") then
		local dialogueSound = game:GetService("SoundService"):FindFirstChild("DialogueKit")
		if dialogueSound and dialogueSound:FindFirstChild("BackgroundSound") then
			backgroundSoundInstance = dialogueSound.BackgroundSound
			backgroundSoundInstance.SoundId = "rbxassetid://" .. backgroundSoundConfig.Value

			local pitch = backgroundSoundConfig:GetAttribute("BackgroundSoundPitch")
			if pitch then
				backgroundSoundInstance.PlaybackSpeed = pitch
			end

			local originalVolume = backgroundSoundInstance.Volume

			backgroundSoundInstance.Volume = 0
			backgroundSoundInstance:Play()

			local volume = backgroundSoundConfig:GetAttribute("BackgroundSoundVolume") or 1
			local skin = skins[currentSkin]
			local tweenInfo = TweenInfo.new(skin:GetAttribute("TweenTime"), Enum.EasingStyle[skin:GetAttribute("EasingStyle")], Enum.EasingDirection[skin:GetAttribute("EasingDirection")])

			game:GetService("TweenService"):Create(backgroundSoundInstance, tweenInfo, {Volume = volume}):Play()
		end
	end
end

function restorePlayerSettings(config)
	if not config then return end

	local player = game.Players.LocalPlayer
	if not player then return end

	if originalWalkSpeed then
		local walkSpeedConfig = config:FindFirstChild("DialogueWalkSpeed")
		local defaultWalkSpeed = walkSpeedConfig and walkSpeedConfig:GetAttribute("DefaultWalkSpeed") or originalWalkSpeed

		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = defaultWalkSpeed
		end

		originalWalkSpeed = nil
	end

	local coreGuiConfig = config:FindFirstChild("CoreGui")
	if coreGuiConfig and coreGuiConfig:IsA("BoolValue") and coreGuiConfig.Value then
		local StarterGui = game:GetService("StarterGui")

		if originalCoreGuiState.Backpack ~= nil then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, originalCoreGuiState.Backpack)
		end

		if originalCoreGuiState.Chat ~= nil then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, originalCoreGuiState.Chat)
		end

		if originalCoreGuiState.PlayerList ~= nil then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, originalCoreGuiState.PlayerList)
		end

		originalCoreGuiState = {
			Backpack = nil,
			Chat = nil,
			PlayerList = nil
		}
	end

	if originalCameraType then
		local camera = workspace.CurrentCamera
		camera.CameraType = originalCameraType
		originalCameraType = nil
	end

	if backgroundSoundInstance then
		local skin = skins[currentSkin]
		local tweenInfo = TweenInfo.new(skin:GetAttribute("TweenTime"), Enum.EasingStyle[skin:GetAttribute("EasingStyle")], Enum.EasingDirection[skin:GetAttribute("EasingDirection")])

		local volumeTween = game:GetService("TweenService"):Create(backgroundSoundInstance, tweenInfo, {Volume = 0})
		volumeTween.Completed:Connect(function()
			backgroundSoundInstance:Stop()
			backgroundSoundInstance = nil
		end)
		volumeTween:Play()
	end

	if healthChangedConnection then
		healthChangedConnection:Disconnect()
		healthChangedConnection = nil
	end
end

function setupPlayerDeathHandling(config)
	if not config then return end

	local playerDeadConfig = config:FindFirstChild("PlayerDead")
	if not playerDeadConfig or not playerDeadConfig:IsA("StringValue") then return end

	local stopDialogueOnDeath = playerDeadConfig:GetAttribute("StopDialogueOnDeath")
	if stopDialogueOnDeath then
		local player = game.Players.LocalPlayer
		if not player then return end

		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		if humanoid then
			if healthChangedConnection then
				healthChangedConnection:Disconnect()
			end

			healthChangedConnection = humanoid.HealthChanged:Connect(function(health)
				if health <= 0 and currentDialogue then
					closeDialogue()
				end
			end)
		end
	end
end

function closeDialogue()
	if not currentSkin then
		return
	end

	if DialogueVisibilityManager then
		DialogueVisibilityManager:onDialogueEnd()
	end

	if typewriterThread then
		isTyping = false
		task.cancel(typewriterThread)
	end

	if activeDialogueSound then
		activeDialogueSound:Stop()
		activeDialogueSound:Destroy()
		activeDialogueSound = nil
	end

	local dialogueSound = game:GetService("SoundService"):FindFirstChild("DialogueKit")
	if dialogueSound and dialogueSound:FindFirstChild("TypewriterSound") then
		dialogueSound.TypewriterSound:Stop()
	end

	clearReplyConnections()
	isShowingReplies = false

	if continueConnection then
		continueConnection:Disconnect()
		continueConnection = nil
	end

	teardownInputHandling()
	local continueButton = skins[currentSkin].Continue.ContinueButton
	continueButton.Active = false
	hideContinueButton()

	local repliesContainer = skins[currentSkin].Replies
	for _, child in ipairs(repliesContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("CanvasGroup") then
			child:Destroy()
		end
	end

	local skin = skins[currentSkin]
	local closedPosition = skin:GetAttribute("ClosedPosition")
	local easingStyle = skin:GetAttribute("EasingStyle")
	local easingDirection = skin:GetAttribute("EasingDirection")
	local tweenTime = skin:GetAttribute("TweenTime")

	local tweenDuration = tweenTransparencyOut(currentSkin)

	tweenPosition(skin, closedPosition, easingStyle, easingDirection, tweenTime)

	local gradient = skin:FindFirstChild("Gradient")
	if gradient then
		local gradientClosedPosition = gradient:GetAttribute("ClosedPosition")
		if gradientClosedPosition then
			local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle[easingStyle], Enum.EasingDirection[easingDirection])
			game:GetService("TweenService"):Create(gradient, tweenInfo, {Position = gradientClosedPosition}):Play()
		end
	end

	if #cinematicBars == 2 then
		local topBar = cinematicBars[1]
		local bottomBar = cinematicBars[2]

		local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle[easingStyle], Enum.EasingDirection[easingDirection])

		game:GetService("TweenService"):Create(topBar, tweenInfo, {Position = UDim2.new(0.5, 0, -0.2, 0)}):Play()
		game:GetService("TweenService"):Create(bottomBar, tweenInfo, {Position = UDim2.new(0.5, 0, 1.2, 0)}):Play()

		task.delay(tweenTime, function()
			topBar:Destroy()
			bottomBar:Destroy()
			cinematicBars = {}
		end)
	end

	if currentDialogue and currentDialogue.Config then
		restorePlayerSettings(currentDialogue.Config)
	end

	task.delay(tweenDuration, function()
		currentDialogue = nil
		currentLayer = nil
		currentContentIndex = nil
		currentSkin = nil
		skin.Visible = false
	end)
end

function showContinueButton()
	local continueButton = skins[currentSkin].Continue.ContinueButton
	local skin = skins[currentSkin]
	local tweenInfo = TweenInfo.new(skin:GetAttribute("TweenTime"), Enum.EasingStyle[skin:GetAttribute("EasingStyle")], Enum.EasingDirection[skin:GetAttribute("EasingDirection")])

	local originalTextTransparency = defaultTransparencyValues[currentSkin][continueButton].TextTransparency or 0
	local originalBackgroundTransparency = defaultTransparencyValues[currentSkin][continueButton].BackgroundTransparency or 0

	continueButton.Active = true

	game:GetService("TweenService"):Create(continueButton, tweenInfo, {TextTransparency = originalTextTransparency, BackgroundTransparency = originalBackgroundTransparency}):Play()

	local continuePosition = skin:GetAttribute("ContinuePosition")
	if continuePosition then
		local easingStyle = skin:GetAttribute("EasingStyle")
		local easingDirection = skin:GetAttribute("EasingDirection")
		local tweenTime = skin:GetAttribute("TweenTime")

		tweenPosition(skin, continuePosition, easingStyle, easingDirection, tweenTime)
	end
end

function hideContinueButton()
	local continueButton = skins[currentSkin].Continue.ContinueButton
	local skin = skins[currentSkin]
	local tweenInfo = TweenInfo.new(skin:GetAttribute("TweenTime"), Enum.EasingStyle[skin:GetAttribute("EasingStyle")], Enum.EasingDirection[skin:GetAttribute("EasingDirection")])

	continueButton.Active = false

	local transparencyWhenUnclickable = 1
	if currentDialogue and currentDialogue.Config then
		local continueButtonConfig = currentDialogue.Config:FindFirstChild("ContinueButton")
		if continueButtonConfig then
			local configValue = continueButtonConfig:GetAttribute("TransparencyWhenUnclickable")
			if configValue ~= nil then
				transparencyWhenUnclickable = configValue
			end
		end
	end

	game:GetService("TweenService"):Create(continueButton, tweenInfo, {TextTransparency = transparencyWhenUnclickable, BackgroundTransparency = 1}):Play()

	if skin:GetAttribute("ContinuePosition") then
		local openPosition = skin:GetAttribute("OpenPosition")
		local easingStyle = skin:GetAttribute("EasingStyle")
		local easingDirection = skin:GetAttribute("EasingDirection")
		local tweenTime = skin:GetAttribute("TweenTime")

		if not isShowingReplies then
			tweenPosition(skin, openPosition, easingStyle, easingDirection, tweenTime)
		end
	end

	return tweenInfo.Time
end

function onContinueButtonClicked()
	if not currentDialogue or not currentLayer or not currentContentIndex or not currentSkin then
		return
	end

	if isTyping then
		local config = currentDialogue.Config
		local continueButtonConfig = config and config:FindFirstChild("ContinueButton")
		local functionalDuringTypewriter = continueButtonConfig and continueButtonConfig:GetAttribute("FunctionalDuringTypewriter")

		if functionalDuringTypewriter then
			skipTypewriter()
		end
		return
	end

	local continueExecs = findExecForContinue(currentContentIndex)
	if continueExecs then
		for _, execData in ipairs(continueExecs) do
			executeLayerFunction(execData)
		end
	end

	local layerData = currentDialogue.Layers[currentLayer]

	if not layerData or not layerData.Dialogue then
		-- warn("Invalid layer data")
		closeDialogue()
		return
	end

	local dialogueCount = #layerData.Dialogue

	if currentContentIndex >= dialogueCount then
		if layerData.Replies and next(layerData.Replies) ~= nil then
			showReplies()
		else
			closeDialogue()
		end
		return
	end

	currentContentIndex = currentContentIndex + 1
	displayContent()
end

function createCinematicBars(config)
	local cinematicBarsValue = config and config:FindFirstChild("CinematicBars")
	if not cinematicBarsValue or not cinematicBarsValue:IsA("BoolValue") or not cinematicBarsValue.Value then
		return false
	end

	local topBar = Instance.new("Frame")
	topBar.Name = "CinematicBarTop"
	topBar.Size = UDim2.new(1, 0, 0.2, 0)
	topBar.Position = UDim2.new(0.5, 0, -0.2, 0)
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	topBar.BorderSizePixel = 0
	topBar.Parent = script.Parent

	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "CinematicBarBottom"
	bottomBar.Size = UDim2.new(1, 0, 0.2, 0)
	bottomBar.Position = UDim2.new(0.5, 0, 1.2, 0)
	bottomBar.AnchorPoint = Vector2.new(0.5, 1)
	bottomBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bottomBar.BorderSizePixel = 0
	bottomBar.Parent = script.Parent

	cinematicBars = {topBar, bottomBar}

	local skin = skins[currentSkin]
	local hasGradient = skin:FindFirstChild("Gradient") ~= nil

	if hasGradient then
		topBar.BorderSizePixel = 6
		bottomBar.BorderSizePixel = 6
		topBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
		bottomBar.BorderColor3 = Color3.fromRGB(0, 0, 0)

		topBar.ZIndex = -1
		bottomBar.ZIndex = -1

		topBar.Parent = script.Parent.Skins.Hotline
		bottomBar.Parent = script.Parent.Skins.Hotline

		local topStroke = Instance.new("UIStroke")
		topStroke.Color = Color3.fromRGB(255, 255, 255)
		topStroke.Thickness = 3
		topStroke.Parent = topBar

		local bottomStroke = Instance.new("UIStroke")
		bottomStroke.Color = Color3.fromRGB(255, 255, 255)
		bottomStroke.Thickness = 3
		bottomStroke.Parent = bottomBar
	end

	local tweenBars = cinematicBarsValue:GetAttribute("TweenBars")
	if tweenBars then
		local easingStyle = skin:GetAttribute("EasingStyle")
		local easingDirection = skin:GetAttribute("EasingDirection")
		local tweenTime = skin:GetAttribute("TweenTime")

		local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle[easingStyle], Enum.EasingDirection[easingDirection])

		game:GetService("TweenService"):Create(topBar, tweenInfo, {Position = UDim2.new(0.5, 0, 0, 0)}):Play()
		game:GetService("TweenService"):Create(bottomBar, tweenInfo, {Position = UDim2.new(0.5, 0, 1, 0)}):Play()
	else
		topBar.Position = UDim2.new(0.5, 0, 0, 0)
		bottomBar.Position = UDim2.new(0.5, 0, 1, 0)
	end

	return true
end

function module.CreateDialogue(dialogueData)
	if currentDialogue then
		return
	end

	if not dialogueData or not dialogueData.InitialLayer or not dialogueData.SkinName or not dialogueData.Layers then
		-- warn("Invalid dialogue data. Required fields: InitialLayer, SkinName, Layers")
		return
	end

	if not dialogueData.Layers[dialogueData.InitialLayer] then
		-- warn("Initial layer not found: " .. tostring(dialogueData.InitialLayer))
		return
	end

	if not skins:FindFirstChild(dialogueData.SkinName) then
		-- warn("Skin not found: " .. tostring(dialogueData.SkinName))
		return
	end

	if dialogueData.Config then
		local playerDeadConfig = dialogueData.Config:FindFirstChild("PlayerDead")
		if playerDeadConfig and playerDeadConfig:IsA("StringValue") then
			local interactWhenDead = playerDeadConfig:GetAttribute("InteractWhenDead")
			if interactWhenDead == false then
				local player = game.Players.LocalPlayer
				local humanoid = player and player.Character and player.Character:FindFirstChild("Humanoid")
				if humanoid and humanoid.Health <= 0 then
					return
				end
			end
		end
	end
	
	if DialogueVisibilityManager then
		DialogueVisibilityManager:onDialogueStart()
	end

	currentDialogue = dialogueData
	currentLayer = dialogueData.InitialLayer
	currentContentIndex = 1
	currentSkin = dialogueData.SkinName

	local skin = skins[currentSkin]

	skin.Visible = true

	currentDialogue = dialogueData
	currentLayer = dialogueData.InitialLayer
	currentContentIndex = 1
	currentSkin = dialogueData.SkinName

	local skin = skins[currentSkin]

	skin.Visible = true

	local layerData = currentDialogue.Layers[currentLayer]
	skin.Title.TitleText.Text = layerData.Title

	if layerData.DialogueImage then
		skin.Content.DialogueImage.Image = layerData.DialogueImage
	end

	local closedPosition = skin:GetAttribute("ClosedPosition")
	skin.Position = closedPosition

	local gradient = skin:FindFirstChild("Gradient")
	if gradient then
		local gradientClosedPosition = gradient:GetAttribute("ClosedPosition")
		if gradientClosedPosition then
			gradient.Position = gradientClosedPosition
		end
	end

	local continueButton = skin.Continue.ContinueButton
	continueButton.TextTransparency = 1
	continueButton.BackgroundTransparency = 1

	if continueConnection then
		continueConnection:Disconnect()
	end

	continueConnection = continueButton.Activated:Connect(function()
		if continueButton.Active then
			onContinueButtonClicked()
		end
	end)

	local contentLabel = skin.Content.ContentText
	contentLabel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and isTyping then
			skipTypewriter()
		end
	end)

	applyPlayerSettings(dialogueData.Config)

	setupPlayerDeathHandling(dialogueData.Config)

	setupInputHandling(dialogueData.Config)

	createCinematicBars(dialogueData.Config)

	local openPosition = skin:GetAttribute("OpenPosition")
	local easingStyle = skin:GetAttribute("EasingStyle")
	local easingDirection = skin:GetAttribute("EasingDirection")
	local tweenTime = skin:GetAttribute("TweenTime")

	tweenPosition(skin, openPosition, easingStyle, easingDirection, tweenTime)

	if gradient then
		local gradientOpenPosition = gradient:GetAttribute("OpenPosition")
		if gradientOpenPosition then
			local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle[easingStyle], Enum.EasingDirection[easingDirection])
			game:GetService("TweenService"):Create(gradient, tweenInfo, {Position = gradientOpenPosition}):Play()
		end
	end

	tweenTransparencyIn(currentSkin)

	displayContent()
end

initializeSkins()
-- print("Initialized Dialogue Kit V"..script.Parent.Version.Value.." by Asadrith")

if DialogueVisibilityManager then
	DialogueVisibilityManager.initialize()
end

return module