--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local HUDController = require(script.Parent.HUDController)
local TowerDefinitions = require(ReplicatedStorage.Shared.Config.TowerDefinitions)
local VFXController = require(script.Parent.VFXController)

local TowerSelectionController = {}

type DetectorRecord = {
	Detector: ClickDetector,
	Connection: RBXScriptConnection,
}

local detectors: { [Model]: DetectorRecord } = {}
local connections: { RBXScriptConnection } = {}
local selectedTower: Model? = nil
local selectedTowerLevelConnection: RBXScriptConnection? = nil
local rangePreview: Model? = nil
local started = false

local MAX_ACTIVATION_DISTANCE = 100

local function destroyRangePreview()
	if rangePreview then
		VFXController.RemoveRangeIndicator(rangePreview)
		rangePreview = nil
	end
end

local function updateRangePreview()
	destroyRangePreview()

	local model = selectedTower

	if not model then
		return
	end

	local towerName = model:GetAttribute("TowerName")
	local level = model:GetAttribute("TowerLevel")

	if typeof(towerName) ~= "string" or typeof(level) ~= "number" then
		return
	end

	local definition = TowerDefinitions[towerName]

	if not definition then
		return
	end

	local levelIndex = math.clamp(math.floor(level), 1, #definition.Levels)
	local range = definition.Levels[levelIndex].Range
	local preview = VFXController.CreateRangeIndicator(range)

	if not preview then
		return
	end

	VFXController.SetRangeIndicatorPosition(preview, model:GetPivot().Position)
	rangePreview = preview
end

local function safelyUpdateRangePreview()
	local succeeded, errorMessage = pcall(updateRangePreview)

	if not succeeded then
		destroyRangePreview()
		warn(`Could not show tower range: {errorMessage}`)
	end
end

local function hideSelection()
	if selectedTowerLevelConnection then
		selectedTowerLevelConnection:Disconnect()
		selectedTowerLevelConnection = nil
	end

	selectedTower = nil
	destroyRangePreview()
	HUDController.HideTowerMenu()
end

local function selectTower(model: Model)
	if selectedTowerLevelConnection then
		selectedTowerLevelConnection:Disconnect()
	end

	selectedTower = model
	HUDController.ShowTowerMenu(model)
	selectedTowerLevelConnection = model:GetAttributeChangedSignal("TowerLevel"):Connect(safelyUpdateRangePreview)
	safelyUpdateRangePreview()
end

function TowerSelectionController.Unregister(model: Model)
	local record = detectors[model]

	if record then
		record.Connection:Disconnect()
		record.Detector:Destroy()
		detectors[model] = nil
	end

	if selectedTower == model then
		hideSelection()
	end
end

function TowerSelectionController.Register(model: Model)
	TowerSelectionController.Unregister(model)

	local detector = Instance.new("ClickDetector")
	detector.Name = "TowerClickDetector"
	detector.MaxActivationDistance = MAX_ACTIVATION_DISTANCE
	detector.Parent = model

	local connection = detector.MouseClick:Connect(function(playerWhoClicked: Player)
		if playerWhoClicked ~= Players.LocalPlayer or Workspace:FindFirstChild("TowerPreview") then
			return
		end

		selectTower(model)
	end)

	detectors[model] = {
		Detector = detector,
		Connection = connection,
	}
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape then
		hideSelection()
		return
	end

	local isPointerInput = input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch

	if isPointerInput and not Workspace:FindFirstChild("TowerPreview") then
		hideSelection()
	end
end

function TowerSelectionController.Start(): boolean
	if started then
		return false
	end

	table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))
	started = true

	return true
end

function TowerSelectionController.Stop(): boolean
	if not started then
		return false
	end

	for _, connection in connections do
		connection:Disconnect()
	end

	local models: { Model } = {}
	for model in detectors do
		table.insert(models, model)
	end

	for _, model in models do
		TowerSelectionController.Unregister(model)
	end

	table.clear(connections)
	hideSelection()
	started = false

	return true
end

return TowerSelectionController
