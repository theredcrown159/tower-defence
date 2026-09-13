--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local towerModels = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Towers")
local towerRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Towers")
local placeFunction = towerRemotes:WaitForChild("Place") :: RemoteFunction
local towerZones = Workspace:WaitForChild("MapData"):WaitForChild("TowerZones")

local TowerPlacementController = {}

local previewModel: Model? = nil
local previewHighlight: Highlight? = nil
local selectedTowerName: string? = nil
local previewPosition: Vector3? = nil
local canPlace = false
local placing = false
local connections: { RBXScriptConnection } = {}
local started = false

local MINIMUM_TOWER_DISTANCE = 4
local RAY_DISTANCE = 2000
local VALID_COLOR = Color3.fromRGB(70, 255, 100)
local INVALID_COLOR = Color3.fromRGB(255, 70, 70)

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function stopPlacement()
	if previewModel then
		previewModel:Destroy()
	end

	previewModel = nil
	previewHighlight = nil
	selectedTowerName = nil
	previewPosition = nil
	canPlace = false
	placing = false
end

local function preparePreview(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Transparency = math.max(descendant.Transparency, 0.35)
		end
	end
end

local function startPlacement(towerName: string)
	local template = towerModels:FindFirstChild(towerName)

	if not template or not template:IsA("Model") then
		warn(`Tower model "{towerName}" not found`)
		return
	end

	stopPlacement()

	local model = template:Clone()
	model.Name = "TowerPreview"
	preparePreview(model)
	model.Parent = Workspace

	local highlight = Instance.new("Highlight")
	highlight.Adornee = model
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = model

	previewModel = model
	previewHighlight = highlight
	selectedTowerName = towerName
end

local function getMousePosition(): Vector3?
	local camera = Workspace.CurrentCamera

	if not camera then
		return nil
	end

	local excluded: { Instance } = {}
	local towerVisuals = Workspace:FindFirstChild("TowerVisuals")
	local enemyVisuals = Workspace:FindFirstChild("EnemyVisuals")

	if towerVisuals then
		table.insert(excluded, towerVisuals)
	end

	if enemyVisuals then
		table.insert(excluded, enemyVisuals)
	end

	table.insert(excluded, towerZones)

	if previewModel then
		table.insert(excluded, previewModel)
	end

	raycastParams.FilterDescendantsInstances = excluded

	local mousePosition = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * RAY_DISTANCE, raycastParams)

	return if result then result.Position else nil
end

local function getValidPosition(position: Vector3): Vector3?
	for _, zone in towerZones:GetChildren() do
		if not zone:IsA("BasePart") then
			continue
		end

		local localPosition = zone.CFrame:PointToObjectSpace(position)
		local halfSize = zone.Size / 2

		local isInsideX = math.abs(localPosition.X) <= halfSize.X
		local isInsideZ = math.abs(localPosition.Z) <= halfSize.Z

		if isInsideX and isInsideZ then
			return position
		end
	end

	return nil
end

local function isPositionFree(position: Vector3): boolean
	local towerVisuals = Workspace:FindFirstChild("TowerVisuals")

	if not towerVisuals then
		return true
	end

	for _, towerModel in towerVisuals:GetChildren() do
		if not towerModel:IsA("Model") then
			continue
		end

		local towerPosition = towerModel:GetPivot().Position
		local offsetX = towerPosition.X - position.X
		local offsetZ = towerPosition.Z - position.Z
		local distanceSquared = offsetX * offsetX + offsetZ * offsetZ

		if distanceSquared < MINIMUM_TOWER_DISTANCE ^ 2 then
			return false
		end
	end

	return true
end

local function updatePreview()
	if not previewModel or not previewHighlight then
		return
	end

	local mousePosition = getMousePosition()

	if not mousePosition then
		canPlace = false
		previewPosition = nil
		previewHighlight.FillColor = INVALID_COLOR
		return
	end

	local validPosition = getValidPosition(mousePosition)
	local displayPosition = validPosition or mousePosition

	previewModel:PivotTo(CFrame.new(displayPosition))

	canPlace = validPosition ~= nil and isPositionFree(validPosition)
	previewPosition = if canPlace then validPosition else nil
	previewHighlight.FillColor = if canPlace then VALID_COLOR else INVALID_COLOR
end

local function placeTower()
	if placing or not canPlace or not selectedTowerName or not previewPosition then
		return
	end

	placing = true
	local wasPlaced = placeFunction:InvokeServer(selectedTowerName, previewPosition)
	placing = false

	if wasPlaced then
		stopPlacement()
	end
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.One then
		startPlacement("Classical")
	elseif input.KeyCode == Enum.KeyCode.Escape then
		stopPlacement()
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		placeTower()
	end
end

function TowerPlacementController.Start(): boolean
	if started then
		return false
	end

	table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))
	table.insert(connections, RunService.RenderStepped:Connect(updatePreview))
	started = true

	return true
end

function TowerPlacementController.Stop(): boolean
	if not started then
		return false
	end

	for _, connection in connections do
		connection:Disconnect()
	end

	table.clear(connections)
	stopPlacement()
	started = false

	return true
end

return TowerPlacementController
