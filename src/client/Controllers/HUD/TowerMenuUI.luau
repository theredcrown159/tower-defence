--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local TowerDefinitions = require(ReplicatedStorage.Shared.Config.TowerDefinitions)

local towerRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Towers")
local sellFunction = towerRemotes:WaitForChild("Sell") :: RemoteFunction
local setTargetModeFunction = towerRemotes:WaitForChild("SetTargetMode") :: RemoteFunction
local upgradeFunction = towerRemotes:WaitForChild("Upgrade") :: RemoteFunction

local TowerMenuUI = {}

local menu: GuiObject? = nil
local titleLabel: TextLabel? = nil
local ownerLabel: TextLabel? = nil
local targetingLabel: TextLabel? = nil
local currentDamageLabel: TextLabel? = nil
local currentRangeLabel: TextLabel? = nil
local currentCooldownLabel: TextLabel? = nil
local nextDamageLabel: TextLabel? = nil
local nextRangeLabel: TextLabel? = nil
local nextCooldownLabel: TextLabel? = nil
local upgradeButton: GuiButton? = nil
local upgradeCostLabel: TextLabel? = nil
local sellButton: GuiButton? = nil
local sellAmountLabel: TextLabel? = nil
local previousTargetModeButton: GuiButton? = nil
local nextTargetModeButton: GuiButton? = nil
local selectedModel: Model? = nil
local levelChangedConnection: RBXScriptConnection? = nil
local targetModeChangedConnection: RBXScriptConnection? = nil
local upgradeActivatedConnection: RBXScriptConnection? = nil
local sellActivatedConnection: RBXScriptConnection? = nil
local previousTargetModeActivatedConnection: RBXScriptConnection? = nil
local nextTargetModeActivatedConnection: RBXScriptConnection? = nil
local upgradeRequestInFlight = false
local sellRequestInFlight = false
local targetModeRequestInFlight = false

local function getOwnerName(ownerUserId: number): string
	local owner = Players:GetPlayerByUserId(ownerUserId)

	if owner == Players.LocalPlayer then
		return "Me"
	end

	return if owner then owner.DisplayName else tostring(ownerUserId)
end

local function setUpgradeEnabled(enabled: boolean)
	if upgradeButton then
		upgradeButton.Active = enabled
		upgradeButton.Interactable = enabled
		upgradeButton.AutoButtonColor = enabled
	end
end

local function setSellEnabled(enabled: boolean)
	if sellButton then
		sellButton.Active = enabled
		sellButton.Interactable = enabled
		sellButton.AutoButtonColor = enabled
	end
end

local function setTargetingEnabled(enabled: boolean)
	for _, button in { previousTargetModeButton, nextTargetModeButton } do
		if button then
			button.Active = enabled
			button.Interactable = enabled
			button.AutoButtonColor = enabled
		end
	end
end

