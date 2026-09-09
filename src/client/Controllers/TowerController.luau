--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EnemyController = require(script.Parent.EnemyController)

local towerRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Towers")
local placedEvent = towerRemotes:WaitForChild("Placed")
local removedEvent = towerRemotes:WaitForChild("Removed")
local readyEvent = towerRemotes:WaitForChild("Ready")

local towerModels = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Towers")

local TowerController = {}

local towers: { [number]: Model } = {}
local towerTargets: { [number]: number } = {}
local connections: { RBXScriptConnection } = {}
local started = false

local MIN_DIRECTION_MAGNITUDE = 0.001
local TURN_SPEED = 12
local TOWER_YAW_OFFSET = CFrame.Angles(0, 0, 0)

local function getVisualsFolder(): Folder
	local existing = Workspace:FindFirstChild("TowerVisuals")

	if existing then
		if not existing:IsA("Folder") then
			error("Workspace.TowerVisuals must be a Folder")
		end

		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = "TowerVisuals"
	folder.Parent = Workspace

	return folder
end

local function prepareVisualModel(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
		end
	end
end

local function getHumanoidRootPart(model: Model): BasePart?
	local rootPart = model:FindFirstChild("HumanoidRootPart", true)

	if rootPart and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

local function faceTarget(model: Model, targetPosition: Vector3, deltaTime: number)
	local pivot = model:GetPivot()
	local flatTarget = Vector3.new(targetPosition.X, pivot.Position.Y, targetPosition.Z)
	local direction = flatTarget - pivot.Position

	if direction.Magnitude <= MIN_DIRECTION_MAGNITUDE then
		return
	end

	local targetCFrame = CFrame.lookAt(pivot.Position, flatTarget) * TOWER_YAW_OFFSET
	local alpha = 1 - math.exp(-TURN_SPEED * deltaTime)

	model:PivotTo(pivot:Lerp(targetCFrame, alpha))
end

local function onTowerPlaced(id: number, modelName: string, position: Vector3, _ownerUserId: number)
	local template = towerModels:FindFirstChild(modelName)

	if not template or not template:IsA("Model") then
		warn(`Tower model "{modelName}" not found`)
		return
	end

	local existing = towers[id]

	if existing then
		existing:Destroy()
	end

	local model = template:Clone()
	prepareVisualModel(model)
	model:PivotTo(CFrame.new(position))
	model.Parent = getVisualsFolder()
	towers[id] = model
end

local function onTowerRemoved(id: number)
	local model = towers[id]

	if model then
		model:Destroy()
	end

	towers[id] = nil
	towerTargets[id] = nil
end

local function onRenderStep(deltaTime: number)
	for towerId, targetId in towerTargets do
		local towerModel = towers[towerId]
		local enemyModel = EnemyController.GetModel(targetId)

		if not towerModel or not enemyModel then
			continue
		end

		local enemyRootPart = getHumanoidRootPart(enemyModel)

		if enemyRootPart then
			faceTarget(towerModel, enemyRootPart.Position, deltaTime)
		end
	end
end

function TowerController.GetModel(id: number): Model?
	return towers[id]
end

function TowerController.SetTarget(towerId: number, targetId: number?)
	if not targetId or targetId == 0 then
		towerTargets[towerId] = nil
		return
	end

	towerTargets[towerId] = targetId
end

function TowerController.Start(): boolean
	if started then
		return false
	end

	table.insert(connections, placedEvent.OnClientEvent:Connect(onTowerPlaced))
	table.insert(connections, removedEvent.OnClientEvent:Connect(onTowerRemoved))
	table.insert(connections, RunService.RenderStepped:Connect(onRenderStep))
	started = true

	readyEvent:FireServer()

	return true
end

function TowerController.Stop(): boolean
	if not started then
		return false
	end

	for _, connection in connections do
		connection:Disconnect()
	end

	for id, model in towers do
		model:Destroy()
		towers[id] = nil
	end

	table.clear(towerTargets)
	table.clear(connections)
	started = false

	return true
end

return TowerController
