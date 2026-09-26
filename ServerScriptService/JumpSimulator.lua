--[===[ JUMP SIMULATOR - COMPLETE GAME IN ONE SCRIPT ]===]
-- Режиссер: ziko228ru-cell
-- Описание: Полнофункциональная Jump Simulator с ландшафтом, геймплеем, магазином и сохранением

--[===[ CONFIG & SETTINGS ]===]
local CONFIG = {
	-- БАЗОВЫЕ ПАРАМЕТРЫ
	startCoins = 100,
	startLevel = 1,
	startJumpPower = 50,
	startWalkSpeed = 16,
	
	-- КОИНЫ
	coinPerJump = 1,
	coinPerPlatformBonus = 10,
	coinRespawnTime = 5,
	coinSpawnCount = 15,
	
	-- УРОВНИ И ПЕРЕРОЖДЕНИЕ
	coinsPerLevel = 500,
	rebirthCostMultiplier = 1000,
	rebirthCostExponent = 2,
	rebirthCoinMultiplierBonus = 0.25,
	
	-- СОХРАНЕНИЕ
	autoSaveInterval = 60,
	dataStoreKey = "player_data_v1",
	
	-- ГЕЙМПАССЫ (ID: 0 или пример значений)
	GAMEPASSES = {
		VIP = 0, -- x2 коины
		SuperJump = 0, -- x1.5 JumpPower
		RainbowTrail = 0, -- Эффект следа
		AutoFarm = 0, -- Автосбор
	},
}

--[===[ SERVICES ]===]
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local playerDataStore = DataStoreService:GetDataStore(CONFIG.dataStoreKey)

--[===[ GAME STATE ]===]
local playerData = {} -- {playerId: {coins, level, rebirths, upgrades, lastSave}}
local playerGameObjects = {} -- {playerId: {character, currentLevel, coins...}}

--[===[ UTILITY FUNCTIONS ]===]
local function warn_safe(msg)
	pcall(function()
		warn("[Jump Simulator] " .. tostring(msg))
	end)
end

local function createPart(parent, cframe, size, color, material, canCollide)
	local part = Instance.new("Part")
	part.Name = "Part"
	part.Shape = Enum.PartType.Block
	part.CFrame = cframe
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.Brick
	part.CanCollide = canCollide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createUnion(parts)
	if #parts == 0 then return nil end
	local result = parts[1]
	for i = 2, #parts do
		pcall(function()
			result = result:UnionAsync(parts[i])
			parts[i]:Destroy()
		end)
	end
	return result
end

local function playSound(parent, id, volume, pitch)
	volume = volume or 0.5
	pitch = pitch or 1
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(id)
	sound.Volume = volume
	sound.Pitch = pitch
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 2)
end

local function createGui(guiType, properties)
	local gui = Instance.new(guiType)
	for key, val in pairs(properties or {}) do
		pcall(function()
			gui[key] = val
		end)
	end
	return gui
end

