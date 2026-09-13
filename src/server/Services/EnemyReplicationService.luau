--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local NetworkConfig = require(ReplicatedStorage.Shared.Config.NetworkConfig)

local Enemy = require(script.Parent.Parent.Domain.Enemies.Enemy)
local EnemyService = require(script.Parent.EnemyService)

type EnemyType = Enemy.Enemy
type EnemyPositionSnapshot = {
	Id: number,
	Position: Vector3,
	Health: number,
}

local enemyRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Enemies")
local spawnedEvent = enemyRemotes:WaitForChild("Spawned")
local removedEvent = enemyRemotes:WaitForChild("Removed")
local readyEvent = enemyRemotes:WaitForChild("Ready")
local updatedEvent = enemyRemotes:WaitForChild("Updated")

local EnemyReplicationService = {}

local readyPlayers: { [Player]: boolean } = {}
local connections: { RBXScriptConnection } = {}
local started: boolean = false

local SEND_INTERVAL = NetworkConfig.EnemySnapshotInterval
local sendAccumulator = 0

local function sendEnemyToPlayer(player: Player, id: number, enemy: EnemyType)
	spawnedEvent:FireClient(
		player,
		id,
		enemy:GetModelName(),
		enemy:GetPosition(),
		Workspace:GetServerTimeNow(),
		enemy:GetHealth(),
		enemy:GetMaxHealth()
	)
end

local function onPlayerReady(player: Player)
	local isActive = player:IsDescendantOf(Players)
	if not isActive then
		return
	end

	local isReady = readyPlayers[player]
	if isReady then
		return
	end

	readyPlayers[player] = true

	local enemies = EnemyService.GetAll()
	for id, enemy in pairs(enemies) do
		if enemy:IsDead() or enemy:HasReachedBase() then
			continue
		end
		sendEnemyToPlayer(player, id, enemy)
	end
end

local function onPlayerRemoving(player: Player)
	readyPlayers[player] = nil
end

local function onEnemySpawned(id: number, _enemyName: string)
	local enemy = EnemyService.GetById(id)

	if not enemy then
		return
	end

	for player in pairs(readyPlayers) do
		if player:IsDescendantOf(Players) then
			sendEnemyToPlayer(player, id, enemy)
		end
	end
end

local function onEnemyRemoved(id: number, reason: EnemyService.RemovalReason, _baseDamage: number, _reward: number)
	for player, _ in pairs(readyPlayers) do
		local isActive = player:IsDescendantOf(Players)
		if not isActive then
			continue
		end

		removedEvent:FireClient(player, id, reason)
	end
end

local function sendPositions()
	local timestamp = Workspace:GetServerTimeNow()
	local positions: { EnemyPositionSnapshot } = {}

	local enemies = EnemyService.GetAll()
	for id, enemy in pairs(enemies) do
		if enemy:IsDead() or enemy:HasReachedBase() then
			continue
		end
		table.insert(positions, {
			Id = id,
			Position = enemy:GetPosition(),
			Health = enemy:GetHealth(),
		})
	end

	for player, _ in pairs(readyPlayers) do
		local isActive = player:IsDescendantOf(Players)
		if not isActive then
			continue
		end

		updatedEvent:FireClient(player, positions, timestamp)
	end
end

local function onHeartbeat(realDeltaTime: number)
	sendAccumulator += realDeltaTime

	if sendAccumulator < SEND_INTERVAL then
		return
	end

	sendAccumulator %= SEND_INTERVAL
	sendPositions()
end

function EnemyReplicationService.Start(): boolean
	if started then
		return false
	end

	table.insert(connections, readyEvent.OnServerEvent:Connect(onPlayerReady))
	table.insert(connections, Players.PlayerRemoving:Connect(onPlayerRemoving))
	table.insert(connections, EnemyService.EnemySpawned:Connect(onEnemySpawned))
	table.insert(connections, EnemyService.EnemyRemoved:Connect(onEnemyRemoved))
	table.insert(connections, RunService.Heartbeat:Connect(onHeartbeat))

	started = true

	return true
end

function EnemyReplicationService.Stop(): boolean
	if not started then
		return false
	end

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end

	table.clear(connections)
	table.clear(readyPlayers)

	sendAccumulator = 0

	started = false

	return true
end

return EnemyReplicationService
