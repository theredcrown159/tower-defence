--!strict

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local HUDController = require(script.Parent.HUDController)

local TowerSelectionController = {}

local connections: { RBXScriptConnection } = {}
local towerVisuals: Folder? = nil
local selectedTower: Model? = nil
local started = false

local RAY_DISTANCE = 2000

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include

local function getTowerModel(instance: Instance): Model?
	local folder = towerVisuals
	local current: Instance? = instance

	if not folder then
		return nil
	end

	while current and current.Parent ~= folder do
		current = current.Parent
	end

	return if current and current:IsA("Model") then current else nil
end

local function selectAt(screenPosition: Vector3)
	local folder = towerVisuals
	local camera = Workspace.CurrentCamera

	if not folder or not camera then
		return
	end

	raycastParams.FilterDescendantsInstances = { folder }

	local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * RAY_DISTANCE, raycastParams)
	local tower = if result then getTowerModel(result.Instance) else nil

	if not tower then
		selectedTower = nil
		HUDController.HideTowerMenu()
		return
	end

	local towerName = tower:GetAttribute("TowerName")
	local ownerUserId = tower:GetAttribute("OwnerUserId")

	if typeof(towerName) ~= "string" or typeof(ownerUserId) ~= "number" then
		return
	end

	selectedTower = tower
	HUDController.ShowTowerMenu(towerName, ownerUserId)
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape then
		selectedTower = nil
		HUDController.HideTowerMenu()
		return
	end

	local isPointerInput = input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch

	if isPointerInput and not Workspace:FindFirstChild("TowerPreview") then
		selectAt(input.Position)
	end
end

local function onTowerRemoved(child: Instance)
	if child == selectedTower then
		selectedTower = nil
		HUDController.HideTowerMenu()
	end
end

function TowerSelectionController.Start(): boolean
	if started then
		return false
	end

	towerVisuals = Workspace:WaitForChild("TowerVisuals") :: Folder
	table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))
	table.insert(connections, towerVisuals.ChildRemoved:Connect(onTowerRemoved))
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

	table.clear(connections)
	selectedTower = nil
	towerVisuals = nil
	HUDController.HideTowerMenu()
	started = false

	return true
end

return TowerSelectionController