--[===[ WORLD GENERATION ]===]
local function createWorld()
	local worldFolder = Instance.new("Folder")
	worldFolder.Name = "World"
	worldFolder.Parent = workspace
	
	-- TERRAIN & BASEPLATE
	local baseplate = createPart(worldFolder, CFrame.new(0, 0, 0), Vector3.new(200, 1, 200), Color3.fromRGB(34, 139, 34), Enum.Material.Grass)
	baseplate.Name = "Baseplate"
	
	-- GRASS BUMPS & TERRAIN DETAIL
	for i = 1, 8 do
		local x = math.random(-80, 80)
		local z = math.random(-80, 80)
		local bump = createPart(worldFolder, CFrame.new(x, 1.5, z), Vector3.new(math.random(8, 20), math.random(1, 3), math.random(8, 20)), Color3.fromRGB(34, 139, 34), Enum.Material.Grass)
		bump.Name = "TerrainBump"
	end
	
	-- ROCKS
	for i = 1, 10 do
		local x = math.random(-90, 90)
		local z = math.random(-90, 90)
		local rockSize = math.random(2, 6)
		local rock = createPart(worldFolder, CFrame.new(x, rockSize / 2 + 1, z), Vector3.new(rockSize, rockSize, rockSize), Color3.fromRGB(128, 128, 128), Enum.Material.Rock)
		rock.Name = "Rock"
		rock.Shape = Enum.PartType.Ball
	end
	
	-- TREES (ствол + крона)
	for i = 1, 6 do
		local x = math.random(-85, 85)
		local z = math.random(-85, 85)
		
		-- Ствол
		local trunk = createPart(worldFolder, CFrame.new(x, 3, z), Vector3.new(1.5, 6, 1.5), Color3.fromRGB(101, 67, 33), Enum.Material.Wood)
		trunk.Name = "TreeTrunk"
		
		-- Крона
		local crown = createPart(worldFolder, CFrame.new(x, 9, z), Vector3.new(6, 5, 6), Color3.fromRGB(34, 139, 34), Enum.Material.Brick)
		crown.Name = "TreeCrown"
		crown.Shape = Enum.PartType.Ball
	end
	
	-- FLOWERS & DECORATIONS
	for i = 1, 12 do
		local x = math.random(-80, 80)
		local z = math.random(-80, 80)
		local flower = createPart(worldFolder, CFrame.new(x, 0.5, z), Vector3.new(0.5, 1, 0.5), Color3.fromRGB(255, math.random(0, 200), 100), Enum.Material.Neon)
		flower.Name = "Flower"
	end
	
	-- FOUNTAINS (декоративные)
	for i = 1, 3 do
		local x = (i - 1) * 60 - 60
		local base = createPart(worldFolder, CFrame.new(x, 1, 0), Vector3.new(8, 1, 8), Color3.fromRGB(200, 200, 200), Enum.Material.Marble)
		base.Name = "FountainBase"
		
		local column = createPart(worldFolder, CFrame.new(x, 3, 0), Vector3.new(3, 4, 3), Color3.fromRGB(200, 200, 200), Enum.Material.Marble)
		column.Name = "FountainColumn"
	end
	
	-- LAMPS (фонари)
	for i = 1, 5 do
		local x = math.random(-90, 90)
		local z = math.random(-90, 90)
		local lampPole = createPart(worldFolder, CFrame.new(x, 2.5, z), Vector3.new(0.5, 5, 0.5), Color3.fromRGB(100, 100, 100), Enum.Material.Metal)
		lampPole.Name = "LampPole"
		
		local lampHead = createPart(worldFolder, CFrame.new(x, 6, z), Vector3.new(1.5, 1, 1.5), Color3.fromRGB(255, 255, 0), Enum.Material.Neon)
		lampHead.Name = "LampHead"
		lampHead.Light = Instance.new("Light")
		lampHead.Light.Brightness = 2
		lampHead.Light.Range = 30
		lampHead.Light.Color = Color3.fromRGB(255, 255, 0)
	end
	
	-- JUMP PLATFORMS (основная механика) - восходящие платформы
	local platformsFolder = Instance.new("Folder")
	platformsFolder.Name = "JumpPlatforms"
	platformsFolder.Parent = worldFolder
	
	local platformCount = 30
	local platformHeight = 8
	local platformSpacing = 12
	
	for i = 1, platformCount do
		local height = platformHeight + (i - 1) * platformSpacing
		local xOffset = math.sin(i * 0.5) * 20
		local zOffset = math.cos(i * 0.3) * 15
		local platformSize = 4
		
		-- Цвет платформы зависит от высоты
		local hueValue = (i % 10) / 10
		local platformColor = Color3.fromHSV(hueValue, 0.8, 0.9)
		
		local platform = createPart(platformsFolder, CFrame.new(xOffset, height, zOffset), Vector3.new(platformSize, 1, platformSize), platformColor, Enum.Material.Neon)
		platform.Name = "Platform_" .. i
		platform.CanCollide = true
		
		-- BillboardGui с номером платформы
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(4, 0, 2, 0)
		billboard.MaxDistance = 100
		billboard.Parent = platform
		
		local textLabel = Instance.new("TextLabel")
		textLabel.Text = tostring(i)
		textLabel.TextSize = 24
		textLabel.Font = Enum.Font.GothamBold
		textLabel.BackgroundTransparency = 1
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.Parent = billboard
	end
	
	-- SKY & ATMOSPHERE
	local sky = Instance.new("Sky")
	sky.Parent = workspace.Terrain
	sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.png"
	sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.png"
	sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.png"
	sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.png"
	sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.png"
	sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.png"
	sky.CelestialBodiesShown = true
	
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Parent = workspace
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.1
	atmosphere.Glare = 0.1
	atmosphere.Color = Color3.fromRGB(200, 220, 255)
	
	-- LIGHTING & EFFECTS
	local lighting = game:GetService("Lighting")
	lighting.Ambient = Color3.fromRGB(135, 206, 235)
	lighting.OutdoorAmbient = Color3.fromRGB(135, 206, 235)
	lighting.ClockTime = 14
	
	-- ColorCorrection
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Parent = lighting
	colorCorrection.Brightness = 0.1
	colorCorrection.Contrast = 0.15
	colorCorrection.Saturation = 0.2
	
	-- Bloom
	local bloom = Instance.new("BloomEffect")
	bloom.Parent = lighting
	bloom.Intensity = 0.5
	bloom.Size = 24
	bloom.Threshold = 2
	
	-- SunRays
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Parent = lighting
	sunRays.Intensity = 0.15
	sunRays.Spread = 1
	
	-- Fog
	lighting.FogColor = Color3.fromRGB(200, 220, 255)
	lighting.FogEnd = 2000
	lighting.FogStart = 500
	
	return worldFolder
