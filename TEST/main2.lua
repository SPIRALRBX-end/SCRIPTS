-- Script deve estar dentro do Frame (o frame que contém ScrollingFrame, Toggle, etc.)
local container = script.Parent
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Lista dos nomes brainrot que você quer
local brainrotNames = {
	"Noobini Pizzanini",
	"Lirilì Larilà",
	"Tim Cheese",
	"Fluriflura",
	"Talpa Di Fero",
	"Svinina Bombardino",
	"Pipi Kiwi",
	"Trippi Troppi",
	"Tung Tung Tung Sahur",
	"Gangster Footera",
	"Boneca Ambalabu",
	"Ta Ta Ta Ta Sahur",
	"Tric Trac Baraboom",
	"Cappuccino Assassino",
	"Brr Brr Patapim",
	"Trulimero Trulicina",
	"Bambini Crostini",
	"Bananita Dolphinita",
	"Perochello Lemonchello",
	"Brri Brri Bicus Dicus Bombicus",
	"Burbaloni Loliloli",
	"Chimpanzini Bananini",
	"Ballerina Cappuccina",
	"Chef Crabracadabra",
	"Glorbo Fruttodrillo",
	"Blueberrinni Octopusini",
	"Frigo Camelo",
	"Rhino Toasterino",
	"Orangutini Ananassini",
	"Bombardiro Crocodilo",
	"Bombombini Gusini",
	"Cocofanto Elefanto",
	"Girafa Celestre",
	"Gattatino Nyanino",
	"Tralalero Tralala",
	"Odin Din Din Dun",
	"Trenostruzzo Turbo 3000",
	"Matteo",
	"La Vacca Saturno Saturnita",
	"Los Tralaleritos",
	"Graipuss Medussi",
	"La Grande Combinasion"
}

-- Variáveis principais
local availableNames = {}
local selected = {}
local AUTO_ACTIVATE = false
local SCRIPT_ACTIVE = false
local MAX_DISTANCE = 15
local ACTIVATION_DELAY = 0.1
local SYSTEM_LOADED = false
local LOADING_COMPLETE = false

local trackedPrompts = {}
local lastActivation = {}
local connections = {}
local targetNames = {}
local processedPrompts = {}
local scanQueue = {}
local targetNamesCache = {}

local brainrotFolder = nil
local selectedNamesValue = nil
local lastKnownValue = ""

-- Referências aos elementos da UI
local toggleBtn = container:WaitForChild("Toggle")
local autoBuyBtn = container:WaitForChild("ToggleBT") 
local scrollingFR = container:WaitForChild("ScrollingFrame")
local listFR = container:WaitForChild("ListFR")
local inf = container:WaitForChild('TextLabel')

-- Criar indicador de carregamento
local loadingLabel = container:FindFirstChild("LoadingLabel")
if not loadingLabel then
	loadingLabel = Instance.new("TextLabel")
	loadingLabel.Name = "LoadingLabel"
	loadingLabel.Size = UDim2.new(1, 0, 0, 30)
	loadingLabel.Position = UDim2.new(0, 0, 0, 320)
	loadingLabel.BackgroundTransparency = 1
	loadingLabel.Font = Enum.Font.Arcade
	loadingLabel.TextSize = 12
	loadingLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	loadingLabel.Text = "🔄 CARREGANDO SISTEMA..."
	loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
	loadingLabel.Visible = true
	loadingLabel.Parent = container
end

-- Criar botão de confirmar se não existir
local confirmBtn = container:FindFirstChild("ConfirmBtn")
if not confirmBtn then
	confirmBtn = Instance.new("TextButton")
	confirmBtn.Name = "ConfirmBtn"
	confirmBtn.Size = UDim2.new(1, 0, 0, 30)
	confirmBtn.Position = UDim2.new(0, 0, 0, 285)
	confirmBtn.BorderSizePixel = 0
	confirmBtn.TextSize = 14
	confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.Text = "CONFIRMAR (0)"
	confirmBtn.Visible = false
	confirmBtn.Parent = container
end

