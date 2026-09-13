--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TowerDefinitions = require(ReplicatedStorage.Shared.Config.TowerDefinitions)

local towerRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Towers")
local upgradeFunction = towerRemotes:WaitForChild("Upgrade") :: RemoteFunction

local TowerMenuUI = {}

local menu: GuiObject? = nil
local titleLabel: TextLabel? = nil
local ownerLabel: TextLabel? = nil
local currentDamageLabel: TextLabel? = nil
local currentRangeLabel: TextLabel? = nil
local currentCooldownLabel: TextLabel? = nil
local nextDamageLabel: TextLabel? = nil
local nextRangeLabel: TextLabel? = nil
local nextCooldownLabel: TextLabel? = nil
local upgradeButton: GuiButton? = nil
local upgradeCostLabel: TextLabel? = nil
local selectedModel: Model? = nil
local levelChangedConnection: RBXScriptConnection? = nil
local upgradeActivatedConnection: RBXScriptConnection? = nil
local upgradeRequestInFlight = false

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

local function update()
	local model = selectedModel

	if
		not model
		or not menu
		or not titleLabel
		or not ownerLabel
		or not currentDamageLabel
		or not currentRangeLabel
		or not currentCooldownLabel
		or not nextDamageLabel
		or not nextRangeLabel
		or not nextCooldownLabel
		or not upgradeCostLabel
	then
		return
	end

	local towerName = model:GetAttribute("TowerName")
	local ownerUserId = model:GetAttribute("OwnerUserId")
	local level = model:GetAttribute("TowerLevel")

	if typeof(towerName) ~= "string" or typeof(ownerUserId) ~= "number" or typeof(level) ~= "number" then
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
	setUpgradeEnabled(isOwner and nextLevel ~= nil and not upgradeRequestInFlight)
end

local function requestUpgrade()
	local model = selectedModel

	if not model or upgradeRequestInFlight then
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

function TowerMenuUI.Start(unitUpgrade: GuiObject)
	local main = unitUpgrade:WaitForChild("Main")
	local upgrade = unitUpgrade:WaitForChild("Upgrade") :: GuiButton

	menu = unitUpgrade
	titleLabel = unitUpgrade:WaitForChild("Title") :: TextLabel
	ownerLabel = unitUpgrade:WaitForChild("Owner") :: TextLabel
	currentDamageLabel = main:WaitForChild("PrevDmg") :: TextLabel
	currentRangeLabel = main:WaitForChild("PrevRange") :: TextLabel
	currentCooldownLabel = main:WaitForChild("PrevCool") :: TextLabel
	nextDamageLabel = main:WaitForChild("NewDmg") :: TextLabel
	nextRangeLabel = main:WaitForChild("NewRange") :: TextLabel
	nextCooldownLabel = main:WaitForChild("NewCool") :: TextLabel
	upgradeButton = upgrade
	upgradeCostLabel = upgrade:WaitForChild("Cost") :: TextLabel
	unitUpgrade.Active = true
	unitUpgrade.Visible = false

	upgradeActivatedConnection = upgrade.Activated:Connect(requestUpgrade)
end

function TowerMenuUI.Show(model: Model)
	TowerMenuUI.Hide()

	selectedModel = model
	levelChangedConnection = model:GetAttributeChangedSignal("TowerLevel"):Connect(update)
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

	selectedModel = nil
	setUpgradeEnabled(false)

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

	menu = nil
	titleLabel = nil
	ownerLabel = nil
	currentDamageLabel = nil
	currentRangeLabel = nil
	currentCooldownLabel = nil
	nextDamageLabel = nil
	nextRangeLabel = nil
	nextCooldownLabel = nil
	upgradeButton = nil
	upgradeCostLabel = nil
end

return TowerMenuUI