end

--[===[ SPAWN COINS ]===]
local function spawnCoins(worldFolder)
	local coinsFolder = Instance.new("Folder")
	coinsFolder.Name = "Coins"
	coinsFolder.Parent = worldFolder
	
	for i = 1, CONFIG.coinSpawnCount do
		local x = math.random(-70, 70)
		local z = math.random(-70, 70)
		local y = math.random(20, 100)
		
		local coin = createPart(coinsFolder, CFrame.new(x, y, z), Vector3.new(0.8, 0.8, 0.8), Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
		coin.Name = "Coin_" .. i
		coin.Shape = Enum.PartType.Cylinder
		coin.CanCollide = false
		
		-- RotationValue для анимации вращения
		local rotValue = Instance.new("IntValue")
		rotValue.Name = "RotationValue"
		rotValue.Parent = coin
		
		-- Touch debounce
		local lastTouched = 0
		coin.Touched:Connect(function(hit)
			if tick() - lastTouched < 0.5 then return end
			lastTouched = tick()
			
			local humanoid = hit.Parent:FindFirstChild("Humanoid")
			if not humanoid then return end
			
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then return end
			
			-- Отправляем событие на сервер
			local remote = Instance.new("RemoteEvent")
			remote.Name = "CoinTouched"
			remote.Parent = Instance.new("Folder")
		end)
	end
	
	return coinsFolder
end

--[===[ SETUP PLAYER CHARACTER ]===]
local function setupCharacter(player, character)
	wait(0.1) -- Даём время игре загрузиться
	
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Получаем данные игрока
	local data = playerData[player.UserId] or {
		coins = CONFIG.startCoins,
		level = CONFIG.startLevel,
		rebirths = 0,
		upgrades = {jumpPower = 1, walkSpeed = 1, coinMultiplier = 1},
		lastSave = tick()
	}
	playerData[player.UserId] = data
	
	-- Создаём Leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = data.coins
	coinsValue.Parent = leaderstats
	
	local levelValue = Instance.new("IntValue")
	levelValue.Name = "Level"
	levelValue.Value = data.level
	levelValue.Parent = leaderstats
	
	local rebirthsValue = Instance.new("IntValue")
	rebirthsValue.Name = "Rebirths"
	rebirthsValue.Value = data.rebirths
	rebirthsValue.Parent = leaderstats
	
	-- HUMANOID SETTINGS
	humanoid.JumpPower = CONFIG.startJumpPower * data.upgrades.jumpPower * (data.rebirths > 0 and (1 + data.rebirths * 0.1) or 1)
	if data.GAMEPASSES and data.GAMEPASSES.SuperJump then
		humanoid.JumpPower = humanoid.JumpPower * 1.5
	end
	
	character:WaitForChild("Humanoid"):FindFirstChild("HumanoidRootPart").Parent:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(0, 20, 0)
	
	-- WALK SPEED
	humanoid.WalkSpeed = CONFIG.startWalkSpeed * data.upgrades.walkSpeed
	
	-- Сохраняем данные в playerGameObjects
	playerGameObjects[player.UserId] = {
		character = character,
		humanoid = humanoid,
		currentLevel = 1,
		lastJumpTime = 0,
		coinsValue = coinsValue,
		levelValue = levelValue,
		rebirthsValue = rebirthsValue,
	}
end

--[===[ REMOTE EVENTS SETUP ]===]
local function setupRemoteEvents()
	local replicatedStorage = game:GetService("ReplicatedStorage")
	
	-- CoinTouched
	local coinTouchedEvent = Instance.new("RemoteEvent")
	coinTouchedEvent.Name = "CoinTouched"
	coinTouchedEvent.Parent = replicatedStorage
	
	-- BuyUpgrade
	local buyUpgradeEvent = Instance.new("RemoteEvent")
	buyUpgradeEvent.Name = "BuyUpgrade"
	buyUpgradeEvent.Parent = replicatedStorage
	
	-- Rebirth
	local rebirthEvent = Instance.new("RemoteEvent")
	rebirthEvent.Name = "Rebirth"
	rebirthEvent.Parent = replicatedStorage
	
	-- JumpEvent
	local jumpEvent = Instance.new("RemoteEvent")
	jumpEvent.Name = "JumpEvent"
	jumpEvent.Parent = replicatedStorage
	
	return {
		CoinTouched = coinTouchedEvent,
		BuyUpgrade = buyUpgradeEvent,
		Rebirth = rebirthEvent,
		JumpEvent = jumpEvent,
	}
end

--[===[ SERVER SIDE REMOTE HANDLERS ]===]
local function setupServerRemoteHandlers(remotes)
	-- JUMP EVENT - Выдача коинов за прыжок
	remotes.JumpEvent.OnServerEvent:Connect(function(player, height)
		if not playerData[player.UserId] then return end
		
		local data = playerData[player.UserId]
		local coinsToAdd = CONFIG.coinPerJump
		
		-- Бонус за высоту
		if height and height > 50 then
			coinsToAdd = coinsToAdd + math.floor(height / 20)
		end
		
		-- Множитель за VIP
		if data.GAMEPASSES and data.GAMEPASSES.VIP then
			coinsToAdd = coinsToAdd * 2
		end
		
		-- Множитель за перерождение
		coinsToAdd = coinsToAdd * (1 + data.rebirths * data.upgrades.coinMultiplier)
		
		data.coins = data.coins + coinsToAdd
		
		if playerGameObjects[player.UserId] then
			playerGameObjects[player.UserId].coinsValue.Value = data.coins
		end
		
		playSound(workspace, 145605882, 0.3) -- Звук монеты
	end)
	
	-- BUY UPGRADE
	remotes.BuyUpgrade.OnServerEvent:Connect(function(player, upgradeType, cost)
		if not playerData[player.UserId] then return end
		
		local data = playerData[player.UserId]
		
		if data.coins < cost then
			return
		end
		
		data.coins = data.coins - cost
		
		if upgradeType == "jumpPower" then
			data.upgrades.jumpPower = data.upgrades.jumpPower + 0.1
			if playerGameObjects[player.UserId] then
				playerGameObjects[player.UserId].humanoid.JumpPower = CONFIG.startJumpPower * data.upgrades.jumpPower
			end
		elseif upgradeType == "walkSpeed" then
			data.upgrades.walkSpeed = data.upgrades.walkSpeed + 0.1
			if playerGameObjects[player.UserId] then
				playerGameObjects[player.UserId].humanoid.WalkSpeed = CONFIG.startWalkSpeed * data.upgrades.walkSpeed
			end
		elseif upgradeType == "coinMultiplier" then
			data.upgrades.coinMultiplier = data.upgrades.coinMultiplier + 0.05
		end
		
		if playerGameObjects[player.UserId] then
			playerGameObjects[player.UserId].coinsValue.Value = data.coins
		end
		
		playSound(workspace, 330706798, 0.5) -- Звук покупки
	end)
	
	-- REBIRTH
	remotes.Rebirth.OnServerEvent:Connect(function(player)
		if not playerData[player.UserId] then return end
		
		local data = playerData[player.UserId]
		local rebirthCost = CONFIG.rebirthCostMultiplier * (CONFIG.rebirthCostExponent ^ data.rebirths)
		
		if data.coins < rebirthCost then
			return
		end
		
		data.coins = 0
		data.rebirths = data.rebirths + 1
		data.upgrades.coinMultiplier = data.upgrades.coinMultiplier * (1 + CONFIG.rebirthCoinMultiplierBonus)
		data.upgrades.jumpPower = 1
		data.upgrades.walkSpeed = 1
		
		if playerGameObjects[player.UserId] then
			playerGameObjects[player.UserId].rebirthsValue.Value = data.rebirths
			playerGameObjects[player.UserId].coinsValue.Value = 0
			playerGameObjects[player.UserId].humanoid.JumpPower = CONFIG.startJumpPower * (1 + data.rebirths * 0.1)
			playerGameObjects[player.UserId].humanoid.WalkSpeed = CONFIG.startWalkSpeed
		end
		
		playSound(workspace, 1370932421, 1) -- Звук перерождения
	end)
end

--[===[ AUTO-SAVE SYSTEM ]===]
local function startAutoSave()
	local function savePlayerData(playerId)
		if not playerData[playerId] then return end
		
		local data = playerData[playerId]
		
		local success = pcall(function()
			playerDataStore:SetAsync("player_" .. playerId, {
				coins = data.coins,
				level = data.level,
				rebirths = data.rebirths,
				upgrades = data.upgrades,
				timestamp = tick(),
			})
		end)
		
		if not success then
			warn_safe("Failed to save data for player " .. playerId)
		end
	end
	
	while true do
		wait(CONFIG.autoSaveInterval)
		
		for playerId, _ in pairs(playerData) do
			savePlayerData(playerId)
		end
	end
end

--[===[ CLIENT SIDE - GUI & EFFECTS ]===]
local function createClientScript()
	local clientScript = Instance.new("LocalScript")
	clientScript.Name = "JumpSimulatorClient"
	clientScript.Parent = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	
	local source = [[
--[===[ CLIENT SIDE ]===]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- REMOTE EVENTS
local jumpEvent = ReplicatedStorage:WaitForChild("JumpEvent")
local buyUpgradeEvent = ReplicatedStorage:WaitForChild("BuyUpgrade")
local rebirthEvent = ReplicatedStorage:WaitForChild("Rebirth")

-- LEADERSTATS
local leaderstats = player:WaitForChild("leaderstats")
local coinsValue = leaderstats:WaitForChild("Coins")
local levelValue = leaderstats:WaitForChild("Level")
local rebirthsValue = leaderstats:WaitForChild("Rebirths")

-- UI SETUP
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JumpSimulatorGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- MAIN UI PANEL (Top-Right)
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, 250, 0, 150)
mainPanel.Position = UDim2.new(1, -270, 0, 20)
mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainPanel.BorderSizePixel = 0
mainPanel.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = mainPanel

-- COINS DISPLAY
local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.Size = UDim2.new(1, 0, 0, 40)
coinsLabel.Position = UDim2.new(0, 0, 0, 10)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinsLabel.TextSize = 20
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.Parent = mainPanel

local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "LevelLabel"
levelLabel.Size = UDim2.new(1, 0, 0, 35)
levelLabel.Position = UDim2.new(0, 0, 0, 50)
levelLabel.BackgroundTransparency = 1
levelLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
levelLabel.TextSize = 18
levelLabel.Font = Enum.Font.Gotham
levelLabel.Parent = mainPanel

local rebirthLabel = Instance.new("TextLabel")
rebirthLabel.Name = "RebirthLabel"
rebirthLabel.Size = UDim2.new(1, 0, 0, 35)
rebirthLabel.Position = UDim2.new(0, 0, 0, 85)
rebirthLabel.BackgroundTransparency = 1
rebirthLabel.TextColor3 = Color3.fromRGB(255, 100, 255)
rebirthLabel.TextSize = 18
rebirthLabel.Font = Enum.Font.Gotham
rebirthLabel.Parent = mainPanel

-- SHOP BUTTON
local shopButton = Instance.new("TextButton")
shopButton.Name = "ShopButton"
shopButton.Size = UDim2.new(0, 50, 0, 50)
shopButton.Position = UDim2.new(1, -70, 0, 20)
shopButton.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopButton.TextSize = 12
shopButton.Font = Enum.Font.GothamBold
shopButton.Text = "SHOP"
shopButton.BorderSizePixel = 0
shopButton.Parent = screenGui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 8)
shopCorner.Parent = shopButton

-- SHOP GUI
local shopGui = Instance.new("Frame")
shopGui.Name = "ShopGui"
shopGui.Size = UDim2.new(0, 400, 0, 500)
shopGui.Position = UDim2.new(0.5, -200, 0.5, -250)
shopGui.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
shopGui.BorderSizePixel = 0
shopGui.Visible = false
shopGui.Parent = screenGui

local shopCorner2 = Instance.new("UICorner")
shopCorner2.CornerRadius = UDim.new(0, 12)
shopCorner2.Parent = shopGui

-- SHOP CLOSE BUTTON
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 14
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.BorderSizePixel = 0
closeButton.Parent = shopGui

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

-- SHOP TITLE
local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "ShopTitle"
shopTitle.Size = UDim2.new(1, 0, 0, 50)
shopTitle.Position = UDim2.new(0, 0, 0, 0)
shopTitle.BackgroundTransparency = 1
shopTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
shopTitle.TextSize = 24
shopTitle.Font = Enum.Font.GothamBold
shopTitle.Text = "🛍 SHOP"
shopTitle.Parent = shopGui

-- SHOP CONTENT (ScrollingFrame)
local shopContent = Instance.new("ScrollingFrame")
shopContent.Name = "ShopContent"
shopContent.Size = UDim2.new(1, -20, 1, -80)
shopContent.Position = UDim2.new(0, 10, 0, 60)
shopContent.BackgroundTransparency = 1
shopContent.ScrollBarThickness = 8
shopContent.CanvasSize = UDim2.new(0, 0, 0, 500)
shopContent.Parent = shopGui

-- UPGRADE ITEMS
local upgrades = {
	{name = "Jump Power", type = "jumpPower", cost = 100, icon = "⬆"},
	{name = "Walk Speed", type = "walkSpeed", cost = 100, icon = "➡"},
	{name = "Coin Multiplier", type = "coinMultiplier", cost = 200, icon = "✕"},
}

for i, upgrade in ipairs(upgrades) do
	local item = Instance.new("TextButton")
	item.Name = upgrade.name
	item.Size = UDim2.new(1, -20, 0, 50)
	item.Position = UDim2.new(0, 10, 0, (i-1) * 60)
	item.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	item.TextColor3 = Color3.fromRGB(255, 255, 255)
	item.TextSize = 14
	item.Font = Enum.Font.Gotham
	item.Text = upgrade.icon .. " " .. upgrade.name .. " - $" .. upgrade.cost
	item.BorderSizePixel = 0
	item.Parent = shopContent
	
	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 8)
	itemCorner.Parent = item
	
	item.MouseButton1Click:Connect(function()
		if coinsValue.Value >= upgrade.cost then
			buyUpgradeEvent:FireServer(upgrade.type, upgrade.cost)
		end
	end)
