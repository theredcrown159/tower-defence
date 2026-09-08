--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enemy = require(script.Parent.Parent.Domain.Enemies.Enemy)
local EnemyDefinitions = require(ReplicatedStorage.Shared.Config.EnemyDefinitions)
local MapService = require(script.Parent.MapService)
local SimulationService = require(script.Parent.SimulationService)

type EnemyType = Enemy.Enemy
export type RemovalReason = "Dead" | "ReachedBase" | "Cleared"

type PendingRemoval = {
	Id: number,
	Reason: RemovalReason,
}

local EnemyService = {}

local enemySpawnedEvent = Instance.new("BindableEvent")
EnemyService.EnemySpawned = enemySpawnedEvent.Event

local enemyRemovedEvent = Instance.new("BindableEvent")
EnemyService.EnemyRemoved = enemyRemovedEvent.Event

local activeEnemies: { [number]: EnemyType } = {}
local nextEnemyId: number = 0
local simulationConnection: RBXScriptConnection? = nil

local function removeEnemy(id: number, reason: RemovalReason): boolean
	local enemy = activeEnemies[id]

	if not enemy then
		return false
	end

	activeEnemies[id] = nil
	enemyRemovedEvent:Fire(id, enemy, reason)

	return true
end

local function onSimulationStep(fixedDeltaTime: number, _gameTime: number)
	local pendingRemovals: { PendingRemoval } = {}

	for id, enemy in activeEnemies do
		enemy:Step(fixedDeltaTime)

		local reason: RemovalReason? = nil

		if enemy:IsDead() then
			reason = "Dead"
		elseif enemy:HasReachedBase() then
			reason = "ReachedBase"
		end

		if reason then
			table.insert(pendingRemovals, {
				Id = id,
				Reason = reason,
			})
		end
	end

	for _, removal in pendingRemovals do
		removeEnemy(removal.Id, removal.Reason)
	end
end

function EnemyService.Spawn(enemyName: string): number
	local enemyDefinition = EnemyDefinitions[enemyName]

	if not enemyDefinition then
		error('Enemy with name "' .. enemyName .. '" not found!')
	end

	local route = MapService.GetRoute()

	if not route then
		error("Map is not loaded!")
	end

	local enemy = Enemy.new(enemyDefinition, route)

	nextEnemyId += 1
	local enemyId = nextEnemyId

	activeEnemies[enemyId] = enemy
	enemySpawnedEvent:Fire(enemyId, enemyName)

	return enemyId
end

function EnemyService.GetById(id: number): EnemyType?
	return activeEnemies[id]
end

function EnemyService.GetAll(): { [number]: EnemyType }
	return table.clone(activeEnemies)
end

function EnemyService.GetCount(): number
	local count = 0

	for _ in activeEnemies do
		count += 1
	end

	return count
end

function EnemyService.DamageEnemy(id: number, damage: number): boolean
	local enemy = EnemyService.GetById(id)

	if not enemy then
		return false
	end

	return enemy:TakeDamage(damage)
end

function EnemyService.Remove(id: number): boolean
	return removeEnemy(id, "Cleared")
end

function EnemyService.Clear(): number
	local ids: { number } = {}

	for id in activeEnemies do
		table.insert(ids, id)
	end

	for _, id in ids do
		removeEnemy(id, "Cleared")
	end

	return #ids
end

function EnemyService.IsRunning(): boolean
	return simulationConnection ~= nil
end

function EnemyService.Start(): boolean
	if simulationConnection then
		return false
	end

	if not MapService.IsLoaded() then
		error("EnemyService cannot start before MapService is loaded")
	end

	simulationConnection = SimulationService.Stepped:Connect(onSimulationStep)

	return true
end

function EnemyService.Stop(): boolean
	if not simulationConnection then
		return false
	end

	simulationConnection:Disconnect()
	simulationConnection = nil

	return true
end

function EnemyService.Reset(): boolean
	if simulationConnection then
		return false
	end

	EnemyService.Clear()
	nextEnemyId = 0

	return true
end

return EnemyService