-- Criar título se não existir
local titleLabel = container:FindFirstChild("TitleLabel")
if not titleLabel then
	titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 25)
	titleLabel.Position = UDim2.new(0, 0, 0, 295)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.Arcade
	titleLabel.TextSize = 12
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
	titleLabel.Text = "📋 SELECIONADOS:"
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Visible = false
	titleLabel.Parent = container
end

-- Função para mostrar loading
local function showLoading(text)
	loadingLabel.Text = text or "🔄 CARREGANDO..."
	loadingLabel.Visible = true
end

-- Função para esconder loading
local function hideLoading()
	loadingLabel.Visible = false
end

-- Função CORRIGIDA para descobrir nomes disponíveis (APENAS da lista fixa)
local function scanForAvailableNames()
	local foundNames = {}

	-- Adicionar APENAS os nomes brainrot da lista fixa
	for _, name in ipairs(brainrotNames) do
		table.insert(foundNames, name)
	end

	-- Ordenar alfabeticamente
	table.sort(foundNames)
	return foundNames
end

-- Atualizar lista de nomes disponíveis
local function updateAvailableNames()
	showLoading("🔍 CARREGANDO BRAINROTS...")
	wait(0.5) -- Simular carregamento
	availableNames = scanForAvailableNames()
	print("Carregados " .. #availableNames .. " nomes brainrot da lista fixa")
end

local function setupCommunicationSystem()
	showLoading("⚙️ CONFIGURANDO SISTEMA...")
	
	brainrotFolder = ReplicatedStorage:FindFirstChild("BrainrotSystem")
	if not brainrotFolder then
		brainrotFolder = Instance.new("Folder")
		brainrotFolder.Name = "BrainrotSystem"
		brainrotFolder.Parent = ReplicatedStorage
	end

	selectedNamesValue = brainrotFolder:FindFirstChild("SelectedNames")
	if not selectedNamesValue then
		selectedNamesValue = Instance.new("StringValue")
		selectedNamesValue.Name = "SelectedNames"
		selectedNamesValue.Value = ""
		selectedNamesValue.Parent = brainrotFolder
	end
	
	wait(0.3) -- Aguardar estabilização
end

-- Função CORRIGIDA para salvar nomes selecionados
local function saveSelectedNames()
	if not selectedNamesValue or not SYSTEM_LOADED then return end

	local selectedList = {}
	for name in pairs(selected) do
		table.insert(selectedList, name)
	end

	local joinedNames = table.concat(selectedList, "|||")
	selectedNamesValue.Value = joinedNames

	-- Aguardar sincronização
	wait(0.1)
	selectedNamesValue.Value = joinedNames
	
	-- Atualizar imediatamente os nomes alvo
	updateTargetNames()
end

local function loadSavedSelection()
	if not selectedNamesValue then return end

	selected = {}

	if selectedNamesValue.Value ~= "" then
		local savedNames = string.split(selectedNamesValue.Value, "|||")
		for _, name in ipairs(savedNames) do
			if name and name ~= "" then
				selected[name] = true
			end
		end
	end
end

local function waitForCommunicationSystem()
	local attempts = 0
	while attempts < 50 do
		brainrotFolder = ReplicatedStorage:FindFirstChild("BrainrotSystem")
		if brainrotFolder then break end
		attempts = attempts + 1
		wait(0.2)
	end

	if not brainrotFolder then return false end

	attempts = 0
	while attempts < 25 do
		selectedNamesValue = brainrotFolder:FindFirstChild("SelectedNames")
		if selectedNamesValue then break end
		attempts = attempts + 1
		wait(0.2)
	end

	return selectedNamesValue ~= nil
end

local function loadSelectedNames()
	if not selectedNamesValue then
		if not waitForCommunicationSystem() then
			return {}
		end
	end

	local currentValue = selectedNamesValue.Value

	if currentValue == "" then
		return {}
	end

	local selectedNames = string.split(currentValue, "|||")
	local validNames = {}

	for _, name in ipairs(selectedNames) do
		if name and name ~= "" then
			table.insert(validNames, name)
		end
	end

	lastKnownValue = currentValue
	return validNames
end

-- Função CORRIGIDA para atualizar nomes alvo
local function updateTargetNames()
	if not SYSTEM_LOADED then return end
	
	local newNames = loadSelectedNames()
	targetNames = newNames

	targetNamesCache = {}
	for i, name in pairs(targetNames) do
		targetNamesCache[i] = {
			original = name,
			lower = name:lower()
		}
	end
	
	print("Target names atualizados: " .. #targetNames)
end

-- Função CORRIGIDA para atualizar aparência do botão
local function updateButtonAppearance()
	if not LOADING_COMPLETE then return end
	
	local count = #targetNames
	if AUTO_ACTIVATE and count > 0 then
		autoBuyBtn.Text = " "
		autoBuyBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		autoBuyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	else
		autoBuyBtn.Text = " "
		autoBuyBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		autoBuyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function setupChangeMonitoring()
	if not selectedNamesValue then return end

	selectedNamesValue.Changed:Connect(function(newValue)
		if newValue ~= lastKnownValue and SYSTEM_LOADED then
			lastKnownValue = newValue
			wait(0.1)
			updateTargetNames()
			updateButtonAppearance()
		end
	end)
end

local function isTargetPrompt(prompt)
	if not prompt or not prompt.ObjectText or not SYSTEM_LOADED then return false end

	local objectText = prompt.ObjectText
	if objectText == "" then return false end

	local objectTextLower = objectText:lower()

	for _, nameData in pairs(targetNamesCache) do
		if objectText:find(nameData.original, 1, true) then
			return true, nameData.original
		end
		if objectTextLower:find(nameData.lower, 1, true) then
			return true, nameData.original
		end
	end

	return false, nil
end

local function activateProximityPrompt(prompt)
	if not prompt or not prompt.Parent or not AUTO_ACTIVATE or not SYSTEM_LOADED then return end

	local promptId = tostring(prompt)
	local currentTime = tick()

	if lastActivation[promptId] and currentTime - lastActivation[promptId] < 1 then
		return
	end

	lastActivation[promptId] = currentTime

	coroutine.wrap(function()
		local success = pcall(function()
			if fireproximityprompt then
				fireproximityprompt(prompt)
				return
			end
		end)

		if success then return end

		pcall(function()
			if prompt.HoldDuration > 0 then
				prompt:InputHoldBegin()
				wait(math.min(prompt.HoldDuration + 0.05, 0.5))
				prompt:InputHoldEnd()
			else
				prompt:InputHoldBegin()
				wait(ACTIVATION_DELAY)
				prompt:InputHoldEnd()
			end
		end)
	end)()
end

local positionCache = {}

local function getModelPosition(promptParent)
	local cacheKey = tostring(promptParent)
	local currentTime = tick()

	if positionCache[cacheKey] and currentTime - positionCache[cacheKey].time < 0.5 then
		return positionCache[cacheKey].position
	end

	local position = nil

	if promptParent:IsA("BasePart") then
		position = promptParent.Position
	elseif promptParent:FindFirstChild("HumanoidRootPart") then
		position = promptParent.HumanoidRootPart.Position
	elseif promptParent:IsA("Model") and promptParent.PrimaryPart then
		position = promptParent.PrimaryPart.Position
	else
		for i, child in pairs(promptParent:GetChildren()) do
			if i > 10 then break end
			if child:IsA("BasePart") then
				position = child.Position
				break
			end
		end
	end

	if position then
		positionCache[cacheKey] = {
			position = position,
			time = currentTime
		}
	end

	return position
end

local function processPromptsQueue()
	if not AUTO_ACTIVATE or not SYSTEM_LOADED then return end

	local processed = 0
	local maxPerFrame = 5

	while #scanQueue > 0 and processed < maxPerFrame do
		local prompt = table.remove(scanQueue, 1)
		processed = processed + 1

		if prompt and prompt.Parent then
			local promptId = tostring(prompt)

			if processedPrompts[promptId] and tick() - processedPrompts[promptId] < 2 then
				continue
			end

			processedPrompts[promptId] = tick()

			local isTarget, foundName = isTargetPrompt(prompt)

			if isTarget and character and humanoidRootPart then
				local playerPosition = humanoidRootPart.Position
				local modelPosition = getModelPosition(prompt.Parent)

				if modelPosition then
					local distance = (playerPosition - modelPosition).Magnitude

					if distance <= MAX_DISTANCE then
						activateProximityPrompt(prompt)
					end
				end
			end
		end
	end
end

local function scanExistingPrompts()
	if not AUTO_ACTIVATE or not character or not humanoidRootPart or not SYSTEM_LOADED then
		return
	end

	local playerPosition = humanoidRootPart.Position

	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.Enabled then
			local modelPosition = getModelPosition(obj.Parent)
			if modelPosition then
				local distance = (playerPosition - modelPosition).Magnitude
				if distance <= MAX_DISTANCE * 2 then
					table.insert(scanQueue, obj)
				end
			end
		end

		if #scanQueue > 100 then break end
	end
end

local function startScript()
	if SCRIPT_ACTIVE or not SYSTEM_LOADED then return end
	SCRIPT_ACTIVE = true

	connections[#connections + 1] = ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if not AUTO_ACTIVATE or not SYSTEM_LOADED then return end

		local isTarget, foundName = isTargetPrompt(prompt)

		if isTarget then
			wait(0.1)
			activateProximityPrompt(prompt)
		end
	end)

	connections[#connections + 1] = ProximityPromptService.PromptHidden:Connect(function(prompt, inputType)
		local promptId = tostring(prompt)
		trackedPrompts[promptId] = nil
		processedPrompts[promptId] = nil
	end)

	local lastScan = 0
	local lastCleanup = 0

	connections[#connections + 1] = RunService.Heartbeat:Connect(function()
		if not AUTO_ACTIVATE or not SYSTEM_LOADED then return end

		local currentTime = tick()

		if #scanQueue > 0 then
			processPromptsQueue()
		end

		if currentTime - lastScan >= 3 then
			lastScan = currentTime
			if #scanQueue < 50 then
				pcall(scanExistingPrompts)
			end
		end

		if currentTime - lastCleanup >= 15 then
			lastCleanup = currentTime

			for promptId, time in pairs(lastActivation) do
				if currentTime - time > 30 then
					lastActivation[promptId] = nil
				end
			end

			for promptId, time in pairs(processedPrompts) do
				if currentTime - time > 10 then
					processedPrompts[promptId] = nil
				end
			end

			for key, data in pairs(positionCache) do
				if currentTime - data.time > 2 then
					positionCache[key] = nil
				end
			end
		end
	end)
end

local function stopScript()
	if not SCRIPT_ACTIVE then return end
	SCRIPT_ACTIVE = false

	for _, connection in pairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	connections = {}

	trackedPrompts = {}
	lastActivation = {}
	processedPrompts = {}
	positionCache = {}
	scanQueue = {}
end

-- Função CORRIGIDA para toggle do script
local function toggleScript()
	if not LOADING_COMPLETE then 
		showLoading("⚠️ AGUARDE O CARREGAMENTO!")
		wait(1)
		hideLoading()
		return 
	end

	-- Verificar se há itens selecionados
	if not AUTO_ACTIVATE and #targetNames == 0 then
		return
	end

	AUTO_ACTIVATE = not AUTO_ACTIVATE
	
	if AUTO_ACTIVATE then
		-- Atualizar nomes antes de ativar
		updateTargetNames()
		if #targetNames == 0 then
			AUTO_ACTIVATE = false
			updateButtonAppearance()
			return
		end
		startScript()
	else
		stopScript()
	end
	
	updateButtonAppearance()
end

-- Função para esconder/mostrar elementos quando o ScrollingFrame abre/fecha
local function hideElementsForSelection()
	if not LOADING_COMPLETE then return end
	autoBuyBtn.Visible = false
	listFR.Visible = false
	titleLabel.Visible = false
	inf.Visible = false
end

local function showElementsAfterSelection()
	if not LOADING_COMPLETE then return end
	autoBuyBtn.Visible = true
	inf.Visible = true
end

-- Função corrigida para popular o scrolling com seu estilo visual
local function populateScrolling()
	if not LOADING_COMPLETE then return end
	
	-- Limpar botões existentes
	for _, child in pairs(scrollingFR:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local y = 0
	for _, name in ipairs(availableNames) do
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0, 280, 0, 28)
		btn.Position = UDim2.new(0, 0, 0, y)
		btn.BackgroundColor3 = Color3.new(0, 0, 0)
		btn.BackgroundTransparency = 0.35
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.Arcade
		btn.TextSize = 14
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Text = name
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = scrollingFR

		-- Aplicar estilo se já estiver selecionado
		if selected[name] then
			btn.BackgroundTransparency = 0.7
			btn.Text = "✅ " .. name
		end

		btn.MouseButton1Click:Connect(function()
			if not LOADING_COMPLETE then return end
			
			-- Alterna seleção usando seu estilo
			if selected[name] then
				selected[name] = nil
				btn.BackgroundTransparency = 0.35
				btn.Text = name
			else
				selected[name] = true
				btn.BackgroundTransparency = 0.7
				btn.Text = "✅ " .. name
			end

			-- Atualizar contador
			local count = 0
			for _ in pairs(selected) do count = count + 1 end
			confirmBtn.Text = "CONFIRMAR (" .. count .. ")"
		end)

		y = y + 32
	end
	scrollingFR.CanvasSize = UDim2.new(0, 0, 0, y)
end

-- Função CORRIGIDA para atualizar a lista
local function refreshList()
	if not LOADING_COMPLETE then return end
	
	for _, child in pairs(listFR:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local y = 0
	for name in pairs(selected) do
		local entry = Instance.new("Frame")
		entry.Size = UDim2.new(1, -10, 0, 28)
		entry.Position = UDim2.new(0, 5, 0, y)
		entry.BackgroundTransparency = 1
		entry.Parent = listFR

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(0.8, 0, 1, 0)
		lbl.Position = UDim2.new(0, 0, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.Arcade
		lbl.TextSize = 11
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.Text = "• " .. name
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = entry

		local btnX = Instance.new("TextButton")
		btnX.Size = UDim2.new(0.2, 0, 1, 0)
		btnX.Position = UDim2.new(0.8, 0, 0, 0)
		btnX.Font = Enum.Font.Arcade
		btnX.TextSize = 12
		btnX.TextColor3 = Color3.fromRGB(255, 100, 100)
		btnX.Text = "❌"
		btnX.BackgroundTransparency = 1
		btnX.Parent = entry

		btnX.MouseButton1Click:Connect(function()
			-- Remover da seleção
			selected[name] = nil

			-- Forçar desativação do auto-buy se estava ativo
			if AUTO_ACTIVATE then
				AUTO_ACTIVATE = false
				stopScript()
			end

			-- Salvar a nova seleção (isso vai atualizar targetNames automaticamente)
			saveSelectedNames()

			-- Atualizar a lista visual
			refreshList()

			-- Atualizar aparência do botão de auto-compra
			updateButtonAppearance()

			-- Atualizar contador do botão principal
			local count = 0
			for _ in pairs(selected) do count = count + 1 end

			if count > 0 then
				toggleBtn.Text = "🎯 SELECIONADOS (" .. count .. ")"
				toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
			else
				toggleBtn.Text = "🎯 SELECIONAR ITENS"
				toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				listFR.Visible = false
				titleLabel.Visible = false
			end
		end)

		y = y + 32
	end

	if listFR:IsA("ScrollingFrame") then
		listFR.CanvasSize = UDim2.new(0, 0, 0, y)
	end
end

-- Conectar eventos dos botões
toggleBtn.MouseButton1Click:Connect(function()
	if not LOADING_COMPLETE then
		showLoading("⚠️ SISTEMA AINDA CARREGANDO!")
		wait(1)
		hideLoading()
		return
	end
	
	if scrollingFR.Visible then
		-- Fechar o seletor
		scrollingFR.Visible = false
		confirmBtn.Visible = false
		showElementsAfterSelection()

		-- Mostrar elementos se houver itens selecionados
		local count = 0
		for _ in pairs(selected) do count = count + 1 end

		if count > 0 then
			listFR.Visible = true
			titleLabel.Visible = true
			toggleBtn.Text = "🎯 SELECIONADOS (" .. count .. ")"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
		else
			toggleBtn.Text = "🎯 SELECIONAR ITENS"
			toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		end
	else
		-- Abrir o seletor
		hideElementsForSelection()

		scrollingFR.Visible = true
		confirmBtn.Visible = true
		toggleBtn.Text = "❌ FECHAR SELETOR"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		populateScrolling()
	end
end)

confirmBtn.MouseButton1Click:Connect(function()
	if not LOADING_COMPLETE then return end
	
	local count = 0
	for _ in pairs(selected) do count = count + 1 end

	if count == 0 then
		confirmBtn.Text = "⚠️ SELECIONE PELO MENOS 1!"
		confirmBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
		wait(2)
		confirmBtn.Text = "CONFIRMAR (0)"
		confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		return
	end

	-- Forçar desativação do auto-buy antes de salvar
	if AUTO_ACTIVATE then
		AUTO_ACTIVATE = false
		stopScript()
	end

	saveSelectedNames()

	scrollingFR.Visible = false
	confirmBtn.Visible = false
	showElementsAfterSelection()
	titleLabel.Visible = true
	listFR.Visible = true
	toggleBtn.Text = "🎯 SELECIONADOS (" .. count .. ")"
	toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)

	refreshList()
	updateButtonAppearance()
end)

autoBuyBtn.MouseButton1Click:Connect(toggleScript)

local function onCharacterAdded(newCharacter)
	character = newCharacter
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	if AUTO_ACTIVATE then
		stopScript()
		wait(1)
		if SYSTEM_LOADED then
			startScript()
		end
	end
end

player.CharacterAdded:Connect(onCharacterAdded)

game.Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		stopScript()
	end
end)

-- Função de inicialização completa
local function initializeSystem()
	showLoading("🔧 INICIANDO SISTEMA...")
	
	-- Desabilitar todos os botões durante o carregamento
	toggleBtn.Visible = false
	autoBuyBtn.Visible = false
	
	wait(0.5)
	
	-- Passo 1: Configurar sistema de comunicação
	setupCommunicationSystem()
	wait(0.3)
	
	-- Passo 2: Carregar nomes disponíveis
	updateAvailableNames()
	wait(0.3)
	
	-- Passo 3: Carregar seleção salva
	showLoading("💾 CARREGANDO SELEÇÕES...")
	loadSavedSelection()
	wait(0.3)
	
	-- Passo 4: Atualizar nomes alvo
	showLoading("🎯 CONFIGURANDO ALVOS...")
	SYSTEM_LOADED = true
	updateTargetNames()
	wait(0.3)
	
	-- Passo 5: Configurar monitoramento
	showLoading("🔍 CONFIGURANDO MONITORAMENTO...")
	setupChangeMonitoring()
	wait(0.3)
	
	-- Passo 6: Finalizar
	showLoading("✅ FINALIZANDO...")
	wait(0.5)
	
	-- Sistema carregado
	LOADING_COMPLETE = true
	hideLoading()
	
	-- Mostrar botões
	toggleBtn.Visible = true
	autoBuyBtn.Visible = true
	
	-- Configurar interface inicial
	local count = 0
	for _ in pairs(selected) do count = count + 1 end
	
	if count > 0 then
		toggleBtn.Text = "🎯 SELECIONADOS (" .. count .. ")"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
		confirmBtn.Text = "CONFIRMAR (" .. count .. ")"
		listFR.Visible = true
		titleLabel.Visible = true
		refreshList()
	else
		toggleBtn.Text = "🎯 SELECIONAR ITENS"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	end
	
	updateButtonAppearance()
	
	print("✅ Sistema Brainrot carregado com sucesso!")
	print("📊 Nomes disponíveis: " .. #availableNames)
	print("🎯 Itens selecionados: " .. count)
end

-- Inicialização
coroutine.wrap(function()
	initializeSystem()
end)()
