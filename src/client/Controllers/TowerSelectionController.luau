--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local HUDController = require(script.Parent.HUDController)

local TowerSelectionController = {}

type DetectorRecord = {
	Detector: ClickDetector,
	Connection: RBXScriptConnection,
}

local detectors: { [Model]: DetectorRecord } = {}
local connections: { RBXScriptConnection } = {}
local selectedTower: Model? = nil
local started = false

local MAX_ACTIVATION_DISTANCE = 100

local function hideSelection()
	selectedTower = nil
	HUDController.HideTowerMenu()
end

local function selectTower(model: Model)
	selectedTower = model
	HUDController.ShowTowerMenu(model)
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
