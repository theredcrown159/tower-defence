--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local enemyRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Enemies")
local spawnedEvent = enemyRemotes:WaitForChild("Spawned")
local removedEvent = enemyRemotes:WaitForChild("Removed")
local readyEvent = enemyRemotes:WaitForChild("Ready")
local updatedEvent = enemyRemotes:WaitForChild("Updated")

local enemyModels = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Enemies")

local EnemyController = {}
local started = false

type EnemyPositionSnapshot = {
	Id: number,
	Position: Vector3,
}

local enemies: { [number]: Model } = {}

local SNAPSHOT_INTERVAL = 0.1
local TURN_SPEED = 12
local MIN_DIRECTION_MAGNITUDE = 0.001

local previousPositions: { [number]: Vector3 } = {}
local targetPositions: { [number]: Vector3 } = {}
local interpolationTimes: { [number]: number } = {}

local function onEnemySpawned(id: number, modelName: string, position: Vector3)
	local model = enemyModels:FindFirstChild(modelName):Clone()
	model:PivotTo(CFrame.new(position))
	model.Parent = game.Workspace.EnemyVisuals

	previousPositions[id] = position
	targetPositions[id] = position
	interpolationTimes[id] = SNAPSHOT_INTERVAL

	enemies[id] = model
	targetPositions[id] = position
end

local function onEnemyRemoved(id: number, _reason: string)
	local model = enemies[id]
	if model then
		model:Destroy()
	end

	enemies[id] = nil
	previousPositions[id] = nil
	targetPositions[id] = nil
	interpolationTimes[id] = nil
end

local function onEnemiesUpdated(positions: { EnemyPositionSnapshot })
	for _, snapshot in ipairs(positions) do
		local id = snapshot.Id
		local position = snapshot.Position
		local model = enemies[id]

		if not model then
			continue
		end

		previousPositions[id] = model:GetPivot().Position
		targetPositions[id] = position
		interpolationTimes[id] = 0
	end
end

local function onRenderStep(deltaTime: number)
	for id, model in enemies do
		local previousPosition = previousPositions[id]
		local targetPosition = targetPositions[id]
		local interpolationTime = interpolationTimes[id]

		if not previousPosition or not targetPosition or interpolationTime == nil then
			continue
		end

		interpolationTime = math.min(interpolationTime + deltaTime, SNAPSHOT_INTERVAL)

		interpolationTimes[id] = interpolationTime

		local alpha = interpolationTime / SNAPSHOT_INTERVAL
		local position = previousPosition:Lerp(targetPosition, alpha)
		local rotation = model:GetPivot().Rotation
		local movement = targetPosition - previousPosition
		local flatDirection = Vector3.new(movement.X, 0, movement.Z)

		if flatDirection.Magnitude > MIN_DIRECTION_MAGNITUDE then
			local targetRotation = CFrame.lookAt(Vector3.zero, flatDirection.Unit)
			local turnAlpha = 1 - math.exp(-TURN_SPEED * deltaTime)

			rotation = rotation:Lerp(targetRotation, turnAlpha)
		end

		model:PivotTo(CFrame.new(position) * rotation)
	end
end

function EnemyController.Start(): boolean
	if started then
		return false
	end

	spawnedEvent.OnClientEvent:Connect(onEnemySpawned)
	removedEvent.OnClientEvent:Connect(onEnemyRemoved)
	updatedEvent.OnClientEvent:Connect(onEnemiesUpdated)

	RunService.RenderStepped:Connect(onRenderStep)
	started = true

	readyEvent:FireServer()

	return true
end

return EnemyController