local function getSellAmount(towerName: string, level: number): number
	local definition = TowerDefinitions[towerName]

	if not definition then
		return 0
	end

	local currentLevel = math.clamp(math.floor(level), 1, #definition.Levels)
	local totalCost = 0

	for levelIndex = 1, currentLevel do
		totalCost += definition.Levels[levelIndex].Cost
	end

	return math.floor(totalCost * GameConfig.TowerSellRefundRate)
end

local function update()
	local model = selectedModel

	if
		not model
		or not menu
		or not titleLabel
		or not ownerLabel
		or not targetingLabel
		or not currentDamageLabel
		or not currentRangeLabel
		or not currentCooldownLabel
		or not nextDamageLabel
		or not nextRangeLabel
		or not nextCooldownLabel
		or not upgradeCostLabel
		or not sellAmountLabel
	then
		return
	end

	local towerName = model:GetAttribute("TowerName")
	local ownerUserId = model:GetAttribute("OwnerUserId")
	local level = model:GetAttribute("TowerLevel")
	local targetMode = model:GetAttribute("TargetMode")

	if
		typeof(towerName) ~= "string"
		or typeof(ownerUserId) ~= "number"
		or typeof(level) ~= "number"
		or typeof(targetMode) ~= "string"
	then
		return
	end

	local definition = TowerDefinitions[towerName]

	if not definition then
		return
	end

	local currentLevelIndex = math.clamp(math.floor(level), 1, #definition.Levels)
	local currentLevel = definition.Levels[currentLevelIndex]
	local nextLevel = definition.Levels[currentLevelIndex + 1]

	titleLabel.Text = towerName:gsub("_", " ")
	ownerLabel.Text = `Owner: {getOwnerName(ownerUserId)}`
	targetingLabel.Text = targetMode
	currentDamageLabel.Text = tostring(currentLevel.Damage)
	currentRangeLabel.Text = tostring(currentLevel.Range)
	currentCooldownLabel.Text = tostring(currentLevel.AttackCooldown)

	if nextLevel then
		nextDamageLabel.Text = tostring(nextLevel.Damage)
		nextRangeLabel.Text = tostring(nextLevel.Range)
		nextCooldownLabel.Text = tostring(nextLevel.AttackCooldown)
		upgradeCostLabel.Text = tostring(nextLevel.Cost)
	else
		nextDamageLabel.Text = "-"
		nextRangeLabel.Text = "-"
		nextCooldownLabel.Text = "-"
		upgradeCostLabel.Text = "MAX"
	end

	local isOwner = ownerUserId == Players.LocalPlayer.UserId
	local requestInFlight = upgradeRequestInFlight or sellRequestInFlight or targetModeRequestInFlight

	sellAmountLabel.Text = tostring(getSellAmount(towerName, currentLevelIndex))
	setUpgradeEnabled(isOwner and nextLevel ~= nil and not requestInFlight)
	setSellEnabled(isOwner and not requestInFlight)
	setTargetingEnabled(isOwner and not requestInFlight)
end

local function requestUpgrade()
	local model = selectedModel

	if not model or upgradeRequestInFlight or sellRequestInFlight or targetModeRequestInFlight then
		return
	end

	local towerId = model:GetAttribute("TowerId")
	local towerName = model:GetAttribute("TowerName")
	local ownerUserId = model:GetAttribute("OwnerUserId")
	local level = model:GetAttribute("TowerLevel")

	if
		typeof(towerId) ~= "number"
		or typeof(towerName) ~= "string"
		or typeof(ownerUserId) ~= "number"
		or typeof(level) ~= "number"
		or ownerUserId ~= Players.LocalPlayer.UserId
	then
		return
	end

	local definition = TowerDefinitions[towerName]
	local nextLevel = if definition then definition.Levels[math.floor(level) + 1] else nil

	if not nextLevel then
		return
	end

	upgradeRequestInFlight = true
	update()
	local requestSucceeded, requestError = pcall(function()
		upgradeFunction:InvokeServer(towerId)
	end)
	upgradeRequestInFlight = false
	update()

	if not requestSucceeded then
		warn(`Tower upgrade request failed: {requestError}`)
	end
end

local function requestSell()
	local model = selectedModel

	if not model or upgradeRequestInFlight or sellRequestInFlight or targetModeRequestInFlight then
		return
	end

	local towerId = model:GetAttribute("TowerId")
	local ownerUserId = model:GetAttribute("OwnerUserId")

	if typeof(towerId) ~= "number" or typeof(ownerUserId) ~= "number" or ownerUserId ~= Players.LocalPlayer.UserId then
		return
	end

	sellRequestInFlight = true
	update()
	local requestSucceeded, wasSoldOrError = pcall(function()
		return sellFunction:InvokeServer(towerId)
	end)
	sellRequestInFlight = false

	if not requestSucceeded then
		warn(`Tower sell request failed: {wasSoldOrError}`)
		update()
		return
	end

	if wasSoldOrError == true then
		if selectedModel == model then
			TowerMenuUI.Hide()
		end
	else
		update()
	end
end

local function requestTargetMode(offset: number)
	local model = selectedModel

	if not model or upgradeRequestInFlight or sellRequestInFlight or targetModeRequestInFlight then
		return
	end

	local towerId = model:GetAttribute("TowerId")
	local towerName = model:GetAttribute("TowerName")
	local ownerUserId = model:GetAttribute("OwnerUserId")
	local targetMode = model:GetAttribute("TargetMode")

	if
		typeof(towerId) ~= "number"
		or typeof(towerName) ~= "string"
		or typeof(ownerUserId) ~= "number"
		or typeof(targetMode) ~= "string"
		or ownerUserId ~= Players.LocalPlayer.UserId
	then
		return
	end

	local definition = TowerDefinitions[towerName]
	local targetModes = if definition then definition.TargetModes else nil

	if not targetModes or #targetModes == 0 then
		return
	end

	local currentIndex = 0

	for index, allowedMode in targetModes do
		if allowedMode == targetMode then
			currentIndex = index
			break
		end
	end

	local nextTargetMode = targetModes[(currentIndex - 1 + offset) % #targetModes + 1]

	targetModeRequestInFlight = true
	update()
	local requestSucceeded, requestError = pcall(function()
		setTargetModeFunction:InvokeServer(towerId, nextTargetMode)
	end)
	targetModeRequestInFlight = false
	update()

	if not requestSucceeded then
		warn(`Target mode request failed: {requestError}`)
	end
end

local function requestPreviousTargetMode()
	requestTargetMode(-1)
end

local function requestNextTargetMode()
	requestTargetMode(1)
end

function TowerMenuUI.Start(unitUpgrade: GuiObject)
	local main = unitUpgrade:WaitForChild("Main")
	local upgrade = unitUpgrade:WaitForChild("Upgrade") :: GuiButton
	local sell = unitUpgrade:WaitForChild("Sell") :: GuiButton
	local targeting = unitUpgrade:WaitForChild("Targeting") :: TextLabel
	local left = unitUpgrade:WaitForChild("Left") :: GuiButton
	local right = unitUpgrade:WaitForChild("Right") :: GuiButton

	menu = unitUpgrade
	titleLabel = unitUpgrade:WaitForChild("Title") :: TextLabel
	ownerLabel = unitUpgrade:WaitForChild("Owner") :: TextLabel
	targetingLabel = targeting
	currentDamageLabel = main:WaitForChild("PrevDmg") :: TextLabel
	currentRangeLabel = main:WaitForChild("PrevRange") :: TextLabel
	currentCooldownLabel = main:WaitForChild("PrevCool") :: TextLabel
	nextDamageLabel = main:WaitForChild("NewDmg") :: TextLabel
	nextRangeLabel = main:WaitForChild("NewRange") :: TextLabel
	nextCooldownLabel = main:WaitForChild("NewCool") :: TextLabel
	upgradeButton = upgrade
	upgradeCostLabel = upgrade:WaitForChild("Cost") :: TextLabel
	sellButton = sell
	sellAmountLabel = sell:WaitForChild("TextLabel") :: TextLabel
	previousTargetModeButton = left
	nextTargetModeButton = right
	targeting.Active = false
	unitUpgrade.Active = true
	unitUpgrade.Visible = false

	upgradeActivatedConnection = upgrade.Activated:Connect(requestUpgrade)
	sellActivatedConnection = sell.Activated:Connect(requestSell)
	previousTargetModeActivatedConnection = left.Activated:Connect(requestPreviousTargetMode)
	nextTargetModeActivatedConnection = right.Activated:Connect(requestNextTargetMode)
end

function TowerMenuUI.Show(model: Model)
	TowerMenuUI.Hide()

	selectedModel = model
	levelChangedConnection = model:GetAttributeChangedSignal("TowerLevel"):Connect(update)
	targetModeChangedConnection = model:GetAttributeChangedSignal("TargetMode"):Connect(update)
	update()

	if menu then
		menu.Visible = true
	end
end

function TowerMenuUI.Hide()
	if levelChangedConnection then
		levelChangedConnection:Disconnect()
		levelChangedConnection = nil
	end

	if targetModeChangedConnection then
		targetModeChangedConnection:Disconnect()
		targetModeChangedConnection = nil
	end

	selectedModel = nil
	setUpgradeEnabled(false)
	setSellEnabled(false)
	setTargetingEnabled(false)

	if menu then
		menu.Visible = false
	end
end

function TowerMenuUI.Stop()
	TowerMenuUI.Hide()

	if upgradeActivatedConnection then
		upgradeActivatedConnection:Disconnect()
		upgradeActivatedConnection = nil
	end

	if sellActivatedConnection then
		sellActivatedConnection:Disconnect()
		sellActivatedConnection = nil
	end

	if previousTargetModeActivatedConnection then
		previousTargetModeActivatedConnection:Disconnect()
		previousTargetModeActivatedConnection = nil
	end

	if nextTargetModeActivatedConnection then
		nextTargetModeActivatedConnection:Disconnect()
		nextTargetModeActivatedConnection = nil
	end

	menu = nil
	titleLabel = nil
	ownerLabel = nil
	targetingLabel = nil
	currentDamageLabel = nil
	currentRangeLabel = nil
	currentCooldownLabel = nil
	nextDamageLabel = nil
	nextRangeLabel = nil
	nextCooldownLabel = nil
	upgradeButton = nil
	upgradeCostLabel = nil
	sellButton = nil
	sellAmountLabel = nil
	previousTargetModeButton = nil
	nextTargetModeButton = nil
	upgradeRequestInFlight = false
	sellRequestInFlight = false
	targetModeRequestInFlight = false
end

return TowerMenuUI
