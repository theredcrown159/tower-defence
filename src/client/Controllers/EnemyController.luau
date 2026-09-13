--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local enemyRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Enemies")
local spawnedEvent = enemyRemotes:WaitForChild("Spawned")
local removedEvent = enemyRemotes:WaitForChild("Removed")
local readyEvent = enemyRemotes:WaitForChild("Ready")
local updatedEvent = enemyRemotes:WaitForChild("Updated")

local enemyModels = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Enemies")

local EnemyHealthUI = require(script.Parent.EnemyHealthUI)
local NetworkConfig = require(ReplicatedStorage.Shared.Config.NetworkConfig)
local PositionBuffer = require(script.Parent.Parent.Util.PositionBuffer)

local EnemyController = {}

type EnemyPositionSnapshot = {
	Id: number,
	Position: Vector3,
	Health: number,
}

type FadePart = {
	Part: BasePart,
	InitialTransparency: number,
}

type DeathAnimation = {
	Elapsed: number,
	Parts: { FadePart },
}

local enemies: { [number]: Model } = {}
local positionBuffers: { [number]: PositionBuffer.Buffer } = {}
local deathAnimations: { [number]: DeathAnimation } = {}
local connections: { RBXScriptConnection } = {}
local started = false

local DEATH_DURATION = 0.25
local TURN_SPEED = 12
local MIN_DIRECTION_MAGNITUDE = 0.001

local function getVisualsFolder(): Folder
	local existing = Workspace:FindFirstChild("EnemyVisuals")

	if existing then
		if not existing:IsA("Folder") then
			error("Workspace.EnemyVisuals must be a Folder")
		end

		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = "EnemyVisuals"
	folder.Parent = Workspace

	return folder
end

local function destroyEnemyVisual(id: number)
	EnemyHealthUI.Remove(id)

	local model = enemies[id]

	if model then
		model:Destroy()
	end

	enemies[id] = nil
	positionBuffers[id] = nil
	deathAnimations[id] = nil
end

local function beginDeath(id: number): boolean
	local model = enemies[id]

	if not model or deathAnimations[id] then
		return false
	end

	local parts: { FadePart } = {}

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanQuery = false
			table.insert(parts, {
				Part = descendant,
				InitialTransparency = descendant.Transparency,
			})
		end
	end

	deathAnimations[id] = {
		Elapsed = 0,
		Parts = parts,
	}

	return true
end

local function onEnemySpawned(
	id: number,
	modelName: string,
	position: Vector3,
	timestamp: number,
	health: number,
	maxHealth: number
)
	local template = enemyModels:FindFirstChild(modelName)

	if not template or not template:IsA("Model") then
		warn(`Enemy model "{modelName}" not found`)
		return
	end

	destroyEnemyVisual(id)

	local model = template:Clone()
	model:PivotTo(CFrame.new(position))
	model.Parent = getVisualsFolder()
	EnemyHealthUI.Create(id, model, modelName, health, maxHealth)

	local buffer: PositionBuffer.Buffer = {}
	PositionBuffer.Push(buffer, timestamp, position)
	positionBuffers[id] = buffer
	enemies[id] = model
end

local function onEnemyRemoved(id: number, reason: string)
	if reason == "Dead" then
		EnemyHealthUI.Remove(id)
		beginDeath(id)
		return
	end

	destroyEnemyVisual(id)
end

local function onEnemiesUpdated(positions: { EnemyPositionSnapshot }, timestamp: number)
	for _, snapshot in ipairs(positions) do
		local id = snapshot.Id
		local model = enemies[id]

		if not model or deathAnimations[id] then
			continue
		end

		local buffer = positionBuffers[id]
		if buffer then
			PositionBuffer.Push(buffer, timestamp, snapshot.Position)
		end

		EnemyHealthUI.Update(id, snapshot.Health)
	end
end

local function updateMovement(deltaTime: number)
	local renderTime = Workspace:GetServerTimeNow() - NetworkConfig.EnemyInterpolationDelay

	for id, model in enemies do
		if deathAnimations[id] then
			continue
		end

		local buffer = positionBuffers[id]
		if not buffer then
			continue
		end

		local position = PositionBuffer.Sample(buffer, renderTime)
		if not position then
			continue
		end

		local pivot = model:GetPivot()
		local rotation = pivot.Rotation
		local movement = position - pivot.Position
		local flatDirection = Vector3.new(movement.X, 0, movement.Z)

		if flatDirection.Magnitude > MIN_DIRECTION_MAGNITUDE then
			local targetRotation = CFrame.lookAt(Vector3.zero, flatDirection.Unit)
			local turnAlpha = 1 - math.exp(-TURN_SPEED * deltaTime)

			rotation = rotation:Lerp(targetRotation, turnAlpha)
		end

		model:PivotTo(CFrame.new(position) * rotation)
	end
end

local function updateDeaths(deltaTime: number)
	local completed: { number } = {}

	for id, animation in deathAnimations do
		animation.Elapsed = math.min(animation.Elapsed + deltaTime, DEATH_DURATION)
		local alpha = animation.Elapsed / DEATH_DURATION

		for _, fadePart in animation.Parts do
			if fadePart.Part.Parent then
				fadePart.Part.Transparency = fadePart.InitialTransparency + (1 - fadePart.InitialTransparency) * alpha
			end
		end

		if animation.Elapsed >= DEATH_DURATION then
			table.insert(completed, id)
		end
	end

	for _, id in completed do
		destroyEnemyVisual(id)
	end
end

local function onRenderStep(deltaTime: number)
	updateMovement(deltaTime)
	updateDeaths(deltaTime)
end

function EnemyController.GetModel(id: number): Model?
	return enemies[id]
end

function EnemyController.Start(): boolean
	if started then
		return false
	end

	table.insert(connections, spawnedEvent.OnClientEvent:Connect(onEnemySpawned))
	table.insert(connections, removedEvent.OnClientEvent:Connect(onEnemyRemoved))
	table.insert(connections, updatedEvent.OnClientEvent:Connect(onEnemiesUpdated))
	table.insert(connections, RunService.RenderStepped:Connect(onRenderStep))
	started = true

	readyEvent:FireServer()

	return true
end

function EnemyController.Stop(): boolean
	if not started then
		return false
	end

	for _, connection in connections do
		connection:Disconnect()
	end

	local ids: { number } = {}
	for id in enemies do
		table.insert(ids, id)
	end

	for _, id in ids do
		destroyEnemyVisual(id)
	end

	EnemyHealthUI.Clear()
	table.clear(connections)
	started = false

	return true
end

return EnemyController