end

-- REBIRTH BUTTON
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.Size = UDim2.new(1, -20, 0, 50)
rebirthButton.Position = UDim2.new(0, 10, 0, 220)
rebirthButton.BackgroundColor3 = Color3.fromRGB(200, 100, 255)
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextSize = 14
rebirthButton.Font = Enum.Font.GothamBold
rebirthButton.Text = "🔄 REBIRTH"
rebirthButton.BorderSizePixel = 0
rebirthButton.Parent = shopContent

local rebirthCorner = Instance.new("UICorner")
rebirthCorner.CornerRadius = UDim.new(0, 8)
rebirthCorner.Parent = rebirthButton

rebirthButton.MouseButton1Click:Connect(function()
	rebirthEvent:FireServer()
end)

-- EVENT HANDLERS
coinsValue.Changed:Connect(function()
	coinsLabel.Text = "💰 Coins: " .. coinsValue.Value
end)

levelValue.Changed:Connect(function()
	levelLabel.Text = "📊 Level: " .. levelValue.Value
end)

rebirthsValue.Changed:Connect(function()
	rebirthLabel.Text = "✨ Rebirths: " .. rebirthsValue.Value
end)

shopButton.MouseButton1Click:Connect(function()
	shopGui.Visible = not shopGui.Visible
end)

