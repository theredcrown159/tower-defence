--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tower = require(script.Parent.Parent.Domain.Towers.Tower)
local TowerService = require(script.Parent.TowerService)

type TowerType = Tower.Tower

local towerRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Towers")
local placedEvent = towerRemotes:WaitForChild("Placed")
local removedEvent = towerRemotes:WaitForChild("Removed")
local attackedEvent = towerRemotes:WaitForChild("Attacked")
local readyEvent = towerRemotes:WaitForChild("Ready")

local TowerReplicationService = {}

local readyPlayers: { [Player]: boolean } = {}
local connections: { RBXScriptConnection } = {}
local started = false

local function sendTowerToPlayer(player: Player, id: number, tower: TowerType)
	placedEvent:FireClient(player, id, tower:GetModelName(), tower:GetPosition(), tower:GetOwnerUserId())
end

local function onPlayerReady(player: Player)
	if not player:IsDescendantOf(Players) or readyPlayers[player] then
		return
	end

	readyPlayers[player] = true

	for id, tower in TowerService.GetAll() do
		sendTowerToPlayer(player, id, tower)
	end
end

local function onPlayerRemoving(player: Player)
	readyPlayers[player] = nil
end

local function onTowerPlaced(id: number, towerName: string, position: Vector3, ownerUserId: number)
	for player in readyPlayers do
		if player:IsDescendantOf(Players) then
			placedEvent:FireClient(player, id, towerName, position, ownerUserId)
		end
	end
end

local function onTowerRemoved(id: number)
	for player in readyPlayers do
		if player:IsDescendantOf(Players) then
			removedEvent:FireClient(player, id)
		end
	end
end

local function onTowerAttacked(towerId: number, targetId: number, damage: number)
	for player in readyPlayers do
		if player:IsDescendantOf(Players) then
			attackedEvent:FireClient(player, towerId, targetId, damage)
		end
	end
end

function TowerReplicationService.Start(): boolean
	if started then
		return false
	end

	table.insert(connections, readyEvent.OnServerEvent:Connect(onPlayerReady))
	table.insert(connections, Players.PlayerRemoving:Connect(onPlayerRemoving))
	table.insert(connections, TowerService.TowerPlaced:Connect(onTowerPlaced))
	table.insert(connections, TowerService.TowerRemoved:Connect(onTowerRemoved))
	table.insert(connections, TowerService.TowerAttacked:Connect(onTowerAttacked))

	started = true

	return true
end

function TowerReplicationService.Stop(): boolean
	if not started then
		return false
	end

	for _, connection in connections do
		connection:Disconnect()
	end

	table.clear(connections)
	table.clear(readyPlayers)
	started = false

	return true
end

return TowerReplicationService
