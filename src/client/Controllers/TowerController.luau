--!strict

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local EnemyController = require(script.Parent.EnemyController)

local towerRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Towers")
local placedEvent = towerRemotes:WaitForChild("Placed")
local removedEvent = towerRemotes:WaitForChild("Removed")
local attackedEvent = towerRemotes:WaitForChild("Attacked")
local readyEvent = towerRemotes:WaitForChild("Ready")

local towerModels = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Towers")

local TowerController = {}

local towers: { [number]: Model } = {}
local connections: { RBXScriptConnection } = {}
local started = false

local BEAM_LIFETIME = 0.15
local BEAM_WIDTH = 0.12
local MIN_DIRECTION_MAGNITUDE = 0.001
local TOWER_YAW_OFFSET = CFrame.Angles(0, math.rad(0), 0)

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

local function getEffectsFolder(): Folder
	local existing = Workspace:FindFirstChild("TowerEffects")

	if existing then
		if not existing:IsA("Folder") then
			error("Workspace.TowerEffects must be a Folder")
		end

		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = "TowerEffects"
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

local function createBeamEndpoint(position: Vector3): (Part, Attachment)
	local part = Instance.new("Part")
	part.Name = "BeamEndpoint"
	part.Size = Vector3.one * 0.1
	part.CFrame = CFrame.new(position)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = getEffectsFolder()

	local attachment = Instance.new("Attachment")
	attachment.Parent = part

	return part, attachment
end

local function createAttackBeam(origin: Vector3, target: Vector3)
	local originPart, originAttachment = createBeamEndpoint(origin)
	local targetPart, targetAttachment = createBeamEndpoint(target)

	local beam = Instance.new("Beam")
	beam.Name = "AttackBeam"
	beam.Attachment0 = originAttachment
	beam.Attachment1 = targetAttachment
	beam.Color = ColorSequence.new(Color3.new(1, 1, 1))
	beam.Transparency = NumberSequence.new(0)
	beam.Width0 = BEAM_WIDTH
	beam.Width1 = BEAM_WIDTH * 0.75
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Parent = originPart

	Debris:AddItem(originPart, BEAM_LIFETIME)
	Debris:AddItem(targetPart, BEAM_LIFETIME)
end

local function getBeamOrigin(model: Model): Vector3
	local muzzle = model:FindFirstChild("Muzzle", true)

	if muzzle and muzzle:IsA("Attachment") then
		return muzzle.WorldPosition
	end

	return model:GetPivot().Position
end

local function faceTarget(model: Model, targetPosition: Vector3)
	local pivot = model:GetPivot()
	local flatTarget = Vector3.new(targetPosition.X, pivot.Position.Y, targetPosition.Z)
	local direction = flatTarget - pivot.Position

	if direction.Magnitude <= MIN_DIRECTION_MAGNITUDE then
		return
	end

	model:PivotTo(CFrame.lookAt(pivot.Position, flatTarget) * TOWER_YAW_OFFSET)
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
end

local function onTowerAttacked(towerId: number, targetId: number, _damage: number)
	local towerModel = towers[towerId]
	local enemyModel = EnemyController.GetModel(targetId)

	if not towerModel or not enemyModel then
		return
	end

	local targetPosition = enemyModel:GetPivot().Position
	faceTarget(towerModel, targetPosition)
	createAttackBeam(getBeamOrigin(towerModel), targetPosition)
end

function TowerController.GetModel(id: number): Model?
	return towers[id]
end

function TowerController.Start(): boolean
	if started then
		return false
	end

	table.insert(connections, placedEvent.OnClientEvent:Connect(onTowerPlaced))
	table.insert(connections, removedEvent.OnClientEvent:Connect(onTowerRemoved))
	table.insert(connections, attackedEvent.OnClientEvent:Connect(onTowerAttacked))
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

	table.clear(connections)
	started = false

	return true
end

return TowerController