closeButton.MouseButton1Click:Connect(function()
	shopGui.Visible = false
end)

-- JUMP TRACKING
local isJumping = false
humanoid.StateChanged:Connect(function(oldState, newState)
	if newState == Enum.HumanoidStateType.Jumping then
		isJumping = true
		jumpEvent:FireServer(rootPart.Position.Y)
	elseif newState == Enum.HumanoidStateType.Landed then
		isJumping = false
	end
end)

-- INITIAL UPDATE
coinsLabel.Text = "💰 Coins: " .. coinsValue.Value
levelLabel.Text = "📊 Level: " .. levelValue.Value
rebirthLabel.Text = "✨ Rebirths: " .. rebirthsValue.Value
]]
	
	clientScript.Source = source
end

--[===[ MAIN GAME INITIALIZATION ]===]
local function initGame()
	print("========================================")
	print("     🎮 JUMP SIMULATOR - LOADING")
	print("========================================")
	
	-- Создаём мир
	local world = createWorld()
	warn_safe("World created successfully")
	
	-- Спавним коины
	spawnCoins(world)
	warn_safe("Coins spawned")
	
	-- Настраиваем RemoteEvents
	local remotes = setupRemoteEvents()
	warn_safe("Remote Events created")
	
	-- Настраиваем обработчики
	setupServerRemoteHandlers(remotes)
	warn_safe("Remote Handlers setup")
	
	-- Создаём клиентский скрипт
	wait(1)
	createClientScript()
	warn_safe("Client script created")
	
	-- Обработка игроков
	Players.PlayerAdded:Connect(function(player)
		warn_safe("Player joined: " .. player.Name)
		
		-- Загружаем данные из DataStore
		local success, data = pcall(function()
			return playerDataStore:GetAsync("player_" .. player.UserId)
		end)
		
		if success and data then
			playerData[player.UserId] = data
			playerData[player.UserId].lastSave = tick()
			warn_safe("Loaded data for " .. player.Name)
		else
			playerData[player.UserId] = {
				coins = CONFIG.startCoins,
				level = CONFIG.startLevel,
				rebirths = 0,
				upgrades = {jumpPower = 1, walkSpeed = 1, coinMultiplier = 1},
				lastSave = tick(),
			}
		end
		
		-- Обработка персонажа
		player.CharacterAdded:Connect(function(character)
			setupCharacter(player, character)
		end)
		
		-- Первый спаун
		if player.Character then
			setupCharacter(player, player.Character)
		end
	end)
	
	-- При выходе игрока - сохраняем данные
	Players.PlayerRemoving:Connect(function(player)
		if playerData[player.UserId] then
			local success = pcall(function()
				playerDataStore:SetAsync("player_" .. player.UserId, playerData[player.UserId])
			end)
			
			if success then
				warn_safe("Saved data for " .. player.Name)
			else
				warn_safe("Failed to save data for " .. player.Name)
			end
			
			playerData[player.UserId] = nil
			playerGameObjects[player.UserId] = nil
		end
	end)
	
	-- Запускаем автосейв
	task.spawn(startAutoSave)
	
	print("========================================")
	print("     ✅ JUMP SIMULATOR READY!")
	print("========================================")
end

-- СТАРТУЕМ
initGame()
